-- GuaranteedDropUI.lua - OPTIMIZED VERSION
-- Place in ServerScriptService > ModuleScripts  
-- Handles UI updates for guaranteed drop countdowns with smooth rainbow God text

local GuaranteedDropUI = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Timing configuration (in seconds)
local GUARANTEED_DROP_TIMINGS = {
	Mythic = 120,    -- 5 minutes
	Youtuber = 300,  -- 15 minutes
	God = 900       -- 30 minutes
}

-- Update intervals for optimization
local UPDATE_INTERVALS = {
	labels = 1,      -- Update labels every 1 second
	rainbow = 0.033, -- Update rainbow ~30fps for ultra-smooth animation
	uiStroke = 0.5   -- Check for UIStroke every 0.5 seconds
}

-- UI References with caching
local uiCache = {
	roadPanel = nil,
	mainFrame = nil,
	mythicLabel = nil,
	youtuberLabel = nil,
	godLabel = nil
}

-- Animation state
local animationState = {
	rainbowConnection = nil,
	lastRainbowUpdate = 0,
	lastUIStrokeCheck = 0,
	isInitialized = false
}

-- Performance tracking
local calculationCache = {}
local lastColorCacheTime = 0

-- Dependencies
local GuaranteedDropManager = nil

-- Safe dependency injection
function GuaranteedDropUI.setGuaranteedDropManager(manager)
	GuaranteedDropManager = manager
end

-- Color definitions
local COLORS = {
	Mythic = "#FF0000",      -- Red
	Youtuber = "#FF6666",    -- Light red
	God = "rainbow"          -- Rainbow animation
}

-- Pre-calculated rainbow colors for smooth transitions
local RAINBOW_COLORS = {
	{r = 255, g = 0, b = 0},     -- Red
	{r = 255, g = 165, b = 0},   -- Orange  
	{r = 255, g = 255, b = 0},   -- Yellow
	{r = 0, g = 255, b = 0},     -- Green
	{r = 0, g = 0, b = 255},     -- Blue
	{r = 75, g = 0, b = 130},    -- Indigo
	{r = 238, g = 130, b = 238}  -- Violet
}

-- Pre-compiled text templates (all times in red)
local TEXT_TEMPLATES = {
	ready = "<font color=\"#FFFFFF\">Guaranteed </font><font color=\"%s\">%s</font><font color=\"#FFFFFF\"> - </font><font color=\"#FF0000\"><b>READY!</b></font>",
	countdown = "<font color=\"#FFFFFF\">Guaranteed </font><font color=\"%s\">%s</font><font color=\"#FFFFFF\"> in </font><font color=\"#FF0000\"><b>%02d:%02d</b></font>"
}

-- Get timing for specific rarity
function GuaranteedDropUI.getTiming(rarity)
	return GUARANTEED_DROP_TIMINGS[rarity] or 300
end

-- Get all timings
function GuaranteedDropUI.getAllTimings()
	return GUARANTEED_DROP_TIMINGS
end

-- Set timing for specific rarity
function GuaranteedDropUI.setTiming(rarity, seconds)
	if GUARANTEED_DROP_TIMINGS[rarity] then
		GUARANTEED_DROP_TIMINGS[rarity] = seconds
		return true
	end
	return false
end

-- Optimized UI element finding with caching
function GuaranteedDropUI.findUIElements()
	-- Use cached references if still valid
	if uiCache.roadPanel and uiCache.roadPanel.Parent then
		return true
	end

	-- Find road panel
	uiCache.roadPanel = workspace:FindFirstChild("RoadPanel")
	if not uiCache.roadPanel then return false end

	local surfaceGui = uiCache.roadPanel:FindFirstChild("SurfaceGui")
	if not surfaceGui then return false end

	uiCache.mainFrame = surfaceGui:FindFirstChild("MainFrame")
	if not uiCache.mainFrame then return false end

	-- Batch find all labels
	local labelConfigs = {
		{key = "mythicLabel", names = {"Mythic"}},
		{key = "youtuberLabel", names = {"Youtube", "Youtuber"}},
		{key = "godLabel", names = {"BabyGod", "Baby God", "God"}}
	}

	local foundCount = 0
	for _, config in ipairs(labelConfigs) do
		for _, name in ipairs(config.names) do
			local label = uiCache.mainFrame:FindFirstChild(name)
			if label then
				uiCache[config.key] = label
				label.RichText = true
				foundCount = foundCount + 1
				break
			end
		end
	end

	return foundCount > 0
end

-- Initialize UI system
function GuaranteedDropUI.init()
	if animationState.isInitialized then
		return true
	end

	if not GuaranteedDropUI.findUIElements() then
		return false
	end

	GuaranteedDropUI.startUpdateLoop()
	animationState.isInitialized = true
	return true
end

-- Optimized countdown text formatting with caching
function GuaranteedDropUI.formatCountdownText(rarity, countdown)
	local cacheKey = rarity .. "_" .. tostring(countdown)
	local currentTime = tick()

	-- Use cache if recent
	if calculationCache[cacheKey] and (currentTime - lastColorCacheTime) < 1 then
		return calculationCache[cacheKey]
	end

	local colorHex = COLORS[rarity]
	local timeStr

	if countdown <= 0 then
		timeStr = string.format(TEXT_TEMPLATES.ready, colorHex, rarity)
	else
		local minutes = math.floor(countdown / 60)
		local seconds = countdown % 60
		timeStr = string.format(TEXT_TEMPLATES.countdown, colorHex, rarity, minutes, seconds)
	end

	-- Periodic cache cleanup
	if currentTime - lastColorCacheTime > 10 then
		calculationCache = {}
		lastColorCacheTime = currentTime
	end

	calculationCache[cacheKey] = timeStr
	return timeStr
end

-- Generate smooth rainbow color hex
local function getRainbowColorHex(time)
	local rainbowSpeed = 2
	local colorCount = #RAINBOW_COLORS
	local position = (time * rainbowSpeed) % colorCount
	local index = math.floor(position) + 1
	local nextIndex = (index % colorCount) + 1
	local alpha = position - math.floor(position)

	-- Smooth interpolation
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

-- Ultra-smooth rainbow color update for God
function GuaranteedDropUI.updateRainbowColor()
	if not uiCache.godLabel then return end

	local currentTime = tick()
	if currentTime - animationState.lastRainbowUpdate < UPDATE_INTERVALS.rainbow then 
		return 
	end
	animationState.lastRainbowUpdate = currentTime

	-- Get countdown
	local countdown = GUARANTEED_DROP_TIMINGS.God
	if GuaranteedDropManager and GuaranteedDropManager.getCountdown then
		local success, result = pcall(GuaranteedDropManager.getCountdown, "God")
		if success and result then
			countdown = result
		end
	end

	-- Generate smooth rainbow color
	local rainbowHex = getRainbowColorHex(currentTime)

	-- Update text with rainbow color
	local timeStr
	if countdown <= 0 then
		timeStr = string.format(TEXT_TEMPLATES.ready, rainbowHex, "God")
	else
		local minutes = math.floor(countdown / 60)
		local seconds = countdown % 60
		timeStr = string.format(TEXT_TEMPLATES.countdown, rainbowHex, "God", minutes, seconds)
	end

	uiCache.godLabel.Text = timeStr

	-- Periodic UIStroke cleanup
	if currentTime - animationState.lastUIStrokeCheck > UPDATE_INTERVALS.uiStroke then
		animationState.lastUIStrokeCheck = currentTime
		local uiStroke = uiCache.godLabel:FindFirstChild("UIStroke")
		if uiStroke then
			uiStroke:Destroy()
		end
	end
end

-- Optimized label updates
function GuaranteedDropUI.updateLabels()
	if not GuaranteedDropManager or not GuaranteedDropManager.getAllCountdowns then
		return 
	end

	local success, countdowns = pcall(GuaranteedDropManager.getAllCountdowns)
	if not success then return end

	-- Batch update static labels (non-rainbow)
	local updates = {
		{label = uiCache.mythicLabel, rarity = "Mythic", countdown = countdowns.Mythic},
		{label = uiCache.youtuberLabel, rarity = "Youtuber", countdown = countdowns.Youtuber}
	}

	for _, update in ipairs(updates) do
		if update.label and update.countdown then
			update.label.Text = GuaranteedDropUI.formatCountdownText(update.rarity, update.countdown)
			update.label.RichText = true
		end
	end
end

-- Optimized update loop system
function GuaranteedDropUI.startUpdateLoop()
	-- Main update loop for static labels
	task.spawn(function()
		while animationState.isInitialized do
			task.wait(UPDATE_INTERVALS.labels)
			if GuaranteedDropManager then
				GuaranteedDropUI.updateLabels()
			end
		end
	end)

	-- High-frequency rainbow animation
	animationState.rainbowConnection = RunService.Heartbeat:Connect(function()
		if uiCache.godLabel then
			GuaranteedDropUI.updateRainbowColor()
		end
	end)
end

-- Cleanup function
function GuaranteedDropUI.cleanup()
	if animationState.rainbowConnection then
		animationState.rainbowConnection:Disconnect()
		animationState.rainbowConnection = nil
	end

	-- Clear cache
	for k in pairs(uiCache) do
		uiCache[k] = nil
	end

	-- Reset state
	animationState = {
		rainbowConnection = nil,
		lastRainbowUpdate = 0,
		lastUIStrokeCheck = 0,
		isInitialized = false
	}

	calculationCache = {}
end

-- Force update
function GuaranteedDropUI.forceUpdate()
	if not GuaranteedDropManager then return false end

	GuaranteedDropUI.updateLabels()
	GuaranteedDropUI.updateRainbowColor()
	return true
end

-- Get UI status
function GuaranteedDropUI.getStatus()
	local cacheSize = 0
	for _ in pairs(calculationCache) do
		cacheSize = cacheSize + 1
	end

	return {
		initialized = animationState.isInitialized,
		elementsFound = {
			roadPanel = uiCache.roadPanel ~= nil,
			mainFrame = uiCache.mainFrame ~= nil,
			mythicLabel = uiCache.mythicLabel ~= nil,
			youtuberLabel = uiCache.youtuberLabel ~= nil,
			godLabel = uiCache.godLabel ~= nil
		},
		rainbowActive = animationState.rainbowConnection ~= nil,
		managerAvailable = GuaranteedDropManager ~= nil,
		timings = GUARANTEED_DROP_TIMINGS,
		cacheSize = cacheSize
	}
end

-- Re-initialize
function GuaranteedDropUI.reinit()
	GuaranteedDropUI.cleanup()
	return GuaranteedDropUI.init()
end

-- Color management
function GuaranteedDropUI.setColor(rarity, hexColor)
	if COLORS[rarity] and rarity ~= "God" then
		COLORS[rarity] = hexColor
		-- Clear relevant cache entries
		for key in pairs(calculationCache) do
			if key:find(rarity) then
				calculationCache[key] = nil
			end
		end
		return true
	end
	return false
end

-- Get color settings
function GuaranteedDropUI.getColors()
	return COLORS
end

-- Wait for manager
function GuaranteedDropUI.waitForManager(timeout)
	timeout = timeout or 5
	local elapsed = 0
	local checkInterval = 0.1

	while not GuaranteedDropManager and elapsed < timeout do
		task.wait(checkInterval)
		elapsed = elapsed + checkInterval
	end

	return GuaranteedDropManager ~= nil
end

-- Batch configuration update
function GuaranteedDropUI.updateConfiguration(config)
	local updated = false

	if config.timings then
		for rarity, time in pairs(config.timings) do
			if GuaranteedDropUI.setTiming(rarity, time) then
				updated = true
			end
		end
	end

	if config.colors then
		for rarity, color in pairs(config.colors) do
			if GuaranteedDropUI.setColor(rarity, color) then
				updated = true
			end
		end
	end

	if config.updateIntervals then
		for key, interval in pairs(config.updateIntervals) do
			if UPDATE_INTERVALS[key] then
				UPDATE_INTERVALS[key] = interval
				updated = true
			end
		end
	end

	return updated
end

-- Get current configuration
function GuaranteedDropUI.getConfiguration()
	return {
		timings = GUARANTEED_DROP_TIMINGS,
		colors = COLORS,
		updateIntervals = UPDATE_INTERVALS
	}
end

-- Force UI text formatting with rainbow God
function GuaranteedDropUI.forceTextFormatting()
	if not GuaranteedDropUI.findUIElements() then return false end

	-- Format Mythic and Youtuber with static colors
	local staticLabels = {
		{label = uiCache.mythicLabel, rarity = "Mythic"},
		{label = uiCache.youtuberLabel, rarity = "Youtuber"}
	}

	for _, config in ipairs(staticLabels) do
		if config.label then
			config.label.RichText = true
			local countdown = GuaranteedDropUI.getTiming(config.rarity)
			local minutes = math.floor(countdown / 60)
			local seconds = countdown % 60
			config.label.Text = string.format(TEXT_TEMPLATES.countdown, 
				COLORS[config.rarity], config.rarity, minutes, seconds)
		end
	end

	-- Format God with rainbow
	if uiCache.godLabel then
		uiCache.godLabel.RichText = true
		GuaranteedDropUI.updateRainbowColor()
	end

	return true
end

-- Global debug functions
_G.ForceGuaranteedDropUIFormat = GuaranteedDropUI.forceTextFormatting
_G.GetGuaranteedDropUIStatus = GuaranteedDropUI.getStatus
_G.RefreshGuaranteedDropUI = GuaranteedDropUI.reinit

return GuaranteedDropUI