--[[
File name: RunLSC_Plugin.lua
Author: RadiatedExodus (ItzEthanPlayz_YT/RealEthanPlayzDev)
Created at: May 6, 2022

The core RunLSC code for setting up the plugin toolbars, buttons, etc
--]]

--// Static configuration
local SHARED_INTERNAL_FOLDER_LOCATION = game:GetService("ReplicatedStorage")
local SHARED_INTERNAL_FOLDER_NAME = "RunLSC_InternalStorage"
local SHARED_INTERNAL_FOLDER_CONNECTOR_NAME = "RunLSC_DataModelConnector"
local SHARED_INTERNAL_FOLDER_MSCACHE_NAME = "RunLSC_ModuleScriptCache"
local EMPTY_CLOSURE = function() return end

--// Services
local serv = {
    Selection = game:GetService("Selection");
    RunService = game:GetService("RunService");
    Debris = game:GetService("Debris");
    Players = game:GetService("Players");
    TextService = game:GetService("TextService");
}

--// Libraries
local loadstring = require(script.Parent.lib.LoadstringHelper)
local SettingsManager = require(script.Parent.lib.SettingsManager)
local UIHelper = require(script.Parent.lib.UIHelper)
local Highlighter = require(script.Parent.lib.Highlighter)

--// Replace stdout functions with a wrapped one (except error)
local function _print(...)
	return getfenv()["print"]("[RunLSC]: ", ...)
end
local function warn(...)
	return getfenv()["warn"]("[RunLSC]: ", ...)
end

--// Functions
local function AddToDebris(item: any, lifetime: number?)
    return serv.Debris:AddItem(item, if lifetime == nil then 0 else lifetime)
end

local function SetupInternalSharedStorage()
    if serv.RunService:IsServer() then
		AddToDebris(SHARED_INTERNAL_FOLDER_LOCATION:FindFirstChild(SHARED_INTERNAL_FOLDER_NAME))
	end

    local RootSharedStorage = Instance.new("Folder")
    RootSharedStorage.Archivable = false
    RootSharedStorage.Name = SHARED_INTERNAL_FOLDER_NAME

    local DataModelConnector = Instance.new("RemoteEvent")
    DataModelConnector.Name = SHARED_INTERNAL_FOLDER_CONNECTOR_NAME
    DataModelConnector.Parent = RootSharedStorage

    local ModuleScriptCache = Instance.new("Folder")
    ModuleScriptCache.Name = SHARED_INTERNAL_FOLDER_MSCACHE_NAME
    ModuleScriptCache.Parent = RootSharedStorage

    RootSharedStorage.Parent = SHARED_INTERNAL_FOLDER_LOCATION
    return RootSharedStorage, DataModelConnector, ModuleScriptCache
end

local function CompileAndRun(lsc: Script | LocalScript | ModuleScript, ... : any)
    local Environment = getfenv(EMPTY_CLOSURE)
    table.clear(Environment)
    Environment["script"] = lsc

    local Closure = loadstring(lsc.Source, lsc:GetFullName(), Environment)
    local Ret = {pcall(Closure, ...)}
    local ClosureRunSuccess = table.remove(Ret, 1)
    if not ClosureRunSuccess then
        task.spawn(error, lsc:GetFullName()..": "..Ret[1])
    end
    return ClosureRunSuccess, table.unpack(Ret)
end

local function CreateModuleScriptWrappedLSC(script: Script | LocalScript | ModuleScript, noscriptinstance: boolean?)
    local ParsedScriptPath = "game" do
        for _, v in ipairs(string.split(script:GetFullName(), ".")) do
            ParsedScriptPath ..= "[\""..v.."\"]"
        end
    end

    local MS = Instance.new("ModuleScript")
    MS.Name = script.Name
    MS.Source = if noscriptinstance then
        string.format([[return {
            Closure = function()
                %s
            end;
        }]], script.Source)
    else
        string.format([[return {
            ScriptInstance = %s;
            Closure = function()
                %s
            end;
        }]], ParsedScriptPath, script.Source)

    return MS
end

local function RunModuleScriptWrappedLSC(modulescript: ModuleScript)
    local RequireSuccess, Result = pcall(require, modulescript)
    if not RequireSuccess then
        return warn("Script run failure (module require failure):\n"..Result)
    end

    local Environment = getfenv(EMPTY_CLOSURE)
    table.clear(Environment)
    Environment["script"] = Result["ScriptInstance"]
    setfenv(Result.Closure, Environment)

    local Ret = {pcall(Result.Closure)}
    local ClosureRunSuccess = table.remove(Ret, 1)
    if not ClosureRunSuccess then
        task.spawn(error, if Result["ScriptInstance"] then Result.ScriptInstance:GetFullName()..": "..Ret[1] else Ret[1])
    end
    return ClosureRunSuccess, table.unpack(Ret)
end

return function(plugin: Plugin)
    --// Remove existing internal shared storage
    if serv.RunService:IsServer() then
		AddToDebris(SHARED_INTERNAL_FOLDER_LOCATION:FindFirstChild(SHARED_INTERNAL_FOLDER_NAME))
	end

    --// SettingsManager
    local PluginSettings = SettingsManager.new(plugin)

    --// Toolbar creation
    local Toolbar = plugin:CreateToolbar("RunLSC")

    if serv.RunService:IsEdit() then
        --// Run button setup
        local RunBtn = Toolbar:CreateButton("Run", "Run the selected LuaSourceContainer(s)", "rbxassetid://10734982144")
        RunBtn.ClickableWhenViewportHidden = true
        RunBtn.Click:Connect(function()
            for _, lsc in ipairs(serv.Selection:Get()) do
                if (not lsc:IsA("Script")) and (not lsc:IsA("LocalScript")) and (not lsc:IsA("ModuleScript")) then
					continue
				end
                task.spawn(CompileAndRun, lsc)
            end
            RunBtn.Enabled = false
            RunBtn.Enabled = true
        end)
    else
        --// Shared internal storage setup
        local InternalSharedStorage, DataModelConnector, ModuleScriptCache do
            if serv.RunService:IsServer() then
                InternalSharedStorage, DataModelConnector, ModuleScriptCache = SetupInternalSharedStorage()
            else
                InternalSharedStorage = SHARED_INTERNAL_FOLDER_LOCATION:WaitForChild(SHARED_INTERNAL_FOLDER_NAME)
                DataModelConnector = InternalSharedStorage:WaitForChild(SHARED_INTERNAL_FOLDER_CONNECTOR_NAME)
                ModuleScriptCache = InternalSharedStorage:WaitForChild(SHARED_INTERNAL_FOLDER_MSCACHE_NAME)
            end
        end

        --// DataModel connector setup
        --// Mostly everything here should be self-explainable
        if serv.RunService:IsServer() then
            local Actions = {
                ["RequestScriptRunOnClient"] = function(plr: Player, targets: {Script | LocalScript | ModuleScript})
                    local MSTargets = {}
                    for _, lsc in ipairs(targets) do
                        if (not lsc:IsA("Script")) and (not lsc:IsA("LocalScript")) and (not lsc:IsA("ModuleScript")) then
                            continue
                        end
                        local MS = CreateModuleScriptWrappedLSC(lsc)
                        MS.Parent = ModuleScriptCache
                        table.insert(MSTargets, MS)
                    end
                    return DataModelConnector:FireClient(plr, MSTargets)
                end,
                ["RequestScriptRunOnServer"] = function(_, targets: {Script | LocalScript | ModuleScript})
                    for _, lsc in ipairs(targets) do
                        if (not lsc:IsA("Script")) and (not lsc:IsA("LocalScript")) and (not lsc:IsA("ModuleScript")) then
                            continue
                        end
                        --// task.spawn(CompileAndRun, lsc)
                        local MS = CreateModuleScriptWrappedLSC(lsc)
                        task.spawn(RunModuleScriptWrappedLSC, MS)
                    end
                    return
                end,
                ["RequestSourceRunOnServer"] = function(_, source: string)
                    local DummyScript = Instance.new("Script")
                    DummyScript.Source = source

                    local MS = CreateModuleScriptWrappedLSC(DummyScript, true)
                    task.spawn(RunModuleScriptWrappedLSC, MS)
                    return
                end,
                ["RequestSourceRunOnClient"] = function(plr: Player, source: string)
                    local DummyScript = Instance.new("LocalScript")
                    DummyScript.Source = source

                    local MS = CreateModuleScriptWrappedLSC(DummyScript, true)
                    MS.Parent = ModuleScriptCache
                    return DataModelConnector:FireClient(plr, {MS})
                end,
                ["RequestDeleteMSCacheTargets"] = function(_, targets: {ModuleScript})
                    for _, ms in ipairs(targets) do
                        if (not ms:IsA("ModuleScript")) or (not ms:IsDescendantOf(ModuleScriptCache)) then
                            continue
                        end
                        AddToDebris(ms)
                    end
                    return
                end
            }
            DataModelConnector.OnServerEvent:Connect(function(plr: Player, action: string, ... : any)
                if typeof(Actions[action]) == "function" then
                    return Actions[action](plr, ...)
                end
                return
            end)
        else
            DataModelConnector.OnClientEvent:Connect(function(targets: {ModuleScript})
                for _, ms in ipairs(targets) do
                    if (not ms:IsA("ModuleScript")) or (not ms:IsDescendantOf(ModuleScriptCache)) then
                        continue
                    end
                    task.spawn(RunModuleScriptWrappedLSC, ms)
                end
                DataModelConnector:FireServer("RequestDeleteMSCacheTargets", targets)
                return
            end)
        end

        --// Run buttons setup
        local RunServerBtn = Toolbar:CreateButton("Run (server)", "Run the selected LuaSourceContainer(s) at the server", "rbxassetid://10734949856")
        RunServerBtn.ClickableWhenViewportHidden = true
        RunServerBtn.Click:Connect(function()
            if serv.RunService:IsServer() then
                for _, lsc in ipairs(serv.Selection:Get()) do
                    if (not lsc:IsA("Script")) and (not lsc:IsA("LocalScript")) and (not lsc:IsA("ModuleScript")) then
                        continue
                    end
                    task.spawn(CompileAndRun, lsc)
                end
            else
                DataModelConnector:FireServer("RequestScriptRunOnServer", serv.Selection:Get())
            end
            RunServerBtn.Enabled = false
            RunServerBtn.Enabled = true
            return
        end)

        local RunClientBtn = Toolbar:CreateButton("Run (client)", "Run the selected LuaSourceContainer(s) at the client", "rbxassetid://10723417797")
        RunClientBtn.ClickableWhenViewportHidden = true
        RunClientBtn.Click:Connect(function()
            if serv.RunService:IsServer() then
                local MSTargets = {}
                for _, lsc in ipairs(serv.Selection:Get()) do
                    if (not lsc:IsA("Script")) and (not lsc:IsA("LocalScript")) and (not lsc:IsA("ModuleScript")) then
                        continue
                    end
                    local MS = CreateModuleScriptWrappedLSC(lsc)
                    MS.Parent = ModuleScriptCache
                    table.insert(MSTargets, MS)
                end
                DataModelConnector:FireAllClients(MSTargets)
            else
                DataModelConnector:FireServer("RequestScriptRunOnClient", serv.Selection:Get())
            end
            RunClientBtn.Enabled = false
            RunClientBtn.Enabled = true
            return
        end)
    end

    --// Settings widget setup
    local SettingsWidget = plugin:CreateDockWidgetPluginGui("RunLSC - Settings", DockWidgetPluginGuiInfo.new(
        Enum.InitialDockState.Left,
        false,
        false,
        0,
        0,
        250,
        100
    ))
    SettingsWidget.Name = "RunLSC_Settings"
    SettingsWidget.Title = "RunLSC - Settings"

    --// Settings button setup
    local SettingsBtn = Toolbar:CreateButton("Settings", "Open the RunLSC configuration window", "rbxassetid://10709810948")
    SettingsBtn.ClickableWhenViewportHidden = true
    SettingsBtn.Click:Connect(function()
        SettingsWidget.Enabled = not SettingsWidget.Enabled
        return warn("Settings widget not implemented yet")
    end)

    --// Executor widget setup
    local ExecutorWidget = plugin:CreateDockWidgetPluginGui("RunLSC - Executor", DockWidgetPluginGuiInfo.new(
        Enum.InitialDockState.Float,
        false,
        false,
        0,
        0,
        250,
        250
    ))
    ExecutorWidget.Name = "RunLSC_Executor"
    ExecutorWidget.Title = "RunLSC - Executor"

    local ExecutorFrameReferences do
        local ExecutorFrame = UIHelper.CreateExecutorUI()
        ExecutorFrameReferences = {
            Frame = ExecutorFrame;
            Run = ExecutorFrame:FindFirstChild("Run") :: TextButton;
            RunServer = ExecutorFrame:FindFirstChild("RunServer") :: TextButton;
            RunClient = ExecutorFrame:FindFirstChild("RunClient") :: TextButton;
            Editor = {
                Frame = ExecutorFrame:FindFirstChild("Editor") :: ScrollingFrame;
                Lines = ExecutorFrame:FindFirstChild("Editor"):FindFirstChild("Lines") :: Frame;
                TextBox = ExecutorFrame:FindFirstChild("Editor"):FindFirstChild("TextBox") :: TextBox;
                LineMark = ExecutorFrame:FindFirstChild("Editor"):FindFirstChild("Lines"):FindFirstChild("1") :: TextLabel;
            };
        }
        ExecutorFrameReferences.Editor.LineMark.Parent = nil
    end

    ExecutorFrameReferences.Editor.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
        --// Resize canvas automatically
        local TextBounds = serv.TextService:GetTextSize(ExecutorFrameReferences.Editor.TextBox.Text, ExecutorFrameReferences.Editor.TextBox.TextSize, Enum.Font.Code, Vector2.new(9999,9999))
        ExecutorFrameReferences.Editor.Frame.CanvasSize = UDim2.new(0, TextBounds.X + 55, 0, TextBounds.Y + 5)

        --// Syntax highlighting
        Highlighter.highlight({ textObject = ExecutorFrameReferences.Editor.TextBox, src = ExecutorFrameReferences.Editor.TextBox.Text })
    end)

    ExecutorFrameReferences.Frame.Parent = ExecutorWidget

    --// Executor button setup
    local ExecuteWindowToggleBtn = Toolbar:CreateButton("Executor", "Open the RunLSC code execution window", "rbxassetid://10734943448")
    ExecuteWindowToggleBtn.ClickableWhenViewportHidden = true
    ExecuteWindowToggleBtn.Click:Connect(function()
        ExecutorWidget.Enabled = not ExecutorWidget.Enabled
        return
    end)

    if serv.RunService:IsEdit() then
        ExecutorFrameReferences.Run.MouseButton1Click:Connect(function()
            local DummyScript = Instance.new("Script")
            DummyScript.Source = ExecutorFrameReferences.Editor.TextBox.Text
            task.spawn(CompileAndRun, DummyScript)
        end)

        ExecutorFrameReferences.Run.Visible = true
        ExecutorFrameReferences.RunClient.Visible = false
        ExecutorFrameReferences.RunServer.Visible = false
    else
        ExecutorFrameReferences.Run.Visible = false
        ExecutorFrameReferences.RunClient.Visible = true
        ExecutorFrameReferences.RunServer.Visible = true

        local DataModelConnector = SHARED_INTERNAL_FOLDER_LOCATION:WaitForChild(SHARED_INTERNAL_FOLDER_NAME):WaitForChild(SHARED_INTERNAL_FOLDER_CONNECTOR_NAME) :: RemoteEvent
        local ModuleScriptCache = SHARED_INTERNAL_FOLDER_LOCATION:WaitForChild(SHARED_INTERNAL_FOLDER_NAME):WaitForChild(SHARED_INTERNAL_FOLDER_MSCACHE_NAME) :: Folder
        
        ExecutorFrameReferences.RunServer.MouseButton1Click:Connect(function()
            if serv.RunService:IsServer() then
                local DummyScript = Instance.new("Script")
                DummyScript.Source = ExecutorFrameReferences.Editor.TextBox.Text

                local MS = CreateModuleScriptWrappedLSC(DummyScript, true)
                task.spawn(RunModuleScriptWrappedLSC, MS)
            else
                DataModelConnector:FireServer("RequestSourceRunOnServer", ExecutorFrameReferences.Editor.TextBox.Text)
            end
            return
        end)

        ExecutorFrameReferences.RunClient.MouseButton1Click:Connect(function()
            if serv.RunService:IsServer() then
                local DummyScript = Instance.new("LocalScript")
                DummyScript.Source = ExecutorFrameReferences.Editor.TextBox.Text

                local MS = CreateModuleScriptWrappedLSC(DummyScript, true)
                MS.Parent = ModuleScriptCache
                return DataModelConnector:FireAllClients({MS})
            else
                DataModelConnector:FireServer("RequestSourceRunOnClient", ExecutorFrameReferences.Editor.TextBox.Text)
            end
            return
        end)
    end

    --// Plugin unload hook
    plugin.Unloading:Connect(function()
        PluginSettings:Destroy()
    end)

    return true
end