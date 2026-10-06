-- IMMEDIATE FIX SCRIPT - Optimized Version
-- Place in ServerScriptService as a regular Script (not ModuleScript)
-- Instantly fixes all guaranteed drop UI issues with smooth rainbow God text

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Correct timings
local CORRECT_INTERVALS = {
	Mythic = 120,    -- 5 minutes
	Youtuber = 300,  -- 15 minutes  
	God = 900       -- 30 minutes
}

-- Correct colors
local CORRECT_COLORS = {
	Mythic = "#FF0000",      -- Red
	Youtuber = "#FF6666",    -- Light red
	God = "rainbow"          -- Rainbow for God
}

-- Rainbow color data for smooth transitions
local RAINBOW_COLORS = {
	{r = 255, g = 0, b = 0},     -- Red
	{r = 255, g = 165, b = 0},   -- Orange  
	{r = 255, g = 255, b = 0},   -- Yellow
	{r = 0, g = 255, b = 0},     -- Green
	{r = 0, g = 0, b = 255},     -- Blue
	{r = 75, g = 0, b = 130},    -- Indigo
	{r = 238, g = 130, b = 238}  -- Violet
}

-- UI Cache
local uiCache = {}
local rainbowConnection = nil

-- Generate smooth rainbow color
local function getRainbowColorHex(time)
	local rainbowSpeed = 2
	local colorCount = #RAINBOW_COLORS
	local position = (time * rainbowSpeed) % colorCount
	local index = math.floor(position) + 1
	local nextIndex = (index % colorCount) + 1
	local alpha = position - math.floor(position)

	-- Smooth interpolation between colors
	local current = RAINBOW_COLORS[index]
	local next = RAINBOW_COLORS[nextIndex]

	local r = current.r + (next.r - current.r) * alpha
	local g = current.g + (next.g - current.g) * alpha
	local b = current.b + (next.b - current.b) * alpha

	return string.format("#%02X%02X%02X", 
		math.floor(r), 
		math.floor(g), 
		math.floor(b)
	)
end

-- Find UI elements efficiently
local function findUIElements()
	if uiCache.roadPanel and uiCache.roadPanel.Parent then
		return true -- Use cached elements
	end

	local roadPanel = workspace:FindFirstChild("RoadPanel")
	if not roadPanel then return false end

	local surfaceGui = roadPanel:FindFirstChild("SurfaceGui")
	if not surfaceGui then return false end

	local mainFrame = surfaceGui:FindFirstChild("MainFrame")
	if not mainFrame then return false end

	-- Cache elements
	uiCache.roadPanel = roadPanel
	uiCache.mainFrame = mainFrame
	uiCache.mythicLabel = mainFrame:FindFirstChild("Mythic")
	uiCache.youtuberLabel = mainFrame:FindFirstChild("Youtube") or mainFrame:FindFirstChild("Youtuber")
	uiCache.godLabel = mainFrame:FindFirstChild("BabyGod") or mainFrame:FindFirstChild("Baby God") or mainFrame:FindFirstChild("God")

	return true
end

-- Format text with RED time
local function formatWithRedTime(rarity, minutes, seconds, colorHex)
	if minutes == 0 and seconds == 0 then
		return string.format(
			"<font color=\"#FFFFFF\">Guaranteed </font><font color=\"%s\">%s</font><font color=\"#FFFFFF\"> - </font><font color=\"#FF0000\"><b>READY!</b></font>",
			colorHex, rarity
		)
	else
		return string.format(
			"<font color=\"#FFFFFF\">Guaranteed </font><font color=\"%s\">%s</font><font color=\"#FFFFFF\"> in </font><font color=\"#FF0000\"><b>%02d:%02d</b></font>",
			colorHex, rarity, minutes, seconds
		)
	end
end

-- Calculate countdown for rarity
local function getCountdownForRarity(rarity)
	-- Try to get from GuaranteedDropManager if available
	if _G.GetGuaranteedDropStatus then
		local success, status = pcall(_G.GetGuaranteedDropStatus)
		if success and status and status.countdowns and status.countdowns[rarity] then
			return status.countdowns[rarity]
		end
	end

	-- Fallback: simulate countdown based on correct intervals using tick()
	local currentTime = tick()
	local interval = CORRECT_INTERVALS[rarity]
	local timeInCycle = currentTime % interval
	local timeLeft = interval - timeInCycle

	return math.max(0, math.ceil(timeLeft))
end

-- Apply immediate fix to static labels (Mythic, Youtuber)
local function fixStaticLabels()
	if not findUIElements() then return false end

	local fixedCount = 0

	-- Fix Mythic label
	if uiCache.mythicLabel then
		local countdown = getCountdownForRarity("Mythic")
		local minutes = math.floor(countdown / 60)
		local seconds = countdown % 60

		uiCache.mythicLabel.RichText = true
		uiCache.mythicLabel.Text = formatWithRedTime("Mythic", minutes, seconds, CORRECT_COLORS.Mythic)
		fixedCount = fixedCount + 1
	end

	-- Fix Youtuber label
	if uiCache.youtuberLabel then
		local countdown = getCountdownForRarity("Youtuber")
		local minutes = math.floor(countdown / 60)
		local seconds = countdown % 60

		uiCache.youtuberLabel.RichText = true
		uiCache.youtuberLabel.Text = formatWithRedTime("Youtuber", minutes, seconds, CORRECT_COLORS.Youtuber)
		fixedCount = fixedCount + 1
	end

	return fixedCount > 0
end

-- Update God label with smooth rainbow
local function updateGodRainbow()
	if not uiCache.godLabel then return end

	local countdown = getCountdownForRarity("God")
	local minutes = math.floor(countdown / 60)
	local seconds = countdown % 60

	-- Generate smooth rainbow color
	local rainbowHex = getRainbowColorHex(tick())

	uiCache.godLabel.RichText = true
	uiCache.godLabel.Text = formatWithRedTime("God", minutes, seconds, rainbowHex)

	-- Remove UIStroke if present (can interfere with text colors)
	local uiStroke = uiCache.godLabel:FindFirstChild("UIStroke")
	if uiStroke then
		uiStroke:Destroy()
	end
end

-- Start rainbow animation for God
local function startRainbowAnimation()
	if rainbowConnection then
		rainbowConnection:Disconnect()
	end

	rainbowConnection = RunService.Heartbeat:Connect(function()
		updateGodRainbow()
	end)
end

-- Apply complete fix
local function applyImmediateFix()
	if not findUIElements() then return false end

	-- Fix static labels
	fixStaticLabels()

	-- Setup God rainbow animation
	if uiCache.godLabel then
		startRainbowAnimation()
	end

	return true
end

-- Fix any GuaranteedDropManager intervals if accessible
local function fixManagerIntervals()
	local ServerScriptService = game:GetService("ServerScriptService")
	local moduleScripts = ServerScriptService:FindFirstChild("ModuleScripts")

	if moduleScripts then
		local guaranteedDropManager = moduleScripts:FindFirstChild("GuaranteedDropManager")
		if guaranteedDropManager then
			local success = pcall(function()
				local manager = require(guaranteedDropManager)

				-- Try to update intervals if the function exists
				if manager.setInterval then
					for rarity, interval in pairs(CORRECT_INTERVALS) do
						manager.setInterval(rarity, interval)
					end
				end

				-- Try to refresh UI if the function exists
				if manager.refreshUI then
					manager.refreshUI()
				end
			end)

			return success
		end
	end

	return false
end

-- Main fix function
local function performCompleteFix()
	-- Step 1: Try to fix manager intervals
	local managerFixed = fixManagerIntervals()

	-- Step 2: Apply immediate UI fixes
	local uiFixed = applyImmediateFix()

	-- Step 3: Set up periodic monitoring for static labels
	task.spawn(function()
		while true do
			task.wait(1) -- Update static labels every second
			fixStaticLabels()
		end
	end)

	local results = {
		managerFixed = managerFixed,
		uiFixed = uiFixed,
		timings = CORRECT_INTERVALS,
		colors = CORRECT_COLORS
	}

	return results
end

-- Global functions
_G.FixGuaranteedDropUIComplete = performCompleteFix
_G.ApplyImmediateUIFix = applyImmediateFix
_G.GetCorrectGuaranteedTimings = function() return CORRECT_INTERVALS end

-- Auto-run the fix
task.spawn(function()
	task.wait(2) -- Wait for other systems to load
	performCompleteFix()
end)

-- Cleanup function
local function cleanup()
	if rainbowConnection then
		rainbowConnection:Disconnect()
		rainbowConnection = nil
	end
end

-- Clean up on script removal
game:GetService("Players").PlayerRemoving:Connect(cleanup)