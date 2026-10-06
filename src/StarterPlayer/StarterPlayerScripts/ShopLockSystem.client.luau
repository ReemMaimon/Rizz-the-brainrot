-- ShopLockSystem LocalScript (Place in StarterGui or StarterPlayerScripts)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for UI elements
local screenGui = playerGui:WaitForChild("MainGui")
local coinsShop = screenGui:WaitForChild("CoinsShop")
local content = coinsShop:WaitForChild("Content")
local items = content:WaitForChild("Items")

-- Wait for RebirthData module
local RebirthData = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("RebirthData"))

-- Tool unlock requirements (rebirth level needed)
local TOOL_UNLOCK_REQUIREMENTS = {
	["Slap"] = 0,           -- Available from start
	["Iron Slap"] = 1,      -- Rebirth 1
	["Speed Coil"] = 2,     -- Rebirth 2  
	["Gravity Coil"] = 1,   -- Rebirth 1
	["Bee Launcher"] = 1,   -- Rebirth 1
	["Coil Combo"] = 2,     -- Rebirth 2
	["Rage Bat"] = 3,       -- Rebirth 3
	["Infinite Bat"] = 5,   -- Rebirth 5
	["Gold Slap"] = 4,      -- Rebirth 4
	["Emerald Slap"] = 3,   -- Rebirth 3
	["Diamond Slap"] = 2,   -- Rebirth 2
	["Ruby Slap"] = 5,      -- Rebirth 5
	["Lazer Gun"] = 4,      -- Rebirth 4
	["Ban Hammer"] = 8,     -- Rebirth 8
	["Blackhole Slap"] = 10 -- Rebirth 10 (max)
}

-- Function to update shop item lock status
local function updateShopItemLocks()
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local rebirthValue = leaderstats:FindFirstChild("Rebirth")
	if not rebirthValue then return end

	local playerRebirth = rebirthValue.Value

	-- Update each tool item in the shop
	for toolName, requiredRebirth in pairs(TOOL_UNLOCK_REQUIREMENTS) do
		local itemFrame = items:FindFirstChild(toolName)
		if itemFrame then
			local lockedFrame = itemFrame:FindFirstChild("Locked")
			if lockedFrame then
				local txt = lockedFrame:FindFirstChild("Txt")

				if playerRebirth >= requiredRebirth then
					-- Player has unlocked this item
					lockedFrame.Visible = false
				else
					-- Item is still locked
					lockedFrame.Visible = true
					if txt then
						txt.Text = "LOCKED BEHIND REBIRTH " .. requiredRebirth
					end
				end
			end
		end
	end
end

-- Function to check if a tool is unlocked
local function isToolUnlocked(toolName)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return false end

	local rebirthValue = leaderstats:FindFirstChild("Rebirth")
	if not rebirthValue then return false end

	local playerRebirth = rebirthValue.Value
	local requiredRebirth = TOOL_UNLOCK_REQUIREMENTS[toolName] or 0

	return playerRebirth >= requiredRebirth
end

-- Update shop locks when rebirth changes
local function onStatsChanged()
	updateShopItemLocks()
end

-- Connect to leaderstats changes
player.ChildAdded:Connect(function(child)
	if child.Name == "leaderstats" then
		local rebirth = child:WaitForChild("Rebirth")
		rebirth.Changed:Connect(onStatsChanged)

		-- Initial update
		updateShopItemLocks()
	end
end)

-- If leaderstats already exists
if player:FindFirstChild("leaderstats") then
	local leaderstats = player.leaderstats
	local rebirth = leaderstats:FindFirstChild("Rebirth")

	if rebirth then 
		rebirth.Changed:Connect(onStatsChanged)
	end

	-- Initial update
	updateShopItemLocks()
end

-- Global function for other scripts to check tool unlocks
_G.IsToolUnlockedInShop = isToolUnlocked

-- Function to add new tool unlock requirement
_G.AddToolUnlockRequirement = function(toolName, rebirthLevel)
	TOOL_UNLOCK_REQUIREMENTS[toolName] = rebirthLevel
	updateShopItemLocks()
end

print("✅ Shop Lock System initialized!")