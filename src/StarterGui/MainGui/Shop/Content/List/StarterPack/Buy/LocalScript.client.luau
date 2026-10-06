local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local BUTTON = script.Parent
local FRAME = BUTTON.Parent
local PRO_PACK_PRODUCT_ID = 3312811704

local function getSound(name)
	local sounds = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("Sounds")
	if sounds then return sounds:FindFirstChild(name) end
end

local SOUNDS = {
	HOVER = getSound("ButtonHover"),
	PRESS = getSound("ButtonPress"),
	SUCCESS = getSound("MilestoneSound")
}

local function playSound(sound)
	if sound then
		local s = sound:Clone()
		s.Parent = FRAME
		s:Play()
		Debris:AddItem(s, s.TimeLength)
	end
end

local GRADIENTS = {
	DEFAULT = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(38, 230, 38)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(208, 255, 0))
	},
	HOVER = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(58, 250, 58)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(228, 255, 20))
	},
	DOWN = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(251, 255, 24)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 166, 94))
	}
}

local gradient = BUTTON:FindFirstChild("UIGradient") or Instance.new("UIGradient", BUTTON)
local scale = BUTTON:FindFirstChild("UIScale") or Instance.new("UIScale", BUTTON)
scale.Scale = 1
gradient.Color = GRADIENTS.DEFAULT

local mouseDown = false
local hovered = false

local function playAnimation()
	playSound(SOUNDS.SUCCESS)
	TweenService:Create(scale, TweenInfo.new(0.05), {Scale = scale.Scale * 1.3}):Play()
	task.delay(0.05, function()
		TweenService:Create(scale, TweenInfo.new(0.2), {Scale = 1}):Play()
	end)
end

BUTTON.MouseEnter:Connect(function()
	hovered = true
	if not mouseDown then
		playSound(SOUNDS.HOVER)
		TweenService:Create(scale, TweenInfo.new(0.18), {Scale = 1.05}):Play()
		gradient.Color = GRADIENTS.HOVER
	end
end)

BUTTON.MouseLeave:Connect(function()
	hovered = false
	TweenService:Create(scale, TweenInfo.new(0.18), {Scale = 1}):Play()
	gradient.Color = GRADIENTS.DEFAULT
end)

BUTTON.MouseButton1Down:Connect(function()
	mouseDown = true
	playSound(SOUNDS.PRESS)
	TweenService:Create(scale, TweenInfo.new(0.18), {Scale = 0.95}):Play()
	gradient.Color = GRADIENTS.DOWN
end)

BUTTON.MouseButton1Up:Connect(function()
	mouseDown = false
	local color = hovered and GRADIENTS.HOVER or GRADIENTS.DEFAULT
	local targetScale = hovered and 1.05 or 1
	TweenService:Create(scale, TweenInfo.new(0.18), {Scale = targetScale}):Play()
	gradient.Color = color
end)

local function promptPurchase()
	MarketplaceService:PromptProductPurchase(player, PRO_PACK_PRODUCT_ID)
	playAnimation()
end

BUTTON.MouseButton1Click:Connect(promptPurchase)
BUTTON.TouchTap:Connect(promptPurchase)