--[[
File name: UIManager.lua
Author: RadiatedExodus (ItzEthanPlayz_YT/RealEthanPlayzDev)
Created at: December 4, 2022

Static class containing UI helper functions for RunLSC.
--]]

--// Libraries
local RESignal = require(script.Parent.RESignal)

local UIManager = {}

local FieldTypes = {
    Boolean = 0x1;
}

local FieldTypeClasses = {
    [FieldTypes.Boolean] = "BooleanField";
}

UIManager.FieldTypes = FieldTypes

function UIManager.new(class: string, ...)
    if script:FindFirstChild(class) then
        return require(script:FindFirstChild(class)).new(...)
    else
        return Instance.new(class :: "Frame")
    end
end

function UIManager.ConstructSettingsUI(settingdef: { [string]: { { SettingName: string, Text: string, FieldType: number, DefaultValue: any } } })
    local SettingChanged = RESignal.new(RESignal.SignalBehavior.NewThread)
    local SSF = UIManager.new("StudioScrollingFrame")
    local UIThings = {SSF}

    for section, settings in pairs(settingdef) do
        local Section = UIManager.new("Section", section, true)
        table.insert(UIThings, Section)
        for _, setting in ipairs(settings) do
            if not FieldTypeClasses[setting.FieldType] then warn("No FieldType class for type "..setting.FieldType.." ("..setting.SettingName..")?"); continue end
            local Field = UIManager.new(FieldTypeClasses[setting.FieldType], setting.Text, setting.DefaultValue)
            table.insert(UIThings, Field)
            Field.OnValueChanged:Connect(function(value)
                return SettingChanged:Fire(setting.SettingName, value)
            end)
            Field.Instance.Parent = Section:GetContentFrame()
        end
        Section.Instance.Parent = SSF:GetContentFrame()
    end

    return {
        ScrollingFrame = SSF;
        SettingChanged = SettingChanged;
        UIs = UIThings;
        Destroy = function()
            SettingChanged:Destroy()
            for _, ui in ipairs(UIThings) do
                ui:Destroy()
            end
        end;
    }
end

function UIManager.CreateExecutorUI()
    --// Last generated with Codify 2.2.5
    local frame = Instance.new("Frame")
    frame.Name = "Frame"
    frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Size = UDim2.fromScale(1, 1)

    local editor = Instance.new("ScrollingFrame")
    editor.Name = "Editor"
    editor.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
    editor.CanvasSize = UDim2.new()
    editor.HorizontalScrollBarInset = Enum.ScrollBarInset.ScrollBar
    editor.ScrollBarImageColor3 = Color3.fromRGB(56, 56, 56)
    editor.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
    editor.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
    editor.BackgroundColor3 = Color3.fromRGB(37, 37, 37)
    editor.BorderSizePixel = 0
    editor.Selectable = false
    editor.Size = UDim2.new(1, 0, 1, -35)
    editor.SelectionGroup = false

    local lines = Instance.new("Frame")
    lines.Name = "Lines"
    lines.BackgroundColor3 = Color3.fromRGB(43, 43, 43)
    lines.BorderSizePixel = 0
    lines.Size = UDim2.new(0, 35, 1, 0)

    local uIListLayout = Instance.new("UIListLayout")
    uIListLayout.Name = "UIListLayout"
    uIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    uIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    uIListLayout.Parent = lines

    local w = Instance.new("TextButton")
    w.Name = "1"
    w.FontFace = Font.fromEnum(Enum.Font.Code)
    w.Text = "1"
    w.TextColor3 = Color3.fromRGB(204, 204, 204)
    w.TextSize = 15
    w.Active = false
    w.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    w.BackgroundTransparency = 1
    w.Selectable = false
    w.Size = UDim2.new(1, 0, 0, 20)
    w.Parent = lines

    lines.Parent = editor

    local textBox = Instance.new("TextBox")
    textBox.Name = "TextBox"
    textBox.ClearTextOnFocus = false
    textBox.FontFace = Font.fromEnum(Enum.Font.Code)
    textBox.PlaceholderColor3 = Color3.fromRGB(178, 178, 178)
    textBox.Text = ""
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.TextSize = 18
    textBox.TextXAlignment = Enum.TextXAlignment.Left
    textBox.TextYAlignment = Enum.TextYAlignment.Top
    textBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    textBox.BackgroundTransparency = 1
    textBox.BorderSizePixel = 0
    textBox.Position = UDim2.fromOffset(55, 5)
    textBox.Size = UDim2.new(1, -55, 1, -5)
    textBox.MultiLine = true
    textBox.Parent = editor

    local collapsibles = Instance.new("Frame")
    collapsibles.Name = "Collapsibles"
    collapsibles.BackgroundColor3 = Color3.fromRGB(48, 48, 48)
    collapsibles.BorderSizePixel = 0
    collapsibles.Position = UDim2.fromOffset(35, 0)
    collapsibles.Size = UDim2.new(0, 15, 1, 0)
    collapsibles.Parent = editor

    editor.Parent = frame

    local run = Instance.new("TextButton")
    run.Name = "Run"
    run.FontFace = Font.fromEnum(Enum.Font.Arial)
    run.Text = "Run"
    run.TextColor3 = Color3.fromRGB(0, 0, 0)
    run.TextSize = 14
    run.AnchorPoint = Vector2.new(1, 1)
    run.BackgroundColor3 = Color3.fromRGB(43, 177, 255)
    run.Position = UDim2.new(1, -5, 1, -5)
    run.Size = UDim2.fromOffset(100, 25)

    local uICorner = Instance.new("UICorner")
    uICorner.Name = "UICorner"
    uICorner.CornerRadius = UDim.new(0, 4)
    uICorner.Parent = run

    local uIStroke = Instance.new("UIStroke")
    uIStroke.Name = "UIStroke"
    uIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    uIStroke.Parent = run

    run.Parent = frame

    local runServer = Instance.new("TextButton")
    runServer.Name = "RunServer"
    runServer.FontFace = Font.fromEnum(Enum.Font.Arial)
    runServer.Text = "Run (server)"
    runServer.TextColor3 = Color3.fromRGB(0, 0, 0)
    runServer.TextSize = 14
    runServer.AnchorPoint = Vector2.new(1, 1)
    runServer.BackgroundColor3 = Color3.fromRGB(0, 255, 127)
    runServer.Position = UDim2.new(1, -5, 1, -5)
    runServer.Size = UDim2.fromOffset(100, 25)
    runServer.Visible = false

    local uICorner1 = Instance.new("UICorner")
    uICorner1.Name = "UICorner"
    uICorner1.CornerRadius = UDim.new(0, 4)
    uICorner1.Parent = runServer

    local uIStroke1 = Instance.new("UIStroke")
    uIStroke1.Name = "UIStroke"
    uIStroke1.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    uIStroke1.Parent = runServer

    runServer.Parent = frame

    local runClient = Instance.new("TextButton")
    runClient.Name = "RunClient"
    runClient.FontFace = Font.fromEnum(Enum.Font.Arial)
    runClient.Text = "Run (client)"
    runClient.TextColor3 = Color3.fromRGB(0, 0, 0)
    runClient.TextSize = 14
    runClient.AnchorPoint = Vector2.new(1, 1)
    runClient.BackgroundColor3 = Color3.fromRGB(43, 177, 255)
    runClient.Position = UDim2.new(1, -110, 1, -5)
    runClient.Size = UDim2.fromOffset(100, 25)
    runClient.Visible = false

    local uICorner2 = Instance.new("UICorner")
    uICorner2.Name = "UICorner"
    uICorner2.CornerRadius = UDim.new(0, 4)
    uICorner2.Parent = runClient

    local uIStroke2 = Instance.new("UIStroke")
    uIStroke2.Name = "UIStroke"
    uIStroke2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    uIStroke2.Parent = runClient

    runClient.Parent = frame

    return frame
end

return UIManager