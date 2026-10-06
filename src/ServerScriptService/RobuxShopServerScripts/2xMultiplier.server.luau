-- SERVER SCRIPT - Place in ServerScriptService
-- Coins Multiplier Purchase System

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

-- Studio detection
local isStudio = RunService:IsStudio()

-- ======== CONFIGURATION ========
local CONFIG = {
	-- Product mapping - current multiplier to next product ID and price
	PRODUCTS = {
		[0] = {id = 3312814735, price = 3, toLevel = 2},   -- 0 -> 2X: 3 Robux (FIRST UPGRADE)
		[2] = {id = 3312815789, price = 5, toLevel = 5},   -- 2X -> 5X: 5 Robux
		[5] = {id = 3312815208, price = 7, toLevel = 7},   -- 5X -> 7X: 7 Robux
		[7] = {id = 3312819370, price = 9, toLevel = 9},   -- 7X -> 9X: 9 Robux
		[9] = {id = 3312819589, price = 11, toLevel = 11}, -- 9X -> 11X: 11 Robux
		[11] = {id = 3312819879, price = 13, toLevel = 13}, -- 11X -> 13X: 13 Robux
		[13] = {id = 3312821944, price = 15, toLevel = 15}, -- 13X -> 15X: 15 Robux
		[15] = {id = 3312822230, price = 17, toLevel = 17}, -- 15X -> 17X: 17 Robux
		[17] = {id = 3312822386, price = 19, toLevel = 19}  -- 17X -> 19X: 19 Robux
	}
}

-- Track processed purchases
local processedPurchases = {}

local function isPurchaseProcessed(purchaseId)
	return processedPurchases[purchaseId] ~= nil
end

local function markPurchaseProcessed(purchaseId)
	processedPurchases[purchaseId] = os.time()
end

-- Force create or get RemoteEvents
local function createOrGetRemoteEvent(name)
	local event = ReplicatedStorage:FindFirstChild(name)
	if not event then
		event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = ReplicatedStorage
	end
	return event
end

-- Create necessary RemoteEvents
local coinsMultiEvent = createOrGetRemoteEvent("CoinsMultiEvent")
local studioPurchaseEvent = createOrGetRemoteEvent("StudioPurchaseEvent")

-- Create GameData folder and CoinsMultiplier for player
local function createGameData(player)
	local gameData = player:FindFirstChild("GameData")
	if not gameData then
		gameData = Instance.new("Folder")
		gameData.Name = "GameData"
		gameData.Parent = player
	end

	local coinsMultiplier = gameData:FindFirstChild("CoinsMultiplier")
	if not coinsMultiplier then
		coinsMultiplier = Instance.new("IntValue")
		coinsMultiplier.Name = "CoinsMultiplier"
		coinsMultiplier.Value = 0 -- Start at 0 multiplier (no boost)
		coinsMultiplier.Parent = gameData
	end

	return coinsMultiplier
end

-- Function to upgrade coins multiplier
local function upgradeCoinsMultiplier(player, purchaseId)
	if purchaseId and isPurchaseProcessed(purchaseId) then
		return true, nil
	end

	local gameData = player:FindFirstChild("GameData")
	if not gameData then
		gameData = Instance.new("Folder")
		gameData.Name = "GameData"
		gameData.Parent = player
	end

	local coinsMultiplier = gameData:FindFirstChild("CoinsMultiplier")
	if not coinsMultiplier then
		coinsMultiplier = Instance.new("IntValue")
		coinsMultiplier.Name = "CoinsMultiplier"
		coinsMultiplier.Value = 0 -- Start at 0
		coinsMultiplier.Parent = gameData
	end

	local currentLevel = coinsMultiplier.Value
	local productInfo = CONFIG.PRODUCTS[currentLevel]

	if not productInfo then
		return false, "Max level reached"
	end

	-- Upgrade to the next level
	local newLevel = productInfo.toLevel
	coinsMultiplier.Value = newLevel

	if purchaseId then
		markPurchaseProcessed(purchaseId)
	end

	-- Send success to client
	coinsMultiEvent:FireClient(player, true, newLevel)

	-- Debug print for server console
	print(player.Name .. " upgraded coins multiplier from " .. currentLevel .. "x to " .. newLevel .. "x")

	return true, newLevel
end

-- Handle player joining
local function onPlayerJoin(player)
	createGameData(player)
	print(player.Name .. " joined with 0x coins multiplier (no boost)")
end

-- Handle Studio purchases (Studio only)
if isStudio then
	studioPurchaseEvent.OnServerEvent:Connect(function(player, productId)
		-- Check if this is one of our coins multiplier products
		local isCoinsMultiProduct = false
		for level, productInfo in pairs(CONFIG.PRODUCTS) do
			if productId == productInfo.id then
				isCoinsMultiProduct = true
				break
			end
		end

		if isCoinsMultiProduct then
			local success, newLevel = upgradeCoinsMultiplier(player, "studio_" .. tick())
			print("Studio purchase processed for " .. player.Name .. ": " .. tostring(success))
		end
	end)
end

-- Setup product purchase handler (Live games only)
if not isStudio then
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
		if not player then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local purchaseId = receiptInfo.PurchaseId
		local productId = receiptInfo.ProductId

		if isPurchaseProcessed(purchaseId) then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		-- Check if this is one of our coins multiplier products
		local isCoinsMultiProduct = false
		for level, productInfo in pairs(CONFIG.PRODUCTS) do
			if productId == productInfo.id then
				isCoinsMultiProduct = true
				break
			end
		end

		if isCoinsMultiProduct then
			local success, newLevel = upgradeCoinsMultiplier(player, purchaseId)

			if success then
				markPurchaseProcessed(purchaseId)
				print("Live purchase processed for " .. player.Name .. ": upgraded to " .. newLevel .. "x")
				return Enum.ProductPurchaseDecision.PurchaseGranted
			else
				print("Failed to process purchase for " .. player.Name)
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end
		end

		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

-- Set up event handlers for player joining
Players.PlayerAdded:Connect(onPlayerJoin)

-- Set up existing players
for _, player in pairs(Players:GetPlayers()) do
	onPlayerJoin(player)
end

-- Optional: Command for testing in Studio (remove in production)
if isStudio then
	game.Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			if message:lower() == "/resetmultiplier" and player.Name == game.CreatorType.User then
				local gameData = player:FindFirstChild("GameData")
				if gameData then
					local coinsMultiplier = gameData:FindFirstChild("CoinsMultiplier")
					if coinsMultiplier then
						coinsMultiplier.Value = 0
						print("Reset " .. player.Name .. "'s coins multiplier to 0")
					end
				end
			end
		end)
	end)
end