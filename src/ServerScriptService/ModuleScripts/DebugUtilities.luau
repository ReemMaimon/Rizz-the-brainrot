-- DebugUtilities.lua - FIXED GLOBAL REFERENCES AND ERROR HANDLING
local DebugUtilities = {}

-- Services
local Players = game:GetService("Players")

-- Module references (injected during init to avoid circular dependencies)
local BabyManager = nil
local CollectionManager = nil
local TheftManager = nil
local PlayerManager = nil
local ErrorHandler = nil

function DebugUtilities.init(modules)
	BabyManager = modules.BabyManager
	CollectionManager = modules.CollectionManager
	TheftManager = modules.TheftManager
	PlayerManager = modules.PlayerManager

	-- Load ErrorHandler safely
	local success, handler = pcall(function()
		return require(game:GetService("ReplicatedStorage"):WaitForChild("ModuleScripts"):WaitForChild("ErrorHandler"))
	end)
	if success then
		ErrorHandler = handler
	end
end

-- ===========================
-- PLAYER DIAGNOSTICS
-- ===========================

function DebugUtilities.getPlayerStatus(playerName)
	local player = Players:FindFirstChild(playerName)
	if not player then
		return nil, "Player not found"
	end

	local status = {
		name = player.Name,
		userId = player.UserId,
		baseNumber = nil,
		babies = {},
		pendingBabies = 0,
		isCarrying = false,
		activeTheft = false,
		collections = {}
	}

	-- Get base number
	if PlayerManager and PlayerManager.playerBases then
		status.baseNumber = PlayerManager.playerBases[player]
	end

	-- Get pending babies
	if BabyManager and BabyManager.pendingBabies then
		status.pendingBabies = BabyManager.pendingBabies[player.UserId] or 0
	end

	-- Get theft status
	if TheftManager then
		status.isCarrying = TheftManager.carriedBabies and TheftManager.carriedBabies[player] ~= nil or false
		status.activeTheft = TheftManager.activeThefts and TheftManager.activeThefts[player] ~= nil or false
	end

	-- Get babies data
	local babiesFolder = player:FindFirstChild("Babies")
	if babiesFolder then
		for _, folder in pairs(babiesFolder:GetChildren()) do
			if folder:IsA("Folder") then
				local standNumber = folder:FindFirstChild("StandNumber")
				local babyName = folder:FindFirstChild("BabyName")
				if standNumber and babyName then
					table.insert(status.babies, {
						name = babyName.Value,
						stand = standNumber.Value,
						folder = folder.Name
					})
				end
			end
		end
	end

	-- Get collection data
	if CollectionManager and CollectionManager.standCollections then
		for standKey, collectionData in pairs(CollectionManager.standCollections) do
			if standKey:find(tostring(player.UserId) .. "_") then
				local standNumber = tonumber(standKey:split("_")[2])
				if standNumber then
					status.collections[standNumber] = {
						regularAmount = collectionData.amount or 0,
						offlineAmount = collectionData.offlineAmount or 0,
						hasBaby = collectionData.baby ~= nil and collectionData.baby.Parent ~= nil,
						babyName = collectionData.baby and collectionData.baby.Name or "None"
					}
				end
			end
		end
	end

	return status
end

function DebugUtilities.printPlayerStatus(playerName)
	local status, error = DebugUtilities.getPlayerStatus(playerName)
	if not status then
		print("❌ " .. error)
		return
	end

	print("=== PLAYER STATUS: " .. status.name .. " ===")
	print("User ID:", status.userId)
	print("Base Number:", status.baseNumber or "None")
	print("Pending Babies:", status.pendingBabies)
	print("Is Carrying Baby:", status.isCarrying)
	print("Active Theft:", status.activeTheft)

	print("\n--- OWNED BABIES ---")
	if #status.babies == 0 then
		print("No babies owned")
	else
		for i, baby in ipairs(status.babies) do
			print(i .. ". " .. baby.name .. " on Stand " .. baby.stand)
		end
	end

	print("\n--- COLLECTIONS ---")
	local hasCollections = false
	for standNumber, collection in pairs(status.collections) do
		hasCollections = true
		print("Stand " .. standNumber .. ":")
		print("  Baby: " .. collection.babyName)
		print("  Regular: " .. collection.regularAmount)
		print("  Offline: " .. collection.offlineAmount)
		print("  Has Baby: " .. tostring(collection.hasBaby))
	end
	if not hasCollections then
		print("No active collections")
	end

	return status
end

-- ===========================
-- SYSTEM DIAGNOSTICS
-- ===========================

function DebugUtilities.getSystemStatus()
	local status = {
		totalPlayers = #Players:GetPlayers(),
		activeBases = 0,
		movingBabies = 0,
		totalPendingBabies = 0,
		activeThefts = 0,
		activeCollections = 0,
		bases = {},
		players = {}
	}

	-- Count players and bases
	if PlayerManager and PlayerManager.playerBases then
		for player, baseNumber in pairs(PlayerManager.playerBases) do
			if player and player.Parent then
				status.activeBases = status.activeBases + 1

				local pendingBabies = 0
				if BabyManager and BabyManager.pendingBabies then
					pendingBabies = BabyManager.pendingBabies[player.UserId] or 0
				end

				local isCarrying = false
				local activeTheft = false
				if TheftManager then
					isCarrying = TheftManager.carriedBabies and TheftManager.carriedBabies[player] ~= nil or false
					activeTheft = TheftManager.activeThefts and TheftManager.activeThefts[player] ~= nil or false
				end

				local playerData = {
					name = player.Name,
					baseNumber = baseNumber,
					pendingBabies = pendingBabies,
					isCarrying = isCarrying,
					activeTheft = activeTheft
				}

				status.totalPendingBabies = status.totalPendingBabies + pendingBabies
				if activeTheft then
					status.activeThefts = status.activeThefts + 1
				end

				table.insert(status.players, playerData)
				status.bases[baseNumber] = player.Name
			end
		end
	end

	-- Count moving babies
	if BabyManager and BabyManager.movingBabiesList then
		status.movingBabies = #BabyManager.movingBabiesList
	end

	-- Count collections
	if CollectionManager and CollectionManager.standCollections then
		for standKey, _ in pairs(CollectionManager.standCollections) do
			status.activeCollections = status.activeCollections + 1
		end
	end

	return status
end

function DebugUtilities.printSystemStatus()
	local status = DebugUtilities.getSystemStatus()

	print("=== SYSTEM STATUS ===")
	print("Total Players:", status.totalPlayers)
	print("Active Bases:", status.activeBases)
	print("Moving Babies:", status.movingBabies)
	print("Total Pending Babies:", status.totalPendingBabies)
	print("Active Thefts:", status.activeThefts)
	print("Active Collections:", status.activeCollections)

	print("\n--- BASE ASSIGNMENTS ---")
	for baseNumber = 1, 8 do
		local playerName = status.bases[baseNumber]
		if playerName then
			print("Base " .. baseNumber .. ": " .. playerName)
		else
			print("Base " .. baseNumber .. ": Empty")
		end
	end

	return status
end

-- ===========================
-- EMERGENCY FIXES
-- ===========================

function DebugUtilities.emergencyPlayerReset(playerName)
	local player = Players:FindFirstChild(playerName)
	if not player then
		return false, "Player not found"
	end

	print("🚨 EMERGENCY RESET for " .. player.Name)

	-- 1. Clear pending babies
	local clearedPending = 0
	if BabyManager and BabyManager.forceClearPendingBabies then
		clearedPending = BabyManager.forceClearPendingBabies(player)
	elseif BabyManager and BabyManager.pendingBabies then
		clearedPending = BabyManager.pendingBabies[player.UserId] or 0
		BabyManager.pendingBabies[player.UserId] = nil
	end
	print("Cleared " .. clearedPending .. " pending babies")

	-- 2. Clear theft data
	if TheftManager and TheftManager.clearPlayerTheftData then
		TheftManager.clearPlayerTheftData(player)
		print("Cleared theft data")
	end

	-- 3. Clear collections
	if CollectionManager and CollectionManager.clearPlayerCollections then
		CollectionManager.clearPlayerCollections(player)
		print("Cleared collections")
	end

	-- 4. Fix all baby positions
	local babiesFolder = player:FindFirstChild("Babies")
	local fixedBabies = 0
	if babiesFolder then
		for _, babyFolder in pairs(babiesFolder:GetChildren()) do
			if babyFolder:IsA("Folder") then
				local standValue = babyFolder:FindFirstChild("StandNumber")
				if standValue then
					local standNumber = standValue.Value
					if _G.FixBabyPosition and _G.FixBabyPosition(player, standNumber) then
						fixedBabies = fixedBabies + 1
					end
					task.wait(0.1)
				end
			end
		end
	end
	print("Fixed " .. fixedBabies .. " baby positions")

	-- 5. Restart all collections
	task.wait(0.5)
	if babiesFolder and CollectionManager and CollectionManager.forceRestartCollection then
		for _, babyFolder in pairs(babiesFolder:GetChildren()) do
			if babyFolder:IsA("Folder") then
				local standValue = babyFolder:FindFirstChild("StandNumber")
				if standValue then
					local standNumber = standValue.Value
					CollectionManager.forceRestartCollection(player, standNumber)
					task.wait(0.1)
				end
			end
		end
	end
	print("Restarted collections")

	if ErrorHandler and ErrorHandler.ShowError then
		ErrorHandler.ShowError(player, "Emergency reset completed!")
	end
	print("✅ Emergency reset completed for " .. player.Name)

	return true, "Reset completed"
end

function DebugUtilities.emergencySystemReset()
	print("🚨 EMERGENCY SYSTEM RESET")

	local resetCount = 0
	for _, player in pairs(Players:GetPlayers()) do
		if player and player.Parent then
			local success, message = DebugUtilities.emergencyPlayerReset(player.Name)
			if success then
				resetCount = resetCount + 1
			end
			task.wait(0.5)
		end
	end

	print("✅ Emergency system reset completed - " .. resetCount .. " players reset")
	return resetCount
end

-- ===========================
-- MONITORING TOOLS
-- ===========================

function DebugUtilities.startMonitoring(intervalSeconds)
	intervalSeconds = intervalSeconds or 30

	print("🔍 Starting system monitoring (every " .. intervalSeconds .. " seconds)")

	task.spawn(function()
		while true do
			task.wait(intervalSeconds)

			local status = DebugUtilities.getSystemStatus()
			local timestamp = os.date("%H:%M:%S")

			print("[" .. timestamp .. "] Players: " .. status.totalPlayers .. 
				", Moving: " .. status.movingBabies .. 
				", Pending: " .. status.totalPendingBabies .. 
				", Thefts: " .. status.activeThefts)

			-- Alert on concerning conditions
			if status.totalPendingBabies > 20 then
				print("⚠️  HIGH PENDING BABIES: " .. status.totalPendingBabies)
			end

			if status.activeThefts > 5 then
				print("⚠️  HIGH THEFT ACTIVITY: " .. status.activeThefts)
			end
		end
	end)
end

-- ===========================
-- COLLECTION DIAGNOSTICS
-- ===========================

function DebugUtilities.testCollectionSystem(playerName, standNumber)
	if not playerName or not standNumber then
		return "Invalid parameters"
	end

	local player = Players:FindFirstChild(playerName)
	if not player then
		return "Player not found"
	end

	local results = {}

	-- Test 1: Check if player has baby at stand
	local babiesFolder = player:FindFirstChild("Babies")
	if babiesFolder then
		local babyFolder = babiesFolder:FindFirstChild("Baby_Stand" .. standNumber)
		results.hasBabyFolder = babyFolder ~= nil
		if babyFolder then
			local babyNameValue = babyFolder:FindFirstChild("BabyName")
			results.babyName = babyNameValue and babyNameValue.Value or "Unknown"
		end
	else
		results.hasBabyFolder = false
	end

	-- Test 2: Check collection status
	if CollectionManager and CollectionManager.debugCollectionStatus then
		local collectionStatus = CollectionManager.debugCollectionStatus(player, standNumber)
		results.collectionStatus = collectionStatus
	end

	-- Test 3: Check if collection UI is visible
	local ownedBase = player:FindFirstChild("OwnedBase")
	if ownedBase then
		local baseNumber = ownedBase.Value
		local baseName = "Base" .. baseNumber
		local basesFolder = game.Workspace:FindFirstChild("Bases")
		if basesFolder then
			local base = basesFolder:FindFirstChild(baseName)
			if base then
				local stand = base:FindFirstChild("Stands") and base.Stands:FindFirstChild("Stand" .. standNumber)
				if stand then
					local collect = stand:FindFirstChild("Collect")
					if collect then
						local text = collect:FindFirstChild("Text")
						results.hasCollectUI = text ~= nil
						if text then
							local billboardGui = text:FindFirstChild("BillboardGui")
							results.uiEnabled = billboardGui and billboardGui.Enabled or false
						end
					end
				end
			end
		end
	end

	-- Test 4: Try to restart collection
	if CollectionManager and CollectionManager.forceRestartCollection then
		local restartSuccess = CollectionManager.forceRestartCollection(player, standNumber)
		results.restartAttempt = restartSuccess
	end

	return results
end

-- ===========================
-- GLOBAL COMMANDS
-- ===========================

function DebugUtilities.setupGlobalCommands()
	-- Player diagnostics
	_G.PlayerStatus = DebugUtilities.printPlayerStatus
	_G.SystemStatus = DebugUtilities.printSystemStatus

	-- Emergency fixes
	_G.EmergencyPlayerReset = DebugUtilities.emergencyPlayerReset
	_G.EmergencySystemReset = DebugUtilities.emergencySystemReset

	-- Collection testing
	_G.TestCollection = DebugUtilities.testCollectionSystem

	-- Monitoring
	_G.StartMonitoring = DebugUtilities.startMonitoring

	-- Safe debugging functions
	_G.DebugBaby = function(player, standNumber)
		if CollectionManager and CollectionManager.debugCollectionStatus then
			return CollectionManager.debugCollectionStatus(player, standNumber)
		end
		return "CollectionManager not available"
	end

	_G.DebugPlayerBabies = function(player)
		if BabyManager and BabyManager.debugPlayerBabyCount then
			return BabyManager.debugPlayerBabyCount(player)
		end
		return "BabyManager not available"
	end

	_G.DebugTheft = function(player)
		if TheftManager and TheftManager.getTheftStatus then
			return TheftManager.getTheftStatus(player)
		end
		return "TheftManager not available"
	end

	print("🔧 Debug commands available:")
	print("  _G.PlayerStatus(playerName)")
	print("  _G.SystemStatus()")
	print("  _G.EmergencyPlayerReset(playerName)")
	print("  _G.EmergencySystemReset()")
	print("  _G.TestCollection(playerName, standNumber)")
	print("  _G.StartMonitoring(intervalSeconds)")
end

return DebugUtilities
