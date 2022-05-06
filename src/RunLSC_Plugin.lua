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
local loadstring = require(script.Parent.LoadstringHelper)

return function(plugin: Plugin)
    --// Preventing the script from running more than a single time
    if script:GetAttribute("Ran") then return end
    script:SetAttribute("Ran", true)

    --// Toolbar and buttons
    local Toolbar = plugin:CreateToolbar("RunLSC")
    local RunBtn = Toolbar:CreateButton(if serv.RunService:IsEdit() then "Run" else if serv.RunService:IsServer() then "Run (server)" else "Run (client)", "Run the selected LuaSourceContainer(s)", "rbxassetid://4458901886")
    RunBtn.ClickableWhenViewportHidden = true

    --// Run button
    RunBtn.Click:Connect(function()
        for _, selection in pairs(serv.Selection:Get()) do
            if not selection:IsA("LuaSourceContainer") or selection:IsA("CoreScript") then continue end
            task.spawn(function()
                local env = getfenv(1)
                env.script = selection
                local success, result = pcall(loadstring(selection.Source, selection:GetFullName(), env))
                if not success then
                    task.spawn(error, result)
                end
            end)
        end
        RunBtn:SetActive(false)
    end)
end