-- GuaranteedDropManager.lua - FIXED VERSION WITH CORRECT COLORS
-- Place in ServerScriptService > ModuleScripts
-- Handles server-wide timed guaranteed drops

local GuaranteedDropManager = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Dependencies
local BrainrotConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("BrainrotConfig"))

-- Constants - Drop intervals in seconds (CORRECT TIMINGS)
local DROP_INTERVALS = {
	Mythic = 120,    -- 5 minutes
	Youtuber = 300,  -- 15 minutes
	God = 900       -- 30 minutes
}

-- UI Color configuration (FIXED COLORS)
local UI_COLORS = {
	Mythic = "#FF0000",      -- Red
	Youtuber = "#FF6666",    -- Light red
	God = "rainbow"          -- Rainbow (handled by GuaranteedDropUI)
}

-- State tracking
local serverStartTime = 0
local nextDropTimes = {}
local lastDropTimes = {}
local isInitialized = false

-- UI References
local uiElements = {
	roadPanel = nil,
	mainFrame = nil,
	mythicLabel = nil,
	youtuberLabel = nil,
	godLabel = nil
}

-- References (set by main script)
GuaranteedDropManager.BabyManager = nil
GuaranteedDropManager.soundRemote = nil
GuaranteedDropManager.serverMessageRemote = nil

-- Find and cache UI elements
local function findUIElements()
	local workspace = game.Workspace

	uiElements.roadPanel = workspace:FindFirstChild("RoadPanel")
	if not uiElements.roadPanel then return false end

	local surfaceGui = uiElements.roadPanel:FindFirstChild("SurfaceGui")
	if not surfaceGui then return false end

	uiElements.mainFrame = surfaceGui:FindFirstChild("MainFrame")
	if not uiElements.mainFrame then return false end

	-- Find labels with multiple possible names
	uiElements.mythicLabel = uiElements.mainFrame:FindFirstChild("Mythic")
	uiElements.youtuberLabel = uiElements.mainFrame:FindFirstChild("Youtube") or uiElements.mainFrame:FindFirstChild("Youtuber")
	uiElements.godLabel = uiElements.mainFrame:FindFirstChild("BabyGod") or uiElements.mainFrame:FindFirstChild("Baby God") or uiElements.mainFrame:FindFirstChild("God")

	-- Enable rich text on found labels
	if uiElements.mythicLabel then uiElements.mythicLabel.RichText = true end
	if uiElements.youtuberLabel then uiElements.youtuberLabel.RichText = true end
	if uiElements.godLabel then uiElements.godLabel.RichText = true end

	return true
end

-- Format countdown with proper colors (RED TIME)
local function formatCountdownDisplay(rarity, countdown)
	local colorHex = UI_COLORS[rarity]

	if countdown <= 0 then
		return string.format(
			"<font color=\"#FFFFFF\">Guaranteed </font><font color=\"%s\">%s</font><font color=\"#FFFFFF\"> - </font><font color=\"#FF0000\"><b>READY!</b></font>",
			colorHex, rarity
		)
	else
		local minutes = math.floor(countdown / 60)
		local seconds = countdown % 60
		return string.format(
			"<font color=\"#FFFFFF\">Guaranteed </font><font color=\"%s\">%s</font><font color=\"#FFFFFF\"> in </font><font color=\"#FF0000\"><b>%02d:%02d</b></font>",
			colorHex, rarity, minutes, seconds
		)
	end
end

-- Update UI labels with proper formatting
local function updateUILabels()
	if not findUIElements() then return end

	local countdowns = GuaranteedDropManager.getAllCountdowns()

	-- Update Mythic label
	if uiElements.mythicLabel and countdowns.Mythic then
		uiElements.mythicLabel.Text = formatCountdownDisplay("Mythic", countdowns.Mythic)
	end

	-- Update Youtuber label
	if uiElements.youtuberLabel and countdowns.Youtuber then
		uiElements.youtuberLabel.Text = formatCountdownDisplay("Youtuber", countdowns.Youtuber)
	end

	-- God label is handled by GuaranteedDropUI for rainbow effect, but ensure red time
	if uiElements.godLabel and countdowns.God then
		local currentText = uiElements.godLabel.Text
		local timePattern = "(%d+):(%d+)"
		local minutes, seconds = currentText:match(timePattern)

		if minutes and seconds then
			-- Keep existing God color but ensure RED time
			local godColorPattern = 'color="(#%w+)"'
			local godColor = currentText:match(godColorPattern) or "#FFD700"

			uiElements.godLabel.Text = string.format(
				"<font color=\"#FFFFFF\">Guaranteed </font><font color=\"%s\">God</font><font color=\"#FFFFFF\"> in </font><font color=\"#FF0000\"><b>%s:%s</b></font>",
				godColor, minutes, seconds
			)
		end
	end
end

-- Initialize the guaranteed drop system
function GuaranteedDropManager.init()
	if isInitialized then return true end

	serverStartTime = tick()

	-- Calculate initial next drop times
	for rarity, interval in pairs(DROP_INTERVALS) do
		nextDropTimes[rarity] = serverStartTime + interval
		lastDropTimes[rarity] = 0
	end

	isInitialized = true

	-- Find UI elements
	findUIElements()

	-- Start the drop checking loop
	GuaranteedDropManager.startDropLoop()

	-- Start UI update loop
	GuaranteedDropManager.startUIUpdateLoop()

	return true
end

-- Get countdown time for a specific rarity
function GuaranteedDropManager.getCountdown(rarity)
	if not isInitialized or not nextDropTimes[rarity] then
		return 0
	end

	local currentTime = tick()
	local timeLeft = nextDropTimes[rarity] - currentTime
	return math.max(0, math.ceil(timeLeft))
end

-- Get all countdown times
function GuaranteedDropManager.getAllCountdowns()
	if not isInitialized then
		return {Mythic = 0, Youtuber = 0, God = 0}
	end

	local countdowns = {}
	for rarity, _ in pairs(DROP_INTERVALS) do
		countdowns[rarity] = GuaranteedDropManager.getCountdown(rarity)
	end
	return countdowns
end

-- Format time as MM:SS
function GuaranteedDropManager.formatTime(seconds)
	if seconds <= 0 then return "00:00" end

	local minutes = math.floor(seconds / 60)
	local secs = seconds % 60
	return string.format("%02d:%02d", minutes, secs)
end

-- Check if it's time for a guaranteed drop
function GuaranteedDropManager.checkForDrop(rarity)
	if not isInitialized or not nextDropTimes[rarity] then
		return false
	end

	local currentTime = tick()
	return currentTime >= nextDropTimes[rarity]
end

-- Trigger a guaranteed drop for specific rarity
function GuaranteedDropManager.triggerDrop(rarity)
	if not GuaranteedDropManager.BabyManager then
		return false
	end

	-- Get babies of this rarity
	local rarityBabies = BrainrotConfig.GetBabiesByRarity(rarity)
	if not rarityBabies or #rarityBabies == 0 then
		return false
	end

	-- Select random baby from this rarity
	local selectedBaby = rarityBabies[math.random(1, #rarityBabies)]

	-- Spawn the guaranteed baby
	local spawnedBaby = GuaranteedDropManager.BabyManager.spawnGuaranteedBaby(selectedBaby, rarity)

	if spawnedBaby then
		-- Update timing
		local currentTime = tick()
		lastDropTimes[rarity] = currentTime
		nextDropTimes[rarity] = currentTime + DROP_INTERVALS[rarity]

		-- Send server messages
		GuaranteedDropManager.sendDropNotification(rarity, selectedBaby)

		return true
	else
		return false
	end
end

-- Send notification to all players about the drop
function GuaranteedDropManager.sendDropNotification(rarity, babyName)
	local message = ""

	if rarity == "God" then
		message = "🌈 GUARANTEED GOD HAS SPAWNED: " .. babyName .. " 🌈"
	elseif rarity == "Youtuber" then
		message = "⭐ GUARANTEED YOUTUBER HAS SPAWNED: " .. babyName .. " ⭐"
	elseif rarity == "Mythic" then
		message = "🔥 GUARANTEED MYTHIC HAS SPAWNED: " .. babyName .. " 🔥"
	end

	if GuaranteedDropManager.serverMessageRemote and message ~= "" then
		for _, player in pairs(Players:GetPlayers()) do
			if player:FindFirstChild("PlayerGui") then
				GuaranteedDropManager.serverMessageRemote:FireClient(player, message)
			end
		end
	end
end

-- UI update loop with proper formatting
function GuaranteedDropManager.startUIUpdateLoop()
	task.spawn(function()
		while isInitialized do
			task.wait(1) -- Update UI every second
			updateUILabels()
		end
	end)
end

-- Main drop checking loop
function GuaranteedDropManager.startDropLoop()
	if not isInitialized then return end

	task.spawn(function()
		while isInitialized do
			task.wait(1) -- Check every second

			-- Check if there are active players
			local activePlayers = 0
			for _, player in pairs(Players:GetPlayers()) do
				if player:FindFirstChild("OwnedBase") then
					activePlayers = activePlayers + 1
				end
			end

			-- Only trigger drops if there are active players
			if activePlayers > 0 then
				for rarity, _ in pairs(DROP_INTERVALS) do
					if GuaranteedDropManager.checkForDrop(rarity) then
						GuaranteedDropManager.triggerDrop(rarity)
					end
				end
			end
		end
	end)
end

-- Get status for debugging
function GuaranteedDropManager.getStatus()
	if not isInitialized then
		return {initialized = false}
	end

	local currentTime = tick()
	local status = {
		initialized = true,
		serverUptime = currentTime - serverStartTime,
		countdowns = GuaranteedDropManager.getAllCountdowns(),
		intervals = DROP_INTERVALS,
		colors = UI_COLORS,
		nextDropTimes = {},
		lastDropTimes = {},
		uiElements = {
			roadPanel = uiElements.roadPanel ~= nil,
			mainFrame = uiElements.mainFrame ~= nil,
			mythicLabel = uiElements.mythicLabel ~= nil,
			youtuberLabel = uiElements.youtuberLabel ~= nil,
			godLabel = uiElements.godLabel ~= nil
		}
	}

	for rarity, nextTime in pairs(nextDropTimes) do
		status.nextDropTimes[rarity] = nextTime - serverStartTime
	end

	for rarity, lastTime in pairs(lastDropTimes) do
		status.lastDropTimes[rarity] = lastTime - serverStartTime
	end

	return status
end

-- Force a drop (admin function)
function GuaranteedDropManager.forceDrop(rarity)
	if not DROP_INTERVALS[rarity] then
		return false, "Invalid rarity: " .. tostring(rarity)
	end

	local success = GuaranteedDropManager.triggerDrop(rarity)
	return success, success and "Drop triggered successfully" or "Failed to trigger drop"
end

-- Reset timers (admin function)
function GuaranteedDropManager.resetTimers()
	local currentTime = tick()

	for rarity, interval in pairs(DROP_INTERVALS) do
		nextDropTimes[rarity] = currentTime + interval
		lastDropTimes[rarity] = 0
	end
end

-- Set custom intervals (admin function)
function GuaranteedDropManager.setInterval(rarity, seconds)
	if not DROP_INTERVALS[rarity] then
		return false, "Invalid rarity"
	end

	if seconds < 60 then
		return false, "Interval too short (minimum 60 seconds)"
	end

	DROP_INTERVALS[rarity] = seconds

	-- Recalculate next drop time
	local currentTime = tick()
	nextDropTimes[rarity] = currentTime + seconds

	return true, "Interval updated"
end

-- Get current intervals
function GuaranteedDropManager.getIntervals()
	local intervals = {}
	for rarity, seconds in pairs(DROP_INTERVALS) do
		intervals[rarity] = {
			seconds = seconds,
			minutes = seconds / 60,
			formatted = GuaranteedDropManager.formatTime(seconds)
		}
	end
	return intervals
end

-- Force UI refresh
function GuaranteedDropManager.refreshUI()
	findUIElements()
	updateUILabels()
	return true
end

-- Cleanup function
function GuaranteedDropManager.cleanup()
	isInitialized = false
	nextDropTimes = {}
	lastDropTimes = {}

	-- Clear UI cache
	uiElements = {
		roadPanel = nil,
		mainFrame = nil,
		mythicLabel = nil,
		youtuberLabel = nil,
		godLabel = nil
	}
end

-- Global functions for debugging
_G.GetGuaranteedDropStatus = GuaranteedDropManager.getStatus
_G.RefreshGuaranteedDropUI = GuaranteedDropManager.refreshUI
_G.ForceGuaranteedDrop = GuaranteedDropManager.forceDrop

return GuaranteedDropManager