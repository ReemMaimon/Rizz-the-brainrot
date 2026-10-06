local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BrainrotConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("BrainrotConfig"))

local BrainrotService = {}

function BrainrotService:GetDefinition(brainrotId)
	if typeof(brainrotId) ~= "string" then return nil end
	return BrainrotConfig.Get(brainrotId)
end

function BrainrotService:GetDefinitionByModelName(modelName)
	if typeof(modelName) ~= "string" then return nil end
	return BrainrotConfig.GetByModelName(modelName)
end

function BrainrotService:HasDefinition(brainrotId)
	return self:GetDefinition(brainrotId) ~= nil
end

function BrainrotService:GetAllDefinitions()
	local result = {}
	for id, definition in pairs(BrainrotConfig.Definitions or {}) do result[id] = table.clone(definition) end
	return result
end

function BrainrotService:GetMutation(mutationName)
	return BrainrotConfig.GetMutation(mutationName)
end

function BrainrotService:GetMutatedDefinition(brainrotId, mutationName)
	local definition = BrainrotConfig.Definitions[brainrotId]
	return definition and BrainrotConfig.ApplyMutation(definition, mutationName) or nil
end

function BrainrotService:GetRandomDamage(brainrotId, rng, mutationName)
	return BrainrotConfig.GetRandomDamage(brainrotId, rng, mutationName)
end

function BrainrotService:GetHP(brainrotId, mutationName)
	local definition = self:GetMutatedDefinition(brainrotId, mutationName)
	return definition and definition.HP or nil
end

function BrainrotService:GetObtainableDefinitions()
	local result = {}
	for id, definition in pairs(BrainrotConfig.Definitions or {}) do
		if definition.Obtainable == true and (tonumber(definition.SpawnChance) or 0) > 0 then result[id] = table.clone(definition) end
	end
	return result
end

return BrainrotService