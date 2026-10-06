local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer

-- Matching Developer Product IDs
local productMap = {
	["2000"] = 3312804490,
	["20000"] = 3312804720,
	["50000"] = 3312804993,
	["200000"] = 3312805338,
	["2000000"] = 3312805793
}

-- Gradient styles
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

-- Load sound from ReplicatedStorage
local function getSound(name)
	local sounds = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("Sounds")
	if sounds then
		return sounds:FindFirstChild(name)
	end
end

local SOUNDS = {
	HOVER = getSound("ButtonHover"),
	PRESS = getSound("ButtonPress"),
	SUCCESS = getSound("MilestoneSound")
}

local function playSound(name, parent)
	local soundTemplate = SOUNDS[name]
	if not soundTemplate then return end
	local clone = soundTemplate:Clone()
	clone.Parent = parent
	clone:Play()
	game.Debris:AddItem(clone, clone.TimeLength)
end

local function hookBuy(moneyFrame)
	local productId = productMap[moneyFrame.Name]
	if not productId then return end

	local buyBtn = moneyFrame:FindFirstChild("Buy")
	if not buyBtn then return end

	local uiGrad = buyBtn:FindFirstChild("UIGradient") or Instance.new("UIGradient", buyBtn)
	uiGrad.Color = GRADIENTS.DEFAULT

	local uiScale = buyBtn:FindFirstChild("UIScale") or Instance.new("UIScale", buyBtn)
	uiScale.Scale = 1

	buyBtn.MouseEnter:Connect(function()
		TweenService:Create(uiScale, TweenInfo.new(0.1), {Scale = 1.05}):Play()
		uiGrad.Color = GRADIENTS.HOVER
		playSound("HOVER", buyBtn)
	end)

	buyBtn.MouseLeave:Connect(function()
		TweenService:Create(uiScale, TweenInfo.new(0.1), {Scale = 1}):Play()
		uiGrad.Color = GRADIENTS.DEFAULT
	end)

	buyBtn.MouseButton1Down:Connect(function()
		TweenService:Create(uiScale, TweenInfo.new(0.08), {Scale = 0.95}):Play()
		uiGrad.Color = GRADIENTS.DOWN
		playSound("PRESS", buyBtn)
	end)

	buyBtn.MouseButton1Up:Connect(function()
		TweenService:Create(uiScale, TweenInfo.new(0.1), {Scale = 1.05}):Play()
		uiGrad.Color = GRADIENTS.HOVER
	end)

	local function doPurchase()
		MarketplaceService:PromptProductPurchase(player, productId)
		playSound("SUCCESS", buyBtn)
	end

	buyBtn.MouseButton1Click:Connect(doPurchase)
	buyBtn.TouchTap:Connect(doPurchase)
end

-- Loop through all purchase frames in container
for _, category in ipairs({"1", "2"}) do
	local container = script.Parent:FindFirstChild(category)
	if container then
		for _, moneyFrame in ipairs(container:GetChildren()) do
			if productMap[moneyFrame.Name] then
				hookBuy(moneyFrame)
			end
		end
	end
end
