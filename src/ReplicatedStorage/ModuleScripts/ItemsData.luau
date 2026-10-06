-- ITEMS DATA MODULE - For "Steal a Baby" (FIXED NUMBER HANDLING)
-- Place this in ReplicatedStorage > ModuleScripts > ItemsData

local ItemsData = {}

-- Items with increased prices, balanced progression, and rebirth requirements
ItemsData.Items = {
	-- Basic Tier (Early Game)
	{
		name = "Slap",
		description = "Basic slap. Hit a thief once to force the baby back into your base.",
		price = 10000,
		toolName = "Slap",
		tier = "Basic",
		rebirth = 0,
		damage = 25,
		range = 5,
		cooldown = 1.0
	},
	{
		name = "Iron Slap",
		description = "Heavier than a normal slap. Sends thieves flying further.",
		price = 50000,
		toolName = "Iron Slap",
		tier = "Basic",
		rebirth = 1,
		damage = 40,
		range = 6,
		cooldown = 1.2
	},
	{
		name = "Speed Coil",
		description = "Outrun thieves before they leave your base.",
		price = 200000,
		toolName = "Speed Coil",
		tier = "Basic",
		rebirth = 2,
		speedMultiplier = 2.0,
		duration = 10
	},

	-- Advanced Tier (Mid Game)
	{
		name = "Gold Slap",
		description = "Golden slap with a guaranteed baby return on hit.",
		price = 8000000,
		toolName = "Gold Slap",
		tier = "Advanced",
		rebirth = 2,
		damage = 60,
		range = 7,
		cooldown = 0.9,
		special = "Guaranteed Return"
	},
	{
		name = "Gravity Coil",
		description = "Launch yourself after thieves with powerful jumps.",
		price = 2500000,
		toolName = "Gravity Coil",
		tier = "Advanced",
		rebirth = 3,
		jumpPower = 150,
		duration = 15
	},
	{
		name = "Emerald Slap",
		description = "A green gem slap that dazes any thief it touches.",
		price = 25000000,
		toolName = "Emerald Slap",
		tier = "Advanced",
		rebirth = 3,
		damage = 75,
		range = 8,
		cooldown = 0.8,
		special = "Stuns Target"
	},
	{
		name = "Rage Bat",
		description = "Swing fueled by rage. Stops thieves dead in their tracks.",
		price = 75000000,
		toolName = "Rage Bat",
		tier = "Advanced",
		rebirth = 4,
		damage = 90,
		range = 10,
		cooldown = 1.5,
		special = "Knockdown"
	},
	{
		name = "Ruby Slap",
		description = "Fiery ruby slap that forces instant drop of stolen baby.",
		price = 200000000,
		toolName = "Ruby Slap",
		tier = "Advanced",
		rebirth = 4,
		damage = 100,
		range = 9,
		cooldown = 0.7,
		special = "Instant Drop"
	},
	{
		name = "Infinite Bat",
		description = "Unbreakable bat. No cooldown. Smack away endlessly.",
		price = 500000000,
		toolName = "Infinite Bat",
		tier = "Expert",
		rebirth = 5,
		damage = 80,
		range = 12,
		cooldown = 0.1,
		special = "No Cooldown"
	},
	{
		name = "Diamond Slap",
		description = "Crystal-clear slap that blasts thieves across the map.",
		price = 750000000,
		toolName = "Diamond Slap",
		tier = "Expert",
		rebirth = 5,
		damage = 150,
		range = 15,
		cooldown = 0.6,
		special = "Map-wide Knockback"
	},

	-- Expert Tier (Late Game)
	{
		name = "Bee Launcher",
		description = "Launch a swarm of bees that chase thieves relentlessly.",
		price = 750000,
		toolName = "Bee Launcher",
		tier = "Expert",
		rebirth = 6,
		damage = 15,
		range = 100,
		cooldown = 3.0,
		special = "Swarm Attack",
		beeCount = 10
	},
	{
		name = "Coil Combo",
		description = "Speed + Gravity + Damage. Ultimate anti-thief weapon.",
		price = 1500000000,
		toolName = "Coil Combo",
		tier = "Expert",
		rebirth = 7,
		damage = 35,
		range = 8,
		cooldown = 0.8,
		special = "Movement + Combat"
	},
	{
		name = "Lazer Gun",
		description = "Zap a thief from across the map and return your baby.",
		price = 3000000000,
		toolName = "Lazer Gun",
		tier = "Expert",
		rebirth = 8,
		damage = 120,
		range = 999,
		cooldown = 2.0,
		special = "Infinite Range"
	},
	{
		name = "Ban Hammer",
		description = "One hit. Thief gone. Baby returned. Boom.",
		price = 7500000000,
		toolName = "Ban Hammer",
		tier = "Expert",
		rebirth = 9,
		damage = 999,
		range = 20,
		cooldown = 5.0,
		special = "Instant KO"
	},

	-- Legendary Tier (End Game)
	{
		name = "Flying Carpet",
		description = "Fly straight to your baby — no thief can outrun air.",
		price = 15000000000,
		toolName = "Flying Carpet",
		tier = "Legendary",
		rebirth = 10,
		flightSpeed = 100,
		duration = 30,
		special = "Flight"
	},
	{
		name = "Blackhole Slap",
		description = "Sucks thief and baby back into your base instantly.",
		price = 50000000000,
		toolName = "Blackhole Slap",
		tier = "Legendary",
		rebirth = 10,
		damage = 200,
		range = 50,
		cooldown = 10.0,
		special = "Teleport to Base"
	}
}

-- Optimized cache for quick lookups
local itemByName = {}
local itemByToolName = {}

-- Initialize caches
local function initializeCaches()
	for _, item in ipairs(ItemsData.Items) do
		itemByName[item.name] = item
		itemByToolName[item.toolName] = item
	end
end

-- Function to get items sorted by price (cheapest first)
function ItemsData:GetSortedItems()
	local sortedItems = {}
	for i = 1, #self.Items do
		sortedItems[i] = self.Items[i]
	end
	table.sort(sortedItems, function(a, b)
		return tonumber(a.price) < tonumber(b.price)
	end)
	return sortedItems
end

-- Function to get items sorted by tier and then by price
function ItemsData:GetItemsByTier()
	local tierOrder = {"Basic", "Advanced", "Expert", "Legendary"}
	local itemsByTier = {}

	for i = 1, #tierOrder do
		itemsByTier[tierOrder[i]] = {}
	end

	for i = 1, #self.Items do
		local item = self.Items[i]
		if itemsByTier[item.tier] then
			table.insert(itemsByTier[item.tier], item)
		end
	end

	-- Sort each tier by price
	for _, items in pairs(itemsByTier) do
		table.sort(items, function(a, b)
			return tonumber(a.price) < tonumber(b.price)
		end)
	end

	return itemsByTier
end

-- Optimized function to get item by name
function ItemsData:GetItemByName(itemName)
	return itemByName[itemName]
end

-- Optimized function to get item by tool name
function ItemsData:GetItemByToolName(toolName)
	return itemByToolName[toolName]
end

-- Function to get items within a price range
function ItemsData:GetItemsInPriceRange(minPrice, maxPrice)
	local itemsInRange = {}
	minPrice = tonumber(minPrice) or 0
	maxPrice = tonumber(maxPrice) or 0

	for i = 1, #self.Items do
		local item = self.Items[i]
		local itemPrice = tonumber(item.price) or 0
		if itemPrice >= minPrice and itemPrice <= maxPrice then
			table.insert(itemsInRange, item)
		end
	end
	table.sort(itemsInRange, function(a, b)
		return tonumber(a.price) < tonumber(b.price)
	end)
	return itemsInRange
end

-- Function to get items by tier
function ItemsData:GetItemsByTierName(tierName)
	local tierItems = {}
	for i = 1, #self.Items do
		local item = self.Items[i]
		if item.tier == tierName then
			table.insert(tierItems, item)
		end
	end
	table.sort(tierItems, function(a, b)
		return tonumber(a.price) < tonumber(b.price)
	end)
	return tierItems
end

-- Function to get affordable items for a player
function ItemsData:GetAffordableItems(playerCoins)
	local affordableItems = {}
	playerCoins = tonumber(playerCoins) or 0

	for i = 1, #self.Items do
		local item = self.Items[i]
		local itemPrice = tonumber(item.price) or 0
		if itemPrice <= playerCoins then
			table.insert(affordableItems, item)
		end
	end
	table.sort(affordableItems, function(a, b)
		return tonumber(a.price) < tonumber(b.price)
	end)
	return affordableItems
end

-- Function to get next affordable item
function ItemsData:GetNextAffordableItem(playerCoins)
	local sortedItems = self:GetSortedItems()
	playerCoins = tonumber(playerCoins) or 0

	for i = 1, #sortedItems do
		local itemPrice = tonumber(sortedItems[i].price) or 0
		if itemPrice > playerCoins then
			return sortedItems[i]
		end
	end
	return nil
end

-- FIXED currency formatting to handle numbers properly
function ItemsData:FormatCurrency(amount)
	amount = tonumber(amount)  -- ENSURE NUMBER
	if not amount then
		return "$0"
	end

	amount = math.floor(amount)

	if amount >= 1000000000000 then
		local formatted = amount / 1000000000000
		return string.format(formatted >= 10 and "$%.0fT" or "$%.1fT", formatted)
	elseif amount >= 1000000000 then
		local formatted = amount / 1000000000
		return string.format(formatted >= 10 and "$%.0fB" or "$%.1fB", formatted)
	elseif amount >= 1000000 then
		local formatted = amount / 1000000
		return string.format(formatted >= 10 and "$%.0fM" or "$%.1fM", formatted)
	elseif amount >= 1000 then
		local formatted = amount / 1000
		return string.format(formatted >= 10 and "$%.0fK" or "$%.1fK", formatted)
	else
		return "$" .. tostring(amount)
	end
end

-- Function to check if player can afford an item
function ItemsData:CanAfford(itemName, playerCoins)
	local item = itemByName[itemName]
	playerCoins = tonumber(playerCoins) or 0
	local itemPrice = tonumber(item and item.price) or 0
	return item and playerCoins >= itemPrice or false
end

-- Function to get item stats summary
function ItemsData:GetItemStats(itemName)
	local item = itemByName[itemName]
	if not item then
		return nil
	end

	local stats = {
		name = item.name,
		price = tonumber(item.price) or 0,
		formattedPrice = self:FormatCurrency(item.price),
		tier = item.tier,
		description = item.description
	}

	-- Add specific stats based on item type
	local statFields = {"damage", "range", "cooldown", "special", "speedMultiplier", 
		"jumpPower", "duration", "flightSpeed", "beeCount"}

	for i = 1, #statFields do
		local field = statFields[i]
		if item[field] then
			stats[field] = item[field]
		end
	end

	return stats
end

-- Function to get recommended items for player level
function ItemsData:GetRecommendedItems(playerCoins, playerRebirthLevel)
	local recommended = {}
	playerCoins = tonumber(playerCoins) or 0
	playerRebirthLevel = tonumber(playerRebirthLevel) or 0

	local coinsMultiplier = math.max(1, playerRebirthLevel * 0.5)
	local adjustedBudget = playerCoins * coinsMultiplier

	for i = 1, #self.Items do
		local item = self.Items[i]
		local itemPrice = tonumber(item.price) or 0
		if itemPrice <= adjustedBudget and itemPrice > playerCoins * 0.1 then
			table.insert(recommended, item)
		end
	end

	table.sort(recommended, function(a, b)
		return tonumber(a.price) > tonumber(b.price)
	end)

	local topRecommended = {}
	for i = 1, math.min(3, #recommended) do
		table.insert(topRecommended, recommended[i])
	end

	return topRecommended
end

-- Function to get items sorted by rebirth requirement then by price
function ItemsData:GetItemsSortedByRebirth()
	local items = {}
	for i = 1, #self.Items do
		items[i] = self.Items[i]
	end

	table.sort(items, function(a, b)
		local rebirthA = tonumber(a.rebirth) or 0
		local rebirthB = tonumber(b.rebirth) or 0
		local priceA = tonumber(a.price) or 0
		local priceB = tonumber(b.price) or 0

		if rebirthA == rebirthB then
			return priceA < priceB -- Same rebirth level, sort by price
		end
		return rebirthA < rebirthB -- Different rebirth levels, sort by rebirth
	end)

	return items
end

-- Function to get rebirth requirement for a tool
function ItemsData:GetToolRebirthRequirement(toolName)
	local item = self:GetItemByToolName(toolName)
	return tonumber(item and item.rebirth) or 0  -- ENSURE NUMBER
end

-- Function to get all items with formatted prices
function ItemsData:GetAllItemsFormatted()
	local formattedItems = {}
	for i = 1, #self.Items do
		local item = self.Items[i]
		local newItem = {}
		for key, value in pairs(item) do
			newItem[key] = value
		end
		newItem.formattedPrice = self:FormatCurrency(item.price)
		table.insert(formattedItems, newItem)
	end
	return formattedItems
end

-- Initialize caches when module loads
initializeCaches()

return ItemsData