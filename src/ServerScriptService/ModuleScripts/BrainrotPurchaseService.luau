local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local BrainrotConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("BrainrotConfig"))
local RarityConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("RarityConfig"))
local CurrencyService = require(script.Parent:WaitForChild("CurrencyService"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))
local StandService = require(script.Parent:WaitForChild("StandService"))
local BrainrotMovement = require(script.Parent:WaitForChild("BrainrotMovement"))
local ErrorHandler = nil

pcall(function()
	ErrorHandler = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("ErrorHandler"))
end)

local BrainrotPurchaseService = {}

local function sendNotification(player, message)
	if ErrorHandler and ErrorHandler.ShowError then
		pcall(function()
			ErrorHandler.ShowError(player, message)
		end)
	else
		print(string.format("[Notification to %s]: %s", player.Name, message))
	end
end

local function rarityColor(rarity)
	local info = RarityConfig.Get(rarity)
	local color = info and info.Color
	if typeof(color) == "table" then
		return Color3.fromRGB(color[1] or 255, color[2] or 255, color[3] or 255)
	end
	return Color3.fromRGB(255, 255, 255)
end

-- Floating rarity-colored name/price card above a freshly-delivered Brainrot, with a slow pulse.
local function attachPurchaseBillboard(primaryPart, brainrotData)
	local existing = primaryPart:FindFirstChild("PurchaseBillboard")
	if existing then existing:Destroy() end

	local color = rarityColor(brainrotData.Rarity)
	local price = brainrotData.Price or brainrotData.PurchaseCost or 100

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "PurchaseBillboard"
	billboard.Size = UDim2.fromOffset(200, 60)
	billboard.StudsOffset = Vector3.new(0, 3.2, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = primaryPart

	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
	frame.BackgroundTransparency = 0.15
	frame.BorderSizePixel = 0
	frame.Size = UDim2.fromScale(1, 1)
	frame.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 2
	stroke.Parent = frame

	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.Size = UDim2.new(1, -8, 0.5, 0)
	nameLabel.Position = UDim2.fromOffset(4, 2)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true
	nameLabel.TextColor3 = color
	nameLabel.Text = tostring(brainrotData.DisplayName or brainrotData.BrainrotId or "Brainrot")
	nameLabel.Parent = frame

	local priceLabel = Instance.new("TextLabel")
	priceLabel.BackgroundTransparency = 1
	priceLabel.Size = UDim2.new(1, -8, 0.5, 0)
	priceLabel.Position = UDim2.new(0, 4, 0.5, 0)
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.TextScaled = true
	priceLabel.TextColor3 = Color3.fromRGB(255, 205, 76)
	priceLabel.Text = string.format("%s  \xe2\x80\xa2  %d Coins", tostring(brainrotData.Rarity or ""), price)
	priceLabel.Parent = frame

	task.spawn(function()
		while billboard.Parent do
			TweenService:Create(stroke, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.6}):Play()
			task.wait(0.6)
			if not billboard.Parent then break end
			TweenService:Create(stroke, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0}):Play()
			task.wait(0.6)
		end
	end)

	return billboard
end

function BrainrotPurchaseService:SetupPurchasePrompt(brainrotModel, brainrotData)
	if not brainrotModel or not brainrotData then return end

	local primaryPart = brainrotModel.PrimaryPart or brainrotModel:FindFirstChildWhichIsA("BasePart")
	if not primaryPart then return end

	local existingPrompt = brainrotModel:FindFirstChildWhichIsA("ProximityPrompt", true)
	if existingPrompt then
		existingPrompt:Destroy()
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PurchasePrompt"
	prompt.ActionText = "BUY"
	prompt.ObjectText = string.format("%s - %d Coins", brainrotData.DisplayName or brainrotData.BrainrotId or "Brainrot", brainrotData.Price or brainrotData.PurchaseCost or 100)
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 24
	prompt.RequiresLineOfSight = false
	prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
	prompt.UIOffset = Vector2.new(0, -40)
	prompt:SetAttribute("BrainrotPurchasePrompt", true)
	prompt.Enabled = true
	prompt.Parent = brainrotModel

	local billboard = attachPurchaseBillboard(primaryPart, brainrotData)

	local isPurchased = false

	prompt.Triggered:Connect(function(player)
		if isPurchased then return end

		local success, reason = self:ProcessPurchase(player, brainrotModel, brainrotData)
		if success then
			isPurchased = true
			prompt.Enabled = false
			prompt:Destroy()
			if billboard and billboard.Parent then billboard:Destroy() end
		else
			if reason == "NOT_ENOUGH_COINS" then
				sendNotification(player, "Not enough Coins!")
			elseif reason == "NO_STANDS" then
				sendNotification(player, "Not enough space! Free up a stand at your base.")
			elseif reason == "NO_BASE_ASSIGNED" then
				sendNotification(player, "You don't have a base yet!")
			elseif reason == "ALREADY_PURCHASED" then
				sendNotification(player, "This Brainrot was already claimed!")
			else
				sendNotification(player, reason or "Cannot purchase Brainrot!")
			end
		end
	end)

	return prompt
end

function BrainrotPurchaseService:ProcessPurchase(player, brainrotModel, brainrotData)
	if not player or not player.Parent then
		return false, "INVALID_PLAYER"
	end

	if brainrotModel:GetAttribute("Purchased") == true then
		return false, "ALREADY_PURCHASED"
	end

	local price = brainrotData.Price or brainrotData.PurchaseCost or 50
	if not CurrencyService:HasCoins(player, price) then
		return false, "NOT_ENOUGH_COINS"
	end

	local base = BaseService:GetPlayerBase(player)
	if not base then
		base = BaseService:AssignBase(player)
	end

	if not base then
		return false, "NO_BASE_ASSIGNED"
	end

	local availableStand = StandService:GetAvailableStand(base)
	if not availableStand then
		return false, "NO_STANDS"
	end

	-- Lock stand immediately to avoid race condition
	availableStand.Occupied = true

	local deducted = CurrencyService:RemoveCoins(player, price)
	if not deducted then
		availableStand.Occupied = false
		return false, "NOT_ENOUGH_COINS"
	end

	brainrotModel:SetAttribute("Purchased", true)
	brainrotModel:SetAttribute("OwnerUserId", player.UserId)
	brainrotModel:SetAttribute("StandId", availableStand.StandId)

	print(string.format("[BrainrotPurchaseService] %s purchased %s for %d Coins. Moving to %s (%s)", player.Name, brainrotData.DisplayName, price, base.Name, availableStand.StandId))

	BrainrotMovement:MoveToBaseStand(brainrotModel, availableStand, function(success)
		StandService:AssignBrainrot(base, availableStand.StandId, brainrotModel, brainrotData.BrainrotId, brainrotData)
		print(string.format("[BrainrotPurchaseService] %s arrived at stand %s and is now generating income", brainrotData.DisplayName, availableStand.StandId))
	end)

	return true
end

return BrainrotPurchaseService
