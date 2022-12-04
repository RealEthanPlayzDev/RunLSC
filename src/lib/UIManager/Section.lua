--[[
File name: Section.lua
Author: RadiatedExodus (RealEthanPlayzDev)
Created at: December 4, 2022

Custom class that creates a section similar to the
properties widget's section.
--]]

--// Libraries
local RESignal = require(script.Parent.Parent.RESignal)

--// Functions
local function CalculateRootSize(instance: Frame & { Content: Frame & { UIListLayout: UIListLayout } }, expanded: boolean)
	if expanded then
		return UDim2.new(1, -13, 0, 20 + instance.Content.UIListLayout.AbsoluteContentSize.Y)
	else
		return UDim2.new(1, -13, 0, 20)
	end
end
local function CreateInstance(name: string, expanded: boolean)
	local Section = Instance.new("Frame")
	Section.Name = name
	Section.BackgroundColor3 = Color3.fromRGB(53, 53, 53)
	Section.BorderColor3 = Color3.fromRGB(34, 34, 34)

	local Header = Instance.new("TextButton")
	Header.Name = "Header"
	Header.Text = ""
	Header.Active = false
	Header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Header.BackgroundTransparency = 1
	Header.BorderSizePixel = 0
	Header.Selectable = false
	Header.Size = UDim2.new(1, 0, 0, 20)

	local ExpandArrow = Instance.new("ImageLabel")
	ExpandArrow.Name = "ExpandArrow"
	ExpandArrow.Image = "rbxassetid://10709767827"
	ExpandArrow.Rotation = if ExpandArrow then 0 else 270
	ExpandArrow.ScaleType = Enum.ScaleType.Fit
	ExpandArrow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	ExpandArrow.BackgroundTransparency = 1
	ExpandArrow.Position = UDim2.fromOffset(2, 2)
	ExpandArrow.Size = UDim2.new(1, -4, 1, -4)

	local ExpandArrowUIARC = Instance.new("UIAspectRatioConstraint")
	ExpandArrowUIARC.Name = "UIAspectRatioConstraint"
	ExpandArrowUIARC.Parent = ExpandArrow

	ExpandArrow.Parent = Header

	local SectionName = Instance.new("TextLabel")
	SectionName.Name = "SectionName"
	SectionName.FontFace = Font.new(
		"rbxasset://fonts/families/Inconsolata.json",
		Enum.FontWeight.Bold,
		Enum.FontStyle.Normal
	)
	SectionName.Text = name
	SectionName.TextColor3 = Color3.fromRGB(255, 255, 255)
	SectionName.TextScaled = true
	SectionName.TextSize = 14
	SectionName.TextWrapped = true
	SectionName.TextXAlignment = Enum.TextXAlignment.Left
	SectionName.AnchorPoint = Vector2.new(1, 0)
	SectionName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	SectionName.BackgroundTransparency = 1
	SectionName.Position = UDim2.new(1, 0, 0, 2)
	SectionName.Size = UDim2.new(1, -22, 1, -4)
	SectionName.Parent = Header

	Header.Parent = Section

	local Content = Instance.new("Frame")
	Content.Name = "Content"
	Content.Visible = expanded
	Content.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Content.BackgroundTransparency = 1
	Content.BorderSizePixel = 0
	Content.Position = UDim2.fromOffset(0, 20)
	Content.Size = UDim2.new(1, 0, 1, -20)

	local ContentUILL = Instance.new("UIListLayout")
	ContentUILL.Name = "UIListLayout"
	ContentUILL.SortOrder = Enum.SortOrder.LayoutOrder
	ContentUILL.Parent = Content

	Content.Parent = Section
	
	Section.Size = CalculateRootSize(Section, expanded)
	return Section, Header, ContentUILL
end

local Section = {}
Section.__index = Section
Section.__tostring = function(self) return self.Name end
Section.__metatable = "This metatable is locked"

function Section:SetName(name: string)
	assert(not self.__Destroyed, "section destroyed")
	assert(typeof(name) == "string", "invalid argument #1 to 'SetName' (string expected, got "..typeof(name)..")")
	self.Instance.Name = name
	self.Instance.Header.SectionName.Text = name
	return
end

function Section:SetExpanded(expanded: boolean? | any)
	assert(not self.__Destroyed, "section destroyed")
	local Expanded: boolean = if typeof(expanded) == "boolean" then expanded else (not (not expanded))
	self.Expanded = Expanded
	self.OnExpandChanged:Fire(Expanded)
	self.Instance.Size = CalculateRootSize(self.Instance, Expanded)
	self.Instance.Header.ExpandArrow.Rotation = if Expanded then 0 else 270
	self.Instance.Content.Visible = Expanded
	return
end

function Section:GetContentFrame()
	return self.Instance.Content
end

function Section:Destroy()
	if self.__Destroyed then return end
	self.__Destroyed = true
	self.Instance:Destroy()
	self.OnExpandChanged:Destroy()
	return
end

local function constructor_Section(name: string?, expanded: boolean?)
	local Name = name or "Section"
	local Expanded = if typeof(value) == "boolean" then expanded else true
	local SectionInstance, SectionHeader, ContentUILL = CreateInstance(Name, Expanded)
	local NewSection = setmetatable({
		--// Properties
		Name = Name;
		Expanded = Expanded;
		Instance = SectionInstance;

		--// Events
		OnExpandChanged = RESignal.new(RESignal.SignalBehavior.NewThread);

		--// Private properties
		__Destroyed = false;
	}, Section)
	
	SectionHeader.MouseButton1Click:Connect(function()
		return NewSection:SetExpanded(not NewSection.Expanded)
	end)

	ContentUILL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		NewSection.Instance.Size = CalculateRootSize(NewSection.Instance, NewSection.Expanded)
	end)
	
	return NewSection
end
return setmetatable({ new = constructor_Section }, { __call = function(_, ...) return constructor_Section(...) end })