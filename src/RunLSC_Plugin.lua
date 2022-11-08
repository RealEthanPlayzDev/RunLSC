--[[
File name: RunLSC_Plugin.lua
Author: RadiatedExodus (ItzEthanPlayz_YT/RealEthanPlayzDev)
Created at: May 6, 2022

The core RunLSC code for setting up the plugin toolbars, buttons, etc
--]]

--// Services
local serv = {
    Selection = game:GetService("Selection");
    ChangeHistoryService = game:GetService("ChangeHistoryService");
    RunService = game:GetService("RunService");
}

--// Libraries
local loadstring = require(script.Parent.lib.LoadstringHelper)

return function(plugin: Plugin)
    --// Toolbar and buttons
    local Toolbar = plugin:CreateToolbar("RunLSC")
    local RunBtn = Toolbar:CreateButton(if serv.RunService:IsEdit() then "Run" else if serv.RunService:IsServer() then "Run (server)" else "Run (client)", "Run the selected LuaSourceContainer(s)", "rbxassetid://4458901886")
    RunBtn.ClickableWhenViewportHidden = true

    --// Run button
    RunBtn.Click:Connect(function()
        for _, selection in pairs(serv.Selection:Get()) do
            if not selection:IsA("LuaSourceContainer") or selection:IsA("CoreScript") then continue end
            task.spawn(function()
                local Environment = getfenv(1)
                Environment["script"] = selection
                local Success, Result = pcall(loadstring(selection.Source, selection:GetFullName(), Environment))
                if not Success then
                    task.spawn(error, string.format("%s:%s", selection:GetFullName(), Result))
                end
            end)
        end
        RunBtn.Enabled = false
        RunBtn.Enabled = true
    end)
end