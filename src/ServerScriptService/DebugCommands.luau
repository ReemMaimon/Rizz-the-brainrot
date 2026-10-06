-- ServerScriptService > DebugCommands.lua
-- Debug commands for testing guaranteed drop system

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for dependencies
local BabiesData = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("BabiesData"))

-- ================================
-- GLOBAL DEBUG FUNCTIONS
-- ================================

-- Force spawn a guaranteed drop of specific rarity
_G.ForceGuaranteedDrop = function(rarityType)
	if not rarityType then
		print("Usage: _G.ForceGuaranteedDrop('Mythic'), _G.ForceGuaranteedDrop('Youtuber'), or _G.ForceGuaranteedDrop('God')")
		return
	end

	local validRarities = {"Mythic", "Youtuber", "God"}
	local isValid = false
	for _, valid in ipairs(validRarities) do
		if rarityType == valid then
			isValid = true
			break
		end
	end

	if not isValid then
		print("❌ Invalid rarity type. Use: Mythic, Youtuber, or God")
		return
	end

	-- Get babies of specified rarity
	local babies = BabiesData.getBabiesByRarity(rarityType)
	if #babies == 0 then
		print("❌ No babies found for rarity:", rarityType)
		return
	end

	-- Select random baby
	local selectedBaby = babies[math.random(1, #babies)]

	-- Force spawn using BabyManager
	if _G.BabyManager and _G.BabyManager.spawnGuaranteedBaby then
		local spawnedBaby = _G.BabyManager.spawnGuaranteedBaby(selectedBaby, rarityType)
		if spawnedBaby then
			print("✅ Force spawned guaranteed " .. rarityType .. ": " .. selectedBaby)

			-- Send message to all players
			for _, player in pairs(Players:GetPlayers()) do
				if _G.SendServerMessage then
					_G.SendServerMessage(player, "🌟 GUARANTEED " .. rarityType:upper() .. " HAS SPAWNED! 🌟")
				end
			end

			return spawnedBaby
		else
			print("❌ Failed to spawn guaranteed baby")
		end
	else
		print("❌ BabyManager not available")
	end
end

-- Get current guaranteed drop status
_G.GetGuaranteedDropStatus = function()
	local status = {
		currentTime = tick(),
		nextDrops = {},
		serverInfo = {}
	}

	-- Get all guaranteed drop info
	local allDrops = BabiesData.getAllGuaranteedDropInfo()
	for _, drop in ipairs(allDrops) do
		table.insert(status.nextDrops, {
			rarity = drop.rarity,
			timeLeft = drop.timeLeft,
			timeString = BabiesData.formatTimeLeft(drop.timeLeft),
			color = drop.color
		})
	end

	-- Get server info
	status.serverInfo = {
		serverStartTime = BabiesData.GuaranteedDrops.serverStartTime,
		lastMythicDrop = BabiesData.GuaranteedDrops.lastMythicDrop,
		lastYoutuberDrop = BabiesData.GuaranteedDrops.lastYoutuberDrop,
		lastGodDrop = BabiesData.GuaranteedDrops.lastGodDrop,
		intervals = {
			mythic = BabiesData.GuaranteedDrops.MYTHIC_INTERVAL,
			youtuber = BabiesData.GuaranteedDrops.YOUTUBER_INTERVAL,
			god = BabiesData.GuaranteedDrops.GOD_INTERVAL
		}
	}

	-- Print status
	print("🕐 GUARANTEED DROP STATUS:")
	for _, drop in ipairs(status.nextDrops) do
		print("   " .. drop.rarity .. ": " .. drop.timeString .. " remaining")
	end

	return status
end

-- Reset guaranteed drop timers (admin only)
_G.ResetGuaranteedDropTimers = function()
	local currentTime = tick()
	BabiesData.GuaranteedDrops.lastMythicDrop = currentTime
	BabiesData.GuaranteedDrops.lastYoutuberDrop = currentTime
	BabiesData.GuaranteedDrops.lastGodDrop = currentTime
	print("✅ Reset all guaranteed drop timers")
end

-- Set custom guaranteed drop timers (for testing)
_G.SetGuaranteedDropTimer = function(rarityType, secondsFromNow)
	if not rarityType or not secondsFromNow then
		print("Usage: _G.SetGuaranteedDropTimer('Mythic', 30) - sets Mythic to drop in 30 seconds")
		return
	end

	local currentTime = tick()
	local targetTime = currentTime - (BabiesData.GuaranteedDrops[rarityType:upper() .. "_INTERVAL"] - secondsFromNow)

	if rarityType == "Mythic" then
		BabiesData.GuaranteedDrops.lastMythicDrop = targetTime
		print("✅ Set Mythic to drop in " .. secondsFromNow .. " seconds")
	elseif rarityType == "Youtuber" then
		BabiesData.GuaranteedDrops.lastYoutuberDrop = targetTime
		print("✅ Set Youtuber to drop in " .. secondsFromNow .. " seconds")
	elseif rarityType == "God" then
		BabiesData.GuaranteedDrops.lastGodDrop = targetTime
		print("✅ Set God to drop in " .. secondsFromNow .. " seconds")
	else
		print("❌ Invalid rarity type. Use: Mythic, Youtuber, or God")
	end
end

-- List all babies by rarity
_G.ListBabiesByRarity = function(rarityType)
	if rarityType then
		local babies = BabiesData.getBabiesByRarity(rarityType)
		print("📋 " .. rarityType .. " babies (" .. #babies .. " total):")
		for i, babyName in ipairs(babies) do
			local babyData = BabiesData.getBabyData(babyName)
			print("   " .. i .. ". " .. (babyData.displayName or babyName) .. " - $" .. babyData.price)
		end
	else
		print("📋 ALL BABIES BY RARITY:")
		for _, rarity in ipairs({"Common", "Rare", "Epic", "Mythic", "Legendary", "Youtuber", "God"}) do
			local babies = BabiesData.getBabiesByRarity(rarity)
			if #babies > 0 then
				print("   " .. rarity .. " (" .. #babies .. " babies):")
				for _, babyName in ipairs(babies) do
					local babyData = BabiesData.getBabyData(babyName)
					print("     - " .. (babyData.displayName or babyName))
				end
			end
		end
	end
end

-- Test client notifications
_G.TestNotification = function(rarityType)
	if not rarityType then
		rarityType = "Mythic"
	end

	local messages = {
		Mythic = "🌟 GUARANTEED MYTHIC HAS SPAWNED! 🌟",
		Youtuber = "🌟 GUARANTEED YOUTUBER HAS SPAWNED! 🌟",
		God = "🌟 GUARANTEED GOD HAS SPAWNED! 🌟"
	}

	local message = messages[rarityType] or "🌟 GUARANTEED DROP HAS SPAWNED! 🌟"

	for _, player in pairs(Players:GetPlayers()) do
		if _G.SendServerMessage then
			_G.SendServerMessage(player, message)
		end
	end

	print("✅ Sent test notification: " .. message)
end

-- Fix all baby name colors to white
_G.FixBabyNameColors = function()
	local fixed = 0

	-- Fix moving babies
	local movingBabies = game.Workspace:FindFirstChild("MovingBabies")
	if movingBabies then
		for _, baby in pairs(movingBabies:GetChildren()) do
			if baby:IsA("Model") then
				local babyUI = baby:FindFirstChild("BabyUI")
				if babyUI and babyUI:FindFirstChild("Frame") then
					local frame = babyUI.Frame
					local nameLabel = frame:FindFirstChild("NameLabel")
					if nameLabel then
						nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
						fixed = fixed + 1
					end
				end
			end
		end
	end

	-- Fix placed babies on bases
	local bases = game.Workspace:FindFirstChild("Bases")
	if bases then
		for _, base in pairs(bases:GetChildren()) do
			if base:IsA("Model") then
				for i = 1, 10 do
					local stand = base:FindFirstChild("Stand" .. i)
					if stand then
						local babyModel = stand:FindFirstChild("BabyModel")
						if babyModel then
							local babyUI = babyModel:FindFirstChild("BabyUI")
							if babyUI and babyUI:FindFirstChild("Frame") then
								local frame = babyUI.Frame
								local nameLabel = frame:FindFirstChild("NameLabel")
								if nameLabel then
									nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
									fixed = fixed + 1
								end
							end
						end
					end
				end
			end
		end
	end

	print("✅ Fixed " .. fixed .. " baby name colors to white")
end

-- Get current moving babies count
_G.GetMovingBabiesCount = function()
	local movingBabies = game.Workspace:FindFirstChild("MovingBabies")
	if movingBabies then
		local count = #movingBabies:GetChildren()
		print("🔄 Current moving babies: " .. count)

		-- List them
		for i, baby in pairs(movingBabies:GetChildren()) do
			if baby:IsA("Model") then
				local isGuaranteed = baby:FindFirstChild("GuaranteedDrop")
				local rarityTag = baby:FindFirstChild("GuaranteedRarity")
				local rarityInfo = ""

				if isGuaranteed and rarityTag then
					rarityInfo = " (GUARANTEED " .. rarityTag.Value .. ")"
				end

				print("   " .. i .. ". " .. baby.Name .. rarityInfo)
			end
		end

		return count
	end
	return 0
end

-- Help command
_G.GuaranteedDropHelp = function()
	print("🎯 GUARANTEED DROP DEBUG COMMANDS:")
	print("   _G.ForceGuaranteedDrop('Mythic') - Force spawn a guaranteed mythic")
	print("   _G.ForceGuaranteedDrop('Youtuber') - Force spawn a guaranteed youtuber")
	print("   _G.ForceGuaranteedDrop('God') - Force spawn a guaranteed god")
	print("   _G.GetGuaranteedDropStatus() - Show next guaranteed drop times")
	print("   _G.ResetGuaranteedDropTimers() - Reset all timers")
	print("   _G.SetGuaranteedDropTimer('Mythic', 30) - Set mythic to drop in 30 seconds")
	print("   _G.TestNotification('Mythic') - Test client notification")
	print("   _G.ListBabiesByRarity('Mythic') - List all babies of rarity")
	print("   _G.FixBabyNameColors() - Fix all baby names to white")
	print("   _G.GetMovingBabiesCount() - Show current moving babies")
	print("   _G.GuaranteedDropHelp() - Show this help")
end

-- ================================
-- MONITORING SYSTEM
-- ================================

-- Monitor guaranteed drop system
task.spawn(function()
	while true do
		task.wait(60) -- Check every minute

		local status = _G.GetGuaranteedDropStatus()
		local hasUpcoming = false

		for _, drop in ipairs(status.nextDrops) do
			if drop.timeLeft <= 120 then -- 2 minutes or less
				hasUpcoming = true
				print("⏰ UPCOMING: " .. drop.rarity .. " in " .. drop.timeString)
			end
		end
	end
end)

print("✅ Guaranteed Drop Debug Commands loaded!")
print("   Type _G.GuaranteedDropHelp() for help")

-- Initialize with status check
task.wait(2)
_G.GetGuaranteedDropStatus()