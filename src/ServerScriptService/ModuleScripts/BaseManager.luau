-- BaseManager.lua - COMPLETE COLLISION GROUP FIXES
local BaseManager = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")

-- Dependencies
local GameUtilities = nil
local UIManager = nil
local ErrorHandler = nil
local RebirthData = nil

-- Initialize workspace references
BaseManager.basesFolder = nil
BaseManager.soundRemote = nil

-- Base state storage
local baseLocks = {}
local DEFAULT_LOCK_TIME = 40

-- How long a player must hold E on a collect-zone pad to claim a base
BaseManager.CLAIM_HOLD_DURATION = 1.2

-- Authoritative base ownership state (shared by ALL callers: bootstrap, PlayerManager, claim prompts)
local playerBases = {}
local basePlayers = {}

-- Collision group management
local baseOwnerConnections = {}
local collisionMaintenanceConnections = {}
local registeredCollisionGroups = {} -- Track all registered groups

-- =============================
-- UTILITY FUNCTIONS
-- =============================

local function loadDependency(path, name)
	local attempts = 0
	while attempts < 50 do
		local success, result = pcall(function()
			return require(path)
		end)
		if success then
			return result
		else
			task.wait(0.1)
			attempts = attempts + 1
		end
	end
	warn("Failed to load " .. name .. " after 50 attempts")
	return nil
end

local function ensureCollisionGroup(groupName)
	-- Track registered groups
	registeredCollisionGroups[groupName] = true

	local success = pcall(function()
		PhysicsService:CollisionGroupSetCollidable(groupName, "Default", true)
	end)

	if not success then
		pcall(function()
			PhysicsService:RegisterCollisionGroup(groupName)
			-- Ensure it can collide with Default after registration
			PhysicsService:CollisionGroupSetCollidable(groupName, "Default", true)
		end)
	end
end

-- ENHANCED: Complete collision group reset for a base (PERFORMANCE FIXED)
local function completelyResetBaseCollisionGroups(baseNumber)
	local barrierGroupName = "LazerBarrier_" .. baseNumber

	print("🔄 Resetting collision groups for base", baseNumber)

	-- Step 1: Reset barrier group to collide with EVERYTHING
	ensureCollisionGroup(barrierGroupName)
	pcall(function()
		PhysicsService:CollisionGroupSetCollidable(barrierGroupName, "Default", true)
	end)

	-- Step 2: Reset with all currently online players
	for _, player in pairs(Players:GetPlayers()) do
		local playerGroupName = "BaseOwner_" .. player.UserId .. "_" .. baseNumber
		pcall(function()
			PhysicsService:CollisionGroupSetCollidable(barrierGroupName, playerGroupName, true)
			PhysicsService:CollisionGroupSetCollidable(playerGroupName, barrierGroupName, true)
		end)

		-- Reset their character parts to default
		if player.Character then
			for _, part in pairs(player.Character:GetDescendants()) do
				if part:IsA("BasePart") then
					pcall(function()
						part.CollisionGroup = "Default"
					end)
				end
			end
		end
	end

	-- Step 3: Reset only tracked collision groups for this base
	for groupName, _ in pairs(registeredCollisionGroups) do
		if groupName:find("BaseOwner_") and groupName:find("_" .. baseNumber) then
			pcall(function()
				PhysicsService:CollisionGroupSetCollidable(barrierGroupName, groupName, true)
				PhysicsService:CollisionGroupSetCollidable(groupName, barrierGroupName, true)
			end)
		end
	end

	print("✅ Base", baseNumber, "collision groups reset")
end

-- ENHANCED: More thorough collision group reset
local function resetBaseCollisionGroups(baseNumber)
	-- Use the complete reset for better reliability
	completelyResetBaseCollisionGroups(baseNumber)
end

local function setupPlayerCollisionGroup(player, baseNumber)
	if not player or not player.Character then return end

	local character = player.Character
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

	-- Wait for character to be fully loaded
	if not humanoidRootPart then
		humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
		if not humanoidRootPart then
			warn("Character not fully loaded for collision setup: " .. player.Name)
			return
		end
	end

	local playerGroupName = "BaseOwner_" .. player.UserId .. "_" .. baseNumber
	local barrierGroupName = "LazerBarrier_" .. baseNumber

	print("🔧 Setting up collision for", player.Name, "on base", baseNumber)

	ensureCollisionGroup(playerGroupName)
	ensureCollisionGroup(barrierGroupName)

	-- Set up the non-collision relationship
	pcall(function()
		PhysicsService:CollisionGroupSetCollidable(playerGroupName, barrierGroupName, false)
		PhysicsService:CollisionGroupSetCollidable(barrierGroupName, playerGroupName, false)
		print("✅ Set collision groups to NOT collide with each other")
	end)

	-- Function to set collision group for a part
	local function setPartCollisionGroup(part)
		if part:IsA("BasePart") then
			pcall(function()
				part.CollisionGroup = playerGroupName
			end)
		end
	end

	-- Set collision group for all existing parts
	for _, part in pairs(character:GetDescendants()) do
		setPartCollisionGroup(part)
	end

	-- Connect to handle new parts (like tools, accessories, etc.)
	local connection = character.DescendantAdded:Connect(function(descendant)
		-- Wait a frame to ensure the part is properly parented
		task.wait()
		setPartCollisionGroup(descendant)
	end)

	-- Store connection for cleanup
	if not baseOwnerConnections[player] then
		baseOwnerConnections[player] = {}
	end
	baseOwnerConnections[player][baseNumber] = connection

	print("✅ Collision setup completed for", player.Name)
end

-- Maintain collision groups every second while locked
local function startCollisionMaintenance(player, baseNumber)
	if not player or not baseNumber then return end

	local playerGroupName = "BaseOwner_" .. player.UserId .. "_" .. baseNumber
	local maintenanceKey = player.UserId .. "_" .. baseNumber

	-- Clean up existing maintenance
	if collisionMaintenanceConnections[maintenanceKey] then
		if typeof(collisionMaintenanceConnections[maintenanceKey]) == "thread" then
			task.cancel(collisionMaintenanceConnections[maintenanceKey])
		elseif collisionMaintenanceConnections[maintenanceKey].Disconnect then
			collisionMaintenanceConnections[maintenanceKey]:Disconnect()
		end
	end

	-- Start maintenance loop
	collisionMaintenanceConnections[maintenanceKey] = task.spawn(function()
		while baseLocks[baseNumber] and baseLocks[baseNumber].locked and baseLocks[baseNumber].owner == player do
			task.wait(1)

			-- Reapply collision groups if they've been reset
			if player.Character then
				for _, part in pairs(player.Character:GetDescendants()) do
					if part:IsA("BasePart") then
						if part.CollisionGroup ~= playerGroupName then
							pcall(function()
								part.CollisionGroup = playerGroupName
							end)
						end
					end
				end
			end
		end
	end)
end

-- Stop collision maintenance
local function stopCollisionMaintenance(player, baseNumber)
	if not player or not baseNumber then return end

	local maintenanceKey = player.UserId .. "_" .. baseNumber
	if collisionMaintenanceConnections[maintenanceKey] then
		if typeof(collisionMaintenanceConnections[maintenanceKey]) == "thread" then
			task.cancel(collisionMaintenanceConnections[maintenanceKey])
		elseif collisionMaintenanceConnections[maintenanceKey].Disconnect then
			collisionMaintenanceConnections[maintenanceKey]:Disconnect()
		end
		collisionMaintenanceConnections[maintenanceKey] = nil
	end
end

local function setupCharacterRespawnHandler(player, baseNumber)
	if not player then return end

	-- Clean up existing connections
	if baseOwnerConnections[player] and baseOwnerConnections[player][baseNumber] then
		baseOwnerConnections[player][baseNumber]:Disconnect()
		baseOwnerConnections[player][baseNumber] = nil
	end

	local characterConnection = player.CharacterAdded:Connect(function(character)
		-- Wait for character to be fully loaded
		local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)
		if not humanoidRootPart then
			warn("Character failed to load properly for player: " .. player.Name)
			return
		end

		-- Additional wait to ensure all character parts are loaded
		task.wait(1)

		local lockData = baseLocks[baseNumber]
		if lockData and lockData.owner == player and lockData.locked then
			setupPlayerCollisionGroup(player, baseNumber)
		end
	end)

	if not baseOwnerConnections[player] then
		baseOwnerConnections[player] = {}
	end
	baseOwnerConnections[player]["characterConnection"] = characterConnection
end

local function getPlayerLockDuration(player)
	if not player or not player.Parent then return DEFAULT_LOCK_TIME end

	local baseTime = DEFAULT_LOCK_TIME
	local bonus = 0

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local rebirthValue = leaderstats:FindFirstChild("Rebirth")
		if rebirthValue and RebirthData and RebirthData.GetTotalLockTimeBonus then
			bonus = RebirthData:GetTotalLockTimeBonus(rebirthValue.Value)
		end
	end

	return baseTime + bonus
end

-- =============================
-- CORE BASEMANAGER FUNCTIONS
-- =============================

function BaseManager.setLazerState(baseNumber, locked, owner)
	if not baseNumber or not BaseManager.basesFolder then return end

	local baseName = "Base" .. baseNumber
	local base = BaseManager.basesFolder:FindFirstChild(baseName)
	if not base then return end

	local lazer = base:FindFirstChild("Lazer")
	if not lazer then return end

	local barrierGroupName = "LazerBarrier_" .. baseNumber

	if locked and owner and owner.Parent then
		print("🔒 Locking base", baseNumber, "for", owner.Name)

		ensureCollisionGroup(barrierGroupName)

		-- Setup respawn handler BEFORE setting collision groups
		setupCharacterRespawnHandler(owner, baseNumber)

		if owner.Character then
			setupPlayerCollisionGroup(owner, baseNumber)
		end

		-- Start collision maintenance
		startCollisionMaintenance(owner, baseNumber)

	elseif not locked then
		print("🔓 Unlocking base", baseNumber)

		-- When unlocking, do a targeted reset
		resetBaseCollisionGroups(baseNumber)

		if owner then
			stopCollisionMaintenance(owner, baseNumber)

			if owner.Character then
				for _, part in pairs(owner.Character:GetDescendants()) do
					if part:IsA("BasePart") then
						pcall(function()
							part.CollisionGroup = "Default"
						end)
					end
				end
			end

			if baseOwnerConnections[owner] then
				if baseOwnerConnections[owner][baseNumber] then
					baseOwnerConnections[owner][baseNumber]:Disconnect()
					baseOwnerConnections[owner][baseNumber] = nil
				end
			end
		end
	end

	-- Set lazer properties after collision setup
	for _, part in pairs(lazer:GetDescendants()) do
		if part:IsA("BasePart") then
			if part.Name ~= "Blocker" then
				part.Transparency = locked and 0.45 or 1
				part.CanCollide = locked
			else
				part.CanCollide = locked
			end

			pcall(function()
				part.CollisionGroup = barrierGroupName
			end)

			part.CanQuery = false
		end
	end
end

function BaseManager.setupLockSystem(baseNumber, owner)
	if not baseNumber or not owner or not owner.Parent then return end

	local baseName = "Base" .. baseNumber
	local base = BaseManager.basesFolder and BaseManager.basesFolder:FindFirstChild(baseName)
	if not base then return end

	local lock = base:FindFirstChild("Lock")
	if not lock then return end

	baseLocks[baseNumber] = {locked = false, endTime = 0, owner = owner}

	BaseManager.setLazerState(baseNumber, false, owner)
	if UIManager and UIManager.updateLockUI then
		UIManager.updateLockUI(baseNumber, baseLocks)
	end

	local debounce = false

	lock.Touched:Connect(function(hit)
		if debounce then return end

		local character = hit.Parent
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end

		local player = Players:GetPlayerFromCharacter(character)
		if player ~= owner then return end

		local lockData = baseLocks[baseNumber]
		if not lockData then return end

		debounce = true

		if lockData.locked then
			local timeLeft = math.max(0, lockData.endTime - tick())
			local timeText = GameUtilities and GameUtilities.formatTime and GameUtilities.formatTime(math.ceil(timeLeft)) or (math.ceil(timeLeft) .. "s")
			if ErrorHandler and ErrorHandler.ShowError then
				ErrorHandler.ShowError(player, "BASE_ALREADY_LOCKED", timeText)
			end
			task.wait(1)
			debounce = false
			return
		end

		local lockDuration = getPlayerLockDuration(player)

		lockData.locked = true
		lockData.endTime = tick() + lockDuration

		BaseManager.setLazerState(baseNumber, true, owner)
		if UIManager and UIManager.updateLockUI then
			UIManager.updateLockUI(baseNumber, baseLocks)
		end

		local lockTimeText = GameUtilities and GameUtilities.formatTime and GameUtilities.formatTime(lockDuration) or (lockDuration .. "s")
		if ErrorHandler and ErrorHandler.ShowError then
			ErrorHandler.ShowError(owner, "BASE_LOCKED_SUCCESS", lockTimeText)
		end

		if BaseManager.soundRemote then
			BaseManager.soundRemote:FireClient(owner, "Closing_Lazer")
		end

		task.spawn(function()
			while baseLocks[baseNumber] and baseLocks[baseNumber].locked and tick() < baseLocks[baseNumber].endTime do
				if UIManager and UIManager.updateLockUI then
					UIManager.updateLockUI(baseNumber, baseLocks)
				end
				task.wait(1)
			end

			if baseLocks[baseNumber] then
				baseLocks[baseNumber].locked = false
				BaseManager.setLazerState(baseNumber, false, owner)
				if UIManager and UIManager.updateLockUI then
					UIManager.updateLockUI(baseNumber, baseLocks)
				end
				if BaseManager.soundRemote then
					BaseManager.soundRemote:FireClient(owner, "Opening_Lazer")
				end
				if ErrorHandler and ErrorHandler.ShowError then
					ErrorHandler.ShowError(owner, "BASE_UNLOCKED")
				end
			end
		end)

		task.wait(1)
		debounce = false
	end)
end

function BaseManager.getBaseLockStatus(baseNumber)
	local lockData = baseLocks[baseNumber]
	if lockData and lockData.locked then
		local timeLeft = math.max(0, lockData.endTime - tick())
		return true, timeLeft, lockData.owner
	end
	return false, 0, nil
end

function BaseManager.clearBaseLock(baseNumber)
	if baseLocks[baseNumber] then
		local owner = baseLocks[baseNumber].owner
		if owner then
			stopCollisionMaintenance(owner, baseNumber)
		end
		-- Reset when clearing lock
		resetBaseCollisionGroups(baseNumber)
		baseLocks[baseNumber] = nil
	end
end

function BaseManager.cleanupPlayerConnections(player)
	print("🧹 Cleaning up connections for", player.Name)

	if baseOwnerConnections[player] then
		for _, connection in pairs(baseOwnerConnections[player]) do
			if connection and connection.Disconnect then
				connection:Disconnect()
			end
		end
		baseOwnerConnections[player] = nil
	end

	-- Clean up collision maintenance connections
	for key, connection in pairs(collisionMaintenanceConnections) do
		if string.find(key, tostring(player.UserId)) then
			if typeof(connection) == "thread" then
				task.cancel(connection)
			elseif connection.Disconnect then
				connection:Disconnect()
			end
			collisionMaintenanceConnections[key] = nil
		end
	end

	-- Reset all character parts to default collision group
	if player.Character then
		for _, part in pairs(player.Character:GetDescendants()) do
			if part:IsA("BasePart") then
				pcall(function()
					part.CollisionGroup = "Default"
				end)
			end
		end
	end

	-- CRITICAL: Reset collision relationships for ALL bases this player might have been associated with
	for baseNum = 1, 8 do
		local playerGroupName = "BaseOwner_" .. player.UserId .. "_" .. baseNum
		local barrierGroupName = "LazerBarrier_" .. baseNum

		pcall(function()
			PhysicsService:CollisionGroupSetCollidable(playerGroupName, barrierGroupName, true)
			PhysicsService:CollisionGroupSetCollidable(barrierGroupName, playerGroupName, true)
		end)

		-- If this player owned this base, do a complete reset
		if baseLocks[baseNum] and baseLocks[baseNum].owner == player then
			completelyResetBaseCollisionGroups(baseNum)
		end
	end

	-- Disable collection UIs
	pcall(function()
		for standNumber = 1, 10 do
			if UIManager and UIManager.disableCollectionUI then
				UIManager.disableCollectionUI(player, standNumber)
			end
		end
	end)

	print("✅ Cleanup completed for", player.Name)
end

function BaseManager.restoreClaimPrompt(baseNumber)
	if not baseNumber or not BaseManager.basesFolder then return end

	local baseName = "Base" .. baseNumber
	local base = BaseManager.basesFolder:FindFirstChild(baseName)
	if not base then return end

	-- Reset when restoring claim prompt
	resetBaseCollisionGroups(baseNumber)

	local standsFolder = base:FindFirstChild("Stands")
	if standsFolder then
		for standNum = 1, 10 do
			local stand = standsFolder:FindFirstChild("Stand" .. standNum)
			if stand then
				local collect = stand:FindFirstChild("Collect")
				if collect then
					for _, child in pairs(collect:GetChildren()) do
						if child:IsA("BillboardGui") or child:IsA("SurfaceGui") or child:IsA("ScreenGui") then
							child:Destroy()
						end
					end
				end
			end
		end
	end

	local claimPart = base:FindFirstChild("ClaimPart") or base:FindFirstChild("UnlockBase")
	if claimPart then
		local prompt = claimPart:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.Enabled = true
			prompt.RequiresLineOfSight = false
			prompt.HoldDuration = BaseManager.CLAIM_HOLD_DURATION
			prompt.MaxActivationDistance = 8
			prompt.ActionText = "Claim Base"
		else
			local newPrompt = Instance.new("ProximityPrompt")
			newPrompt.ActionText = "Claim Base"
			newPrompt.HoldDuration = BaseManager.CLAIM_HOLD_DURATION
			newPrompt.MaxActivationDistance = 8
			newPrompt.RequiresLineOfSight = false
			newPrompt.Enabled = true
			newPrompt.Parent = claimPart

			newPrompt.Triggered:Connect(function(player)
				BaseManager.handleBaseClaim(player, baseNumber)
			end)
		end
	end
end

function BaseManager.handleBaseClaim(player, baseNumber)
	if not player or not player.Parent or not baseNumber then return nil end

	local baseName = "Base" .. baseNumber
	local base = BaseManager.basesFolder and BaseManager.basesFolder:FindFirstChild(baseName)
	if not base then return nil end

	-- Each player may claim only ONE base
	local currentBase = player:FindFirstChild("OwnedBase")
	if currentBase and currentBase.Value > 0 then
		if ErrorHandler and ErrorHandler.ShowError then
			ErrorHandler.ShowError(player, "BASE_ALREADY_CLAIMED")
		end
		if BaseManager.soundRemote then
			BaseManager.soundRemote:FireClient(player, "Error")
		end
		return nil
	end

	-- Only a free base can be claimed
	if not BaseManager.isBaseClaimable(baseNumber) then
		if ErrorHandler and ErrorHandler.ShowError then
			ErrorHandler.ShowError(player, "BASE_NOT_AVAILABLE")
		end
		if BaseManager.soundRemote then
			BaseManager.soundRemote:FireClient(player, "Error")
		end
		return nil
	end

	local assigned = BaseManager.assignBaseToPlayer(player, baseNumber)
	if assigned then
		if BaseManager.soundRemote then
			BaseManager.soundRemote:FireClient(player, "Success")
		end
		if ErrorHandler and ErrorHandler.ShowError then
			ErrorHandler.ShowError(player, "BASE_CLAIMED")
		end
		-- Let the other base systems (BaseService sync, brainrot loading, touch detection) react
		local claimEvent = ReplicatedStorage:FindFirstChild("BaseClaimed")
		if claimEvent and claimEvent:IsA("BindableEvent") then
			claimEvent:Fire(player, assigned)
		end
	end
	return assigned
end

function BaseManager.assignBaseToPlayer(player, baseNumber)
	if not player or not player.Parent then return nil end

	if playerBases[player] then
		return playerBases[player]
	end

	-- A specific base was requested (manual claim): it must be free
	if baseNumber then
		if not BaseManager.isBaseClaimable(baseNumber) then
			return nil
		end
	else
		baseNumber = GameUtilities and GameUtilities.findAvailableBase and GameUtilities.findAvailableBase(basePlayers) or nil
		if not baseNumber then
			for i = 1, (GameUtilities and GameUtilities.MAX_PLAYERS or 8) do
				if not basePlayers[i] then
					baseNumber = i
					break
				end
			end
		end
	end

	if baseNumber then
		print("🏠 Assigning base", baseNumber, "to", player.Name)

		playerBases[player] = baseNumber
		basePlayers[baseNumber] = player

		if UIManager and UIManager.setBaseOccupied then
			UIManager.setBaseOccupied(baseNumber, player)
		end

		local oldValue = player:FindFirstChild("OwnedBase")
		if oldValue then oldValue:Destroy() end

		local ownedBaseValue = Instance.new("IntValue")
		ownedBaseValue.Name = "OwnedBase"
		ownedBaseValue.Value = baseNumber
		ownedBaseValue.Parent = player

		local baseName = "Base" .. baseNumber
		local base = BaseManager.basesFolder and BaseManager.basesFolder:FindFirstChild(baseName)
		if base then
			local ownerValue = base:FindFirstChild("Owner")
			if not ownerValue then
				ownerValue = Instance.new("ObjectValue")
				ownerValue.Name = "Owner"
				ownerValue.Parent = base
			end
			ownerValue.Value = player

			-- Ensure collection UIs are properly set up
			local standsFolder = base:FindFirstChild("Stands")
			if standsFolder then
				for standNum = 1, 10 do
					local stand = standsFolder:FindFirstChild("Stand" .. standNum)
					if stand then
						local collect = stand:FindFirstChild("Collect")
						if collect then
							-- Ensure UI structure exists
							if UIManager and UIManager.createCollectionUI then
								UIManager.createCollectionUI(collect)
							end
						end
					end
				end
			end
		end

		-- Reset before setting up lock system
		resetBaseCollisionGroups(baseNumber)

		BaseManager.setupLockSystem(baseNumber, player)

		if base then
			local claimPart = base:FindFirstChild("ClaimPart") or base:FindFirstChild("UnlockBase")
			if claimPart then
				local prompt = claimPart:FindFirstChildOfClass("ProximityPrompt")
				if prompt then
					prompt.Enabled = false
				end
			end
		end

		-- Initialize collection UIs as disabled initially
		local maxStands = GameUtilities and GameUtilities.MAX_STANDS or 10
		for i = 1, maxStands do
			if UIManager and UIManager.disableCollectionUI then
				UIManager.disableCollectionUI(player, i)
			end
		end

		return baseNumber
	else
		return nil
	end
end

function BaseManager.releasePlayerBase(player)
	if not player then return end

	local baseNumber = playerBases[player]
	if baseNumber then
		print("🏠 Releasing base", baseNumber, "from", player.Name)

		pcall(function()
			for standNumber = 1, 10 do
				if UIManager and UIManager.disableCollectionUI then
					UIManager.disableCollectionUI(player, standNumber)
				end
			end
		end)

		playerBases[player] = nil
		basePlayers[baseNumber] = nil

		if UIManager and UIManager.setBaseEmpty then
			UIManager.setBaseEmpty(baseNumber)
		end

		if baseLocks[baseNumber] then
			-- Clean up collision maintenance when releasing base
			stopCollisionMaintenance(player, baseNumber)
			baseLocks[baseNumber] = nil
		end

		-- Reset when releasing base
		resetBaseCollisionGroups(baseNumber)

		BaseManager.cleanupPlayerConnections(player)

		local baseName = "Base" .. baseNumber
		local base = BaseManager.basesFolder and BaseManager.basesFolder:FindFirstChild(baseName)
		if base then
			local ownerValue = base:FindFirstChild("Owner")
			if ownerValue then
				ownerValue.Value = nil
			end

			local standsFolder = base:FindFirstChild("Stands")
			if standsFolder then
				for standNum = 1, 10 do
					local stand = standsFolder:FindFirstChild("Stand" .. standNum)
					if stand then
						local collect = stand:FindFirstChild("Collect")
						if collect then
							for _, child in pairs(collect:GetChildren()) do
								if child:IsA("BillboardGui") or child:IsA("SurfaceGui") or child:IsA("ScreenGui") then
									child:Destroy()
								end
							end
						end
					end
				end
			end
		end

		BaseManager.restoreClaimPrompt(baseNumber)

		local ownedBaseValue = player:FindFirstChild("OwnedBase")
		if ownedBaseValue then
			ownedBaseValue:Destroy()
		end
	end
end

function BaseManager.spawnPlayerAtBase(player)
	if not player or not player.Parent then return end

	local baseNumber = playerBases[player]
	if not baseNumber then return end

	if not player.Character then
		player.CharacterAdded:Wait()
	end

	local character = player.Character
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)

	if humanoidRootPart then
		local spawnPosition = Vector3.new(0, 10, 0)
		if GameUtilities and GameUtilities.getBaseSpawnPosition then
			spawnPosition = GameUtilities.getBaseSpawnPosition(baseNumber)
		end
		humanoidRootPart.CFrame = CFrame.new(spawnPosition)
	end
end

function BaseManager.initializeEmptyBases()
	local maxPlayers = GameUtilities and GameUtilities.MAX_PLAYERS or 8
	for i = 1, maxPlayers do
		if not basePlayers[i] then
			if UIManager and UIManager.setBaseEmpty then
				UIManager.setBaseEmpty(i)
			end
			-- Reset for all empty bases
			resetBaseCollisionGroups(i)
			BaseManager.restoreClaimPrompt(i)
		end
	end
end

function BaseManager.debugBaseStatus()
	local status = {}
	local maxPlayers = GameUtilities and GameUtilities.MAX_PLAYERS or 8
	for i = 1, maxPlayers do
		local baseName = "Base" .. i
		local base = BaseManager.basesFolder and BaseManager.basesFolder:FindFirstChild(baseName)

		status[i] = {
			exists = base ~= nil,
			hasOwner = base and base:FindFirstChild("Owner") and base.Owner.Value ~= nil,
			ownerName = base and base:FindFirstChild("Owner") and base.Owner.Value and base.Owner.Value.Name or nil,
			hasClaimPrompt = base and base:FindFirstChild("ClaimPart") and base.ClaimPart:FindFirstChild("ProximityPrompt") ~= nil,
			isLocked = baseLocks[i] and baseLocks[i].locked or false
		}
	end
	return status
end

-- =============================
-- BASE STATUS HELPERS
-- =============================

-- A base is claimable when no one owns it in the shared state or on the base itself
function BaseManager.isBaseClaimable(baseNumber)
	if not baseNumber or not BaseManager.basesFolder then return false end
	if basePlayers[baseNumber] then return false end
	local baseName = "Base" .. baseNumber
	local base = BaseManager.basesFolder:FindFirstChild(baseName)
	if not base then return false end
	local ownerValue = base:FindFirstChild("Owner")
	if ownerValue and ownerValue.Value then return false end
	return true
end

function BaseManager.getBaseOwner(baseNumber)
	if not baseNumber then return nil end
	local baseName = "Base" .. baseNumber
	local base = BaseManager.basesFolder and BaseManager.basesFolder:FindFirstChild(baseName)
	local ownerValue = base and base:FindFirstChild("Owner")
	return ownerValue and ownerValue.Value or nil
end

function BaseManager.getPlayerBase(player)
	return player and playerBases[player] or nil
end

-- =============================
-- DEBUG AND UTILITY FUNCTIONS
-- =============================

-- Debug function to check collision status
function BaseManager.debugPlayerCollision(player, baseNumber)
	if not player or not player.Character then
		print("Player or character is nil")
		return
	end

	local playerGroupName = "BaseOwner_" .. player.UserId .. "_" .. baseNumber
	local barrierGroupName = "LazerBarrier_" .. baseNumber

	print("=== COLLISION DEBUG ===")
	print("Player:", player.Name)
	print("Base Number:", baseNumber)
	print("Player Group:", playerGroupName)
	print("Barrier Group:", barrierGroupName)

	-- Check if collision groups exist and their settings
	local success1, canCollide1 = pcall(function()
		return PhysicsService:CollisionGroupsAreCollidable(playerGroupName, barrierGroupName)
	end)

	local success2, canCollide2 = pcall(function()
		return PhysicsService:CollisionGroupsAreCollidable(barrierGroupName, playerGroupName)
	end)

	print("Groups can collide (1->2):", success1 and canCollide1 or "ERROR")
	print("Groups can collide (2->1):", success2 and canCollide2 or "ERROR")

	-- Check character parts collision groups
	print("Character parts collision groups:")
	for _, part in pairs(player.Character:GetDescendants()) do
		if part:IsA("BasePart") then
			print("  " .. part.Name .. ": " .. part.CollisionGroup)
		end
	end

	-- Check base lock status
	local lockData = baseLocks[baseNumber]
	print("Lock Data:")
	print("  Exists:", lockData ~= nil)
	if lockData then
		print("  Locked:", lockData.locked)
		print("  Owner:", lockData.owner and lockData.owner.Name or "nil")
		if lockData.locked then
			local timeLeft = math.max(0, lockData.endTime - tick())
			print("  Time Left:", math.ceil(timeLeft) .. "s")
		end
	end
	print("==================")
end

-- ENHANCED: Emergency collision fix function
function BaseManager.forceFixPlayerCollision(player, baseNumber)
	if not player or not player.Character then 
		print("Cannot fix collision - player or character is nil")
		return 
	end

	print("🚑 EMERGENCY COLLISION FIX for", player.Name, "on base", baseNumber)

	-- Use complete reset only in emergency situations
	completelyResetBaseCollisionGroups(baseNumber)

	-- Wait a moment
	task.wait(0.2)

	local lockData = baseLocks[baseNumber]
	if lockData and lockData.owner == player and lockData.locked then
		print("Setting up fresh collision groups...")
		setupPlayerCollisionGroup(player, baseNumber)
		print("Emergency collision fix completed")

		-- Debug the result
		task.wait(0.5)
		BaseManager.debugPlayerCollision(player, baseNumber)
	else
		print("Cannot fix collision - player doesn't own locked base", baseNumber)
		if lockData then
			print("Lock owner:", lockData.owner and lockData.owner.Name or "nil")
			print("Lock status:", lockData.locked)
		else
			print("No lock data found")
		end
	end
end

-- Function to check if a player should be able to pass through a base's lazers
function BaseManager.canPlayerPassThrough(player, baseNumber)
	if not player or not baseNumber then return false end

	local lockData = baseLocks[baseNumber]
	if not lockData then return true end -- No lock = everyone can pass

	if not lockData.locked then return true end -- Unlocked = everyone can pass

	return lockData.owner == player -- Only owner can pass when locked
end

-- =============================
-- DEPENDENCY LOADING
-- =============================

task.spawn(function()
	GameUtilities = loadDependency(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("GameUtilities"), "GameUtilities")
	UIManager = loadDependency(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("UIManager"), "UIManager")
	ErrorHandler = loadDependency(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("ErrorHandler"), "ErrorHandler")

	RebirthData = loadDependency(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("RebirthData"), "RebirthData")
	if not RebirthData then
		RebirthData = {
			GetTotalLockTimeBonus = function(self, level) return 0 end
		}
	end
end)

-- =============================
-- EXPORTS
-- =============================

BaseManager.baseLocks = baseLocks
BaseManager.getPlayerLockDuration = getPlayerLockDuration
BaseManager.playerBases = playerBases
BaseManager.basePlayers = basePlayers

return BaseManager