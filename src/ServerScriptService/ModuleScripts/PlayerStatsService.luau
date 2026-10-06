local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RizzConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("RizzConfig"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))

local PlayerStatsService = {}
local defeatedEvent = Instance.new("BindableEvent")
PlayerStatsService.OnPlayerDefeated = defeatedEvent.Event
local modifiers = {}

local function finite(value)
	return typeof(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function state(player)
	return player and player:FindFirstChild("PlayerStats")
end

local function value(player, name, fallback)
	local folder = state(player)
	local object = folder and folder:FindFirstChild(name)
	return object and object.Value or fallback
end

local function setValue(player, name, nextValue)
	local folder = state(player)
	local object = folder and folder:FindFirstChild(name)
	if not object then
		return false
	end
	object.Value = nextValue
	return true
end

local function setting(path, fallback)
	local current = RizzConfig
	for _, key in ipairs(path) do
		current = current and current[key]
	end
	return current == nil and fallback or current
end

local function modifierTotal(player, statName, modifierType)
	local total = 0
	local bucket = modifiers[player] and modifiers[player][statName]
	if not bucket then
		return 0
	end
	for _, modifier in pairs(bucket) do
		if modifier.Type == modifierType then
			total += modifier.Amount
		end
	end
	return total
end

local function applyModifiers(player, statName, baseValue)
	local flat = modifierTotal(player, statName, "Flat")
	local percentage = modifierTotal(player, statName, "Percentage")
	return (baseValue + flat) * (1 + percentage)
end

local function syncHumanoid(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.MaxHealth = PlayerStatsService:GetMaxHP(player)
		humanoid.Health = math.max(1, PlayerStatsService:GetHP(player))
	end
end

function PlayerStatsService:Initialize(player)
	local folder = player:FindFirstChild("PlayerStats") or Instance.new("Folder")
	folder.Name = "PlayerStats"
	folder.Parent = player
	local defaults = {
		HP = setting({"Stats", "BaseMaxHP"}, RizzConfig.BaseMaxHP),
		MaxHP = setting({"Stats", "BaseMaxHP"}, RizzConfig.BaseMaxHP),
		RizzDamage = setting({"Damage", "Base"}, RizzConfig.BaseRizzDamage),
		Mana = setting({"Stats", "BaseMaxMana"}, RizzConfig.BaseMaxMana),
		MaxMana = setting({"Stats", "BaseMaxMana"}, RizzConfig.BaseMaxMana),
		ManaRegeneration = setting({"Mana", "RegenerationPerInterval"}, RizzConfig.ManaRegeneration),
	}
	for name, defaultValue in pairs(defaults) do
		local object = folder:FindFirstChild(name) or Instance.new("NumberValue")
		object.Name = name
		if object.Parent ~= folder then
			object.Parent = folder
			object.Value = defaultValue
		end
	end
	modifiers[player] = modifiers[player] or {}
	self:Recalculate(player)
end

function PlayerStatsService:Recalculate(player)
	if not state(player) then
		self:Initialize(player)
		return
	end
	local data = PlayerDataService:Get(player)
	local rizz = data and data.Rizz or 0
	local baseMaxHP = setting({"Stats", "BaseMaxHP"}, RizzConfig.BaseMaxHP)
	local baseMaxMana = setting({"Stats", "BaseMaxMana"}, RizzConfig.BaseMaxMana)
	local maxHP = applyModifiers(player, "MaxHP", baseMaxHP)
	local maxMana = applyModifiers(player, "MaxMana", baseMaxMana)
	local damageBase = setting({"Damage", "Base"}, RizzConfig.BaseRizzDamage) + rizz * setting({"Damage", "RizzScaling"}, RizzConfig.RizzScaling)
	local damage = applyModifiers(player, "RizzDamage", damageBase * setting({"Damage", "Multiplier"}, RizzConfig.DamageMultiplier))
	local regen = applyModifiers(player, "ManaRegeneration", setting({"Mana", "RegenerationPerInterval"}, RizzConfig.ManaRegeneration))
	local minimumMaxHP = setting({"Stats", "MinimumMaxHP"}, 1)
	local maximumMaxHP = setting({"Stats", "MaximumMaxHP"}, math.huge)
	local minimumMaxMana = setting({"Stats", "MinimumMaxMana"}, 0)
	local maximumMaxMana = setting({"Stats", "MaximumMaxMana"}, math.huge)
	local minimumRegen = setting({"Mana", "MinimumRegeneration"}, 0)
	local maximumRegen = setting({"Mana", "MaximumRegeneration"}, math.huge)
	maxHP = math.clamp(maxHP, minimumMaxHP, maximumMaxHP)
	maxMana = math.clamp(maxMana, minimumMaxMana, maximumMaxMana)
	regen = math.clamp(regen, minimumRegen, maximumRegen)
	local oldMaxHP = value(player, "MaxHP", maxHP)
	setValue(player, "MaxHP", maxHP)
	setValue(player, "MaxMana", maxMana)
	setValue(player, "RizzDamage", math.clamp(damage, setting({"Damage", "Minimum"}, 0), setting({"Damage", "Maximum"}, math.huge)))
	setValue(player, "ManaRegeneration", regen)
	setValue(player, "HP", math.clamp(value(player, "HP", maxHP) + (maxHP - oldMaxHP), 0, maxHP))
	setValue(player, "Mana", math.clamp(value(player, "Mana", maxMana), 0, maxMana))
	syncHumanoid(player)
end

function PlayerStatsService:GetHP(player) return value(player, "HP", 0) end
function PlayerStatsService:GetMaxHP(player) return value(player, "MaxHP", setting({"Stats", "BaseMaxHP"}, RizzConfig.BaseMaxHP)) end
function PlayerStatsService:GetMana(player) return value(player, "Mana", 0) end
function PlayerStatsService:GetMaxMana(player) return value(player, "MaxMana", setting({"Stats", "BaseMaxMana"}, RizzConfig.BaseMaxMana)) end
function PlayerStatsService:GetRizzDamage(player) return value(player, "RizzDamage", 0) end
function PlayerStatsService:GetManaRegeneration(player) return value(player, "ManaRegeneration", 0) end

function PlayerStatsService:DamagePlayer(player, amount)
	if not finite(amount) or amount <= 0 or not state(player) then return false end
	local hp = math.max(0, self:GetHP(player) - amount)
	setValue(player, "HP", hp)
	syncHumanoid(player)
	if hp <= 0 then
		defeatedEvent:Fire(player)
	end
	return true
end

function PlayerStatsService:HealPlayer(player, amount)
	if not finite(amount) or amount <= 0 or not state(player) then return false end
	setValue(player, "HP", math.clamp(self:GetHP(player) + amount, 0, self:GetMaxHP(player)))
	syncHumanoid(player)
	return true
end

function PlayerStatsService:SetMaxHP(player, amount)
	if not finite(amount) or amount <= 0 or not state(player) then return false end
	setValue(player, "MaxHP", math.clamp(amount, setting({"Stats", "MinimumMaxHP"}, 1), setting({"Stats", "MaximumMaxHP"}, math.huge)))
	setValue(player, "HP", math.clamp(self:GetHP(player), 0, self:GetMaxHP(player)))
	syncHumanoid(player)
	return true
end

function PlayerStatsService:SetMaxMana(player, amount)
	if not finite(amount) or amount < 0 or not state(player) then return false end
	setValue(player, "MaxMana", math.clamp(amount, setting({"Stats", "MinimumMaxMana"}, 0), setting({"Stats", "MaximumMaxMana"}, math.huge)))
	setValue(player, "Mana", math.clamp(self:GetMana(player), 0, self:GetMaxMana(player)))
	return true
end

function PlayerStatsService:AddMana(player, amount)
	if not finite(amount) or amount <= 0 or not state(player) then return false end
	setValue(player, "Mana", math.clamp(self:GetMana(player) + amount, 0, self:GetMaxMana(player)))
	return true
end

function PlayerStatsService:RemoveMana(player, amount)
	if not finite(amount) or amount <= 0 or self:GetMana(player) < amount then return false end
	setValue(player, "Mana", self:GetMana(player) - amount)
	return true
end

function PlayerStatsService:HasEnoughMana(player, amount)
	return finite(amount) and amount >= 0 and self:GetMana(player) >= amount
end

function PlayerStatsService:IsPlayerAlive(player)
	return self:GetHP(player) > 0
end

function PlayerStatsService:AddModifier(player, statName, modifierId, amount, modifierType)
	if not finite(amount) or not state(player) or typeof(statName) ~= "string" or typeof(modifierId) ~= "string" then return false end
	modifierType = modifierType or "Flat"
	if modifierType ~= "Flat" and modifierType ~= "Percentage" then return false end
	modifiers[player] = modifiers[player] or {}
	modifiers[player][statName] = modifiers[player][statName] or {}
	modifiers[player][statName][modifierId] = {Amount = amount, Type = modifierType}
	self:Recalculate(player)
	return true
end

function PlayerStatsService:RemoveModifier(player, statName, modifierId)
	if modifiers[player] and modifiers[player][statName] then
		modifiers[player][statName][modifierId] = nil
	end
	self:Recalculate(player)
	return true
end

function PlayerStatsService:GetModifier(player, statName, modifierId)
	local modifier = modifiers[player] and modifiers[player][statName] and modifiers[player][statName][modifierId]
	return modifier and modifier.Amount or nil, modifier and modifier.Type or nil
end

function PlayerStatsService:Clear(player)
	modifiers[player] = nil
end

return PlayerStatsService