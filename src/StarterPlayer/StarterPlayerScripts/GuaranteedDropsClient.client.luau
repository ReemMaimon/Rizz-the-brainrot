-- Client compatibility facade backed by BrainrotConfig
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BrainrotConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("BrainrotConfig"))
local BabiesData = {}

-- ================================
-- CONFIGURATION SETTINGS
-- ================================

BabiesData.Config = {
	STEAL_HOLD_DURATION = 1.5,
	PURCHASE_HOLD_DURATION = 0.7,
	SELL_HOLD_DURATION = 1.2,
	STEALING_ANIMATION_ID = "rbxassetid://70837675618257",
	SELL_PRICE_MULTIPLIER = 0.5  -- 50% of base price when selling
}

-- ================================
-- GUARANTEED DROP SYSTEM (INTEGRATED WITH NEW TIMER SYSTEM)
-- ================================

BabiesData.GuaranteedDrops = {
	MYTHIC_INTERVAL = 600,    -- 10 minutes (600 seconds)
	YOUTUBER_INTERVAL = 1800, -- 30 minutes (1800 seconds)
	GOD_INTERVAL = 3600,      -- 1 hour (3600 seconds)

	-- Server-wide timestamps (shared across all players)
	serverStartTime = tick(),
	lastMythicDrop = 0,
	lastYoutuberDrop = 0,
	lastGodDrop = 0
}

-- ================================
-- RARITY MAPPING FOR GUARANTEED DROPS
-- ================================

BabiesData.RARITY_BABIES = {
	Mythic = {
		"Baby_Steve",
		"Baby_Yoda", 
		"Baby_PeppaPig",
		"Baby_Skibidi_ElonMusk"
	},
	Youtuber = {
		"KreekCraft",
		"Preston"
	},
	God = {
		"Baby_God",
		"David_Baszucki"
	}
}

-- ================================
-- BABY DATABASE (YOUR EXISTING DATA)
-- ================================

BabiesData.Babies = {}
for _, definition in pairs(BrainrotConfig.Definitions or {}) do
	BabiesData.Babies[definition.ModelName or definition.BrainrotId] = {
		price = definition.Price,
		perSec = definition.IncomePerSecond or definition.PerSec or 0,
		displayName = definition.DisplayName,
		rarity = definition.Rarity,
		spawnWeight = definition.SpawnChance,
		generation = definition.IncomePerSecond or 0,
	}
end

-- Legacy inline entries are intentionally not used.
if false then
BabiesData.Babies = {

	-- COMMON BABIES (40% total)
	Baby_Noob = {
		price = 25,
		perSec = 3,
		displayName = "Baby Noob",
		rarity = "Common",
		spawnWeight = 15
	},

	Bacon_Girl = {
		price = 100,
		perSec = 6,
		displayName = "Bacon Girl",
		rarity = "Common",
		spawnWeight = 12
	},

	Baby_Crying = {
		price = 150,
		perSec = 8,
		displayName = "Baby Crying",
		rarity = "Common",
		spawnWeight = 10
	},

	Baby_Bacon = {
		price = 500,
		perSec = 15,
		displayName = "Baby Bacon",
		rarity = "Common",
		spawnWeight = 3
	},

	-- RARE BABIES (30% total)
	Baby_Boss = {
		price = 1250,
		perSec = 28,
		displayName = "Baby Boss",
		rarity = "Rare",
		spawnWeight = 10
	},

	Baby_GrannyBoss = {
		price = 2750,
		perSec = 40,
		displayName = "Granny Boss",
		rarity = "Rare",
		spawnWeight = 8
	},

	Baby_Crawling_Baby = {
		price = 5000,
		perSec = 60,
		displayName = "Baby Crawling",
		rarity = "Rare",
		spawnWeight = 7
	},

	Baby_Shrex = {
		price = 12000,
		perSec = 100,
		displayName = "Baby Shrex",
		rarity = "Rare",
		spawnWeight = 5
	},

	-- EPIC BABIES (20% total)
	BuilderMan = {
		price = 25000,
		perSec = 150,
		displayName = "BuilderMan",
		rarity = "Epic",
		spawnWeight = 8
	},

	Pizza_Boy = {
		price = 38000,
		perSec = 190,
		displayName = "Pizza Boy",
		rarity = "Epic",
		spawnWeight = 6
	},

	Baby_Obama = {
		price = 80000,
		perSec = 270,
		displayName = "Baby Obama",
		rarity = "Epic",
		spawnWeight = 4
	},

	Baby_Skibidi = {
		price = 50000,
		perSec = 220,
		displayName = "Skibidi Toilet",
		rarity = "Epic",
		spawnWeight = 2
	},

	-- MYTHIC BABIES (7% total) - Previously Legendary
	Baby_Steve = {
		price = 250000,
		perSec = 500,
		displayName = "Baby Steve",
		rarity = "Mythic",
		spawnWeight = 3
	},

	Baby_Yoda = {
		price = 300000,
		perSec = 600,
		displayName = "Baby Yoda",
		rarity = "Mythic",
		spawnWeight = 2
	},

	Baby_PeppaPig = {
		price = 500000,
		perSec = 800,
		displayName = "KreekCraft Favorite Pig",
		rarity = "Mythic",
		spawnWeight = 1.5
	},

	Baby_Skibidi_ElonMusk = {
		price = 150000,
		perSec = 350,
		displayName = "Skibidi Elon Musk",
		rarity = "Mythic",
		spawnWeight = 0.5
	},

	-- LEGENDARY BABIES (2.5% total) - Previously BABIES KING
	Baby_Flamingo = {
		price = 5000000,
		perSec = 3000,
		displayName = "Baby Flamingo",
		rarity = "Legendary",
		spawnWeight = 1.2
	},

	Jandel = {
		price = 25000000,
		perSec = 7500,
		displayName = "Baby Jandel",
		rarity = "Legendary",
		spawnWeight = 0.8
	},

	MrBeaset_Daddy = {
		price = 50000000,
		perSec = 10000,
		displayName = "MrBeast Daddy",
		rarity = "Legendary",
		spawnWeight = 0.5
	},

	-- YOUTUBER BABIES (0.4% total)
	KreekCraft = {
		price = 1000000,
		perSec = 1200,
		displayName = "KreekCraft",
		rarity = "Youtuber",
		spawnWeight = 0.3
	},

	Preston = {
		price = 10000000,
		perSec = 5000,
		displayName = "Baby Preston",
		rarity = "Youtuber",
		spawnWeight = 0.1
	},

	-- GOD BABIES (0.1% total)
	Baby_God = {
		price = 100000000,
		perSec = 15000,
		displayName = "Baby God",
		rarity = "God",
		spawnWeight = 0.08
	},

	David_Baszucki = {
		price = 1000000000,
		perSec = 30000,
		displayName = "David Baszucki",
		rarity = "God",
		spawnWeight = 0.02
	},
}

-- ================================
-- RARITY SYSTEM (UPDATED FOR NEW SYSTEM)
-- ================================

BabiesData.RarityInfo = {
	Common = {
		color = Color3.fromRGB(169, 169, 169),
		textColor = Color3.fromRGB(169, 169, 169),
		displayName = "Common",
		guaranteedColor = "#A9A9A9"
	},
	Rare = {
		color = Color3.fromRGB(0, 179, 255),
		textColor = Color3.fromRGB(0, 150, 220),
		displayName = "Rare",
		guaranteedColor = "#00B3FF"
	},
	Epic = {
		color = Color3.fromRGB(128, 0, 255),
		textColor = Color3.fromRGB(100, 0, 200),
		displayName = "Epic",
		guaranteedColor = "#8000FF"
	},
	Mythic = {
		color = Color3.fromRGB(139, 0, 139),  -- Dark Magenta (red-purple)
		textColor = Color3.fromRGB(139, 0, 139),
		displayName = "Mythic",
		guaranteedColor = "#8B008B"  -- Red purple for UI
	},
	Legendary = {
		color = Color3.fromRGB(255, 215, 0),
		textColor = Color3.fromRGB(220, 190, 0),
		displayName = "Legendary",
		guaranteedColor = "#FFD700"
	},
	Youtuber = {
		color = Color3.fromRGB(255, 107, 107),  -- Light red-pink (red-white mix)
		textColor = Color3.fromRGB(255, 107, 107),
		displayName = "Youtuber",
		guaranteedColor = "#FF6B6B",  -- Red-white mix for UI
		strokeColor = Color3.fromRGB(255, 255, 255) -- White stroke
	},
	God = {
		color = Color3.fromRGB(255, 255, 255),
		textColor = Color3.fromRGB(255, 255, 255),
		displayName = "God",
		isRainbow = true,
		guaranteedColor = "rainbow"  -- Rainbow for UI
	}
}

-- ================================
-- NEW GUARANTEED DROP FUNCTIONS (FOR NEW SYSTEM)
-- ================================

-- Function to get babies by rarity (required by new system)
function BabiesData.getBabiesByRarity(rarity)
	local babies = {}

	-- First check our RARITY_BABIES mapping (for guaranteed drops)
	if BabiesData.RARITY_BABIES[rarity] then
		for _, babyName in ipairs(BabiesData.RARITY_BABIES[rarity]) do
			-- Verify baby exists and has data
			local babyData = BabiesData.getBabyData(babyName)
			local spawnWeight = BabiesData.BabyRarities[babyName]

			if babyData and spawnWeight then
				table.insert(babies, babyName)
			end
		end
		return babies
	end

	-- Fallback: search all babies with matching rarity
	for babyName, data in pairs(BabiesData.Babies) do
		if data.rarity == rarity then
			table.insert(babies, babyName)
		end
	end

	return babies
end

-- Function to get all babies in guaranteed drop categories
function BabiesData.getAllGuaranteedBabies()
	local allBabies = {}

	for rarity, babies in pairs(BabiesData.RARITY_BABIES) do
		allBabies[rarity] = {}
		for _, babyName in ipairs(babies) do
			local babyData = BabiesData.getBabyData(babyName)
			if babyData then
				table.insert(allBabies[rarity], {
					name = babyName,
					data = babyData
				})
			end
		end
	end

	return allBabies
end

-- Function to check if a baby is in guaranteed drop categories
function BabiesData.isGuaranteedBaby(babyName)
	for rarity, babies in pairs(BabiesData.RARITY_BABIES) do
		for _, name in ipairs(babies) do
			if name == babyName then
				return true, rarity
			end
		end
	end
	return false, nil
end

-- Function to get guaranteed drop statistics
function BabiesData.getGuaranteedStats()
	local stats = {}

	for rarity, babies in pairs(BabiesData.RARITY_BABIES) do
		local validBabies = BabiesData.getBabiesByRarity(rarity)
		stats[rarity] = {
			total = #babies,
			valid = #validBabies,
			babies = validBabies
		}
	end

	return stats
end

-- Enhanced rarity info with guaranteed drop support
function BabiesData.getGuaranteedRarityInfo(rarity)
	return BabiesData.RarityInfo[rarity]
end

-- Function to apply enhanced rarity effects for guaranteed drops
function BabiesData.applyGuaranteedRarityEffects(textLabel, rarity)
	local rarityInfo = BabiesData.RarityInfo[rarity]
	if not rarityInfo then
		-- Fall back to normal rarity effects
		BabiesData.applyRarityEffects(textLabel, rarity)
		return
	end

	-- Apply enhanced effects for guaranteed rarities
	if rarity == "God" and rarityInfo.isRainbow then
		-- God babies get rainbow text effect via RichText (handled by UI system)
		textLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold base
		textLabel.RichText = true

		-- Apply rainbow animation
		BabiesData.createRainbowEffect(textLabel)

	elseif rarity == "Youtuber" then
		-- Youtuber babies get red-white gradient effect
		textLabel.TextColor3 = rarityInfo.color

		local uiStroke = textLabel:FindFirstChild("UIStroke")
		if not uiStroke then
			uiStroke = Instance.new("UIStroke")
			uiStroke.Parent = textLabel
		end

		uiStroke.Thickness = 1.5
		uiStroke.Color = Color3.fromRGB(255, 255, 255) -- White stroke

	elseif rarity == "Mythic" then
		-- Mythic babies get dark magenta with purple stroke
		textLabel.TextColor3 = rarityInfo.color

		local uiStroke = textLabel:FindFirstChild("UIStroke")
		if not uiStroke then
			uiStroke = Instance.new("UIStroke")
			uiStroke.Parent = textLabel
		end

		uiStroke.Thickness = 1.5
		uiStroke.Color = Color3.fromRGB(128, 0, 128) -- Purple stroke
	end
end

-- Admin function to add baby to guaranteed category
function BabiesData.addBabyToGuaranteed(babyName, rarity)
	if not BabiesData.RARITY_BABIES[rarity] then
		return false, "Invalid rarity"
	end

	-- Check if baby exists and has data
	local babyData = BabiesData.getBabyData(babyName)
	if not babyData then
		return false, "Baby data not found"
	end

	-- Check if already in this category
	for _, name in ipairs(BabiesData.RARITY_BABIES[rarity]) do
		if name == babyName then
			return false, "Baby already in this category"
		end
	end

	-- Add to category
	table.insert(BabiesData.RARITY_BABIES[rarity], babyName)
	return true, "Baby added to " .. rarity .. " category"
end

-- Admin function to remove baby from guaranteed category
function BabiesData.removeBabyFromGuaranteed(babyName, rarity)
	if not BabiesData.RARITY_BABIES[rarity] then
		return false, "Invalid rarity"
	end

	for i, name in ipairs(BabiesData.RARITY_BABIES[rarity]) do
		if name == babyName then
			table.remove(BabiesData.RARITY_BABIES[rarity], i)
			return true, "Baby removed from " .. rarity .. " category"
		end
	end

	return false, "Baby not found in " .. rarity .. " category"
end

-- Validation function
function BabiesData.validateGuaranteedSetup()
	local issues = {}
	local totalGuaranteed = 0

	for rarity, babies in pairs(BabiesData.RARITY_BABIES) do
		print("Validating " .. rarity .. " babies...")

		for _, babyName in ipairs(babies) do
			-- Check if baby exists in data
			local babyData = BabiesData.getBabyData(babyName)
			if not babyData then
				table.insert(issues, "❌ " .. rarity .. " baby '" .. babyName .. "' has no data in BabiesData")
			end

			-- Check if baby has spawn weight
			local spawnWeight = BabiesData.BabyRarities[babyName]
			if not spawnWeight then
				table.insert(issues, "⚠️ " .. rarity .. " baby '" .. babyName .. "' has no spawn weight in BabyRarities")
			end
		end

		totalGuaranteed = totalGuaranteed + #babies
		print("✅ " .. #babies .. " " .. rarity .. " babies configured")
	end

	print("\n=== VALIDATION SUMMARY ===")
	print("Total guaranteed babies: " .. totalGuaranteed)
	print("Issues found: " .. #issues)

	if #issues > 0 then
		print("\n=== ISSUES TO FIX ===")
		for _, issue in ipairs(issues) do
			print(issue)
		end
		return false
	else
		print("✅ ALL GUARANTEED BABIES VALIDATED SUCCESSFULLY!")
		return true
	end
end

-- ================================
-- LEGACY GUARANTEED DROP FUNCTIONS (KEEP FOR COMPATIBILITY)
-- ================================

function BabiesData.initializeGuaranteedDrops()
	-- Initialize server start time if not already set
	if not BabiesData.GuaranteedDrops.serverStartTime then
		BabiesData.GuaranteedDrops.serverStartTime = tick()
	end

	-- Set initial drop times based on server start
	local startTime = BabiesData.GuaranteedDrops.serverStartTime
	BabiesData.GuaranteedDrops.lastMythicDrop = startTime
	BabiesData.GuaranteedDrops.lastYoutuberDrop = startTime
	BabiesData.GuaranteedDrops.lastGodDrop = startTime
end

function BabiesData.getGuaranteedDrop()
	local currentTime = tick()

	-- Check God drop (highest priority)
	if currentTime - BabiesData.GuaranteedDrops.lastGodDrop >= BabiesData.GuaranteedDrops.GOD_INTERVAL then
		BabiesData.GuaranteedDrops.lastGodDrop = currentTime
		local godBabies = BabiesData.getBabiesByRarity("God")
		if #godBabies > 0 then
			return godBabies[math.random(1, #godBabies)], "God"
		end
	end

	-- Check Youtuber drop
	if currentTime - BabiesData.GuaranteedDrops.lastYoutuberDrop >= BabiesData.GuaranteedDrops.YOUTUBER_INTERVAL then
		BabiesData.GuaranteedDrops.lastYoutuberDrop = currentTime
		local youtuberBabies = BabiesData.getBabiesByRarity("Youtuber")
		if #youtuberBabies > 0 then
			return youtuberBabies[math.random(1, #youtuberBabies)], "Youtuber"
		end
	end

	-- Check Mythic drop
	if currentTime - BabiesData.GuaranteedDrops.lastMythicDrop >= BabiesData.GuaranteedDrops.MYTHIC_INTERVAL then
		BabiesData.GuaranteedDrops.lastMythicDrop = currentTime
		local mythicBabies = BabiesData.getBabiesByRarity("Mythic")
		if #mythicBabies > 0 then
			return mythicBabies[math.random(1, #mythicBabies)], "Mythic"
		end
	end

	return nil, nil
end

function BabiesData.getNextGuaranteedDropInfo()
	local currentTime = tick()
	local nextDrops = {
		{
			rarity = "Mythic",
			timeLeft = BabiesData.GuaranteedDrops.MYTHIC_INTERVAL - (currentTime - BabiesData.GuaranteedDrops.lastMythicDrop),
			color = BabiesData.RarityInfo.Mythic.guaranteedColor
		},
		{
			rarity = "Youtuber", 
			timeLeft = BabiesData.GuaranteedDrops.YOUTUBER_INTERVAL - (currentTime - BabiesData.GuaranteedDrops.lastYoutuberDrop),
			color = BabiesData.RarityInfo.Youtuber.guaranteedColor
		},
		{
			rarity = "God",
			timeLeft = BabiesData.GuaranteedDrops.GOD_INTERVAL - (currentTime - BabiesData.GuaranteedDrops.lastGodDrop),
			color = BabiesData.RarityInfo.God.guaranteedColor
		}
	}

	-- Sort by shortest time
	table.sort(nextDrops, function(a, b) return a.timeLeft < b.timeLeft end)

	return nextDrops[1] -- Return the next guaranteed drop
end

function BabiesData.getAllGuaranteedDropInfo()
	local currentTime = tick()
	return {
		{
			rarity = "Mythic",
			timeLeft = BabiesData.GuaranteedDrops.MYTHIC_INTERVAL - (currentTime - BabiesData.GuaranteedDrops.lastMythicDrop),
			color = BabiesData.RarityInfo.Mythic.guaranteedColor
		},
		{
			rarity = "Youtuber", 
			timeLeft = BabiesData.GuaranteedDrops.YOUTUBER_INTERVAL - (currentTime - BabiesData.GuaranteedDrops.lastYoutuberDrop),
			color = BabiesData.RarityInfo.Youtuber.guaranteedColor
		},
		{
			rarity = "God",
			timeLeft = BabiesData.GuaranteedDrops.GOD_INTERVAL - (currentTime - BabiesData.GuaranteedDrops.lastGodDrop),
			color = BabiesData.RarityInfo.God.guaranteedColor
		}
	}
end

function BabiesData.formatTimeLeft(seconds)
	if seconds <= 0 then return "00:00" end

	local minutes = math.floor(seconds / 60)
	local secs = math.floor(seconds % 60)

	return string.format("%02d:%02d", minutes, secs)
end

-- ================================
-- AUTO-GENERATED DATA
-- ================================

-- Auto-generate spawn weights table
BabiesData.BabyRarities = {}
for babyName, data in pairs(BabiesData.Babies) do
	if data and type(data.spawnWeight) == "number" then
		BabiesData.BabyRarities[babyName] = data.spawnWeight
	end
end

-- Auto-generate baby stats table (for backwards compatibility)
BabiesData.BabyStats = {}
for babyName, data in pairs(BabiesData.Babies) do
	if data then
		BabiesData.BabyStats[babyName] = {
			price = data.price,
			perSec = data.perSec,
			displayName = data.displayName,
			rarity = data.rarity
		}
	end
end

-- Auto-generate rarity odds (1/X format)
BabiesData.RarityOdds = {}
local totalWeight = 0
for _, data in pairs(BabiesData.Babies) do
	if data and type(data.spawnWeight) == "number" then
		totalWeight = totalWeight + data.spawnWeight
	end
end

for babyName, data in pairs(BabiesData.Babies) do
	if data and type(data.spawnWeight) == "number" and totalWeight > 0 then
		local odds = math.floor(totalWeight / data.spawnWeight)
		BabiesData.RarityOdds[babyName] = odds
	end
end

-- ================================
-- LABEL CUSTOMIZATION HELPERS (UPDATED FOR WHITE NAMES)
-- ================================

function BabiesData.getLabelCustomization(babyName)
	local babyData = BabiesData.getBabyData(babyName)
	local rarity = babyData and babyData.rarity or "Common"
	local rarityInfo = BabiesData.RarityInfo[rarity]

	-- ALWAYS USE WHITE FOR BABY NAMES
	return {
		nameLabel = {
			textColor = Color3.fromRGB(255, 255, 255), -- WHITE
			isRainbow = false
		},
		rarityLabel = {
			textColor = rarityInfo and rarityInfo.textColor or Color3.fromRGB(200, 200, 200),
			isRainbow = (rarity == "God") and true or false
		}
	}
end

function BabiesData.getNameLabelSettings(babyName)
	local babyData = BabiesData.getBabyData(babyName)

	local displayName = babyName:gsub("_", " ")
	if babyData and babyData.displayName then
		displayName = babyData.displayName
	end

	return {
		text = displayName,
		textColor = Color3.fromRGB(255, 255, 255), -- ALWAYS WHITE for display names
		isRainbow = false -- NEVER RAINBOW for display names
	}
end

function BabiesData.getRarityLabelSettings(babyName)
	local customization = BabiesData.getLabelCustomization(babyName)
	local rarityOdds = BabiesData.getRarityOdds(babyName) or 100

	return {
		text = ("1/" .. tostring(rarityOdds)),
		textColor = customization.rarityLabel.textColor,
		isRainbow = customization.rarityLabel.isRainbow or false
	}
end

-- ================================
-- EASY CUSTOMIZATION HELPERS
-- ================================

function BabiesData.addBaby(name, price, perSec, displayName, rarity, spawnWeight)
	BabiesData.Babies[name] = {
		price = price,
		perSec = perSec,
		displayName = displayName,
		rarity = rarity,
		spawnWeight = spawnWeight
	}
	BabiesData.refreshData()
end

function BabiesData.modifyBaby(name, newData)
	if BabiesData.Babies[name] then
		for key, value in pairs(newData) do
			BabiesData.Babies[name][key] = value
		end
		BabiesData.refreshData()
	end
end

function BabiesData.refreshData()
	BabiesData.BabyRarities = {}
	for babyName, data in pairs(BabiesData.Babies) do
		if data and type(data.spawnWeight) == "number" then
			BabiesData.BabyRarities[babyName] = data.spawnWeight
		end
	end

	BabiesData.BabyStats = {}
	for babyName, data in pairs(BabiesData.Babies) do
		if data then
			BabiesData.BabyStats[babyName] = {
				price = data.price,
				perSec = data.perSec,
				displayName = data.displayName,
				rarity = data.rarity
			}
		end
	end

	BabiesData.RarityOdds = {}
	local totalWeight = 0
	for _, data in pairs(BabiesData.Babies) do
		if data and type(data.spawnWeight) == "number" then
			totalWeight = totalWeight + data.spawnWeight
		end
	end

	for babyName, data in pairs(BabiesData.Babies) do
		if data and type(data.spawnWeight) == "number" and totalWeight > 0 then
			local odds = math.floor(totalWeight / data.spawnWeight)
			BabiesData.RarityOdds[babyName] = odds
		end
	end
end

-- ================================
-- CURRENCY FORMATTING (REDUCED TO SP MAX)
-- ================================

local currencySuffixes = {
	{1e24, "Sp"},
	{1e21, "Sx"},
	{1e18, "Qi"},
	{1e15, "Q"},
	{1e12, "T"},
	{1e9, "B"},
	{1e6, "M"},
	{1e3, "k"}
}

-- ================================
-- UTILITY FUNCTIONS
-- ================================

function BabiesData.formatCurrency(amount)
	if type(amount) ~= "number" then
		amount = tonumber(amount) or 0
	end

	if amount < 1000 then
		return "$" .. tostring(math.floor(amount))
	end

	for _, suffix in ipairs(currencySuffixes) do
		local threshold = suffix[1]
		local label = suffix[2]
		if amount >= threshold then
			local value = amount / threshold
			if value >= 100 then
				return string.format("$%.0f%s", value, label)
			elseif value >= 10 then
				return string.format("$%.1f%s", value, label)
			else
				return string.format("$%.2f%s", value, label)
			end
		end
	end
	return "$" .. tostring(math.floor(amount))
end

function BabiesData.formatPerSec(amount)
	if type(amount) ~= "number" then
		amount = tonumber(amount) or 0
	end

	if amount < 1 then
		return string.format("+%.2f/s", amount)
	elseif amount < 1000 then
		if amount == math.floor(amount) then
			return string.format("+%.0f/s", amount)
		else
			return string.format("+%.1f/s", amount)
		end
	end

	for _, suffix in ipairs(currencySuffixes) do
		local threshold = suffix[1]
		local label = suffix[2]
		if amount >= threshold then
			local value = amount / threshold
			if value >= 100 then
				return string.format("+%.0f%s/s", value, label)
			elseif value >= 10 then
				return string.format("+%.1f%s/s", value, label)
			else
				return string.format("+%.2f%s/s", value, label)
			end
		end
	end
	return string.format("+%.0f/s", amount)
end

function BabiesData.getBabyData(babyName)
	return BabiesData.Babies[babyName] or BabiesData.BabyStats[babyName]
end

function BabiesData.getRarityInfo(rarityName)
	return BabiesData.RarityInfo[rarityName]
end

function BabiesData.getBabyRarity(babyName)
	local babyData = BabiesData.getBabyData(babyName)
	return babyData and babyData.rarity or "Common"
end

function BabiesData.getRarityOdds(babyName)
	return BabiesData.RarityOdds[babyName] or 999
end

function BabiesData.getSellPrice(babyName)
	local babyData = BabiesData.getBabyData(babyName)
	if babyData and type(babyData.price) == "number" then
		return math.floor(babyData.price * BabiesData.Config.SELL_PRICE_MULTIPLIER)
	end
	return 0
end

function BabiesData.getHoldDuration(actionType)
	if actionType == "steal" then
		return BabiesData.Config.STEAL_HOLD_DURATION
	elseif actionType == "purchase" then
		return BabiesData.Config.PURCHASE_HOLD_DURATION
	elseif actionType == "sell" then
		return BabiesData.Config.SELL_HOLD_DURATION
	else
		return 1.0
	end
end

function BabiesData.createRainbowEffect(textLabel)
	if not textLabel then return end
	local RunService = game:GetService("RunService")
	local connection = RunService.Heartbeat:Connect(function()
		if not textLabel or not textLabel.Parent then
			if connection then
				connection:Disconnect()
			end
			return
		end
		local time = tick() * 2
		local hue = (time % 6) / 6
		textLabel.TextColor3 = Color3.fromHSV(hue, 1, 1)
	end)
	return connection
end

function BabiesData.applyRarityEffects(textLabel, rarity, isDisplayName)
	if not textLabel or not rarity then return end

	local rarityInfo = BabiesData.RarityInfo[rarity]
	if not rarityInfo then return end

	-- Check if this is a display name (baby name) vs rarity label
	if isDisplayName or textLabel.Name == "Name" or textLabel.Name == "NameLabel" then
		-- For display names (baby names): ALWAYS WHITE
		textLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- WHITE
		textLabel.RichText = false -- No rich text for names
		return -- Exit early to prevent any effects on display names
	end

	-- For rarity labels: Apply normal rarity colors and effects
	textLabel.TextColor3 = rarityInfo.textColor

	-- Apply special effects based on rarity (only for rarity labels)
	if rarity == "Youtuber" and rarityInfo.strokeColor then
		-- Create white stroke for Youtuber
		local uiStroke = textLabel:FindFirstChild("UIStroke")
		if not uiStroke then
			uiStroke = Instance.new("UIStroke")
			uiStroke.Parent = textLabel
		end
		uiStroke.Color = rarityInfo.strokeColor
		uiStroke.Thickness = 2
		uiStroke.Transparency = 0
	elseif rarity == "God" and rarityInfo.isRainbow then
		-- Apply rainbow effect for God (only for rarity labels)
		BabiesData.createRainbowEffect(textLabel)
	end
end

-- ================================
-- GLOBAL TESTING FUNCTIONS
-- ================================

-- Global functions for testing the guaranteed drop system
_G.PrintBabyNames = function()
	print("=== ALL BABY NAMES IN BABIES DATA ===")
	local babyNames = {}
	for babyName, _ in pairs(BabiesData.Babies) do
		table.insert(babyNames, babyName)
	end

	table.sort(babyNames) -- Sort alphabetically

	for i, name in ipairs(babyNames) do
		print(i .. ". " .. name)
	end

	print("=== TOTAL: " .. #babyNames .. " babies ===")
	return babyNames
end

_G.ValidateRaritySetup = BabiesData.validateGuaranteedSetup

-- Initialize guaranteed drops when module loads
BabiesData.initializeGuaranteedDrops()

return BabiesData