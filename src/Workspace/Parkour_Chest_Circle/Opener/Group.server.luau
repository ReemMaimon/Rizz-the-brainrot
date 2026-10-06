-- SERVER SCRIPT (Put inside the PART you want to touch)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local part = script.Parent -- The part to touch

local GROUP_ID = 991274173
local COINS_REWARD = 100000
local COOLDOWN_TIME = 15 * 60 -- 15 minutes
local TOUCH_COOLDOWN = 2 -- Anti-spam

-- Ensure RemoteEvents exist
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = ReplicatedStorage
end

local chestClaimedEvent = remotesFolder:FindFirstChild("ChestClaimed")
if not chestClaimedEvent then
	chestClaimedEvent = Instance.new("RemoteEvent")
	chestClaimedEvent.Name = "ChestClaimed"
	chestClaimedEvent.Parent = remotesFolder
end


-- Player data
local playerCooldowns = {}
local playerTouchCooldowns = {}

local function isInGroup(player)
	local success, result = pcall(function()
		return player:IsInGroup(GROUP_ID)
	end)
	return success and result
end

local function canClaim(player)
	local lastClaim = playerCooldowns[player.UserId] or 0
	return tick() - lastClaim >= COOLDOWN_TIME
end

local function canTouch(player)
	local now = tick()
	local last = playerTouchCooldowns[player.UserId] or 0
	if now - last >= TOUCH_COOLDOWN then
		playerTouchCooldowns[player.UserId] = now
		return true
	end
	return false
end

-- Handle part touches
local function onTouched(hit)
	local character = hit.Parent
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end

	if not canTouch(player) then return end

	-- Check if in group
	if not isInGroup(player) then return end

	-- Check cooldown
	if not canClaim(player) then return end

	-- Check if player has leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local coins = leaderstats:FindFirstChild("Coins")
	if not coins then return end

	-- Give reward
	coins.Value = coins.Value + COINS_REWARD

	-- Set cooldown
	playerCooldowns[player.UserId] = tick()

	-- Tell client they claimed successfully
	chestClaimedEvent:FireClient(player)
end

part.Touched:Connect(onTouched)

-- Cleanup
Players.PlayerRemoving:Connect(function(player)
	playerCooldowns[player.UserId] = nil
	playerTouchCooldowns[player.UserId] = nil
end)