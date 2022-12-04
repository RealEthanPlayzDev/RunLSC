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

function UIManager.CreateExecutorEditor()
    local Editor = Instance.new("ScrollingFrame")
    Editor.Name = "Editor"
    Editor.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
    Editor.CanvasSize = UDim2.new()
    Editor.HorizontalScrollBarInset = Enum.ScrollBarInset.ScrollBar
    Editor.ScrollBarImageColor3 = Color3.fromRGB(56, 56, 56)
    Editor.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
    Editor.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
    Editor.BackgroundColor3 = Color3.fromRGB(37, 37, 37)
    Editor.BorderSizePixel = 0
    Editor.Selectable = false
    Editor.Size = UDim2.new(1, 0, 1, 0)
    Editor.SelectionGroup = false

    local Lines = Instance.new("Frame")
    Lines.Name = "Lines"
    Lines.BackgroundColor3 = Color3.fromRGB(43, 43, 43)
    Lines.BorderSizePixel = 0
    Lines.Size = UDim2.new(0, 35, 1, 0)

    local LinesUILL = Instance.new("UIListLayout")
    LinesUILL.Name = "UIListLayout"
    LinesUILL.HorizontalAlignment = Enum.HorizontalAlignment.Center
    LinesUILL.SortOrder = Enum.SortOrder.LayoutOrder
    LinesUILL.Parent = Lines

    local LineMarker = Instance.new("TextButton")
    LineMarker.Name = "1"
    LineMarker.FontFace = Font.fromEnum(Enum.Font.Code)
    LineMarker.Text = "1"
    LineMarker.TextColor3 = Color3.fromRGB(204, 204, 204)
    LineMarker.TextSize = 15
    LineMarker.Active = false
    LineMarker.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    LineMarker.BackgroundTransparency = 1
    LineMarker.Selectable = false
    LineMarker.Size = UDim2.new(1, 0, 0, 25)
    LineMarker.Parent = Lines

    Lines.Parent = Editor

    local TextBox = Instance.new("TextBox")
    TextBox.Name = "TextBox"
    TextBox.ClearTextOnFocus = false
    TextBox.FontFace = Font.fromEnum(Enum.Font.Code)
    TextBox.PlaceholderColor3 = Color3.fromRGB(178, 178, 178)
    TextBox.Text = ""
    TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    TextBox.TextSize = 18
    TextBox.TextXAlignment = Enum.TextXAlignment.Left
    TextBox.TextYAlignment = Enum.TextYAlignment.Top
    TextBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    TextBox.BackgroundTransparency = 1
    TextBox.BorderSizePixel = 0
    TextBox.Position = UDim2.fromOffset(55, 5)
    TextBox.Size = UDim2.new(1, -55, 1, -5)
    TextBox.MultiLine = true
    TextBox.Parent = Editor

    local Collapsibles = Instance.new("Frame")
    Collapsibles.Name = "Collapsibles"
    Collapsibles.BackgroundColor3 = Color3.fromRGB(48, 48, 48)
    Collapsibles.BorderSizePixel = 0
    Collapsibles.Position = UDim2.fromOffset(35, 0)
    Collapsibles.Size = UDim2.new(0, 15, 1, 0)
    Collapsibles.Parent = Editor

    return Editor
end

function UIManager.CreateExecutorActions()
    local ActionsFrame = Instance.new("Frame")
    ActionsFrame.Name = "ActionsFrame"
    ActionsFrame.Size = UDim2.new(1, 0, 1, 0)
    ActionsFrame.BackgroundTransparency = 1

    local Run = Instance.new("TextButton")
    Run.Name = "Run"
    Run.FontFace = Font.fromEnum(Enum.Font.Arial)
    Run.Text = "Run"
    Run.TextColor3 = Color3.fromRGB(0, 0, 0)
    Run.TextSize = 14
    Run.BackgroundColor3 = Color3.fromRGB(43, 177, 255)
    Run.Position = UDim2.fromOffset(5, 5)
    Run.Size = UDim2.fromOffset(100, 25)

    local RunUIC = Instance.new("UICorner")
    RunUIC.Name = "UICorner"
    RunUIC.CornerRadius = UDim.new(0, 4)
    RunUIC.Parent = Run

    local RunUIS = Instance.new("UIStroke")
    RunUIS.Name = "UIStroke"
    RunUIS.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    RunUIS.Parent = Run

    Run.Parent = ActionsFrame

    local RunServer = Instance.new("TextButton")
    RunServer.Name = "RunServer"
    RunServer.FontFace = Font.fromEnum(Enum.Font.Arial)
    RunServer.Text = "Run (server)"
    RunServer.TextColor3 = Color3.fromRGB(0, 0, 0)
    RunServer.TextSize = 14
    RunServer.BackgroundColor3 = Color3.fromRGB(0, 255, 127)
    RunServer.Position = UDim2.fromOffset(5, 5)
    RunServer.Size = UDim2.fromOffset(100, 25)
    RunServer.Visible = false

    local RunServerUIC = Instance.new("UICorner")
    RunServerUIC.Name = "UICorner"
    RunServerUIC.CornerRadius = UDim.new(0, 4)
    RunServerUIC.Parent = RunServer

    local RunServerUIS = Instance.new("UIStroke")
    RunServerUIS.Name = "UIStroke"
    RunServerUIS.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    RunServerUIS.Parent = RunServer

    RunServer.Parent = ActionsFrame

    local RunClient = Instance.new("TextButton")
    RunClient.Name = "RunClient"
    RunClient.FontFace = Font.fromEnum(Enum.Font.Arial)
    RunClient.Text = "Run (client)"
    RunClient.TextColor3 = Color3.fromRGB(0, 0, 0)
    RunClient.TextSize = 14
    RunClient.BackgroundColor3 = Color3.fromRGB(43, 177, 255)
    RunClient.Position = UDim2.fromOffset(110, 5)
    RunClient.Size = UDim2.fromOffset(100, 25)
    RunClient.Visible = false

    local RunClientUIC = Instance.new("UICorner")
    RunClientUIC.Name = "UICorner"
    RunClientUIC.CornerRadius = UDim.new(0, 4)
    RunClientUIC.Parent = RunClient

    local RunClientUIS = Instance.new("UIStroke")
    RunClientUIS.Name = "UIStroke"
    RunClientUIS.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    RunClientUIS.Parent = RunClient

    RunClient.Parent = ActionsFrame

    return ActionsFrame
end

return UIManager