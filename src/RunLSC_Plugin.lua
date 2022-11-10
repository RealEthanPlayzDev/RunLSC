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
}

--// Libraries
local loadstring = require(script.Parent.lib.LoadstringHelper)
local SettingsManager = require(script.Parent.lib.SettingsManager)

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

local function CreateModuleScriptWrappedLSC(script: Script | LocalScript | ModuleScript)
    local ParsedScriptPath = "game" do
        for _, v in ipairs(string.split(script:GetFullName(), ".")) do
            ParsedScriptPath ..= "[\""..v.."\"]"
        end
    end

    local MS = Instance.new("ModuleScript")
    MS.Name = script.Name
    MS.Source = string.format([[return {
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
    Environment["script"] = Result.ScriptInstance
    setfenv(Result.Closure, Environment)

    local Ret = {pcall(Result.Closure)}
    local ClosureRunSuccess = table.remove(Ret, 1)
    if not ClosureRunSuccess then
        task.spawn(error, Result.ScriptInstance:GetFullName()..": "..Ret[1])
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
        100,
        100,
        200,
        100
    ))
    SettingsWidget.Title = "RunLSC - Settings"

    --// Settings button setup
    local SettingsBtn = Toolbar:CreateButton("Settings", "Open the RunLSC configuration window", "rbxassetid://10709810948")
    SettingsBtn.ClickableWhenViewportHidden = true
    SettingsBtn.Click:Connect(function()
        SettingsWidget.Enabled = not SettingsWidget.Enabled
        return warn("Settings widget not implemented yet")
    end)

    --// Plugin unload hook
    plugin.Unloading:Connect(function()
        PluginSettings:Destroy()
    end)

    return true
end