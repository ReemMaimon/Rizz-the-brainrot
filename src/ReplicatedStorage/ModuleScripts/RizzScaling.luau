local RizzScaling = {}

local function finiteNumber(value, fallback)
	if typeof(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
		return fallback
	end
	return value
end

local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, item in pairs(value) do result[key] = copy(item) end
	return result
end

local function clampValue(value, config)
	local minValue = finiteNumber(config.MinValue, nil)
	local maxValue = finiteNumber(config.MaxValue, nil)
	if minValue ~= nil and maxValue ~= nil and minValue > maxValue then
		minValue, maxValue = maxValue, minValue
	end
	if minValue ~= nil then value = math.max(minValue, value) end
	if maxValue ~= nil then value = math.min(maxValue, value) end
	return value
end

function RizzScaling.GetSteps(rizzLevel, interval)
	local level = math.max(0, math.floor(finiteNumber(rizzLevel, 0)))
	local stepInterval = finiteNumber(interval, 0)
	if stepInterval <= 0 then return 0 end
	return math.floor(level / stepInterval)
end

function RizzScaling.ValidateConfig(config)
	if config == nil then return true end
	if type(config) ~= "table" then return false, "Scaling configuration must be a table." end
	local interval = finiteNumber(config.Interval, nil)
	if interval == nil or interval <= 0 then return false, "Interval must be a positive number." end
	local mode = config.Mode or "Additive"
	if mode ~= "Additive" and mode ~= "Multiplicative" then return false, "Mode must be Additive or Multiplicative." end
	if finiteNumber(config.IncreasePerStep, nil) == nil then return false, "IncreasePerStep must be a finite number." end
	return true
end

function RizzScaling.CalculateScaledStat(baseValue, scalingConfig, rizzLevel)
	local base = finiteNumber(baseValue, 0)
	if type(scalingConfig) ~= "table" or scalingConfig.Enabled == false then return clampValue(base, scalingConfig or {}) end
	local valid = RizzScaling.ValidateConfig(scalingConfig)
	if not valid then return clampValue(base, scalingConfig) end
	local steps = RizzScaling.GetSteps(rizzLevel, scalingConfig.Interval)
	local increase = finiteNumber(scalingConfig.IncreasePerStep, 0)
	local value
	if (scalingConfig.Mode or "Additive") == "Multiplicative" then
		local multiplier = 1 + increase * steps
		local maxMultiplier = finiteNumber(scalingConfig.MaxMultiplier, nil)
		if maxMultiplier ~= nil then multiplier = math.min(multiplier, maxMultiplier) end
		value = base * multiplier
	else
		value = base + steps * increase
	end
	return clampValue(value, scalingConfig)
end

function RizzScaling.CalculateAbilityStats(baseStats, scaling, rizzLevel)
	local result = {}
	if type(baseStats) ~= "table" then return result end
	for statName, baseValue in pairs(baseStats) do
		local config = type(scaling) == "table" and scaling[statName] or nil
		if typeof(baseValue) == "number" then
			result[statName] = RizzScaling.CalculateScaledStat(baseValue, config, rizzLevel)
		else
			result[statName] = copy(baseValue)
		end
	end
	return result
end

function RizzScaling.GetAbilityStat(baseStats, scaling, statName, rizzLevel, fallback)
	if type(baseStats) ~= "table" then return fallback end
	local baseValue = baseStats[statName]
	if typeof(baseValue) ~= "number" then return fallback end
	local config = type(scaling) == "table" and scaling[statName] or nil
	return RizzScaling.CalculateScaledStat(baseValue, config, rizzLevel)
end

return RizzScaling