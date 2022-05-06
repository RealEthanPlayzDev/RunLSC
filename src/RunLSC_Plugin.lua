--// Services
local serv = {
    Selection = game:GetService("Selection");
    ChangeHistoryService = game:GetService("ChangeHistoryService");
    RunService = game:GetService("RunService");
}

--// Libraries
local loadstring = require(script.Parent.LoadstringHelper)

return function(plugin: Plugin)
    --// Toolbar and buttons
    local Toolbar = plugin:CreateToolbar("RunLSC")
    local RunBtn = Toolbar:CreateButton("Run", "Run the selected LuaSourceContainer(s)", "rbxassetid://4458901886")
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