-- LOCAL SCRIPT (Put in StarterPlayerScripts)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local GROUP_ID = 991274173
local COOLDOWN_TIME = 15 * 60 -- 15 minutes

-- Find the specific TextLabel
local textLabel = workspace:WaitForChild("Parkour_Chest_Circle"):WaitForChild("Part"):WaitForChild("DescriptionGui"):WaitForChild("JoinTheGroup")

-- Set fixed size and properties
textLabel.Size = UDim2.new(1, 0, 1, 0)
textLabel.TextScaled = true
textLabel.TextWrapped = true
textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
textLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
textLabel.RichText = true

-- Create/Find RemoteEvent
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
remotesFolder.Name = "Remotes"
remotesFolder.Parent = ReplicatedStorage

local chestClaimedEvent = remotesFolder:FindFirstChild("ChestClaimed") or Instance.new("RemoteEvent")
chestClaimedEvent.Name = "ChestClaimed"
chestClaimedEvent.Parent = remotesFolder

-- Persistent claim tracking
local lastClaimTick = 0

-- Group check
local function isInGroup()
	local success, result = pcall(function()
		return player:IsInGroup(GROUP_ID)
	end)
	return success and result
end

local function getTimeLeft()
	if lastClaimTick == 0 then return 0 end
	return math.max(0, COOLDOWN_TIME - (tick() - lastClaimTick))
end

local function canClaim()
	return getTimeLeft() <= 0
end

local function formatTime(seconds)
	local minutes = math.floor(seconds / 60)
	local secs = math.floor(seconds % 60)
	return string.format("%02d:%02d", minutes, secs)
end

local currentText = ""

local function updateText()
	if not textLabel or not textLabel.Parent then return end

	local inGroup = isInGroup()
	local timeLeft = getTimeLeft()
	local canClaimNow = canClaim()
	local newText = ""
	local newColor = Color3.fromRGB(255, 255, 255)

	if not inGroup then
		newText = "LIKE THE GAME AND JOIN THE GROUP!"
		newColor = Color3.fromRGB(255, 0, 0)
	elseif canClaimNow then
		newText = "Claim!"
		newColor = Color3.fromRGB(98, 255, 0)
	else
		newText = "Claim In: " .. formatTime(timeLeft)
		newColor = Color3.fromRGB(98, 255, 0)
	end

	if newText ~= currentText then
		currentText = newText
		textLabel.Text = newText
		textLabel.TextColor3 = newColor
	end
end

-- Listen to server event when player claims
chestClaimedEvent.OnClientEvent:Connect(function()
	lastClaimTick = tick()
end)

-- Restore claim timestamp across respawns (optional)
player.CharacterAdded:Connect(function()
	wait(1)
	updateText()
end)

-- Main update loop
task.spawn(function()
	while true do
		updateText()
		task.wait(1)
	end
end)

-- Initial call
updateText()
