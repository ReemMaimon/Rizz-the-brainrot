local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local EncounterConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("EncounterConfig"))
local BrainrotWorldService = require(script.Parent:WaitForChild("ModuleScripts"):WaitForChild("BrainrotWorldService"))
local BattleService = require(script.Parent:WaitForChild("ModuleScripts"):WaitForChild("BattleService"))

local startEncounter = ReplicatedStorage:WaitForChild("StartEncounter")
local encounterFeedback = ReplicatedStorage:WaitForChild("EncounterFeedback")
local activeFolder = Workspace:WaitForChild("ActiveBrainrots")

local encountersByBrainrot = {}
local encountersByPlayer = {}
local lastRequestAt = {}
local nextEncounterId = 0

local function getRoot(model)
	return model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
end

local function isActiveBrainrot(model)
	return typeof(model) == "Instance" and model:IsA("Model") and model.Parent == activeFolder and BrainrotWorldService:GetData(model) ~= nil
end

local function setState(model, state)
	model:SetAttribute("EncounterState", state)
end

local function send(player, success, message, encounter)
	encounterFeedback:FireClient(player, {
		Success = success,
		Message = message,
		Encounter = encounter,
	})
end

local function release(model)
	local encounter = encountersByBrainrot[model]
	if not encounter then
		return
	end
	encountersByBrainrot[model] = nil
	if encountersByPlayer[encounter.Player] == encounter then
		encountersByPlayer[encounter.Player] = nil
	end
	if model and model.Parent then
		setState(model, EncounterConfig.Encounter.StateDespawned)
		model:SetAttribute(EncounterConfig.Encounter.PlayerAttribute, nil)
	end
end

local start

local function bindPrompt(model)
	local root = getRoot(model)
	local prompt = root and root:FindFirstChild(EncounterConfig.PromptName)
	if prompt and prompt:IsA("ProximityPrompt") and not prompt:GetAttribute("EncounterBound") then
		prompt:SetAttribute("EncounterBound", true)
		prompt.Triggered:Connect(function(player)
			start(player, model)
		end)
	end
end

start = function(player, model)
	if not player or not player:IsDescendantOf(Players) then
		return
	end
	local now = os.clock()
	local cooldown = math.max(0, tonumber(EncounterConfig.Encounter.StartCooldown) or 0)
	if now - (lastRequestAt[player] or 0) < cooldown then
		return
	end
	lastRequestAt[player] = now

	if not isActiveBrainrot(model) then
		send(player, false, "This Brainrot is no longer available.")
		return
	end
	if encountersByPlayer[player] then
		send(player, false, "You already have an active encounter.")
		return
	end
	if encountersByBrainrot[model] or model:GetAttribute("EncounterState") ~= EncounterConfig.Encounter.StateAvailable then
		send(player, false, EncounterConfig.UI.UnavailableText)
		return
	end
	local character = player.Character
	local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
	local brainrotRoot = getRoot(model)
	local maxDistance = math.max(0, tonumber(EncounterConfig.InteractionDistance) or 12)
	if not playerRoot or not brainrotRoot or (playerRoot.Position - brainrotRoot.Position).Magnitude > maxDistance then
		send(player, false, "Move closer to interact.")
		return
	end
	if model:GetAttribute("EncounterState") == EncounterConfig.Encounter.StateDespawned then
		send(player, false, "This Brainrot has despawned.")
		return
	end

	nextEncounterId += 1
	local encounter = {
		Player = player,
		Brainrot = model,
		BrainrotName = tostring(model:GetAttribute("BrainrotName") or model.Name),
		BrainrotRarity = tostring(model:GetAttribute("BrainrotRarity") or "Unknown"),
		EncounterID = string.format("ENC-%d-%d", player.UserId, nextEncounterId),
		StartTime = os.time(),
	}
	encountersByBrainrot[model] = encounter
	encountersByPlayer[player] = encounter
	setState(model, EncounterConfig.Encounter.StateInEncounter)
	model:SetAttribute(EncounterConfig.Encounter.PlayerAttribute, player.UserId)

	local success, message = BattleService:Start(player, model)
	if not success then
		release(model)
		send(player, false, tostring(message or "Unable to start battle."))
		return
	end

	send(player, true, EncounterConfig.UI.PreparedText, encounter)
end

startEncounter.OnServerEvent:Connect(function(player, model)
	start(player, model)
end)

activeFolder.ChildRemoved:Connect(function(model)
	release(model)
	BrainrotWorldService:CleanupRemoved(model)
end)

BrainrotWorldService.OnBrainrotSpawned.Event:Connect(function(model)
	if model and model.Parent then
		setState(model, EncounterConfig.Encounter.StateAvailable)
		bindPrompt(model)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local encounter = encountersByPlayer[player]
	if encounter then
		release(encounter.Brainrot)
	end
	lastRequestAt[player] = nil
end)

for _, model in activeFolder:GetChildren() do
	if model:IsA("Model") and BrainrotWorldService:GetData(model) then
		setState(model, model:GetAttribute("EncounterState") or EncounterConfig.Encounter.StateAvailable)
		bindPrompt(model)
	end
end

print("[BrainrotEncounterService] Encounter validation ready")