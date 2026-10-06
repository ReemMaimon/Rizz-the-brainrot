local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RizzConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("RizzConfig"))
local PlayerDataService = require(script.Parent:WaitForChild("ModuleScripts"):WaitForChild("PlayerDataService"))
local ProgressionService = require(script.Parent:WaitForChild("ModuleScripts"):WaitForChild("ProgressionService"))

local config = RizzConfig.Training or {}
local mirrorTemplate = Workspace:WaitForChild(config.TargetName or "Mirror1")
local remotes = ReplicatedStorage:WaitForChild("TrainingRemotes")
local actionRemote = remotes:WaitForChild("TrainingAction")
local stateRemote = remotes:WaitForChild("TrainingState")
local active = {}
local cooldowns = {}
local movementConnections = {}
local mirrors = {}

local function registerMirror(mirror)
	if not mirror:IsA("Model") then return end
	local prompt = mirror:FindFirstChild(config.PromptName or "TrainRizzPrompt", true)
	if not prompt or not prompt:IsA("ProximityPrompt") then
		warn("[MirrorTraining] Missing prompt in " .. mirror:GetFullName())
		return
	end
	if not prompt.Parent:IsA("BasePart") and not prompt.Parent:IsA("Attachment") then
		local host = mirror.PrimaryPart or mirror:FindFirstChildWhichIsA("BasePart", true)
		if not host then
			warn("[MirrorTraining] No BasePart available for prompt in " .. mirror:GetFullName())
			return
		end
		prompt.Parent = host
	end
	prompt.ActionText = "Train"
	prompt.ObjectText = "Mirror Training"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.MaxActivationDistance = math.max(1, config.InteractionRange or 12)
	prompt.RequiresLineOfSight = false
	prompt.Enabled = true
	mirrors[mirror] = prompt
	prompt.Triggered:Connect(function(player)
		local valid, humanoid, root = (function()
			local character = player.Character
			local currentHumanoid = character and character:FindFirstChildOfClass("Humanoid")
			local currentRoot = character and character:FindFirstChild("HumanoidRootPart")
			if not currentHumanoid or not currentRoot or currentHumanoid.Health <= 0 then return false end
			if not PlayerDataService:IsLoaded(player) then return false end
			if player:GetAttribute("InBattle") or player:GetAttribute("InEncounter") or player:GetAttribute("InCombat") then return false end
			return true, currentHumanoid, currentRoot
		end)()
		if not valid then return end
		if (root.Position - mirror:GetPivot().Position).Magnitude > math.max(1, config.InteractionRange or 12) + 5 then return end
		local base = mirror:GetPivot()
		local offset = config.TrainingOffset or Vector3.zero
		local rotation = config.TrainingRotation or Vector3.zero
		local target = base * CFrame.new(0, 0, -(config.TrainingDistance or 3)) * CFrame.new(offset) * CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))
		root.CFrame = CFrame.lookAt(target.Position, mirror:GetPivot().Position)
		active[player] = {Origin = root.Position, Mirror = mirror}
		player:SetAttribute("IsTraining", true)
		stateRemote:FireClient(player, "Started", config.AnimationId or "")
		if movementConnections[player] then movementConnections[player]:Disconnect() end
		movementConnections[player] = humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
			if active[player] and humanoid.MoveDirection.Magnitude > 0.05 then
				if (root.Position - active[player].Origin).Magnitude >= math.max(0.05, config.MovementThreshold or 1.25) then
					active[player] = nil
					movementConnections[player]:Disconnect()
					movementConnections[player] = nil
					player:SetAttribute("IsTraining", false)
					stateRemote:FireClient(player, "Stopped", "Movement")
				end
			end
		end)
	end)
end

local function stopTraining(player, reason)
	if not active[player] then return end
	active[player] = nil
	if movementConnections[player] then
		movementConnections[player]:Disconnect()
		movementConnections[player] = nil
	end
	player:SetAttribute("IsTraining", false)
	stateRemote:FireClient(player, "Stopped", reason or "Stopped")
end

local function getRoot(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return character, humanoid, root
end

local function isValidPlayer(player)
	local _, humanoid, root = getRoot(player)
	if not humanoid or not root or humanoid.Health <= 0 then return false end
	if not PlayerDataService:IsLoaded(player) then return false end
	if player:GetAttribute("InBattle") or player:GetAttribute("InEncounter") or player:GetAttribute("InCombat") then return false end
	return true, humanoid, root
end

local function reward(player)
	local valid, humanoid, root = isValidPlayer(player)
	local session = active[player]
	if not valid or not session then
		if session then stopTraining(player, "InvalidState") end
		return
	end
	if (root.Position - session.Mirror:GetPivot().Position).Magnitude > math.max(1, config.InteractionRange or 12) + 5 then
		stopTraining(player, "TooFar")
		return
	end
	if humanoid.MoveDirection.Magnitude > 0.05 then
		stopTraining(player, "Movement")
		return
	end
	local now = os.clock()
	local cooldown = math.max(0.05, config.Cooldown or 0.35)
	if now - (cooldowns[player] or 0) < cooldown then return end
	local level = ProgressionService:CheckRizzLevel(player)
	local levelData = (RizzConfig.RizzLevels or {})[level]
	local amount = math.max(0, math.floor(levelData and levelData.RizzPerClick or 1))
	if amount <= 0 then return end
	cooldowns[player] = now
	local beforeLevel = ProgressionService:GetRizzLevel(player)
	local success, total, newLevel = ProgressionService:AddRizz(player, amount)
	if success then
		stateRemote:FireClient(player, "Reward", amount, total, newLevel, newLevel > beforeLevel)
	end
end

for _, child in Workspace:GetChildren() do
	if child:IsA("Model") and (child == mirrorTemplate or child.Name:match("^Mirror%d+$")) then registerMirror(child) end
end

local targetCount = math.max(1, config.MirrorCount or 6)
local spacing = config.MirrorSpacing or 30
for index = 2, targetCount do
	local name = "Mirror" .. index
	local existing = Workspace:FindFirstChild(name)
	if existing and existing:IsA("Model") then
		registerMirror(existing)
	elseif not existing then
		local clone = mirrorTemplate:Clone()
		clone.Name = name
		clone:PivotTo(mirrorTemplate:GetPivot() * CFrame.new(spacing * (index - 1), 0, 0))
		clone.Parent = Workspace
		registerMirror(clone)
	end
end

actionRemote.OnServerEvent:Connect(function(player, action)
	if action == "Train" then reward(player)
	elseif action == "Stop" then stopTraining(player, "ClientStopped") end
end)

Players.PlayerRemoving:Connect(function(player)
	stopTraining(player, "Leaving")
	cooldowns[player] = nil
end)

local function bindStateStops(player)
	player:SetAttribute("IsTraining", false)
	player:GetAttributeChangedSignal("InBattle"):Connect(function() if player:GetAttribute("InBattle") then stopTraining(player, "Battle") end end)
	player:GetAttributeChangedSignal("InEncounter"):Connect(function() if player:GetAttribute("InEncounter") then stopTraining(player, "Encounter") end end)
	player.CharacterAdded:Connect(function()
		stopTraining(player, "Respawn")
		player:SetAttribute("IsTraining", false)
	end)
end

Players.PlayerAdded:Connect(bindStateStops)
for _, player in Players:GetPlayers() do bindStateStops(player) end

print("[MirrorTraining] Server initialized with " .. tostring(targetCount) .. " mirrors")