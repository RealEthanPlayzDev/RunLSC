--[[
File name: BooleanField.lua
Author: RadiatedExodus (RealEthanPlayzDev)
Created at: December 4, 2022

Custom class that creates a boolean field similar
to the properties widget's boolean field.
--]]


--// Libraries
local RESignal = require(script.Parent.Parent.RESignal)

--// Variables
local CheckmarkImages = {
	[false] = "rbxassetid://10734965702";
	[true] = "rbxassetid://10709790537";
}

local CheckmarkColors = {
	[false] = Color3.fromRGB(255, 255, 255);
	[true] = Color3.fromRGB(43, 177, 255);
}

--// Functions
local function CreateInstance(name: string, value: boolean)
	local BooleanField = Instance.new("Frame")
	BooleanField.Name = name
	BooleanField.BackgroundColor3 = Color3.fromRGB(46, 46, 46)
	BooleanField.BorderColor3 = Color3.fromRGB(34, 34, 34)
	BooleanField.Size = UDim2.new(1, 0, 0, 20)
	
	local Name = Instance.new("TextLabel")
	Name.Name = "Name"
	Name.Text = name
	Name.FontFace = Font.fromEnum(Enum.Font.Code)
	Name.TextColor3 = Color3.fromRGB(255, 255, 255)
	Name.TextSize = 14
	Name.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Name.BackgroundTransparency = 1
	Name.BorderColor3 = Color3.fromRGB(34, 34, 34)
	Name.Size = UDim2.fromScale(0.5, 1)
	
	local NameUIStroke = Instance.new("UIStroke")
	NameUIStroke.Name = "UIStroke"
	NameUIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	NameUIStroke.Color = Color3.fromRGB(34, 34, 34)
	NameUIStroke.Parent = Name
	
	Name.Parent = BooleanField
	
	local Value = Instance.new("Frame")
	Value.Name = "Value"
	Value.AnchorPoint = Vector2.new(1, 0)
	Value.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Value.BackgroundTransparency = 1
	Value.BorderColor3 = Color3.fromRGB(34, 34, 34)
	Value.Position = UDim2.fromScale(1, 0)
	Value.Size = UDim2.fromScale(0.5, 1)
	
	local ValueUIStroke = Instance.new("UIStroke")
	ValueUIStroke.Name = "UIStroke"
	ValueUIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ValueUIStroke.Color = Color3.fromRGB(34, 34, 34)
	ValueUIStroke.Parent = Value
	
	local Checkmark = Instance.new("ImageButton")
	Checkmark.Name = "Checkmark"
	Checkmark.Image = CheckmarkImages[value]
	Checkmark.ImageColor3 = CheckmarkColors[value]
	Checkmark.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Checkmark.BackgroundTransparency = 1
	Checkmark.Position = UDim2.fromOffset(2, 2)
	Checkmark.Size = UDim2.new(1, -4, 1, -4)
	
	local UIARC = Instance.new("UIAspectRatioConstraint")
	UIARC.Name = "UIAspectRatioConstraint"
	UIARC.Parent = Checkmark
	
	Checkmark.Parent = Value
	Value.Parent = BooleanField
	
	return BooleanField, Checkmark
end

local BooleanField = {}
BooleanField.__index = BooleanField
BooleanField.__tostring = function(self) return self.Name end
BooleanField.__metatable = "This metatable is locked"

function BooleanField:SetName(name: string)
	assert(not self.__Destroyed, "field destroyed")
	assert(typeof(name) == "string", "invalid argument #1 to 'SetName' (string expected, got "..typeof(name)..")")
	self.Name = name
	self.Instance.Name = name
	self.Instance.Name:FindFirstChild("Name").Text = name
	return
end

function BooleanField:SetValue(value: boolean? | any)
	assert(not self.__Destroyed, "field destroyed")
	local Value: boolean = if typeof(value) == "boolean" then value else (not (not value))
	self.Value = Value
	self.OnValueChanged:Fire(Value)
	self.Instance.Value.Checkmark.Image = CheckmarkImages[Value]
	self.Instance.Value.Checkmark.ImageColor3 = CheckmarkColors[Value]
	return
end

function BooleanField:Destroy()
	if self.__Destroyed then return end
	self.__Destroyed = true
	self.Instance:Destroy()
	self.OnValueChanged:Destroy()
	return
end

local function constructor_BooleanField(name: string?, value: boolean?)
	local Name = name or "BooleanField"
	local Value = if typeof(value) == "boolean" then value else (not (not value))
	local BooleanFieldInstance, Checkmark = CreateInstance(Name, Value)
	
	local NewBooleanField = setmetatable({
		--// Properties
		Name = Name;
		Value = Value;
		Instance = BooleanFieldInstance;
		
		--// Events
		OnValueChanged = RESignal.new(RESignal.SignalBehavior.NewThread);
		
		--// Private properties
		__Destroyed = false;
	}, BooleanField)
	
	Checkmark.MouseButton1Click:Connect(function()
		return NewBooleanField:SetValue(not NewBooleanField.Value)
	end)
	
	return NewBooleanField
end
return setmetatable({ new = constructor_BooleanField }, { __call = function(_, ...) return constructor_BooleanField(...) end })