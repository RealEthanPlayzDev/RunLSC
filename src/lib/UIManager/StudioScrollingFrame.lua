--[[
File name: StudioScrollingFrame.lua
Author: RadiatedExodus (RealEthanPlayzDev)
Created at: December 4, 2022

Custom class that creates a scrolling frame similar to
Studio's scrolling frame in properties widget
--]]

--// Functions
local function CreateInstance()
	local StudioScrollingFrame = Instance.new("Frame")
	StudioScrollingFrame.Name = "StudioScrollingFrame"
	StudioScrollingFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	StudioScrollingFrame.BackgroundTransparency = 1
	StudioScrollingFrame.Size = UDim2.fromScale(1, 1)

	local ScrollBarBG = Instance.new("Frame")
	ScrollBarBG.Name = "ScrollBarBG"
	ScrollBarBG.AnchorPoint = Vector2.new(1, 0)
	ScrollBarBG.BackgroundColor3 = Color3.fromRGB(41, 41, 41)
	ScrollBarBG.BorderSizePixel = 0
	ScrollBarBG.Position = UDim2.fromScale(1, 0)
	ScrollBarBG.Size = UDim2.new(0, 12, 1, 0)
	ScrollBarBG.Parent = StudioScrollingFrame

	local ScrollingFrame = Instance.new("ScrollingFrame")
	ScrollingFrame.Name = "ScrollingFrame"
	ScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	ScrollingFrame.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	ScrollingFrame.CanvasSize = UDim2.new()
	ScrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(56, 56, 56)
	ScrollingFrame.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	ScrollingFrame.Active = true
	ScrollingFrame.BackgroundColor3 = Color3.fromRGB(46, 46, 46)
	ScrollingFrame.BackgroundTransparency = 1
	ScrollingFrame.BorderColor3 = Color3.fromRGB(34, 34, 34)
	ScrollingFrame.Size = UDim2.fromScale(1, 1)
	ScrollingFrame.ElasticBehavior = Enum.ElasticBehavior.Never
	ScrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
	ScrollingFrame.ZIndex = 2

	local UILL = Instance.new("UIListLayout")
	UILL.Name = "UIListLayout"
	UILL.SortOrder = Enum.SortOrder.LayoutOrder
	UILL.Parent = ScrollingFrame

	ScrollingFrame.Parent = StudioScrollingFrame
	return StudioScrollingFrame, ScrollingFrame, ScrollBarBG
end

local StudioScrollingFrame = {}
StudioScrollingFrame.__index = StudioScrollingFrame
StudioScrollingFrame.__tostring = function(self) return "StudioScrollingFrame" end
StudioScrollingFrame.__metatable = "This metatable is locked"

function StudioScrollingFrame:GetContentFrame()
	return self.Instance.ScrollingFrame
end

function StudioScrollingFrame:Destroy()
	if self.__Destroyed then return end
	self.__Destroyed = true
	self.Instance:Destroy()
	return
end

local function constructor_StudioScrollingFrame()
	local StudioScrollingFrameInstance, ScrollingFrame, ScrollingFrameBG = CreateInstance()
	ScrollingFrame:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(function()
		if ScrollingFrame.AbsoluteCanvasSize.Y > ScrollingFrame.AbsoluteSize.Y then
			ScrollingFrameBG.Visible = true
		else
			ScrollingFrameBG.Visible = false
		end
	end)
	
	return setmetatable({
		--// Properties
		Instance = StudioScrollingFrameInstance;

		--// Private properties
		__Destroyed = false;
	}, StudioScrollingFrame)
end
return setmetatable({ new = constructor_StudioScrollingFrame }, { __call = function(_, ...) return constructor_StudioScrollingFrame(...) end })