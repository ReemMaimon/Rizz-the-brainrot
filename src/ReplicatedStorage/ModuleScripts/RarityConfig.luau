local rarityList = {
	{Id = "Common", DisplayName = "Common", Order = 1, Obtainable = true, SpawnChance = 60, Color = {170, 170, 170}, RizzRewardMultiplier = 1, CoinRewardMultiplier = 1, Metadata = {}},
	{Id = "Uncommon", DisplayName = "Uncommon", Order = 2, Obtainable = true, SpawnChance = 20, Color = {85, 200, 120}, RizzRewardMultiplier = 1.25, CoinRewardMultiplier = 1.25, Metadata = {}},
	{Id = "Rare", DisplayName = "Rare", Order = 3, Obtainable = true, SpawnChance = 10, Color = {85, 170, 255}, RizzRewardMultiplier = 1.5, CoinRewardMultiplier = 1.5, Metadata = {}},
	{Id = "Epic", DisplayName = "Epic", Order = 4, Obtainable = true, SpawnChance = 5, Color = {170, 85, 255}, RizzRewardMultiplier = 2, CoinRewardMultiplier = 2, Metadata = {}},
	{Id = "Legendary", DisplayName = "Legendary", Order = 5, Obtainable = true, SpawnChance = 2, Color = {255, 170, 0}, RizzRewardMultiplier = 3, CoinRewardMultiplier = 3, Metadata = {}},
	{Id = "Mythic", DisplayName = "Mythic", Order = 6, Obtainable = true, SpawnChance = 0.8, Color = {255, 85, 127}, RizzRewardMultiplier = 5, CoinRewardMultiplier = 5, Metadata = {}},
	{Id = "Brainrot God", DisplayName = "Brainrot God", Order = 7, Obtainable = true, SpawnChance = 0, Color = {255, 85, 255}, RizzRewardMultiplier = 7.5, CoinRewardMultiplier = 7.5, Metadata = {}},
	{Id = "Secret", DisplayName = "Secret", Order = 8, Obtainable = true, SpawnChance = 0.2, Color = {40, 40, 40}, RizzRewardMultiplier = 10, CoinRewardMultiplier = 10, Metadata = {}},
	{Id = "OG", DisplayName = "OG", Order = 9, Obtainable = false, SpawnChance = 0, Color = {255, 215, 0}, RizzRewardMultiplier = 0, CoinRewardMultiplier = 0, Metadata = {}},
}

local definitions, order = {}, {}
for _, definition in ipairs(rarityList) do
	local copy = table.clone(definition)
	definitions[copy.Id] = copy
	table.insert(order, copy.Id)
end

local result = {Rarities = rarityList, Order = order, Definitions = definitions}
function result.Get(rarity) return definitions[rarity] and table.clone(definitions[rarity]) or nil end
function result.IsObtainable(rarity) return definitions[rarity] ~= nil and definitions[rarity].Obtainable == true end
return result