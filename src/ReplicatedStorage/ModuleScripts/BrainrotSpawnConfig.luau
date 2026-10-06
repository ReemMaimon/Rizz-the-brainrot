local AreaConfig = require(script.Parent:WaitForChild("AreaConfig"))

local chances = {ByArea = {StartingArea = {}, Area2 = {}, Area3 = {}, DangerousArea = {}, BossArea = {}}}

local function positive(value)
	return typeof(value) == "number" and value == value and value >= 0 and value < math.huge
end

local function getWeight(definition, areaId)
	if not definition or definition.Obtainable ~= true then return 0 end
	local areaOverrides = chances.ByArea[areaId] or {}
	local areaChance
	for _, area in ipairs(AreaConfig.Areas or {}) do
		if area.Id == areaId then areaChance = area.SpawnRates and area.SpawnRates[definition.Rarity] break end
	end
	if positive(areaOverrides[definition.BrainrotId]) then return areaOverrides[definition.BrainrotId] end
	if positive(areaOverrides[definition.ModelName]) then return areaOverrides[definition.ModelName] end
	if positive(areaChance) then return areaChance * (tonumber(definition.SpawnChance) or 0) end
	return positive(definition.SpawnChance) and definition.SpawnChance or 0
end

local function choose(definitions, allowedRarities, areaId, rng)
	local allowed = {}
	for _, rarity in ipairs(allowedRarities or {}) do allowed[rarity] = true end
	local candidates, total = {}, 0
	for id, definition in pairs(definitions or {}) do
		if allowed[definition.Rarity] and definition.Obtainable == true then
			local weight = getWeight(definition, areaId)
			if weight > 0 then total += weight table.insert(candidates, {Id = id, Definition = definition, Weight = weight}) end
		end
	end
	if total <= 0 then return nil, "No obtainable Brainrots with positive SpawnChance for area" end
	local roll, cumulative = (rng or Random.new()):NextNumber(0, total), 0
	for _, candidate in ipairs(candidates) do
		cumulative += candidate.Weight
		if roll <= cumulative then return candidate end
	end
	return candidates[#candidates]
end

return {Chances = chances, GetWeight = getWeight, Choose = choose}