local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local moduleScripts = ReplicatedStorage:WaitForChild("ModuleScripts")
local AbilityConfig = require(moduleScripts:WaitForChild("AbilityConfig"))
local RizzScaling = require(moduleScripts:WaitForChild("RizzScaling"))
local RizzLevelService = require(script.Parent:WaitForChild("RizzLevelService"))
local ProgressionService = require(script.Parent:WaitForChild("ProgressionService"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))

local AbilityService = {}
local states = {}

local function stateFor(player)
	states[player] = states[player] or {Cooldowns = {}, Effects = {}, ActiveAbilities = {}}
	return states[player]
end

local function maxSlots()
	return math.max(1, math.floor(tonumber(AbilityConfig.MaxEquippedAbilities) or 4))
end

local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, item in pairs(value) do result[key] = copy(item) end
	return result
end

local function dataFor(player)
	local data = PlayerDataService:EnsureAbilityData(player, maxSlots())
	if data and AbilityConfig.GiveTestAbilities then
		print("[AbilityService] Applying test abilities for " .. player.Name)
		local equippedCount = 0
		for slot = 1, maxSlots() do
			if data.EquippedAbilities[slot] then equippedCount += 1 end
		end
		for _, abilityId in ipairs(AbilityConfig.TestAbilities or {}) do
			if AbilityConfig.Abilities[abilityId] then
				data.OwnedAbilities[abilityId] = data.OwnedAbilities[abilityId] or {}
				local alreadyEquipped = false
				for slot = 1, maxSlots() do
					if data.EquippedAbilities[slot] == abilityId then alreadyEquipped = true break end
				end
				if not alreadyEquipped and equippedCount < maxSlots() then
					for slot = 1, maxSlots() do
						if not data.EquippedAbilities[slot] then
							data.EquippedAbilities[slot] = abilityId
							equippedCount += 1
							break
						end
					end
				end
			end
		end
	end
	return data
end

local function isEquipped(data, abilityId)
	for slot = 1, maxSlots() do
		if data.EquippedAbilities[slot] == abilityId then return slot end
	end
	return nil
end

function AbilityService:GetDefinition(abilityId)
	if typeof(abilityId) ~= "string" then return nil end
	return AbilityConfig.Abilities[abilityId]
end

function AbilityService:GetScaledStats(player, abilityId)
	local definition = self:GetDefinition(abilityId)
	if not definition then return nil end
	local baseStats = definition.BaseStats or {}
	return RizzScaling.CalculateAbilityStats(baseStats, definition.RizzScaling, RizzLevelService:GetRizzLevel(player))
end

function AbilityService:GetScaledStat(player, abilityId, statName, fallback)
	local definition = self:GetDefinition(abilityId)
	if not definition then return fallback end
	return RizzScaling.GetAbilityStat(definition.BaseStats or {}, definition.RizzScaling, statName, RizzLevelService:GetRizzLevel(player), fallback)
end

function AbilityService:GetState(player)
	local data = dataFor(player)
	if not data then
		return {MaxEquippedAbilities = maxSlots(), EquippedAbilities = {}, Cooldowns = {}}
	end
	local equipped = {}
	local cooldowns = {}
	local state = stateFor(player)
	for slot = 1, maxSlots() do equipped[slot] = data.EquippedAbilities[slot] end
	for abilityId, expiresAt in pairs(state.Cooldowns) do
		cooldowns[abilityId] = math.max(0, expiresAt - os.clock())
	end
	return {MaxEquippedAbilities = maxSlots(), EquippedAbilities = equipped, Cooldowns = cooldowns}
end

function AbilityService:GetOwnedAbilities(player)
	local data = dataFor(player)
	if data and AbilityConfig.GiveTestAbilities then
		for _, abilityId in ipairs(AbilityConfig.TestAbilities or {}) do
			if AbilityConfig.Abilities[abilityId] then data.OwnedAbilities[abilityId] = data.OwnedAbilities[abilityId] or {} end
		end
	end
	local owned = {}
	if not data then return owned end
	for abilityId, metadata in pairs(data.OwnedAbilities) do
		if self:GetDefinition(abilityId) then owned[abilityId] = copy(metadata) end
	end
	return owned
end

function AbilityService:HasAbility(player, abilityId)
	local data = dataFor(player)
	return data ~= nil and self:GetDefinition(abilityId) ~= nil and data.OwnedAbilities[abilityId] ~= nil
end

function AbilityService:GiveAbility(player, abilityId, metadata)
	if not self:GetDefinition(abilityId) then return false, "Unknown ability." end
	local data = dataFor(player)
	if not data then return false, "Player data is not loaded." end
	if data.OwnedAbilities[abilityId] == nil then
		data.OwnedAbilities[abilityId] = typeof(metadata) == "table" and copy(metadata) or {}
	end
	return true, self:GetOwnedAbilities(player)
end

function AbilityService:RemoveAbility(player, abilityId)
	local data = dataFor(player)
	if not data or not self:GetDefinition(abilityId) then return false, "Unknown ability." end
	if data.OwnedAbilities[abilityId] == nil then return false, "You do not own that ability." end
	data.OwnedAbilities[abilityId] = nil
	for slot = 1, maxSlots() do
		if data.EquippedAbilities[slot] == abilityId then data.EquippedAbilities[slot] = nil end
	end
	return true, self:GetOwnedAbilities(player)
end

function AbilityService:Own(player, abilityId, metadata)
	return self:GiveAbility(player, abilityId, metadata)
end

function AbilityService:Equip(player, abilityId, slot)
	local definition = self:GetDefinition(abilityId)
	local data = dataFor(player)
	if not data or not definition or not data.OwnedAbilities[abilityId] then return false, "You do not own that ability." end
	if ProgressionService:GetRizzLevel(player) < math.max(1, math.floor(definition.RequiredLevel or 1)) then return false, "Your Rizz level is too low." end
	slot = math.floor(tonumber(slot) or 0)
	if slot < 1 or slot > maxSlots() then return false, "Invalid ability slot." end
	local previousSlot = isEquipped(data, abilityId)
	if previousSlot and previousSlot ~= slot then data.EquippedAbilities[previousSlot] = nil end
	data.EquippedAbilities[slot] = abilityId
	return true, self:GetState(player)
end

function AbilityService:Unequip(player, slot)
	local data = dataFor(player)
	slot = math.floor(tonumber(slot) or 0)
	if not data or slot < 1 or slot > maxSlots() then return false, "Invalid ability slot." end
	data.EquippedAbilities[slot] = nil
	return true, self:GetState(player)
end

function AbilityService:Replace(player, slot, abilityId)
	if abilityId == nil or abilityId == "" then return self:Unequip(player, slot) end
	return self:Equip(player, abilityId, slot)
end

function AbilityService:Reorder(player, fromSlot, toSlot)
	local data = dataFor(player)
	fromSlot, toSlot = math.floor(tonumber(fromSlot) or 0), math.floor(tonumber(toSlot) or 0)
	if not data or fromSlot < 1 or fromSlot > maxSlots() or toSlot < 1 or toSlot > maxSlots() then return false, "Invalid ability slot." end
	data.EquippedAbilities[fromSlot], data.EquippedAbilities[toSlot] = data.EquippedAbilities[toSlot], data.EquippedAbilities[fromSlot]
	return true, self:GetState(player)
end

function AbilityService:IsEquipped(player, abilityId)
	local data = dataFor(player)
	return data ~= nil and isEquipped(data, abilityId) ~= nil
end

function AbilityService:ValidateUse(player, abilityId)
	local definition = self:GetDefinition(abilityId)
	local data = dataFor(player)
	if not definition then return false, "Ability does not exist." end
	if not data or not data.OwnedAbilities[abilityId] then return false, "You do not own that ability." end
	if not isEquipped(data, abilityId) then return false, "Ability is not equipped." end
	if ProgressionService:GetRizzLevel(player) < math.max(1, math.floor(definition.RequiredLevel or 1)) then return false, "Your Rizz level is too low." end
	local remaining = (stateFor(player).Cooldowns[abilityId] or 0) - os.clock()
	if remaining > 0 then return false, string.format("Ability is on cooldown for %.1f seconds.", remaining) end
	return true, definition, data
end

function AbilityService:StartCooldown(player, abilityId, duration)
	stateFor(player).Cooldowns[abilityId] = os.clock() + math.max(0, tonumber(duration) or 0)
end

function AbilityService:IsPresentationActive(player, abilityId)
	return stateFor(player).ActiveAbilities[abilityId] == true
end

function AbilityService:BeginPresentation(player, abilityId, duration)
	local state = stateFor(player)
	if state.ActiveAbilities[abilityId] then return false end
	state.ActiveAbilities[abilityId] = true
	task.delay(math.max(0, tonumber(duration) or 0), function()
		if states[player] == state then state.ActiveAbilities[abilityId] = nil end
	end)
	return true
end

function AbilityService:ApplyEffect(player, targetKey, effect, battle)
	if type(effect) ~= "table" or typeof(effect.EffectType) ~= "string" then return end
	stateFor(player).Effects[targetKey] = {EffectType = effect.EffectType, Value = tonumber(effect.Value) or 0, ExpiresTurn = (battle.TurnNumber or 0) + math.max(1, math.floor(tonumber(effect.Duration) or 1))}
end

function AbilityService:HasEffect(player, targetKey, effectType, turnNumber)
	local effect = stateFor(player).Effects[targetKey]
	if not effect or effect.EffectType ~= effectType or effect.ExpiresTurn < turnNumber then return false, 0 end
	return true, effect.Value
end

function AbilityService:Clear(player)
	states[player] = nil
end

Players.PlayerRemoving:Connect(function(player) states[player] = nil end)

return AbilityService