-- Shared weighted-random-choice helper, used anywhere something is picked by a {key = weight} table
-- (ability card packs, Lucky Blocks, etc) so the roll algorithm only lives in one place.
local WeightedRoll = {}

local function finitePositive(value)
	return typeof(value) == "number" and value == value and value > 0 and value < math.huge
end

-- weights: {key = weight}, both string and other hashable key types work.
-- Returns the chosen key, or nil if there are no valid (finite, positive) weights.
function WeightedRoll.Choose(weights, rng)
	local total = 0
	for key, weight in pairs(weights or {}) do
		if finitePositive(weight) then total += weight end
	end
	if total <= 0 then return nil end

	local roll = (rng and rng:NextNumber() or math.random()) * total
	local running = 0
	for key, weight in pairs(weights) do
		if finitePositive(weight) then
			running += weight
			if roll <= running then return key end
		end
	end
	return nil
end

-- Returns an ordered list of {Key, Weight, Percent} for display (e.g. shop odds), sorted by
-- descending percent. Percent is 0-100, rounded to `decimals` places (default 2).
function WeightedRoll.ToPercentages(weights, decimals)
	decimals = decimals or 2
	local multiplier = 10 ^ decimals
	local total = 0
	local entries = {}
	for key, weight in pairs(weights or {}) do
		if finitePositive(weight) then
			total += weight
			table.insert(entries, {Key = key, Weight = weight})
		end
	end
	if total <= 0 then return {} end
	for _, entry in ipairs(entries) do
		entry.Percent = math.floor((entry.Weight / total) * 100 * multiplier + 0.5) / multiplier
	end
	table.sort(entries, function(a, b) return a.Percent > b.Percent end)
	return entries
end

return WeightedRoll
