local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AbilityConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("AbilityConfig"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))

local AbilityPowerService = {}

local function finiteNumber(value, fallback)
	if typeof(value) ~= "number" then
		return fallback
	end
	if value ~= value or value == math.huge or value == -math.huge then
		return fallback
	end
	return value
end

local function getLeaderstat(player, name)
	local leaderstats = player and player:FindFirstChild("leaderstats")
	return leaderstats and leaderstats:FindFirstChild(name)
end

function AbilityPowerService:GetLevelRate(level)
	local rates = AbilityConfig.LevelRates or {}
	local numericLevel = math.max(1, math.floor(finiteNumber(level, 1)))
	local rate = rates[numericLevel]
	if rate == nil then
		local highestLevel
		for configuredLevel in pairs(rates) do
			if typeof(configuredLevel) == "number" and (not highestLevel or configuredLevel > highestLevel) then
				highestLevel = configuredLevel
			end
		end
		rate = highestLevel and rates[highestLevel] or 0
	end
	return math.max(0, finiteNumber(rate, 0))
end

function AbilityPowerService:GetCurrentLevelRate(player)
	local levelValue = getLeaderstat(player, "RizzLevel")
	local data = PlayerDataService:Get(player)
	local level = finiteNumber(levelValue and levelValue.Value, nil)
	if level == nil and data then
		level = finiteNumber(data.RizzLevel, nil)
	end
	return self:GetLevelRate(level or 1)
end

function AbilityPowerService:GetPowerStrengthDivider()
	return math.max(0.000001, finiteNumber(AbilityConfig.PowerStrengthDivider, 50))
end

function AbilityPowerService:GetRawPower(player)
	if not player then
		return 0
	end
	local data = PlayerDataService:Get(player)
	return math.max(0, finiteNumber(data and data.RawPower, 0))
end

function AbilityPowerService:GetEffectivePower(player)
	return self:GetRawPower(player) / self:GetPowerStrengthDivider()
end

function AbilityPowerService:GetBasePower(player)
	return self:GetEffectivePower(player)
end

function AbilityPowerService:GetRawPowerFromRizz(player, amount)
	return math.max(0, finiteNumber(amount, 0)) * self:GetCurrentLevelRate(player)
end

function AbilityPowerService:AddRawPower(player, amount)
	local data = PlayerDataService:Get(player)
	local numericAmount = finiteNumber(amount, 0)
	if not data or numericAmount <= 0 then
		return false, self:GetRawPower(player)
	end
	local nextRawPower = self:GetRawPower(player) + numericAmount
	data.RawPower = nextRawPower
	PlayerDataService:Update(player, "RawPower", nextRawPower)
	player:SetAttribute("RawPower", nextRawPower)
	return true, nextRawPower
end

function AbilityPowerService:AddRizzPower(player, amount)
	return self:AddRawPower(player, self:GetRawPowerFromRizz(player, amount))
end

function AbilityPowerService:GetAbilityPower(player, abilityId)
	local definition = (AbilityConfig.Abilities or {})[abilityId]
	if not definition then
		return 0
	end
	local multiplier = math.max(0, finiteNumber(definition.PowerMultiplier, 1))
	return self:GetEffectivePower(player) * multiplier
end

function AbilityPowerService:GetScaledValue(player, abilityId, scale)
	return self:GetAbilityPower(player, abilityId) * finiteNumber(scale, 1)
end

function AbilityPowerService:GetAbilityDamage(player, abilityId)
	local definition = (AbilityConfig.Abilities or {})[abilityId]
	local baseDamage = definition and math.max(0, finiteNumber(definition.Damage, 0)) or 0
	return baseDamage + math.max(0, self:GetAbilityPower(player, abilityId))
end

return AbilityPowerService