local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RarityConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("RarityConfig"))

local RarityService = {}

function RarityService:Get(rarity)
	return RarityConfig.Get(rarity)
end

function RarityService:IsObtainable(rarity)
	return RarityConfig.IsObtainable(rarity)
end

function RarityService:GetObtainableRarities()
	local result = {}
	for _, rarity in ipairs(RarityConfig.Rarities) do
		if rarity.Obtainable == true then
			table.insert(result, table.clone(rarity))
		end
	end
	return result
end

return RarityService
