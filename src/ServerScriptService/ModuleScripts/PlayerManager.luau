-- PlayerManager.lua - Place in ServerScriptService > ModuleScripts
-- Handles player joining, leaving, and character management

local PlayerManager = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Dependencies
local GameUtilities = require(game:GetService("ReplicatedStorage"):WaitForChild("ModuleScripts"):WaitForChild("GameUtilities"))
local BaseManager = require(game:GetService("ServerScriptService"):WaitForChild("ModuleScripts"):WaitForChild("BaseManager"))
local BabyManager = require(game:GetService("ServerScriptService"):WaitForChild("ModuleScripts"):WaitForChild("BabyManager"))
local TheftManager = require(game:GetService("ServerScriptService"):WaitForChild("ModuleScripts"):WaitForChild("TheftManager"))
local CollectionManager = require(game:GetService("ServerScriptService"):WaitForChild("ModuleScripts"):WaitForChild("CollectionManager"))

-- State storage
local baseTouchConnections = {}

function PlayerManager.setupBaseTouchDetection(player, baseNumber)
	if baseTouchConnections[player] then
		baseTouchConnections[player]:Disconnect()
		baseTouchConnections[player] = nil
	end

	local baseName = "Base" .. baseNumber
	local base = GameUtilities.basesFolder:FindFirstChild(baseName)
	if not base then return end

	local touchingPart = base:FindFirstChild("TouchingPart")
	if not touchingPart then return end

	baseTouchConnections[player] = touchingPart.Touched:Connect(function(hit)
		local character = hit.Parent
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end

		local touchingPlayer = Players:GetPlayerFromCharacter(character)
		if touchingPlayer ~= player then return end

		local carriedData = TheftManager.carriedBabies[touchingPlayer]
		if carriedData and TheftManager.activeThefts[touchingPlayer] then
			local isLocked, timeLeft, lockOwner = BaseManager.getBaseLockStatus(baseNumber)
			if isLocked and lockOwner ~= touchingPlayer then
				local timeText = GameUtilities.formatTime(math.ceil(timeLeft))
				require(game:GetService("ReplicatedStorage"):WaitForChild("ModuleScripts"):WaitForChild("ErrorHandler")).ShowError(touchingPlayer, "BASE_ALREADY_LOCKED", timeText)
				return
			end

			local babyName = carriedData.babyName
			TheftManager.completeTheft(touchingPlayer, babyName)
		end
	end)
end

function PlayerManager.onPlayerAdded(player)
	local function onCharacterAdded(character)
		task.wait(0.1)

		-- Clear any existing theft/carried data
		TheftManager.clearPlayerTheftData(player)

		-- Owners respawn at their base; baseless players use the default spawn
		if BaseManager.getPlayerBase(player) then
			BaseManager.spawnPlayerAtBase(player)
		end
	end

	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		onCharacterAdded(player.Character)
	end

	-- Load offline data with proper delay
	task.spawn(function()
		task.wait(3)
		if _G.DataManager and _G.DataManager.loadOfflineData then
			_G.DataManager.loadOfflineData(player)
		end
	end)
end

-- A base claimed at a collect-zone pad becomes the player's delivery base
local baseClaimed = ReplicatedStorage:WaitForChild("BaseClaimed")
baseClaimed.Event:Connect(function(player, baseNumber)
	if not player or not player.Parent then return end
	PlayerManager.setupBaseTouchDetection(player, baseNumber)
end)

function PlayerManager.onPlayerRemoving(player)
	-- Clear theft data
	TheftManager.clearPlayerTheftData(player)

	-- Save offline data
	if _G.DataManager and _G.DataManager.saveOfflineData then
		_G.DataManager.saveOfflineData(player)
	end

	-- Clear touch connections
	if baseTouchConnections[player] then
		baseTouchConnections[player]:Disconnect()
		baseTouchConnections[player] = nil
	end

	-- Clear collections
	CollectionManager.clearPlayerCollections(player)

	-- Clear pending babies
	BabyManager.clearPlayerPendingBabies(player)

	-- Release base
	BaseManager.releasePlayerBase(player)
end

function PlayerManager.initializeExistingPlayers()
	for _, player in pairs(Players:GetPlayers()) do
		PlayerManager.onPlayerAdded(player)
	end
end

function PlayerManager.connectPlayerEvents()
	Players.PlayerAdded:Connect(PlayerManager.onPlayerAdded)
	Players.PlayerRemoving:Connect(PlayerManager.onPlayerRemoving)
end

function PlayerManager.initializeEmptyBases()
	BaseManager.initializeEmptyBases()
end

-- Export state for other modules to access (authoritative tables live in BaseManager)
PlayerManager.playerBases = BaseManager.playerBases
PlayerManager.basePlayers = BaseManager.basePlayers
PlayerManager.baseTouchConnections = baseTouchConnections

return PlayerManager