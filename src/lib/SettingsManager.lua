--[[
File name: SettingsManager.lua
Author: RadiatedExodus (ItzEthanPlayz_YT/RealEthanPlayzDev)
Created at: November 8, 2022

RunLSC's plugin settings manager
--]]

--// Static configuration
local LOCK_KEY_NAME = "SettingsManagerInternal-Locked"

local SettingsManager = {}
SettingsManager.__index = SettingsManager
SettingsManager.__tostring = function(self) return "SettingsManager-"..self.Plugin.Name end
SettingsManager.__metatable = "This metatable is locked"

function SettingsManager:GetSetting(key: string)
    if not table.find(self.AccessedKeys, key) then
        table.insert(self.AccessedKeys, key)
        self.Settings[key] = self.Plugin:GetSetting(key)
    end
    return self.Settings[key]
end

function SettingsManager:SetSetting(key: string, value: any)
    if not table.find(self.AccessedKeys, key) then
        table.insert(self.AccessedKeys, key)
    end
    self.Settings[key] = value
    return
end

function SettingsManager:GetLocalSettings()
    return self.Settings
end

function SettingsManager:Flush(silentflush: boolean?)
    if self.IsLocked then
        if not silentflush then
            warn("["..self.StdoutIdentifier.."]: Modified settings won't be flushed as it was locked from another session")
        end
        return
    end
    for key, value in pairs(self.Settings) do
        self.Plugin:SetSetting(key, value)
    end
    return
end

function SettingsManager:Destroy(silentflush: boolean?)
    self:Flush(silentflush)
    self.Plugin:SetSetting(LOCK_KEY_NAME, false)
    self.Settings = nil
    self.AccessedKeys = nil
    self.Plugin = nil
    return
end

local function constructor_SettingsManager(plugin: Plugin)
    local Manager = setmetatable({
        Plugin = plugin;
        IsLocked = if plugin:GetSetting(LOCK_KEY_NAME) then true else false;
        Settings = {};
        AccessedKeys = {};
        StdoutIdentifier = "SettingsManager-"..plugin.Name;
    }, SettingsManager)

    if not Manager.IsLocked then
        plugin:SetSetting(LOCK_KEY_NAME, true)
    end

    return Manager
end
return setmetatable({ new = constructor_SettingsManager }, { __call = function(_, ...) return constructor_SettingsManager(...) end })