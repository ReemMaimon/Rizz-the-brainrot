-- GuaranteedDropsAdmin.lua - Place in ServerScriptService > ModuleScripts
-- Admin panel and management tools for guaranteed drops system

local GuaranteedDropsAdmin = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BrainrotConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("BrainrotConfig"))

-- Dependencies (set by main script)
GuaranteedDropsAdmin.GuaranteedDropManager = nil
GuaranteedDropsAdmin.GuaranteedDropUI = nil
GuaranteedDropsAdmin.BabyManager = nil
GuaranteedDropsAdmin.BrainrotConfig = BrainrotConfig
GuaranteedDropsAdmin.serverMessageRemote = nil

-- Admin permissions (add admin userIds here)
local ADMIN_USERS = {
	8103703448
}

-- Admin commands
local ADMIN_COMMANDS = {}

-- Check if player is admin
local function isAdmin(player)
	if not player then return false end

	-- Check if player is in admin list
	for _, adminId in ipairs(ADMIN_USERS) do
		if player.UserId == adminId then
			return true
		end
	end

	-- Check if player is game owner/creator
	if player.UserId == game.CreatorId then
		return true
	end

	-- Check if player has admin pass (if you use one)
	-- Add your admin gamepass check here if needed

	return false
end

-- Send message to admin
local function adminMessage(player, message)
	if GuaranteedDropsAdmin.serverMessageRemote and isAdmin(player) then
		GuaranteedDropsAdmin.serverMessageRemote:FireClient(player, "🔧 ADMIN: " .. message)
	end
end

-- ===========================
-- ADMIN COMMAND FUNCTIONS
-- ===========================

ADMIN_COMMANDS.help = function(player, args)
	local helpText = [[
🔧 GUARANTEED DROPS ADMIN COMMANDS:

/gdrop force [rarity] - Force spawn guaranteed drop
/gdrop status - Show system status  
/gdrop reset - Reset all timers
/gdrop set [rarity] [minutes] - Set interval
/gdrop list - List all babies by rarity
/gdrop validate - Validate configuration
/gdrop stats - Show detailed statistics
/gdrop test [rarity] - Test UI effects
/gdrop reload - Reload UI system
/gdrop intervals - Show current intervals
/gdrop babies - Show baby counts by rarity
/gdrop help - Show this help

RARITIES: Mythic, Youtuber, God
EXAMPLES:
/gdrop force God
/gdrop set Mythic 5
/gdrop test rainbow
]]

	adminMessage(player, helpText)
end

ADMIN_COMMANDS.force = function(player, args)
	local rarity = args[1]
	if not rarity then
		adminMessage(player, "❌ Usage: /gdrop force [Mythic/Youtuber/God]")
		return
	end

	rarity = rarity:gsub("^%l", string.upper) -- Capitalize first letter

	if not GuaranteedDropsAdmin.GuaranteedDropManager then
		adminMessage(player, "❌ GuaranteedDropManager not available")
		return
	end

	local success, message = GuaranteedDropsAdmin.GuaranteedDropManager.forceDrop(rarity)
	if success then
		adminMessage(player, "✅ Forced " .. rarity .. " drop successfully!")
	else
		adminMessage(player, "❌ Failed to force " .. rarity .. " drop: " .. (message or "Unknown error"))
	end
end

ADMIN_COMMANDS.status = function(player, args)
	if not GuaranteedDropsAdmin.GuaranteedDropManager then
		adminMessage(player, "❌ GuaranteedDropManager not available")
		return
	end

	local status = GuaranteedDropsAdmin.GuaranteedDropManager.getStatus()
	local uiStatus = GuaranteedDropsAdmin.GuaranteedDropUI and GuaranteedDropsAdmin.GuaranteedDropUI.getStatus() or {}

	local statusText = string.format([[
📊 GUARANTEED DROPS STATUS:

System: %s
Server Uptime: %.1f minutes

COUNTDOWNS:
🔥 Mythic: %d seconds
⭐ Youtuber: %d seconds  
🌈 God: %d seconds

UI STATUS:
RoadPanel: %s
MainFrame: %s
Labels Found: %d/3

Last Activity: %.1f seconds ago
]], 
		status.initialized and "✅ Active" or "❌ Inactive",
		(status.serverUptime or 0) / 60,
		status.countdowns.Mythic or 0,
		status.countdowns.Youtuber or 0,
		status.countdowns.God or 0,
		uiStatus.roadPanel and "✅" or "❌",
		uiStatus.mainFrame and "✅" or "❌",
		(uiStatus.mythicLabel and 1 or 0) + (uiStatus.youtuberLabel and 1 or 0) + (uiStatus.godLabel and 1 or 0),
		tick() - (status.lastDropTimes and math.max(status.lastDropTimes.Mythic or 0, status.lastDropTimes.Youtuber or 0, status.lastDropTimes.God or 0) or 0)
	)

	adminMessage(player, statusText)
end

ADMIN_COMMANDS.reset = function(player, args)
	if not GuaranteedDropsAdmin.GuaranteedDropManager then
		adminMessage(player, "❌ GuaranteedDropManager not available")
		return
	end

	GuaranteedDropsAdmin.GuaranteedDropManager.resetTimers()
	adminMessage(player, "✅ All guaranteed drop timers have been reset!")
end

ADMIN_COMMANDS.set = function(player, args)
	local rarity = args[1]
	local minutes = tonumber(args[2])

	if not rarity or not minutes then
		adminMessage(player, "❌ Usage: /gdrop set [rarity] [minutes]")
		return
	end

	if minutes < 1 then
		adminMessage(player, "❌ Interval must be at least 1 minute")
		return
	end

	rarity = rarity:gsub("^%l", string.upper)
	local seconds = minutes * 60

	if not GuaranteedDropsAdmin.GuaranteedDropManager then
		adminMessage(player, "❌ GuaranteedDropManager not available")
		return
	end

	local success, message = GuaranteedDropsAdmin.GuaranteedDropManager.setInterval(rarity, seconds)
	if success then
		adminMessage(player, string.format("✅ Set %s interval to %d minutes (%d seconds)", rarity, minutes, seconds))
	else
		adminMessage(player, "❌ Failed to set interval: " .. (message or "Unknown error"))
	end
end

ADMIN_COMMANDS.list = function(player, args)
	local stats = {}
	for _, rarity in ipairs(GuaranteedDropsAdmin.BrainrotConfig.RarityOrder or {}) do
		local names = GuaranteedDropsAdmin.BrainrotConfig.GetBabiesByRarity(rarity)
		stats[rarity] = {valid = #names, total = #names, babies = names}
	end

	local listText = "📋 GUARANTEED BABIES BY RARITY:\n\n"

	for rarity, data in pairs(stats) do
		listText = listText .. string.format("🎯 %s (%d valid / %d total):\n", rarity, data.valid or 0, data.total or 0)

		if data.babies and #data.babies > 0 then
			for i, babyName in ipairs(data.babies) do
				listText = listText .. "  • " .. babyName .. "\n"
				if i >= 10 then -- Limit to first 10 to avoid message overflow
					listText = listText .. "  ... and " .. (#data.babies - 10) .. " more\n"
					break
				end
			end
		else
			listText = listText .. "  (No valid babies found)\n"
		end
		listText = listText .. "\n"
	end

	adminMessage(player, listText)
end

ADMIN_COMMANDS.validate = function(player, args)
	local count = 0
	for _, definition in pairs(GuaranteedDropsAdmin.BrainrotConfig.Definitions or {}) do
		if definition.ModelName and definition.DisplayName then count += 1 end
	end
	adminMessage(player, count > 0 and ("✅ BrainrotConfig is valid (" .. count .. " definitions)!" ) or "❌ BrainrotConfig has no valid definitions")
end

ADMIN_COMMANDS.stats = function(player, args)
	local statsText = "📈 DETAILED STATISTICS:\n\n"

	-- System stats
	if GuaranteedDropsAdmin.GuaranteedDropManager then
		local status = GuaranteedDropsAdmin.GuaranteedDropManager.getStatus()
		local intervals = GuaranteedDropsAdmin.GuaranteedDropManager.getIntervals()

		statsText = statsText .. "⏱️ INTERVALS:\n"
		for rarity, data in pairs(intervals) do
			statsText = statsText .. string.format("  %s: %d min (%d sec)\n", rarity, data.minutes, data.seconds)
		end
		statsText = statsText .. "\n"
	end

	-- Baby spawning stats
	if GuaranteedDropsAdmin.BabyManager and GuaranteedDropsAdmin.BabyManager.getSpawningStatus then
		local spawnStatus = GuaranteedDropsAdmin.BabyManager.getSpawningStatus()
		statsText = statsText .. "🍼 SPAWNING:\n"
		statsText = statsText .. string.format("  Moving Babies: %d\n", spawnStatus.movingBabiesCount or 0)
		statsText = statsText .. string.format("  Last Spawn: %.1fs ago\n", spawnStatus.timeSinceLastSpawn or 0)
		statsText = statsText .. string.format("  Can Spawn: %s\n", spawnStatus.canSpawnNow and "✅" or "❌")
		statsText = statsText .. "\n"
	end

	-- Player count
	local activePlayers = 0
	for _, p in pairs(Players:GetPlayers()) do
		if p:FindFirstChild("OwnedBase") then
			activePlayers = activePlayers + 1
		end
	end
	statsText = statsText .. string.format("👥 PLAYERS:\n  Active: %d / %d total\n", activePlayers, #Players:GetPlayers())

	adminMessage(player, statsText)
end

ADMIN_COMMANDS.test = function(player, args)
	local testType = args[1] or "message"

	if testType == "rainbow" then
		adminMessage(player, "🌈 Testing rainbow effect...")
		if GuaranteedDropsAdmin.serverMessageRemote then
			GuaranteedDropsAdmin.serverMessageRemote:FireClient(player, "🌈 GUARANTEED GOD HAS SPAWNED: TestBaby 🌈")
		end
	elseif testType == "flash" then
		adminMessage(player, "⚡ Testing flash effect...")
		if GuaranteedDropsAdmin.serverMessageRemote then
			GuaranteedDropsAdmin.serverMessageRemote:FireClient(player, "🔥 GUARANTEED MYTHIC HAS SPAWNED: TestBaby 🔥")
		end
	else
		adminMessage(player, "🧪 Testing server message...")
		if GuaranteedDropsAdmin.serverMessageRemote then
			GuaranteedDropsAdmin.serverMessageRemote:FireClient(player, "📢 Test message from admin panel!")
		end
	end
end

ADMIN_COMMANDS.reload = function(player, args)
	adminMessage(player, "🔄 Reloading UI system...")

	if GuaranteedDropsAdmin.GuaranteedDropUI and GuaranteedDropsAdmin.GuaranteedDropUI.reinit then
		local success = GuaranteedDropsAdmin.GuaranteedDropUI.reinit()
		adminMessage(player, success and "✅ UI system reloaded!" or "❌ Failed to reload UI system")
	else
		adminMessage(player, "❌ UI reload function not available")
	end
end

ADMIN_COMMANDS.intervals = function(player, args)
	if not GuaranteedDropsAdmin.GuaranteedDropManager then
		adminMessage(player, "❌ GuaranteedDropManager not available")
		return
	end

	local intervals = GuaranteedDropsAdmin.GuaranteedDropManager.getIntervals()
	local countdowns = GuaranteedDropsAdmin.GuaranteedDropManager.getAllCountdowns()

	local intervalText = "⏰ CURRENT INTERVALS & COUNTDOWNS:\n\n"

	for rarity, data in pairs(intervals) do
		local countdown = countdowns[rarity] or 0
		local nextMinutes = math.floor(countdown / 60)
		local nextSeconds = countdown % 60

		intervalText = intervalText .. string.format(
			"%s:\n  Interval: %d minutes\n  Next Drop: %02d:%02d\n\n",
			rarity, data.minutes, nextMinutes, nextSeconds
		)
	end

	adminMessage(player, intervalText)
end

ADMIN_COMMANDS.babies = function(player, args)
	local stats = {}
	for _, rarity in ipairs(GuaranteedDropsAdmin.BrainrotConfig.RarityOrder or {}) do
		local names = GuaranteedDropsAdmin.BrainrotConfig.GetBabiesByRarity(rarity)
		stats[rarity] = {valid = #names, total = #names}
	end

	local babyText = "🍼 BABY COUNTS BY RARITY:\n\n"

	local totalValid = 0
	local totalConfigured = 0

	for rarity, data in pairs(stats) do
		babyText = babyText .. string.format("%s: %d valid / %d configured\n", rarity, data.valid or 0, data.total or 0)
		totalValid = totalValid + (data.valid or 0)
		totalConfigured = totalConfigured + (data.total or 0)
	end

	babyText = babyText .. string.format("\n📊 TOTALS: %d valid / %d configured", totalValid, totalConfigured)

	if totalValid == 0 then
		babyText = babyText .. "\n\n⚠️ WARNING: No valid guaranteed babies found!"
		babyText = babyText .. "\nCheck your RARITY_BABIES configuration in BabiesData."
	end

	adminMessage(player, babyText)
end

-- ===========================
-- COMMAND PROCESSING
-- ===========================

local function processAdminCommand(player, message)
	if not isAdmin(player) then
		return false
	end

	-- Check if message starts with command prefix
	if not message:lower():find("^/gdrop") then
		return false
	end

	-- Parse command
	local args = {}
	for arg in message:gmatch("%S+") do
		table.insert(args, arg)
	end

	if #args < 2 then
		ADMIN_COMMANDS.help(player, {})
		return true
	end

	local command = args[2]:lower()
	local commandArgs = {}
	for i = 3, #args do
		table.insert(commandArgs, args[i])
	end

	-- Execute command
	if ADMIN_COMMANDS[command] then
		ADMIN_COMMANDS[command](player, commandArgs)
	else
		adminMessage(player, "❌ Unknown command: " .. command .. "\nUse /gdrop help for available commands")
	end

	return true
end

-- ===========================
-- INITIALIZATION
-- ===========================

function GuaranteedDropsAdmin.init()
	-- Connect to chat commands
	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			processAdminCommand(player, message)
		end)
	end)

	-- Connect existing players
	for _, player in pairs(Players:GetPlayers()) do
		player.Chatted:Connect(function(message)
			processAdminCommand(player, message)
		end)
	end

	print("✅ GuaranteedDropsAdmin initialized")
	print("🔧 Admin commands available with /gdrop [command]")
	return true
end

-- Add admin user function
function GuaranteedDropsAdmin.addAdmin(userId)
	table.insert(ADMIN_USERS, userId)
	print("👑 Added admin: " .. userId)
end

-- Remove admin user function  
function GuaranteedDropsAdmin.removeAdmin(userId)
	for i, adminId in ipairs(ADMIN_USERS) do
		if adminId == userId then
			table.remove(ADMIN_USERS, i)
			print("👑 Removed admin: " .. userId)
			return true
		end
	end
	return false
end

-- Get admin list
function GuaranteedDropsAdmin.getAdmins()
	return ADMIN_USERS
end

-- Global admin functions
_G.AddGuaranteedAdmin = GuaranteedDropsAdmin.addAdmin
_G.RemoveGuaranteedAdmin = GuaranteedDropsAdmin.removeAdmin  
_G.GetGuaranteedAdmins = GuaranteedDropsAdmin.getAdmins

return GuaranteedDropsAdmin