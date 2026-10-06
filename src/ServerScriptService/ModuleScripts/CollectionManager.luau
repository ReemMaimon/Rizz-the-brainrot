-- CollectionManager.lua - FIXED VERSION WITH NAME PRESERVATION
local CollectionManager = {}

-- Services
local Players = game:GetService("Players")

-- Dependencies
local BrainrotConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("ModuleScripts"):WaitForChild("BrainrotConfig"))

local function getBrainrotData(name)
	return BrainrotConfig.GetByModelName(name) or BrainrotConfig.Get(name)
end
local UIManager = require(game:GetService("ReplicatedStorage"):WaitForChild("ModuleScripts"):WaitForChild("UIManager"))

-- Initialize workspace references
CollectionManager.basesFolder = nil
CollectionManager.soundRemote = nil

-- Collection state storage
local standCollections = {}
local activeCleanupTasks = {}

local function comprehensiveCleanup(player, standNumber, babyModel)
	local standKey = player.UserId .. "_" .. standNumber

	if standCollections[standKey] then
		standCollections[standKey] = nil
	end

	pcall(function()
		UIManager.disableCollectionUI(player, standNumber)
	end)

	if babyModel and babyModel.Parent then
		pcall(function()
			babyModel:SetAttribute("CollectionActive", nil)
		end)
	end

	if activeCleanupTasks[standKey] then
		activeCleanupTasks[standKey] = nil
	end
end

-- Helper function to get the actual baby name from the model
local function getOriginalBabyName(babyModel)
	if not babyModel then return nil end

	-- First check if there's a stored original name attribute
	local originalName = babyModel:GetAttribute("OriginalBabyName")
	if originalName then
		return originalName
	end

	-- Check if there's a StringValue storing the original name
	local nameValue = babyModel:FindFirstChild("BabyName") or babyModel:FindFirstChild("OriginalName")
	if nameValue and nameValue:IsA("StringValue") then
		return nameValue.Value
	end

	-- If the current name isn't "BabyModel", use it
	if babyModel.Name ~= "BabyModel" then
		return babyModel.Name
	end

	-- As fallback, try to determine from model structure or other indicators
	-- This is a backup in case the name was already changed
	local humanoid = babyModel:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.DisplayName ~= "Humanoid" and humanoid.DisplayName ~= "" then
		return humanoid.DisplayName
	end

	return nil
end

-- Helper function to find baby model in stand (regardless of current name)
local function findBabyModelInStand(stand)
	-- Look for any model that has baby characteristics
	for _, child in pairs(stand:GetChildren()) do
		if child:IsA("Model") then
			-- Check if it has humanoid (baby characteristic)
			local humanoid = child:FindFirstChildOfClass("Humanoid")
			if humanoid then
				-- Check if it has owner value (another baby characteristic)
				local owner = child:FindFirstChild("Owner")
				if owner then
					return child
				end
			end
		end
	end

	-- Fallback to looking for "BabyModel" if nothing else found
	return stand:FindFirstChild("BabyModel")
end

function CollectionManager.setupStandCollection(player, standNumber, babyName, babyModel)
	local ownedBase = player:FindFirstChild("OwnedBase")
	if not ownedBase then return end

	local baseNumber = ownedBase.Value
	local baseName = "Base" .. baseNumber
	local base = CollectionManager.basesFolder:FindFirstChild(baseName)
	if not base then return end

	local standsFolder = base:FindFirstChild("Stands")
	if not standsFolder then return end

	local stand = standsFolder:FindFirstChild("Stand" .. standNumber)
	if not stand then return end

	local collect = stand:FindFirstChild("Collect")
	if not collect then return end

	if collect:IsA("BasePart") then
		collect.CanCollide = false
		collect.CanTouch = true
		collect.Anchored = true
	end

	local standKey = player.UserId .. "_" .. standNumber

	-- Force cleanup existing collection
	comprehensiveCleanup(player, standNumber, nil)
	task.wait()

	-- Store the original baby name in the model to preserve it
	if babyModel and babyName then
		babyModel:SetAttribute("OriginalBabyName", babyName)

		-- Also create a StringValue as backup
		local nameValue = babyModel:FindFirstChild("BabyName")
		if not nameValue then
			nameValue = Instance.new("StringValue")
			nameValue.Name = "BabyName"
			nameValue.Parent = babyModel
		end
		nameValue.Value = babyName
	end

	-- Initialize new collection data
	standCollections[standKey] = {amount = 0, baby = babyModel, offlineAmount = 0}

	-- Apply offline earnings
	local offlineEarnings = 0
	if _G.DataManager and _G.DataManager.getOfflineEarningsForStand then
		offlineEarnings = _G.DataManager.getOfflineEarningsForStand(player, standNumber)
		if offlineEarnings > 0 then
			standCollections[standKey].offlineAmount = offlineEarnings
		end
	end

	-- Update UI using existing structure
	if offlineEarnings > 0 then
		UIManager.updateCollectionUIWithOffline(player, standNumber, 0, offlineEarnings)
	else
		UIManager.updateCollectionUI(player, standNumber, 0)
	end

	-- Enable the UI
	UIManager.enableCollectionUI(player, standNumber)

	-- Set up touch detection
	local debounce = false
	local touchConnection = nil

	touchConnection = collect.Touched:Connect(function(hit)
		if debounce then return end

		local character = hit.Parent
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end

		local touchingPlayer = Players:GetPlayerFromCharacter(character)
		if touchingPlayer ~= player then return end

		local collectionData = standCollections[standKey]
		if collectionData and collectionData.baby and collectionData.baby.Parent then
			local regularAmount = collectionData.amount or 0
			local offlineAmount = collectionData.offlineAmount or 0
			local totalToCollect = regularAmount + offlineAmount

			if totalToCollect > 0 then
				debounce = true

				-- Add coins to player
				if _G.DataManager and _G.DataManager.addCoins then
					_G.DataManager.addCoins(player, totalToCollect)
				else
					local coins = player.leaderstats:FindFirstChild("Coins")
					if coins then
						coins.Value = coins.Value + totalToCollect
					end
				end

				CollectionManager.soundRemote:FireClient(player, "Collecting_Coins")

				-- Clear offline earnings
				if offlineAmount > 0 then
					if _G.DataManager and _G.DataManager.clearOfflineEarningsForStand then
						_G.DataManager.clearOfflineEarningsForStand(player, standNumber)
					end
					collectionData.offlineAmount = 0
				end

				collectionData.amount = 0
				UIManager.updateCollectionUI(player, standNumber, 0)

				task.wait(0.5)
				debounce = false
			end
		end
	end)

	-- Cleanup connections
	local cleanupConnections = {}
	activeCleanupTasks[standKey] = true

	local function performCleanup()
		if not activeCleanupTasks[standKey] then return end

		if touchConnection then
			touchConnection:Disconnect()
			touchConnection = nil
		end

		for _, connection in pairs(cleanupConnections) do
			if connection then
				connection:Disconnect()
			end
		end
		cleanupConnections = {}

		comprehensiveCleanup(player, standNumber, babyModel)
	end

	-- Setup cleanup triggers
	cleanupConnections[#cleanupConnections + 1] = babyModel.AncestryChanged:Connect(function()
		if not babyModel.Parent then
			performCleanup()
		end
	end)

	local owner = babyModel:FindFirstChild("Owner")
	if owner then
		cleanupConnections[#cleanupConnections + 1] = owner.Changed:Connect(function()
			if not owner.Value or owner.Value ~= player then
				performCleanup()
			end
		end)
	end

	cleanupConnections[#cleanupConnections + 1] = player.AncestryChanged:Connect(function()
		if not player.Parent then
			performCleanup()
		end
	end)

	cleanupConnections[#cleanupConnections + 1] = babyModel:GetAttributeChangedSignal("IsBeingStolen"):Connect(function()
		if babyModel:GetAttribute("IsBeingStolen") then
			performCleanup()
		end
	end)

	-- Start collection loop if not already active
	if not babyModel:GetAttribute("CollectionActive") then
		babyModel:SetAttribute("CollectionActive", true)

		task.spawn(function()
			-- Use the preserved original name instead of current model name
			local actualBabyName = babyName or getOriginalBabyName(babyModel)
			local babyData = getBrainrotData(actualBabyName)
			if not babyData then 
				performCleanup()
				return 
			end

			while standCollections[standKey] and 
				standCollections[standKey].baby and 
				standCollections[standKey].baby.Parent and 
				babyModel.Parent and 
				activeCleanupTasks[standKey] do

				task.wait(1)

				local collectionData = standCollections[standKey]
				if not collectionData or not collectionData.baby or not collectionData.baby.Parent then
					break
				end

				if babyModel:GetAttribute("IsBeingStolen") then
					break
				end

				-- Calculate income with multiplier
				local basePerSec = babyData.perSec
				local totalMultiplier = 1

				if _G.GetPlayerCoinsMultiplier then
					totalMultiplier = _G.GetPlayerCoinsMultiplier(player)
				end

				local finalAmount = basePerSec * totalMultiplier

				-- Add to collection
				collectionData.amount = collectionData.amount + finalAmount
				UIManager.updateCollectionUIWithOffline(player, standNumber, collectionData.amount, collectionData.offlineAmount)
			end

			performCleanup()
		end)
	end
end

function CollectionManager.clearStandCollection(player, standNumber)
	local standKey = player.UserId .. "_" .. standNumber

	if standCollections[standKey] then
		standCollections[standKey] = nil
	end

	if activeCleanupTasks[standKey] then
		activeCleanupTasks[standKey] = nil
	end

	pcall(function()
		UIManager.disableCollectionUI(player, standNumber)
	end)
end

function CollectionManager.clearPlayerCollections(player)
	for standKey, _ in pairs(standCollections) do
		if standKey:find(tostring(player.UserId) .. "_") then
			standCollections[standKey] = nil
		end
	end

	for standKey, _ in pairs(activeCleanupTasks) do
		if standKey:find(tostring(player.UserId) .. "_") then
			activeCleanupTasks[standKey] = nil
		end
	end

	for standNumber = 1, 10 do
		pcall(function()
			UIManager.disableCollectionUI(player, standNumber)
		end)
	end
end

function CollectionManager.applyOfflineEarningsToStand(player, standNumber, offlineAmount)
	local standKey = player.UserId .. "_" .. standNumber
	if standCollections[standKey] and standCollections[standKey].baby then
		standCollections[standKey].offlineAmount = (standCollections[standKey].offlineAmount or 0) + offlineAmount
		UIManager.updateCollectionUIWithOffline(player, standNumber, standCollections[standKey].amount, standCollections[standKey].offlineAmount)
		return true
	end
	return false
end

function CollectionManager.getPlayerCollectionState(player)
	local state = {}
	for standKey, collectionData in pairs(standCollections) do
		if standKey:find(tostring(player.UserId) .. "_") then
			local standNumber = tonumber(standKey:split("_")[2])
			if standNumber then
				state[standNumber] = {
					regularAmount = collectionData.amount or 0,
					offlineAmount = collectionData.offlineAmount or 0,
					hasBaby = collectionData.baby ~= nil and collectionData.baby.Parent ~= nil
				}
			end
		end
	end
	return state
end

function CollectionManager.forceRestartCollection(player, standNumber)
	if not player or not standNumber then return false end

	local ownedBase = player:FindFirstChild("OwnedBase")
	if not ownedBase then return false end

	local baseNumber = ownedBase.Value
	local baseName = "Base" .. baseNumber
	local base = CollectionManager.basesFolder:FindFirstChild(baseName)
	if not base then return false end

	local standsFolder = base:FindFirstChild("Stands")
	if not standsFolder then return false end

	local stand = standsFolder:FindFirstChild("Stand" .. standNumber)
	if not stand then return false end

	-- Use the helper function to find baby model regardless of current name
	local babyModel = findBabyModelInStand(stand)
	if not babyModel then return false end

	-- Get the original baby name from preserved data
	local babyName = getOriginalBabyName(babyModel)
	if not babyName then
		-- If we can't get the original name, we can't restart properly
		return false
	end

	CollectionManager.clearStandCollection(player, standNumber)
	babyModel:SetAttribute("CollectionActive", nil)

	task.spawn(function()
		task.wait(0.2)
		CollectionManager.setupStandCollection(player, standNumber, babyName, babyModel)
	end)

	return true
end

-- Export
CollectionManager.standCollections = standCollections

return CollectionManager