local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local moduleScripts = ReplicatedStorage:WaitForChild("ModuleScripts")
local BattleConfig = require(moduleScripts:WaitForChild("BattleConfig"))
local EncounterConfig = require(moduleScripts:WaitForChild("EncounterConfig"))
local PlayerStatsService = require(script.Parent:WaitForChild("PlayerStatsService"))
local ProgressionService = require(script.Parent:WaitForChild("ProgressionService"))
local BrainrotService = require(script.Parent:WaitForChild("BrainrotService"))
local BrainrotWorldService = require(script.Parent:WaitForChild("BrainrotWorldService"))
local AbilityService = require(script.Parent:WaitForChild("AbilityService"))
local AbilityPowerService = require(script.Parent:WaitForChild("AbilityPowerService"))
local RizzScaling = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("RizzScaling"))
local RizzLevelService = require(script.Parent:WaitForChild("RizzLevelService"))
local AbilityPresentationConfig = require(moduleScripts:WaitForChild("AbilityPresentationConfig"))
local abilityPresentation = ReplicatedStorage:WaitForChild("AbilityPresentation")
local activeBrainrots = Workspace:WaitForChild("ActiveBrainrots")

local BattleService = {}
BattleService.Changed = Instance.new("BindableEvent")
BattleService.Finished = Instance.new("BindableEvent")

local battlesByPlayer = {}
local battlesByBrainrot = {}
local nextBattleId = 0
local beginPlayerTurn
local beginBrainrotTurn

local function rootOf(instance)
	return instance and (instance.PrimaryPart or instance:FindFirstChild("HumanoidRootPart") or instance:FindFirstChildWhichIsA("BasePart"))
end

local function releaseBrainrotFromWorld(model)
	if BrainrotWorldService.ReleaseFromWorld then
		BrainrotWorldService:ReleaseFromWorld(model)
	end
end

local function isActiveBattle(battle)
	return battle
		and battlesByPlayer[battle.Player] == battle
		and battlesByBrainrot[battle.Brainrot] == battle
end

function BattleService:_snapshotData(battle)
	local snapshot = {
		BattleID = battle.BattleID,
		Brainrot = battle.Brainrot,
		BrainrotName = battle.BrainrotName,
		BrainrotRarity = battle.BrainrotRarity,
		BrainrotMutation = battle.BrainrotMutation,
		CurrentTurn = battle.CurrentTurn,
		TurnNumber = battle.TurnNumber,
		PlayerHP = battle.PlayerHP,
		PlayerMaxHP = battle.PlayerMaxHP,
		BrainrotHP = battle.BrainrotHP,
		BrainrotMaxHP = battle.BrainrotMaxHP,
		BattleStatus = battle.BattleStatus,
		TurnEndsAt = battle.TurnEndsAt,
		Rizz = ProgressionService:GetRizz(battle.Player),
		RizzLevel = ProgressionService:GetRizzLevel(battle.Player),
		Mana = PlayerStatsService:GetMana(battle.Player),
		MaxMana = PlayerStatsService:GetMaxMana(battle.Player),
	}
	local abilityState = AbilityService:GetState(battle.Player)
	snapshot.MaxEquippedAbilities = abilityState.MaxEquippedAbilities
	snapshot.EquippedAbilities = abilityState.EquippedAbilities
	snapshot.AbilityCooldowns = abilityState.Cooldowns
	return snapshot
end

function BattleService:GetSnapshot(player)
	local battle = battlesByPlayer[player]
	return battle and self:_snapshotData(battle) or nil
end

function BattleService:GetSnapshotForFinished(battle, status)
	local snapshot = self:_snapshotData(battle)
	snapshot.BattleStatus = status
	snapshot.CurrentTurn = nil
	snapshot.TurnEndsAt = 0
	return snapshot
end

local function emit(battle)
	BattleService.Changed:Fire(battle.Player, BattleService:_snapshotData(battle))
end

local function finish(battle, status)
	if not isActiveBattle(battle) then
		return false
	end
	battle.BattleStatus = status
	battle.CurrentTurn = nil
	battle.TurnEndsAt = 0
	battle.TimerToken += 1
	battlesByPlayer[battle.Player] = nil
	battlesByBrainrot[battle.Brainrot] = nil

	local model = battle.Brainrot
	if model and model.Parent then
		model:SetAttribute("EncounterState", EncounterConfig.Encounter.StateAvailable)
		model:SetAttribute(EncounterConfig.Encounter.PlayerAttribute, nil)
		if status == BattleConfig.Statuses.Victory then
			releaseBrainrotFromWorld(model)
		end
	end

	BattleService.Changed:Fire(battle.Player, BattleService:GetSnapshotForFinished(battle, status))
	BattleService.Finished:Fire(battle.Player, battle, status)
	if status == BattleConfig.Statuses.Defeat then
		task.defer(function()
			if battle.Player.Parent then
				battle.Player:LoadCharacter()
			end
		end)
	end
	return true
end

local function lockPlayerAction(battle)
	battle.BattleStatus = BattleConfig.Statuses.Waiting
	battle.CurrentTurn = nil
	battle.TurnEndsAt = 0
	battle.TimerToken += 1
end

local function queueBrainrotTurn(battle)
	if not isActiveBattle(battle) then
		return
	end
	lockPlayerAction(battle)
	emit(battle)
	local token = battle.TimerToken
	task.delay(math.max(0, tonumber(BattleConfig.PlayerActionRecovery) or 0.35), function()
		if isActiveBattle(battle) and battle.TimerToken == token then
			beginBrainrotTurn(battle)
		end
	end)
end

beginPlayerTurn = function(battle)
	if not isActiveBattle(battle) then
		return
	end
	battle.BattleStatus = BattleConfig.Statuses.PlayerTurn
	battle.CurrentTurn = "Player"
	battle.TurnNumber += 1
	battle.TimerToken += 1
	local token = battle.TimerToken
	local duration = math.max(1, tonumber(BattleConfig.TurnDuration) or 15)
	battle.TurnEndsAt = os.clock() + duration
	emit(battle)
	task.delay(duration, function()
		if isActiveBattle(battle)
			and battle.TimerToken == token
			and battle.BattleStatus == BattleConfig.Statuses.PlayerTurn then
			beginBrainrotTurn(battle)
		end
	end)
end

beginBrainrotTurn = function(battle)
	if not isActiveBattle(battle) then
		return
	end
	battle.BattleStatus = BattleConfig.Statuses.BrainrotTurn
	battle.CurrentTurn = "Brainrot"
	battle.TurnEndsAt = 0
	battle.TimerToken += 1
	local token = battle.TimerToken
	emit(battle)
	task.delay(math.max(0, tonumber(BattleConfig.BrainrotActionDelay) or 0.8), function()
		if not isActiveBattle(battle)
			or battle.TimerToken ~= token
			or battle.BattleStatus ~= BattleConfig.Statuses.BrainrotTurn then
			return
		end
		local damage = math.max(0, tonumber(BrainrotService:GetRandomDamage(battle.BrainrotId, nil, battle.BrainrotMutation)) or tonumber(battle.BrainrotBasicAttackDamage) or 0)
		if damage > 0 then
			PlayerStatsService:DamagePlayer(battle.Player, damage)
		end
		battle.PlayerHP = math.clamp(PlayerStatsService:GetHP(battle.Player), 0, battle.PlayerMaxHP)
		if battle.PlayerHP <= 0 or not PlayerStatsService:IsPlayerAlive(battle.Player) then
			finish(battle, BattleConfig.Statuses.Defeat)
		else
			beginPlayerTurn(battle)
		end
	end)
end

function BattleService:Start(player, model)
	if not player or not player:IsDescendantOf(Players) or battlesByPlayer[player] then
		return false, "You already have an active battle."
	end
	if typeof(model) ~= "Instance" or not model:IsA("Model") then
		return false, "Invalid Brainrot."
	end
	if model.Parent ~= activeBrainrots or not BrainrotWorldService:GetData(model) then
		return false, "This Brainrot is unavailable."
	end
	local owner = model:GetAttribute(EncounterConfig.Encounter.PlayerAttribute)
	if model:GetAttribute("EncounterState") ~= EncounterConfig.Encounter.StateInEncounter or owner ~= player.UserId then
		return false, "Prepare an encounter first."
	end
	if battlesByBrainrot[model] then
		return false, "This Brainrot is already in battle."
	end
	local playerRoot = rootOf(player.Character)
	local brainrotRoot = rootOf(model)
	if not playerRoot or not brainrotRoot
		or (playerRoot.Position - brainrotRoot.Position).Magnitude > math.max(1, tonumber(BattleConfig.BattleDistance) or 35) then
		return false, "Move closer to battle."
	end
	local stats = player:FindFirstChild("PlayerStats")
	if not stats or not stats:FindFirstChild("HP") then
		return false, "Your player stats are still loading. Try again in a moment."
	end
	if not PlayerStatsService:IsPlayerAlive(player) then
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not character or not humanoid or humanoid.Health <= 0 then
			return false, "You cannot battle while defeated. Wait for your character to respawn."
		end
		PlayerStatsService:HealPlayer(player, PlayerStatsService:GetMaxHP(player))
	end

	-- Position the player 10 studs in front of the Brainrot and face the opponent.
	-- Position the player 10 studs in front of the Brainrot and face the opponent.
	local targetPosition = brainrotRoot.Position + brainrotRoot.CFrame.LookVector * 10
	local lookTarget = Vector3.new(brainrotRoot.Position.X, targetPosition.Y, brainrotRoot.Position.Z)
	player.Character:PivotTo(CFrame.lookAt(targetPosition, lookTarget))

	local brainrotId = tostring(model:GetAttribute("BrainrotId") or model:GetAttribute("BrainrotID") or model.Name)
	local definition = BrainrotService:GetDefinition(brainrotId)
	local maxHP = math.max(1, tonumber(model:GetAttribute("BrainrotHP")) or (definition and definition.HP) or 1)
	nextBattleId += 1
	local battle = {
		BattleID = string.format("BAT-%d-%d", player.UserId, nextBattleId),
		Player = player,
		Brainrot = model,
		BrainrotId = brainrotId,
		BrainrotName = tostring(model:GetAttribute("BrainrotName") or model.Name),
		BrainrotRarity = tostring(model:GetAttribute("BrainrotRarity") or "Unknown"),
		BrainrotMutation = tostring(model:GetAttribute("BrainrotMutation") or "Normal"),
		CurrentTurn = nil,
		TurnNumber = 0,
		PlayerHP = math.clamp(PlayerStatsService:GetHP(player), 0, PlayerStatsService:GetMaxHP(player)),
		PlayerMaxHP = PlayerStatsService:GetMaxHP(player),
		BrainrotHP = maxHP,
		BrainrotMaxHP = maxHP,
		BattleStatus = BattleConfig.Statuses.Waiting,
		TurnEndsAt = 0,
		TimerToken = 0,
		BrainrotBasicAttackDamage = tonumber(model:GetAttribute("BrainrotRizzDamage"))
			or (definition and definition.RizzDamage)
			or BattleConfig.BrainrotBasicAttackDamage,
	}
	battlesByPlayer[player] = battle
	battlesByBrainrot[model] = battle
	beginPlayerTurn(battle)
	return true, battle.BattleID
end

function BattleService:ChooseAction(player, action)
	local battle = battlesByPlayer[player]
	if not battle or battle.BattleStatus ~= BattleConfig.Statuses.PlayerTurn then
		return false, "It is not your turn."
	end
	if action ~= BattleConfig.Actions.BasicAttack then
		return false, "Invalid action."
	end
	lockPlayerAction(battle)
	local damage = math.max(0, tonumber(PlayerStatsService:GetRizzDamage(player)) or tonumber(BattleConfig.PlayerBasicAttackDamage) or 0)
	battle.BrainrotHP = math.clamp(battle.BrainrotHP - damage, 0, battle.BrainrotMaxHP)
	if battle.BrainrotHP <= 0 then
		finish(battle, BattleConfig.Statuses.Victory)
	else
		queueBrainrotTurn(battle)
	end
	return true
end

function BattleService:UseAbility(player, abilityId)
	local battle = battlesByPlayer[player]
	if not battle or battle.BattleStatus ~= BattleConfig.Statuses.PlayerTurn then
		return false, "It is not your turn."
	end
	local valid, definition = AbilityService:ValidateUse(player, abilityId)
	if not valid then
		return false, definition
	end
	local abilityType = definition.AbilityType
	if abilityType ~= "Heal" and abilityType ~= "Damage" then
		return false, "Unsupported ability type."
	end
	local scaledStats = AbilityService:GetScaledStats(player, abilityId) or {}
	local manaCost = math.max(0, tonumber(scaledStats.ManaCost) or tonumber(definition.ManaCost) or 0)
	if manaCost > 0 and not PlayerStatsService:RemoveMana(player, manaCost) then
		return false, "You do not have enough Mana."
	end

	local cooldown = math.max(0, tonumber(scaledStats.Cooldown) or tonumber(definition.Cooldown) or 0)
	AbilityService:StartCooldown(player, abilityId, cooldown)
	lockPlayerAction(battle)
	local presentation = AbilityPresentationConfig.Get(abilityId)
	local hitTime = 0
	if type(presentation) == "table" then
		local timing = presentation.Timing or {}
		hitTime = math.max(0, tonumber(timing.Cast) or tonumber(timing.Attack) or tonumber(timing.Hit) or tonumber(timing.Impact) or 0)
	end
	local appliedPower = 0
	if abilityType == "Heal" then
		appliedPower = scaledStats.HealAmount ~= nil
			and math.max(0, tonumber(scaledStats.HealAmount) or 0)
			or AbilityPowerService:GetScaledValue(player, abilityId, definition.HealPowerMultiplier or 1)
	else
		local minDamage = tonumber(scaledStats.MinDamage)
		local maxDamage = tonumber(scaledStats.MaxDamage)
		if minDamage ~= nil or maxDamage ~= nil then
			minDamage = math.max(0, minDamage or maxDamage or 0)
			maxDamage = math.max(minDamage, maxDamage or minDamage)
			appliedPower = math.random(math.floor(minDamage), math.floor(maxDamage))
		else
			appliedPower = tonumber(scaledStats.Damage) or AbilityPowerService:GetAbilityDamage(player, abilityId)
		end
	end
	if type(presentation) == "table" then
		abilityPresentation:FireClient(player, "Cast", abilityId, presentation, battle.Brainrot)
	end

	local battleId = battle.BattleID
	task.delay(hitTime, function()
		if not isActiveBattle(battle) or battle.BattleID ~= battleId then
			return
		end
		if type(presentation) == "table" then
			abilityPresentation:FireClient(player, "Impact", abilityId, presentation, battle.Brainrot)
		end
		if definition.AbilityType == "Heal" then
			PlayerStatsService:HealPlayer(player, appliedPower)
			battle.PlayerHP = math.clamp(PlayerStatsService:GetHP(player), 0, battle.PlayerMaxHP)
		else
			battle.BrainrotHP = math.clamp(battle.BrainrotHP - appliedPower, 0, battle.BrainrotMaxHP)
		end
		if battle.BrainrotHP <= 0 then
			finish(battle, BattleConfig.Statuses.Victory)
		else
			queueBrainrotTurn(battle)
		end
	end)

	return true, {
		AbilityId = abilityId,
		AppliedPower = appliedPower,
		Cooldown = cooldown,
		RizzLevel = RizzLevelService:GetRizzLevel(player),
		Stats = RizzScaling.CalculateAbilityStats(definition.BaseStats or {}, definition.RizzScaling, RizzLevelService:GetRizzLevel(player)),
		BaseAbilityPower = AbilityPowerService:GetBasePower(player),
	}
end

activeBrainrots.ChildRemoved:Connect(function(model)
	local battle = battlesByBrainrot[model]
	if battle then
		finish(battle, BattleConfig.Statuses.Cancelled)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local battle = battlesByPlayer[player]
	if battle then
		finish(battle, BattleConfig.Statuses.Cancelled)
	end
end)

return BattleService