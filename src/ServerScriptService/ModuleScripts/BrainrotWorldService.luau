local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local BrainrotConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("BrainrotConfig"))
local BrainrotSpawnConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("BrainrotSpawnConfig"))
local RarityService = require(script.Parent:WaitForChild("RarityService"))
local WorldProgressionService = require(script.Parent:WaitForChild("WorldProgressionService"))

local BrainrotWorldService = {}
BrainrotWorldService.OnBrainrotSpawned = Instance.new("BindableEvent")
BrainrotWorldService.OnBrainrotDespawned = Instance.new("BindableEvent")
local active = {}
local rng = Random.new()

local function getAllowedSpawnRarities(areaId)
	local area = WorldProgressionService:GetArea(areaId)
	local result = {}
	for _, rarity in ipairs(area and area.AllowedRarities or {}) do if RarityService:IsObtainable(rarity) then table.insert(result, rarity) end end
	return result
end
local function normalizeModelName(value) return string.lower((tostring(value):gsub("[^%w]", ""))) end
local function findModelInFolder(folder, modelName)
	if not folder then return nil end
	local direct = folder:FindFirstChild(modelName)
	if direct and direct:IsA("Model") then return direct end
	local normalizedName = normalizeModelName(modelName)
	for _, descendant in folder:GetDescendants() do if descendant:IsA("Model") and normalizeModelName(descendant.Name) == normalizedName then return descendant end end
end
local function findAnyRegularModel(folder)
	if not folder then return nil end
	for _, child in folder:GetChildren() do if child:IsA("Model") then return child end end
	for _, descendant in folder:GetDescendants() do if descendant:IsA("Model") then return descendant end end
end
local function findModelSource(rarity, modelName, mutationName)
	local sourceRoot = ServerStorage:FindFirstChild("BrainrotsRarities")
	local rarityFolder = sourceRoot and sourceRoot:FindFirstChild(rarity)
	if rarityFolder then
		local mutationFolder = rarityFolder:FindFirstChild(mutationName or "Normal")
		local mutatedModel = findModelInFolder(mutationFolder, modelName)
		if mutatedModel then return mutatedModel end
		local normal = rarityFolder:FindFirstChild("Normal")
		local normalModel = findModelInFolder(normal, modelName) or findAnyRegularModel(normal)
		if normalModel then return normalModel end
		local exact = findModelInFolder(rarityFolder, modelName)
		if exact then return exact end
		local fallback = findAnyRegularModel(rarityFolder)
		if fallback then return fallback end
	end
	local workspacePack = Workspace:FindFirstChild("BrainrotPack")
	return workspacePack and findModelInFolder(workspacePack, modelName) or nil
end

local function chooseMutation(rarity, modelName)
	local mutations = BrainrotConfig.Mutations or {}
	local names = {}
	for mutationName in pairs(mutations) do table.insert(names, mutationName) end
	table.sort(names, function(left, right) return left == "Normal" or (left ~= "Normal" and right ~= "Normal" and left < right) end)
	for _, mutationName in ipairs(names) do
		if findModelSource(rarity, modelName, mutationName) then return mutationName end
	end
	return "Normal"
end
local function chooseDefinition(areaId)
	local allowed = getAllowedSpawnRarities(areaId)
	local available = {}
	for id, definition in pairs(BrainrotConfig.Definitions or {}) do
		for _, rarity in ipairs(allowed) do
			if definition.Rarity == rarity and definition.Obtainable == true and findModelSource(rarity, definition.ModelName, "Normal") then available[id] = definition break end
		end
	end
	local choice, reason = BrainrotSpawnConfig.Choose(available, allowed, areaId, rng)
	if not choice then return nil, reason end
	local mutationName = chooseMutation(choice.Definition.Rarity, choice.Definition.ModelName)
	local source = findModelSource(choice.Definition.Rarity, choice.Definition.ModelName, mutationName)
	choice.Mutation = mutationName
	return source and choice or nil, source or "No Brainrot model found for " .. tostring(choice.Definition.ModelName)
end
local function getBounds(platform) local half = platform.Size * 0.5 return math.max(0, half.X - 3), math.max(0, half.Z - 3) end
-- Public wrapper around the private model-source lookup, reused by anything that needs to
-- clone a Brainrot's 3D model outside of the normal world-spawn flow (e.g. Lucky Blocks).
function BrainrotWorldService:FindModelSource(rarity, modelName, mutationName)
	return findModelSource(rarity, modelName, mutationName or "Normal")
end

function BrainrotWorldService:GetActiveCount() local count = 0 for model in pairs(active) do if model.Parent then count += 1 else active[model] = nil end end return count end
function BrainrotWorldService:GetActiveModels() local result = {} for model in pairs(active) do if model.Parent then table.insert(result, model) else active[model] = nil end end return result end
function BrainrotWorldService:GetData(model) return active[model] end
function BrainrotWorldService:FindSpawnPosition(platform)
	local config, halfX, halfZ = BrainrotConfig.Spawn, getBounds(platform)
	local maxDistance, minDistance = math.max(0, tonumber(config.MaxSpawnDistance) or math.max(halfX, halfZ)), math.max(0, tonumber(config.MinSpawnDistance) or 0)
	local minSeparation, attempts = math.max(0, tonumber(config.MinimumBrainrotSeparation) or 0), math.max(1, math.floor(tonumber(config.PositionAttempts) or 12))
	for _ = 1, attempts do
		local x, z = rng:NextNumber(-halfX, halfX), rng:NextNumber(-halfZ, halfZ)
		if Vector2.new(x, z).Magnitude >= minDistance and Vector2.new(x, z).Magnitude <= maxDistance then
			local position, valid = platform.CFrame:PointToWorldSpace(Vector3.new(x, platform.Size.Y * 0.5, z)), true
			for model in pairs(active) do local root = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart") if model.Parent and root and (root.Position - position).Magnitude < minSeparation then valid = false break end end
			if valid then return position end
		end
	end
end
function BrainrotWorldService:Spawn(platform, parent, areaId)
	if not platform or not platform:IsA("BasePart") then return nil, "Spawn platform is missing or invalid" end
	if self:GetActiveCount() >= BrainrotConfig.Spawn.MaxWorldBrainrots then return nil, "Maximum brainrots reached" end
	areaId = areaId or platform:GetAttribute("AreaId") or "StartingArea"
	local choice, sourceOrReason = chooseDefinition(areaId)
	if not choice then return nil, sourceOrReason end
	local source = sourceOrReason
	local position = self:FindSpawnPosition(platform)
	if not position then return nil, "No valid spawn position" end
	local model = source:Clone()
	model.Name, model.Parent = choice.Definition.DisplayName, parent
	local sourcePivot = model:GetPivot()
	local boundsCFrame, boundsSize = model:GetBoundingBox()
	local boundsInPivot = sourcePivot:ToObjectSpace(boundsCFrame)
	local bottomOffset = boundsInPivot.Position.Y - boundsSize.Y * 0.5
	local spawnPivot = CFrame.new(position) * sourcePivot.Rotation * CFrame.new(0, -bottomOffset, 0)
	model:PivotTo(spawnPivot)
	for _, descendant in model:GetDescendants() do if descendant:IsA("BasePart") then descendant.Anchored = true end end
	local definition = BrainrotConfig.ApplyMutation(choice.Definition, choice.Mutation)
	model:SetAttribute("BrainrotMutation", definition.Mutation)
	model:SetAttribute("BrainrotDamageMultiplier", definition.DamageMultiplier)
	model:SetAttribute("BrainrotHPMultiplier", definition.HPMultiplier)
	model:SetAttribute("BrainrotId", definition.BrainrotId)
	model:SetAttribute("BrainrotName", definition.DisplayName)
	model:SetAttribute("BrainrotRarity", definition.Rarity)
	model:SetAttribute("BrainrotAreaId", areaId)
	model:SetAttribute("BrainrotHP", definition.HP)
	model:SetAttribute("BrainrotRizzDamage", definition.MinDamage)
	model:SetAttribute("BrainrotMinDamage", definition.MinDamage)
	model:SetAttribute("BrainrotMaxDamage", definition.MaxDamage)
	model:SetAttribute("BrainrotPrice", definition.Price)
	model:SetAttribute("BrainrotSpawnChance", definition.SpawnChance)
	model:SetAttribute("BrainrotLifetime", BrainrotConfig.Spawn.Lifetime)
	model:SetAttribute("SpawnedAt", os.time())
	active[model] = definition
	task.delay(math.max(0, tonumber(BrainrotConfig.Spawn.Lifetime) or 60), function() self:Despawn(model) end)
	self.OnBrainrotSpawned:Fire(model, definition)
	return model
end
function BrainrotWorldService:ReleaseFromWorld(model) if not active[model] then return false end active[model] = nil self.OnBrainrotDespawned:Fire(model) return true end
function BrainrotWorldService:Despawn(model) if not active[model] then return false end active[model] = nil if model and model.Parent then model:Destroy() end self.OnBrainrotDespawned:Fire(model) return true end
function BrainrotWorldService:CleanupRemoved(model) if active[model] and not model.Parent then active[model] = nil self.OnBrainrotDespawned:Fire(model) end end
return BrainrotWorldService