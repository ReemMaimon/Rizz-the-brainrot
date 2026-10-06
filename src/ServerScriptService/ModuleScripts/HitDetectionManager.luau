-- HitDetectionManager.lua - NEW MODULE FOR HANDLING THIEF HIT DETECTION
local HitDetectionManager = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Dependencies
local TheftManager = nil
local soundRemote = nil

-- Hit tracking
local hitCooldowns = {}
local playerConnections = {}

-- Settings
local HIT_COOLDOWN = 2 -- Seconds between hits
local HIT_DISTANCE = 10 -- Max distance to register hit

-- Initialize the manager
function HitDetectionManager.init(theftManager, sound)
	TheftManager = theftManager
	soundRemote = sound

	-- Set up hit detection for existing players
	for _, player in pairs(Players:GetPlayers()) do
		HitDetectionManager.setupPlayerHitDetection(player)
	end

	-- Set up for new players
	Players.PlayerAdded:Connect(function(player)
		HitDetectionManager.setupPlayerHitDetection(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		HitDetectionManager.clearPlayerData(player)
	end)
end

-- Setup hit detection for a player
function HitDetectionManager.setupPlayerHitDetection(player)
	local function onCharacterAdded(character)
		local humanoid = character:WaitForChild("Humanoid")

		-- Connect to punch/hit events
		local connection = humanoid.StateChanged:Connect(function(oldState, newState)
			if newState == Enum.HumanoidStateType.Physics then
				-- Player was hit/fell - check if they're a thief
				HitDetectionManager.checkThiefHit(player)
			end
		end)

		-- Store connection for cleanup
		if not playerConnections[player] then
			playerConnections[player] = {}
		end
		playerConnections[player].stateConnection = connection

		-- Also detect tool activation (like slap tools)
		character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				child.Activated:Connect(function()
					HitDetectionManager.checkPlayerSlap(player, child)
				end)
			end
		end)
	end

	if player.Character then
		onCharacterAdded(player.Character)
	end

	player.CharacterAdded:Connect(onCharacterAdded)
end

-- Check if a player hit a thief with a tool
function HitDetectionManager.checkPlayerSlap(attacker, tool)
	if not TheftManager or not TheftManager.carriedBabies then return end

	local attackerId = tostring(attacker.UserId)
	local currentTime = tick()

	-- Check cooldown
	if hitCooldowns[attackerId] and (currentTime - hitCooldowns[attackerId]) < HIT_COOLDOWN then
		return
	end

	local attackerChar = attacker.Character
	if not attackerChar or not attackerChar:FindFirstChild("HumanoidRootPart") then return end

	local attackerPos = attackerChar.HumanoidRootPart.Position

	-- Check all players carrying babies
	for thief, carriedData in pairs(TheftManager.carriedBabies) do
		if thief ~= attacker and thief.Character and thief.Character:FindFirstChild("HumanoidRootPart") then
			local thiefPos = thief.Character.HumanoidRootPart.Position
			local distance = (attackerPos - thiefPos).Magnitude

			if distance <= HIT_DISTANCE then
				-- Check if the attacker owns the baby being stolen
				if carriedData.originalOwner == attacker then
					HitDetectionManager.processThiefHit(attacker, thief)
					hitCooldowns[attackerId] = currentTime
					break
				end
			end
		end
	end
end

-- Check if a thief was hit (for physics-based hits)
function HitDetectionManager.checkThiefHit(possibleThief)
	if not TheftManager or not TheftManager.carriedBabies then return end

	local carriedData = TheftManager.carriedBabies[possibleThief]
	if not carriedData then return end

	local originalOwner = carriedData.originalOwner
	if not originalOwner or not originalOwner.Character then return end

	local thiefChar = possibleThief.Character
	local ownerChar = originalOwner.Character

	if not thiefChar or not ownerChar then return end

	local thiefRoot = thiefChar:FindFirstChild("HumanoidRootPart")
	local ownerRoot = ownerChar:FindFirstChild("HumanoidRootPart")

	if not thiefRoot or not ownerRoot then return end

	local distance = (thiefRoot.Position - ownerRoot.Position).Magnitude

	-- If the owner is close enough, they might have hit the thief
	if distance <= HIT_DISTANCE then
		local thiefId = tostring(possibleThief.UserId)
		local currentTime = tick()

		-- Check cooldown
		if hitCooldowns[thiefId] and (currentTime - hitCooldowns[thiefId]) < HIT_COOLDOWN then
			return
		end

		HitDetectionManager.processThiefHit(originalOwner, possibleThief)
		hitCooldowns[thiefId] = currentTime
	end
end

-- Process when a thief gets hit
function HitDetectionManager.processThiefHit(attacker, thief)
	if not TheftManager then return end

	-- Force return the stolen baby
	local success = TheftManager.forceReturnStolenBaby(thief)

	if success then
		-- Play success sound for attacker
		if soundRemote and attacker then
			soundRemote:FireClient(attacker, "Code_Reedemed")
		end

		-- Play hit sound for thief
		if soundRemote and thief then
			soundRemote:FireClient(thief, "Error")
		end

		-- Add visual feedback
		if attacker.Character and attacker.Character:FindFirstChild("HumanoidRootPart") then
			-- Create hit effect
			local effect = Instance.new("Explosion")
			effect.BlastRadius = 0
			effect.BlastPressure = 0
			effect.Position = attacker.Character.HumanoidRootPart.Position
			effect.Parent = workspace
		end
	end
end

-- Clear player data when they leave
function HitDetectionManager.clearPlayerData(player)
	local playerId = tostring(player.UserId)

	-- Clear cooldown
	hitCooldowns[playerId] = nil

	-- Clear connections
	if playerConnections[player] then
		for _, connection in pairs(playerConnections[player]) do
			if connection and connection.Connected then
				connection:Disconnect()
			end
		end
		playerConnections[player] = nil
	end
end

return HitDetectionManager