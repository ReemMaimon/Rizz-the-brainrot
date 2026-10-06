-- Full config for the Lucky Block system: every purchasable tier, its Robux product, the
-- Brainrot rarity odds, and the exact pool of Brainrots that can come out of it.
--
-- IMPORTANT: ProductId = 0 is a placeholder. Create a real Developer Product for each tier in
-- the Roblox Creator Dashboard (Monetization > Developer Products) and paste its numeric id in.
-- Until that's done, purchasing will fail with "This Lucky Block is unavailable" (LuckyBlockService
-- refuses to sell a tier whose ProductId isn't a real positive number, so nothing can be bought
-- for free by accident).
local config = {
	-- Safety cap so a runaway client can't spam PurchasePack-style abuse into an unbounded inventory.
	MaxUnopenedPerBlock = 99,

	Blocks = {
		CommonLuckyBlock = {
			BlockId = "CommonLuckyBlock",
			DisplayName = "Common Lucky Block",
			Description = "A basic block. Mostly Common and Uncommon Brainrots, with a small shot at Rare.",
			ProductId = 0,
			RobuxPrice = 25,
			Style = "Wood",
			IconColor = {150, 200, 120},
			RarityWeights = {Common = 65, Uncommon = 28, Rare = 7},
			EligibleBrainrots = {
				"NoobiniPizzanini", "TimCheese", "BananitaDolphinita", "TalpaDiFero",
				"SvininaBombardino", "PipiKiwi", "LiriliLarila", "FluriFlura",
				"CappuccinoAssassino", "ChimpanziniBananini",
				"BombarbiroCrocodilo", "BallerinaCappuccina",
			},
		},
		RareLuckyBlock = {
			BlockId = "RareLuckyBlock",
			DisplayName = "Rare Lucky Block",
			Description = "Guarantees at least Uncommon, with real odds at Rare and a shot at Epic.",
			ProductId = 0,
			RobuxPrice = 75,
			Style = "Silver",
			IconColor = {120, 190, 255},
			RarityWeights = {Uncommon = 40, Rare = 45, Epic = 15},
			EligibleBrainrots = {
				"CappuccinoAssassino", "ChimpanziniBananini",
				"BombarbiroCrocodilo", "BallerinaCappuccina", "TrippiTroppi", "GangsterFootera",
				"BobritoBandito", "BonecaAmbalabu", "CactoHipopotamo", "TaTaTaTaSahur",
				"TricTracBarabum", "BananitaDolphinitaRare",
				"OdinDinDinDun", "BrrBrrPatapim",
			},
		},
		EpicLuckyBlock = {
			BlockId = "EpicLuckyBlock",
			DisplayName = "Epic Lucky Block",
			Description = "The good stuff. Weighted toward Epic and Legendary, with a shot at Mythic.",
			ProductId = 0,
			RobuxPrice = 149,
			Style = "Gold",
			IconColor = {200, 150, 255},
			RarityWeights = {Epic = 55, Legendary = 35, Mythic = 10},
			EligibleBrainrots = {
				"OdinDinDinDun", "BrrBrrPatapim", "TrulimeroTrulicina", "BambiniCrostini",
				"BrriBrriBicusDicus", "AvocadiniGuffo",
				"ChimpanziniBananiniLegendary", "BallerinaCappuccinaLegendary",
				"Preston", "OrangutiniAnanassini", "BombombiniGusini",
			},
		},
		MythicLuckyBlock = {
			BlockId = "MythicLuckyBlock",
			DisplayName = "Mythic Lucky Block",
			Description = "The best Lucky Block money can buy. Always Mythic or better.",
			ProductId = 0,
			RobuxPrice = 399,
			Style = "Diamond",
			IconColor = {255, 120, 190},
			RarityWeights = {Mythic = 65, ["Brainrot God"] = 28, Secret = 7},
			EligibleBrainrots = {
				"Preston", "OrangutiniAnanassini", "BombombiniGusini",
				"OdinDinDinDunGod", "CocofantoElefanto", "Matteo",
				"KreekCraft", "MrBeasetDaddy", "Jandel",
			},
		},
	},

	-- Display order in the shop, cheapest first.
	Order = {"CommonLuckyBlock", "RareLuckyBlock", "EpicLuckyBlock", "MythicLuckyBlock"},
}

function config.Get(blockId)
	local block = config.Blocks[blockId]
	return block and table.clone(block) or nil
end

function config.GetOrdered()
	local result = {}
	for _, blockId in ipairs(config.Order) do
		if config.Blocks[blockId] then table.insert(result, config.Blocks[blockId]) end
	end
	return result
end

return config
