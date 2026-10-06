-- BOOST SYSTEM INTEGRATION - CLEAN VERSION WITH PROPER MULTIPLIER COMBINATION
-- This enhances your existing system without breaking anything

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

-- ===========================
-- BOOST SYSTEM SETUP
-- ===========================

-- Create boost event
local boostEvent = ReplicatedStorage:FindFirstChild("BoostEvent")
if not boostEvent then
	boostEvent = Instance.new("RemoteEvent")
	boostEvent.Name = "BoostEvent"
	boostEvent.Parent = ReplicatedStorage
end

-- Boost product configuration
local BOOST_PRODUCTS = {
	[3305211382] = {fromLevel = 1, toLevel = 3},   -- 1X -> 3X
	[3305211668] = {fromLevel = 3, toLevel = 5},   -- 3X -> 5X
	[3305211841] = {fromLevel = 5, toLevel = 7},   -- 5X -> 7X
	[3305211985] = {fromLevel = 7, toLevel = 9},   -- 7X -> 9X
	[3305212165] = {fromLevel = 9, toLevel = 11},  -- 9X -> 11X
	[3305212380] = {fromLevel = 11, toLevel = 13}, -- 11X -> 13X
	[3305212591] = {fromLevel = 13, toLevel = 15}, -- 13X -> 15X
	[3305212906] = {fromLevel = 15, toLevel = 17}, -- 15X -> 17X
	[3305213120] = {fromLevel = 17, toLevel = 19}  -- 17X -> 19X
}

-- ===========================
-- BOOST LEVEL MANAGEMENT
-- ===========================

-- Function to ensure GameData folder exists
local function ensureGameData(player)
	local gameData = player:FindFirstChild("GameData")
	if not gameData then
		gameData = Instance.new("Folder")
		gameData.Name = "GameData"
		gameData.Parent = player
	end
	return gameData
end

-- Function to get player boost level
local function getPlayerBoostLevel(player)
	local gameData = player:FindFirstChild("GameData")
	if gameData and gameData:FindFirstChild("BoostLevel") then
		return gameData.BoostLevel.Value
	end
	return 1 -- Default boost level
end

-- Function to set player boost level
local function setPlayerBoostLevel(player, level)
	local gameData = ensureGameData(player)

	local boostLevelValue = gameData:FindFirstChild("BoostLevel")
	if not boostLevelValue then
		boostLevelValue = Instance.new("IntValue")
		boostLevelValue.Name = "BoostLevel"
		boostLevelValue.Value = 1
		boostLevelValue.Parent = gameData
	end

	boostLevelValue.Value = level

	-- Save to datastore if available
	if _G.DataManager and _G.DataManager.setPlayerData then
		pcall(function()
			_G.DataManager.setPlayerData(player, "boostLevel", level)
		end)
	end

	-- Send confirmation to client
	boostEvent:FireClient(player, true, level)

	-- Update displays using existing functions
	task.spawn(function()
		task.wait(0.5)
		if updateBaseMultiplierDisplay then
			updateBaseMultiplierDisplay(player)
		end
		if updateAllBabyDisplaysForPlayer then
			updateAllBabyDisplaysForPlayer(player)
		end
	end)

	return true
end

-- Function to load boost level from datastore
local function loadPlayerBoostLevel(player)
	local savedLevel = 1

	-- Load from datastore if available
	if _G.DataManager and _G.DataManager.getPlayerData then
		local success, result = pcall(function()
			return _G.DataManager.getPlayerData(player, "boostLevel")
		end)
		if success and result then
			savedLevel = result
		end
	end

	-- Set the loaded level
	local gameData = ensureGameData(player)
	local boostLevelValue = gameData:FindFirstChild("BoostLevel")
	if not boostLevelValue then
		boostLevelValue = Instance.new("IntValue")
		boostLevelValue.Name = "BoostLevel"
		boostLevelValue.Parent = gameData
	end

	boostLevelValue.Value = savedLevel
	return savedLevel
end

-- ===========================
-- ENHANCED MULTIPLIER SYSTEM (ADDITIVE)
-- ===========================

-- Store the original function if it exists
local originalGetPlayerCoinsMultiplier = _G.GetPlayerCoinsMultiplier

-- Enhanced multiplier function that combines rebirth and boost multipliers ADDITIVELY
-- Example: 73x rebirth + 9x boost = 73x + 8x = 81x total (not 73x * 9x = 657x)
_G.GetPlayerCoinsMultiplier = function(player)
	-- Get rebirth multiplier
	local rebirthMultiplier = 1
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats and leaderstats:FindFirstChild("Rebirth") then
		local rebirthValue = leaderstats.Rebirth.Value
		-- Use RebirthData if available
		if RebirthData and RebirthData.GetTotalCoinsMultiplier then
			local bonusMultiplier = RebirthData:GetTotalCoinsMultiplier(rebirthValue)
			rebirthMultiplier = 1 + bonusMultiplier
		elseif originalGetPlayerCoinsMultiplier then
			rebirthMultiplier = originalGetPlayerCoinsMultiplier(player)
		end
	end

	-- Get boost multiplier
	local boostMultiplier = getPlayerBoostLevel(player)

	-- Calculate total: rebirth multiplier + boost multiplier (additive, not multiplicative)
	-- If boost is 9x, it adds 8x to the total (since 1x is the base)
	local totalMultiplier = rebirthMultiplier + (boostMultiplier - 1)

	return totalMultiplier
end

-- ===========================
-- MARKETPLACE HANDLING
-- ===========================

-- Function to process boost purchases
local function processBoostPurchase(receiptInfo)
	local userId = receiptInfo.PlayerId
	local productId = receiptInfo.ProductId

	-- Check if this is a boost product
	local boostData = BOOST_PRODUCTS[productId]
	if not boostData then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Find the player
	local player = nil
	for _, p in pairs(Players:GetPlayers()) do
		if p.UserId == userId then
			player = p
			break
		end
	end

	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Grant the boost upgrade
	setPlayerBoostLevel(player, boostData.toLevel)

	-- Send server message
	if _G.SendServerMessage then
		_G.SendServerMessage(player, "🚀 Boost upgraded to " .. boostData.toLevel .. "x!")
	end

	-- Play success sound
	if soundRemote then
		soundRemote:FireClient(player, "Code_Reedemed")
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- Set ProcessReceipt handler
MarketplaceService.ProcessReceipt = function(receiptInfo)
	-- Try boost products first
	local boostResult = processBoostPurchase(receiptInfo)
	if boostResult == Enum.ProductPurchaseDecision.PurchaseGranted then
		return boostResult
	end

	-- Default fallback for unknown products
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- ===========================
-- PLAYER SETUP
-- ===========================

-- Function to setup boost system for a player
local function setupPlayerBoostSystem(player)
	task.spawn(function()
		task.wait(3) -- Wait for other systems to load
		loadPlayerBoostLevel(player)

		-- Update displays after loading
		task.wait(1)
		if updateBaseMultiplierDisplay then
			updateBaseMultiplierDisplay(player)
		end
		if updateAllBabyDisplaysForPlayer then
			updateAllBabyDisplaysForPlayer(player)
		end
	end)
end

-- Setup boost system for existing players
for _, player in pairs(Players:GetPlayers()) do
	setupPlayerBoostSystem(player)
end

-- Setup boost system for new players
Players.PlayerAdded:Connect(function(player)
	setupPlayerBoostSystem(player)
end)

-- ===========================
-- GLOBAL FUNCTIONS
-- ===========================

-- Export functions for other scripts
_G.GetPlayerBoostLevel = getPlayerBoostLevel
_G.SetPlayerBoostLevel = setPlayerBoostLevel
_G.LoadPlayerBoostLevel = loadPlayerBoostLevel