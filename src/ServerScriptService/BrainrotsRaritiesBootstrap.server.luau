local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local BrainrotConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("BrainrotConfig"))
local root = ServerStorage:WaitForChild("BrainrotsRarities")
local sourceRoot = ServerStorage:FindFirstChild("BrainrotsRarities")
local rarities = BrainrotConfig.RarityOrder
local mutations = {}
for mutationName in pairs(BrainrotConfig.Mutations or {}) do table.insert(mutations, mutationName) end
table.sort(mutations, function(left, right) return left == "Normal" or (left ~= "Normal" and right ~= "Normal" and left < right) end)
local definitions = BrainrotConfig.Definitions or {}
local rarityByModel = {}
for _, definition in pairs(definitions) do if definition.ModelName and definition.Rarity then rarityByModel[definition.ModelName] = definition.Rarity end end
for _, rarity in ipairs(rarities) do
	local rarityFolder = root:FindFirstChild(rarity) or Instance.new("Folder")
	rarityFolder.Name, rarityFolder.Parent = rarity, root
	for _, mutation in ipairs(mutations) do
		local mutationFolder = rarityFolder:FindFirstChild(mutation) or Instance.new("Folder")
		mutationFolder.Name, mutationFolder.Parent = mutation, rarityFolder
	end
end
if sourceRoot then
	for _, rarity in ipairs(rarities) do
		local rarityFolder = sourceRoot:FindFirstChild(rarity)
		local normalFolder = rarityFolder and rarityFolder:FindFirstChild("Normal")
		if normalFolder then
			for _, source in ipairs(normalFolder:GetChildren()) do
				if source:IsA("Model") then
					local targetRarity = rarityByModel[source.Name] or rarity
					local target = root:FindFirstChild(targetRarity) and root[targetRarity]:FindFirstChild("Normal")
					if target and not target:FindFirstChild(source.Name) then source:Clone().Parent = target end
				end
			end
		end
	end
end
print("[BrainrotsRarities] Regular Brainrot rarity and mutation folders are ready")