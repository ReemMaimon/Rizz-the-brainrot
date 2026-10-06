-- Enhanced RebirthData Module - CLEAN VERSION (NO DEPENDENCIES)
-- Place this in ReplicatedStorage > ModuleScripts > RebirthData

local RebirthData = {}

-- Define rebirth rewards for each level with exactly 6 rewards each
RebirthData.Rewards = {
	[1] = {
		{
			type = "multiplier",
			name = "MULTI",
			value = "x0.5",
			description = "0.5X coins from babies",
			image = "rbxassetid://82462348100010",
			multiplier = 0.5
		},
		{
			type = "coins",
			name = "Coins",
			value = "5K",
			description = "Extra 5K coins instantly",
			image = "rbxassetid://82462348100010",
			amount = 5000
		},
		{
			type = "ability",
			name = "LOCK BASE",
			value = "+10 Sec",
			description = "Lock base for 50 seconds instead of 40",
			image = "rbxassetid://83182316838316",
			lockTimeBonus = 10
		},
		{
			type = "tool", 
			name = "IRON SLAP",
			value = "",
			description = "Unlocks Iron Slap tool",
			toolName = "Iron Slap",
			showModel = true
		},
		{
			type = "tool",
			name = "GRAVITY COIL",
			value = "",
			description = "Unlocks Gravity Coil tool",
			toolName = "Gravity Coil",
			showModel = true
		},
		{
			type = "special",
			name = "STARTER BONUS",
			value = "+5% Speed",
			description = "5% movement speed bonus",
			image = "rbxassetid://82462348100010",
			speedBonus = 0.05
		}
	},
	[2] = {
		{
			type = "multiplier",
			name = "MULTI",
			value = "x0.75",
			description = "0.75X coins from babies",
			image = "rbxassetid://82462348100010",
			multiplier = 0.75
		},
		{
			type = "coins",
			name = "Coins",
			value = "15K",
			description = "Extra 15K coins instantly",
			image = "rbxassetid://82462348100010",
			amount = 15000
		},
		{
			type = "ability",
			name = "LOCK BASE",
			value = "+5 Sec",
			description = "Additional 5 seconds lock time",
			image = "rbxassetid://83182316838316",
			lockTimeBonus = 5
		},
		{
			type = "tool",
			name = "SPEED COIL",
			value = "",
			description = "Unlocks Speed Coil tool", 
			toolName = "Speed Coil",
			showModel = true
		},
		{
			type = "tool",
			name = "GOLD SLAP",
			value = "",
			description = "Unlocks Gold Slap tool",
			toolName = "Gold Slap",
			showModel = true
		},
		{
			type = "tool",
			name = "EMERALD SLAP",
			value = "",
			description = "Unlocks Emerald Slap tool",
			toolName = "Emerald Slap", 
			showModel = true
		}
	},
	[3] = {
		{
			type = "multiplier",
			name = "MULTI",
			value = "x1.0",
			description = "1.0X coins from babies",
			image = "rbxassetid://82462348100010",
			multiplier = 1.0
		},
		{
			type = "coins",
			name = "Coins",
			value = "50K",
			description = "Extra 50K coins instantly",
			image = "rbxassetid://82462348100010",
			amount = 50000
		},
		{
			type = "ability",
			name = "LOCK BASE",
			value = "+10 Sec",
			description = "Lock base for 65 seconds total",
			image = "rbxassetid://83182316838316",
			lockTimeBonus = 10
		},
		{
			type = "tool",
			name = "RAGE BAT",
			value = "",
			description = "Unlocks Rage Bat tool",
			toolName = "Rage Bat",
			showModel = true
		},
		{
			type = "tool",
			name = "RUBY SLAP",
			value = "",
			description = "Unlocks Ruby Slap tool",
			toolName = "Ruby Slap",
			showModel = true
		},
		{
			type = "tool",
			name = "INFINITE BAT",
			value = "",
			description = "Unlocks Infinite Bat tool",
			toolName = "Infinite Bat",
			showModel = true
		}
	},
	[4] = {
		{
			type = "multiplier",
			name = "MULTI",
			value = "x1.25",
			description = "1.25X coins from babies",
			image = "rbxassetid://82462348100010",
			multiplier = 1.25
		},
		{
			type = "coins",
			name = "Coins", 
			value = "100K",
			description = "Extra 100K coins instantly",
			image = "rbxassetid://82462348100010",
			amount = 100000
		},
		{
			type = "ability",
			name = "LOCK BASE",
			value = "+10 Sec",
			description = "Lock base for 75 seconds total",
			image = "rbxassetid://83182316838316",
			lockTimeBonus = 10
		},
		{
			type = "tool",
			name = "DIAMOND SLAP",
			value = "",
			description = "Unlocks Diamond Slap tool",
			toolName = "Diamond Slap",
			showModel = true
		},
		{
			type = "tool",
			name = "LAZER GUN",
			value = "",
			description = "Unlocks Lazer Gun tool",
			toolName = "Lazer Gun", 
			showModel = true
		},
		{
			type = "tool",
			name = "BAN HAMMER",
			value = "",
			description = "Unlocks Ban Hammer tool",
			toolName = "Ban Hammer",
			showModel = true
		}
	},
	[5] = {
		{
			type = "multiplier",
			name = "MULTI",
			value = "x1.5",
			description = "1.5X coins from babies",
			image = "rbxassetid://82462348100010",
			multiplier = 1.5
		},
		{
			type = "coins",
			name = "Coins",
			value = "250K", 
			description = "Extra 250K coins instantly",
			image = "rbxassetid://82462348100010",
			amount = 250000
		},
		{
			type = "ability",
			name = "LOCK BASE",
			value = "+15 Sec",
			description = "Lock base for 90 seconds total",
			image = "rbxassetid://83182316838316",
			lockTimeBonus = 15
		},
		{
			type = "tool",
			name = "FLYING CARPET",
			value = "",
			description = "Unlocks Flying Carpet tool",
			toolName = "Flying Carpet",
			showModel = true
		},
		{
			type = "tool",
			name = "BLACKHOLE SLAP",
			value = "",
			description = "Unlocks Blackhole Slap tool",
			toolName = "Blackhole Slap",
			showModel = true
		},
		{
			type = "tool",
			name = "COIL COMBO",
			value = "",
			description = "Unlocks Coil Combo tool",
			toolName = "Coil Combo",
			showModel = true
		}
	},
	[6] = {
		{
			type = "multiplier",
			name = "MULTI",
			value = "x2.0",
			description = "2.0X coins from babies",
			image = "rbxassetid://82462348100010",
			multiplier = 2.0
		},
		{
			type = "coins",
			name = "Coins",
			value = "500K", 
			description = "Extra 500K coins instantly",
			image = "rbxassetid://82462348100010",
			amount = 500000
		},
		{
			type = "ability",
			name = "LOCK BASE",
			value = "+20 Sec",
			description = "Lock base for 110 seconds total",
			image = "rbxassetid://83182316838316",
			lockTimeBonus = 20
		},
		{
			type = "tool",
			name = "BEE LAUNCHER",
			value = "",
			description = "Unlocks Bee Launcher tool",
			toolName = "Bee Launcher",
			showModel = true
		},
		{
			type = "special",
			name = "RAGE MODE",
			value = "2x Damage",
			description = "Double damage when health is low",
			image = "rbxassetid://82462348100010",
			damageMultiplier = 2.0
		},
		{
			type = "special",
			name = "SHIELD BOOST",
			value = "+50% Defense",
			description = "50% damage reduction from attacks",
			image = "rbxassetid://83182316838316",
			defenseBonus = 0.5
		}
	},
	[7] = {
		{
			type = "multiplier",
			name = "MULTI",
			value = "x2.5",
			description = "2.5X coins from babies",
			image = "rbxassetid://82462348100010",
			multiplier = 2.5
		},
		{
			type = "coins",
			name = "Coins",
			value = "1M", 
			description = "Extra 1M coins instantly",
			image = "rbxassetid://82462348100010",
			amount = 1000000
		},
		{
			type = "ability",
			name = "LOCK BASE",
			value = "+25 Sec",
			description = "Lock base for 135 seconds total",
			image = "rbxassetid://83182316838316",
			lockTimeBonus = 25
		},
		{
			type = "coins",
			name = "BONUS COINS",
			value = "500K",
			description = "Extra bonus 500K coins",
			image = "rbxassetid://82462348100010",
			amount = 500000
		},
		{
			type = "special",
			name = "ENERGY BOOST",
			value = "+25% Stamina",
			description = "25% faster stamina regeneration",
			image = "rbxassetid://82462348100010",
			staminaBonus = 0.25
		},
		{
			type = "special",
			name = "LUCKY DROPS",
			value = "+10% Drop Rate",
			description = "10% higher chance for bonus drops",
			image = "rbxassetid://82462348100010",
			dropRateBonus = 0.1
		}
	},
	[8] = {
		{
			type = "multiplier",
			name = "MULTI",
			value = "x3.0",
			description = "3.0X coins from babies",
			image = "rbxassetid://82462348100010",
			multiplier = 3.0
		},
		{
			type = "coins",
			name = "Coins",
			value = "2M", 
			description = "Extra 2M coins instantly",
			image = "rbxassetid://82462348100010",
			amount = 2000000
		},
		{
			type = "ability",
			name = "LOCK BASE",
			value = "+30 Sec",
			description = "Lock base for 165 seconds total",
			image = "rbxassetid://83182316838316",
			lockTimeBonus = 30
		},
		{
			type = "special",
			name = "MASTER THIEF",
			value = "+50% Speed",
			description = "50% faster movement when carrying baby",
			image = "rbxassetid://82462348100010",
			carrySpeedBonus = 0.5
		},
		{
			type = "special",
			name = "IRON WILL",
			value = "Stun Immunity",
			description = "Immune to stun effects for 5 seconds",
			image = "rbxassetid://83182316838316",
			stunImmunity = 5
		},
		{
			type = "special",
			name = "TREASURE HUNTER",
			value = "+20% Coin Find",
			description = "20% more coins from all sources",
			image = "rbxassetid://82462348100010",
			coinBonus = 0.2
		}
	},
	[9] = {
		{
			type = "multiplier",
			name = "MULTI",
			value = "x4.0",
			description = "4.0X coins from babies",
			image = "rbxassetid://82462348100010",
			multiplier = 4.0
		},
		{
			type = "coins",
			name = "Coins",
			value = "5M", 
			description = "Extra 5M coins instantly",
			image = "rbxassetid://82462348100010",
			amount = 5000000
		},
		{
			type = "ability",
			name = "LOCK BASE",
			value = "+35 Sec",
			description = "Lock base for 200 seconds total",
			image = "rbxassetid://83182316838316",
			lockTimeBonus = 35
		},
		{
			type = "special",
			name = "PHANTOM MODE",
			value = "Ghost Form",
			description = "Phase through walls for 3 seconds",
			image = "rbxassetid://82462348100010",
			phaseTime = 3
		},
		{
			type = "special",
			name = "BERSERKER",
			value = "+100% Attack",
			description = "Double attack speed when below 25% health",
			image = "rbxassetid://83182316838316",
			attackSpeedBonus = 1.0
		},
		{
			type = "special",
			name = "FORTUNE FINDER",
			value = "+50% Rare Drops",
			description = "50% higher chance for rare items",
			image = "rbxassetid://82462348100010",
			rareDropBonus = 0.5
		}
	},
	[10] = {
		{
			type = "multiplier",
			name = "MULTI",
			value = "x5.0",
			description = "5.0X coins from babies",
			image = "rbxassetid://82462348100010",
			multiplier = 5.0
		},
		{
			type = "coins",
			name = "Coins",
			value = "10M", 
			description = "Extra 10M coins instantly",
			image = "rbxassetid://82462348100010",
			amount = 10000000
		},
		{
			type = "ability",
			name = "ULTIMATE LOCK",
			value = "+60 Sec",
			description = "Lock base for 260 seconds total - Ultimate Protection",
			image = "rbxassetid://83182316838316",
			lockTimeBonus = 60
		},
		{
			type = "special",
			name = "GODMODE",
			value = "Invincibility",
			description = "10 seconds of complete invincibility",
			image = "rbxassetid://82462348100010",
			invincibilityTime = 10
		},
		{
			type = "special",
			name = "MASTER BUILDER",
			value = "Instant Build",
			description = "Instantly build defenses around base",
			image = "rbxassetid://83182316838316",
			instantBuild = true
		},
		{
			type = "special",
			name = "LEGENDARY AURA",
			value = "Team Boost",
			description = "All nearby players get 25% stat boost",
			image = "rbxassetid://82462348100010",
			teamBonus = 0.25
		}
	}
}

-- Function to get rewards for a specific rebirth level
function RebirthData:GetRewardsForRebirth(rebirthLevel)
	local rewards = self.Rewards[rebirthLevel]
	if rewards then
		return rewards
	else
		return {}
	end
end

-- Function to get all rewards up to a certain rebirth level
function RebirthData:GetAllRewardsUpTo(rebirthLevel)
	local allRewards = {}
	for level = 1, rebirthLevel do
		local rewards = self.Rewards[level]
		if rewards then
			for i = 1, #rewards do
				local reward = rewards[i]
				table.insert(allRewards, {
					level = level,
					reward = reward
				})
			end
		end
	end
	return allRewards
end

-- Function to check if a tool is unlocked at a rebirth level
function RebirthData:IsToolUnlocked(toolName, playerRebirthLevel)
	for level = 1, playerRebirthLevel do
		local rewards = self.Rewards[level]
		if rewards then
			for i = 1, #rewards do
				local reward = rewards[i]
				if reward.type == "tool" and reward.toolName == toolName then
					return true
				end
			end
		end
	end
	return false
end

-- Function to get total coins multiplier from all rebirth levels
function RebirthData:GetTotalCoinsMultiplier(playerRebirthLevel)
	local totalMultiplier = 0
	for level = 1, playerRebirthLevel do
		local rewards = self.Rewards[level]
		if rewards then
			for i = 1, #rewards do
				local reward = rewards[i]
				if reward.type == "multiplier" and reward.multiplier then
					totalMultiplier = totalMultiplier + reward.multiplier
				end
			end
		end
	end
	return totalMultiplier
end

-- Function to get total lock time bonus
function RebirthData:GetTotalLockTimeBonus(playerRebirthLevel)
	local totalBonus = 0
	for level = 1, playerRebirthLevel do
		local rewards = self.Rewards[level]
		if rewards then
			for i = 1, #rewards do
				local reward = rewards[i]
				if reward.type == "ability" and reward.lockTimeBonus then
					totalBonus = totalBonus + reward.lockTimeBonus
				end
			end
		end
	end
	return totalBonus
end

-- Function to get all unlocked tools
function RebirthData:GetUnlockedTools(playerRebirthLevel)
	local unlockedTools = {}
	for level = 1, playerRebirthLevel do
		local rewards = self.Rewards[level]
		if rewards then
			for i = 1, #rewards do
				local reward = rewards[i]
				if reward.type == "tool" and reward.toolName then
					table.insert(unlockedTools, reward.toolName)
				end
			end
		end
	end
	return unlockedTools
end

-- Function to get special abilities
function RebirthData:GetSpecialAbilities(playerRebirthLevel)
	local abilities = {}
	for level = 1, playerRebirthLevel do
		local rewards = self.Rewards[level]
		if rewards then
			for i = 1, #rewards do
				local reward = rewards[i]
				if reward.type == "special" then
					table.insert(abilities, {
						level = level,
						ability = reward
					})
				end
			end
		end
	end
	return abilities
end

-- Function to format currency
function RebirthData:FormatCurrency(amount)
	local num = tonumber(amount)
	if not num then
		return "$0"
	end

	num = math.floor(num)

	if num >= 1000000000000 then
		return string.format("$%.1fT", num / 1000000000000)
	elseif num >= 1000000000 then
		return string.format("$%.1fB", num / 1000000000)
	elseif num >= 1000000 then
		return string.format("$%.1fM", num / 1000000)
	elseif num >= 1000 then
		return string.format("$%.1fK", num / 1000)
	else
		return "$" .. tostring(num)
	end
end

return RebirthData