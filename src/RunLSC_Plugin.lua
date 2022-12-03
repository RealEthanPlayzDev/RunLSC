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
local NATIVEIDE_TEMPLSC_LOCATION = game:GetService("Debris")
local EMPTY_CLOSURE = function() return end

--// Services
local serv = {
    Selection = game:GetService("Selection");
    RunService = game:GetService("RunService");
    Debris = game:GetService("Debris");
    Players = game:GetService("Players");
    TextService = game:GetService("TextService");
    ScriptEditorService = game:GetService("ScriptEditorService");
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

    --// Warn about locked settings if it is locked
    if PluginSettings.IsLocked then
        warn("It seems like you have another Studio session running and this isn't the first session, saving plugin settings will be disabled.\nIf this is the first Studio session, you might have to manually release the lock via settings.")
    end

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

    local CurrentNativeIDELSC
    local CurrentNativeIDELSCScriptDoc
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
                LineCount = ExecutorFrame:FindFirstChild("Editor"):FindFirstChild("Lines"):FindFirstChild("1") :: TextLabel;
            };
        }
        ExecutorFrameReferences.Editor.LineCount.Parent = nil
    end

    ExecutorFrameReferences.Editor.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
        local Text = ExecutorFrameReferences.Editor.TextBox.Text

        --// Resize canvas automatically
        local TextBounds = serv.TextService:GetTextSize(Text, ExecutorFrameReferences.Editor.TextBox.TextSize, Enum.Font.Code, Vector2.new(9999,9999))
        ExecutorFrameReferences.Editor.Frame.CanvasSize = UDim2.new(0, TextBounds.X + 55, 0, TextBounds.Y + 5)

        --// Line counter
        local TotalLines = #(string.split(Text, "\n"))
        local CountedLines = ExecutorFrameReferences.Editor.Lines:GetChildren()
        local TotalCountedLines = #CountedLines - 1 --// Theres a UIListLayout which is not a counted line instance
        if TotalCountedLines < TotalLines then
            for i = TotalCountedLines, TotalLines do
                local Count = ExecutorFrameReferences.Editor.LineCount:Clone()
                Count.Name = i
                Count.Text = i
                Count.LayoutOrder = i
                Count.Parent = ExecutorFrameReferences.Editor.Lines
            end
        else
            for i = TotalLines + 1, TotalCountedLines do
                AddToDebris(CountedLines[i], 0)
            end
        end

        --// Syntax highlighting
        Highlighter.highlight({ textObject = ExecutorFrameReferences.Editor.TextBox, src = Text })
    end)

    ExecutorFrameReferences.Frame.Parent = ExecutorWidget

    --// ScriptEditorService setup
	serv.ScriptEditorService.TextDocumentDidClose:Connect(function(document)
        if not CurrentNativeIDELSCScriptDoc then return end
		if document:GetScript() == CurrentNativeIDELSCScriptDoc:GetScript() then
			CurrentNativeIDELSCScriptDoc = nil
			ExecutorWidget.Enabled = false
		end
	end)

    --// Executor button setup
    local ExecuteWindowToggleBtn = Toolbar:CreateButton("Executor", "Open the RunLSC code execution window", "rbxassetid://10734943448")
    ExecuteWindowToggleBtn.ClickableWhenViewportHidden = true
    ExecuteWindowToggleBtn.Click:Connect(function()
        if PluginSettings:GetSetting("UseNativeScriptIDE") then
            if CurrentNativeIDELSCScriptDoc then return end
			if not CurrentNativeIDELSC then
                local TempLSC = if serv.RunService:IsServer() then Instance.new("Script") else Instance.new("LocalScript")
                TempLSC.Name = "RunLSC - Executor IDE"
                TempLSC.Archivable = false
                TempLSC.Parent = NATIVEIDE_TEMPLSC_LOCATION
                CurrentNativeIDELSC = TempLSC
			end

			local OpenSuccess, Reason = serv.ScriptEditorService:OpenScriptDocumentAsync(CurrentNativeIDELSC)
            if not OpenSuccess then
                return warn("Failed to open native script editor using \"ScriptEditorService:OpenScriptDocumentAsync()\":\n"..Reason)
            end

			CurrentNativeIDELSCScriptDoc = serv.ScriptEditorService:FindScriptDocument(CurrentNativeIDELSC)
			ExecutorWidget.Enabled = true
		else
			ExecutorWidget.Enabled = not ExecutorWidget.Enabled
		end
        return
    end)

    if serv.RunService:IsEdit() then
        ExecutorFrameReferences.Run.MouseButton1Click:Connect(function()
            local DummyScript = Instance.new("Script")
            if PluginSettings:GetSetting("UseNativeScriptIDE") then
				if not CurrentNativeIDELSCScriptDoc then return end
				DummyScript.Source = CurrentNativeIDELSCScriptDoc:GetText()
			else
				DummyScript.Source = ExecutorFrameReferences.Editor.TextBox.Text
			end
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
				if PluginSettings:GetSetting("UseNativeScriptIDE") then
					if not CurrentNativeIDELSCScriptDoc then return end
					DummyScript.Source = CurrentNativeIDELSCScriptDoc:GetText()
				else
					DummyScript.Source = ExecutorFrameReferences.Editor.TextBox.Text
				end

                local MS = CreateModuleScriptWrappedLSC(DummyScript, true)
                task.spawn(RunModuleScriptWrappedLSC, MS)
            else
				if PluginSettings:GetSetting("UseNativeScriptIDE") then
					if not CurrentNativeIDELSCScriptDoc then return end
					DataModelConnector:FireServer("RequestSourceRunOnServer", CurrentNativeIDELSCScriptDoc:GetText())
				else
					DataModelConnector:FireServer("RequestSourceRunOnServer", ExecutorFrameReferences.Editor.TextBox.Text)
				end
            end
            return
        end)

        ExecutorFrameReferences.RunClient.MouseButton1Click:Connect(function()
            if serv.RunService:IsServer() then
                local DummyScript = Instance.new("LocalScript")
				if PluginSettings:GetSetting("UseNativeScriptIDE") then
					if not CurrentNativeIDELSCScriptDoc then return end
					DummyScript.Source = CurrentNativeIDELSCScriptDoc:GetText()
				else
					DummyScript.Source = ExecutorFrameReferences.Editor.TextBox.Text
				end

                local MS = CreateModuleScriptWrappedLSC(DummyScript, true)
                MS.Parent = ModuleScriptCache
                return DataModelConnector:FireAllClients({MS})
            else
				if PluginSettings:GetSetting("UseNativeScriptIDE") then
					if not CurrentNativeIDELSCScriptDoc then return end
					DataModelConnector:FireServer("RequestSourceRunOnServer", CurrentNativeIDELSCScriptDoc:GetText())
				else
					DataModelConnector:FireServer("RequestSourceRunOnServer", ExecutorFrameReferences.Editor.TextBox.Text)
				end
            end
            return
        end)
    end

    --// Plugin unload hook
    plugin.Unloading:Connect(function()
        PluginSettings:Destroy(if serv.RunService:IsEdit() then false else true)
        if CurrentNativeIDELSC then
            CurrentNativeIDELSCScriptDoc = nil
            AddToDebris(CurrentNativeIDELSC, 0)
        end
    end)

    return true
end