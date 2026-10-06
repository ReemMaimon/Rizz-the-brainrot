-- COMPLETE BABY COLLECTION SYSTEM WITH ADVANCED INDEXING
-- Put this LocalScript inside: script.parent>Content>Holder>List

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-- ================================
-- ENHANCED CONFIGURATION
-- ================================
local Config = {
	-- Camera angle settings
	CameraYRotation = 90, -- 90 degrees to the right
	CameraXRotation = 0, -- No downward angle - straight view

	-- Performance settings
	MaxConcurrentCreations = 5,
	CreationDelay = 0.03,
	CacheSize = 100,
	ReducedQuality = false,

	-- NEW: Sorting configuration
	DefaultSortType = "price", -- price, rarity, generation, perSec, alphabetical
	SortDirection = "ascending", -- ascending, descending
	EnableMultiSort = true, -- Enable secondary sorting criteria
}

-- ================================
-- OPTIMIZED MODULE LOADING
-- ================================
local function waitForModule(parent, moduleName, timeout)
	timeout = timeout or 3
	local startTime = tick()

	while not parent:FindFirstChild(moduleName) and tick() - startTime < timeout do
		task.wait(0.05)
	end

	local module = parent:FindFirstChild(moduleName)
	if module then
		local success, result = pcall(require, module)
		if success then return result end
	end
	return nil
end

local BrainrotConfig = waitForModule(ReplicatedStorage.ModuleScripts, "BrainrotConfig")
if not BrainrotConfig then
	error("BrainrotConfig module not found or failed to load")
end

local BrainrotData = {
	Babies = {},
	BabyStats = {},
	RarityInfo = {},
}
for brainrotId, definition in pairs(BrainrotConfig.Definitions or {}) do
	local data = {
		price = definition.Price,
		perSec = definition.IncomePerSecond or definition.PerSec or 0,
		displayName = definition.DisplayName,
		rarity = definition.Rarity,
		spawnWeight = definition.SpawnChance,
	}
	BrainrotData.Babies[definition.ModelName or brainrotId] = data
	BrainrotData.BabyStats[definition.ModelName or brainrotId] = data
end
for rarity, info in pairs(BrainrotConfig.RarityInfo or {}) do
	BrainrotData.RarityInfo[rarity] = info
end
function BrainrotData.getBabyData(name)
	return BrainrotData.Babies[name] or BrainrotData.BabyStats[name] or BrainrotConfig.GetByModelName(name) or BrainrotConfig.Get(name)
end
function BrainrotData.getRarityInfo(rarity)
	return BrainrotConfig.GetRarityInfo(rarity)
end
function BrainrotData.formatCurrency(amount)
	return BrainrotConfig.FormatCurrency(amount)
end
function BrainrotData.getRarityOdds(name)
	local data = BrainrotData.getBabyData(name)
	return data and math.max(1, math.floor(100 / math.max(0.001, tonumber(data.spawnWeight) or 1))) or 999
end
function BrainrotData.getNameLabelSettings(name)
	local data = BrainrotData.getBabyData(name)
	return {
		text = data and data.displayName or tostring(name):gsub("_", " "),
		textColor = Color3.fromRGB(255, 255, 255),
		isRainbow = false,
	}
end

local Baby3DFolder = ReplicatedStorage:FindFirstChild("Brainrots") or ReplicatedStorage:FindFirstChild("Baby3D")
local listFrame = script.Parent
local templateFrame = listFrame:WaitForChild("Template")

-- ================================
-- ENHANCED BABY COLLECTION SYSTEM
-- ================================
local BabyCollection = {}
BabyCollection.templates = {}
BabyCollection.viewportData = {}
BabyCollection.updateQueue = {}

-- Enhanced cache system
local ownershipCache = {}
local lastOwnershipCheck = {}
local calculationCache = {}
local positionCache = {}
local priceCache = {}
local indexCache = {}
local cacheTimestamps = {}
local sortCache = {}

-- ================================
-- ADVANCED INDEXING SYSTEM
-- ================================

-- Rarity hierarchy for sorting (lower tier = rarer)
local RarityHierarchy = {
	["Secret"] = 1,
	["God"] = 2,
	["Brainrot God"] = 3,
	["Youtuber"] = 4,
	["Mythic"] = 5,
	["Legendary"] = 6,
	["Epic"] = 7,
	["Rare"] = 8,
	["Common"] = 9
}

function BabyCollection.getRarityTier(rarity)
	return RarityHierarchy[rarity] or 10
end

function BabyCollection.getBabySortIndex(babyName, sortType)
	local cacheKey = babyName .. "_" .. sortType
	local now = tick()

	-- Use cached value if recent (within 30 seconds)
	if indexCache[cacheKey] and cacheTimestamps[cacheKey] and 
		(now - cacheTimestamps[cacheKey]) < 30 then
		return indexCache[cacheKey]
	end

	local babyData = BrainrotData.getBabyData(babyName)
	if not babyData then 
		indexCache[cacheKey] = 999999
		cacheTimestamps[cacheKey] = now
		return 999999 
	end

	local index
	if sortType == "price" then
		index = babyData.price or 0
	elseif sortType == "generation" then
		index = babyData.generation or 999
	elseif sortType == "rarity" then
		index = BabyCollection.getRarityTier(babyData.rarity)
	elseif sortType == "perSec" then
		index = babyData.perSec or 0
	elseif sortType == "alphabetical" then
		index = babyData.displayName or babyName
	elseif sortType == "owned" then
		index = BabyCollection.checkOwnership(babyName) and 1 or 0
	else
		index = babyData.price or 0
	end

	-- Cache the result
	indexCache[cacheKey] = index
	cacheTimestamps[cacheKey] = now

	return index
end

function BabyCollection.getMultiSortKey(babyName)
	local babyData = BrainrotData.getBabyData(babyName)
	if not babyData then return {999999, 999999, 999999} end

	-- Primary: Rarity (rarest first)
	-- Secondary: Price within rarity
	-- Tertiary: Generation
	return {
		BabyCollection.getRarityTier(babyData.rarity),
		babyData.price or 0,
		babyData.generation or 999
	}
end

function BabyCollection.sortBabies(babyList, sortType, direction)
	direction = direction or Config.SortDirection
	sortType = sortType or Config.DefaultSortType

	local cacheKey = sortType .. "_" .. direction .. "_" .. #babyList
	if sortCache[cacheKey] and sortCache[cacheKey].timestamp and 
		(tick() - sortCache[cacheKey].timestamp) < 60 then
		return sortCache[cacheKey].result
	end

	if Config.EnableMultiSort and sortType == "smart" then
		-- Smart sorting: Rarity first, then price within rarity
		table.sort(babyList, function(a, b)
			local keyA = BabyCollection.getMultiSortKey(a)
			local keyB = BabyCollection.getMultiSortKey(b)

			-- Compare rarity first
			if keyA[1] ~= keyB[1] then
				return direction == "ascending" and keyA[1] < keyB[1] or keyA[1] > keyB[1]
			end

			-- If same rarity, compare price
			if keyA[2] ~= keyB[2] then
				return direction == "ascending" and keyA[2] < keyB[2] or keyA[2] > keyB[2]
			end

			-- If same price, compare generation
			return direction == "ascending" and keyA[3] < keyB[3] or keyA[3] > keyB[3]
		end)
	else
		-- Single criteria sorting
		table.sort(babyList, function(a, b)
			local indexA = BabyCollection.getBabySortIndex(a, sortType)
			local indexB = BabyCollection.getBabySortIndex(b, sortType)

			if sortType == "alphabetical" then
				if direction == "ascending" then
					return tostring(indexA):lower() < tostring(indexB):lower()
				else
					return tostring(indexA):lower() > tostring(indexB):lower()
				end
			end

			if direction == "ascending" then
				return indexA < indexB
			else
				return indexA > indexB
			end
		end)
	end

	-- Cache the result
	sortCache[cacheKey] = {
		result = babyList,
		timestamp = tick()
	}

	return babyList
end

-- ================================
-- ENHANCED PRICE SYSTEM
-- ================================
function BabyCollection.getBabyPrice(babyName)
	if priceCache[babyName] then
		return priceCache[babyName]
	end

	local babyData = BrainrotData.getBabyData(babyName)
	local price = (babyData and babyData.price) or 0

	priceCache[babyName] = price
	return price
end

function BabyCollection.getBabyLayoutOrder(babyName, sortType)
	sortType = sortType or Config.DefaultSortType
	local index = BabyCollection.getBabySortIndex(babyName, sortType)

	-- For certain sort types, we want to invert the order
	if sortType == "rarity" then
		return index * 1000 -- Multiply to avoid conflicts
	elseif sortType == "perSec" and Config.SortDirection == "descending" then
		return 999999 - index -- Higher perSec gets lower layout order
	else
		return index
	end
end

-- ================================
-- VISUAL EFFECTS (UNCHANGED)
-- ================================
function BabyCollection.createMovingZebraEffect(uiGradient)
	if not uiGradient then return end

	uiGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)), 
		ColorSequenceKeypoint.new(0.015625, Color3.new(1, 1, 1)), 
		ColorSequenceKeypoint.new(0.1458333283662796, Color3.new(1, 1, 1)), 
		ColorSequenceKeypoint.new(0.2482638955116272, Color3.new(1, 1, 1)), 
		ColorSequenceKeypoint.new(0.3559027910232544, Color3.new(1, 1, 1)), 
		ColorSequenceKeypoint.new(0.4970000088214874, Color3.new(1, 1, 1)), 
		ColorSequenceKeypoint.new(0.503000020980835, Color3.new(0, 0, 0)), 
		ColorSequenceKeypoint.new(0.647569477558136, Color3.new(0, 0, 0)), 
		ColorSequenceKeypoint.new(0.7829861044883728, Color3.new(0, 0, 0)), 
		ColorSequenceKeypoint.new(0.890625, Color3.new(0, 0, 0)), 
		ColorSequenceKeypoint.new(0.9774305820465088, Color3.new(0, 0, 0)), 
		ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0))
	})

	uiGradient.Rotation = 90

	local startTime = tick()
	local speed = 0.015

	local connection = RunService.Heartbeat:Connect(function()
		if not uiGradient or not uiGradient.Parent then
			if connection then
				connection:Disconnect()
			end
			return
		end

		local elapsed = tick() - startTime
		local offsetValue = (elapsed * speed) % 1
		uiGradient.Offset = Vector2.new(offsetValue, 0)
	end)

	return connection
end

function BabyCollection.createRainbowTweenEffect(textLabel)
	if not textLabel then return end

	local rainbowColors = {
		Color3.fromRGB(255, 0, 0),   -- Red
		Color3.fromRGB(255, 127, 0), -- Orange
		Color3.fromRGB(255, 255, 0), -- Yellow
		Color3.fromRGB(0, 255, 0),   -- Green
		Color3.fromRGB(0, 0, 255),   -- Blue
		Color3.fromRGB(75, 0, 130),  -- Indigo
		Color3.fromRGB(148, 0, 211)  -- Violet
	}

	local currentColorIndex = 1
	local tweenInfo = TweenInfo.new(
		1.5,
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.InOut,
		-1,
		false,
		0
	)

	local function tweenToNextColor()
		if not textLabel or not textLabel.Parent then return end

		currentColorIndex = currentColorIndex + 1
		if currentColorIndex > #rainbowColors then
			currentColorIndex = 1
		end

		local tween = TweenService:Create(textLabel, tweenInfo, {
			TextColor3 = rainbowColors[currentColorIndex]
		})

		tween:Play()

		tween.Completed:Connect(function()
			if textLabel and textLabel.Parent then
				tweenToNextColor()
			end
		end)
	end

	textLabel.TextColor3 = rainbowColors[1]
	tweenToNextColor()
end

-- ================================
-- ENHANCED OWNERSHIP CHECKING
-- ================================
function BabyCollection.checkOwnership(babyName)
	local now = tick()

	if ownershipCache[babyName] and lastOwnershipCheck[babyName] and 
		(now - lastOwnershipCheck[babyName]) < 3 then
		return ownershipCache[babyName]
	end

	local allTimeBabies = player:FindFirstChild("AllTimeBabies")
	if not allTimeBabies then
		ownershipCache[babyName] = false
		lastOwnershipCheck[babyName] = now
		return false
	end

	local function getBabiesDataKey(displayName)
		local cacheKey = "datakey_" .. displayName
		if calculationCache[cacheKey] then
			return calculationCache[cacheKey]
		end

		for key, data in pairs(BrainrotData.Babies) do
			if key == displayName or 
				(data.displayName == displayName) or
				(key:gsub("_", " ") == displayName) or
				(displayName:gsub(" ", "_") == key) then
				calculationCache[cacheKey] = key
				return key
			end
		end

		local result = displayName:gsub(" ", "_")
		calculationCache[cacheKey] = result
		return result
	end

	local babiesDataKey = getBabiesDataKey(babyName)
	local babyValue = allTimeBabies:FindFirstChild(babiesDataKey)
	local isOwned = babyValue and babyValue:IsA("StringValue")

	ownershipCache[babyName] = isOwned
	lastOwnershipCheck[babyName] = now

	return isOwned
end

-- ================================
-- 3D POSITIONING (UNCHANGED)
-- ================================
function BabyCollection.getBaby3DPosition(babyName)
	if positionCache[babyName] then
		return positionCache[babyName]
	end

	local position = (babyName == "Baby_DavidBaszucki" or babyName == "David_Baszucki") and "center" or "bottom"
	positionCache[babyName] = position
	return position
end

function BabyCollection.updateLockedVisibility(template, isOwned, babyName)
	if not template then return end

	local cacheKey = "locked_" .. babyName
	local lockedElement = calculationCache[cacheKey]

	if not lockedElement then
		lockedElement = template:FindFirstChild("Locked") or template:FindFirstChild("Locked", true)
		if lockedElement then
			calculationCache[cacheKey] = lockedElement
		end
	end

	if lockedElement then
		lockedElement.Visible = not isOwned
	end
end

function BabyCollection.setup3DModel(viewportFrame, babyName, isOwned)
	local babyModel = Baby3DFolder:FindFirstChild(babyName)
	if not babyModel or not viewportFrame then return nil end

	for _, child in pairs(viewportFrame:GetChildren()) do
		if child.Name ~= "UICorner" and child.Name ~= "UIStroke" and not child:IsA("UIBase") then
			child:Destroy()
		end
	end

	local success, viewportData = pcall(function()
		local modelClone = babyModel:Clone()
		local camera = Instance.new("Camera")
		camera.Parent = viewportFrame
		viewportFrame.CurrentCamera = camera

		local basePrimaryPart = modelClone.PrimaryPart
		if not basePrimaryPart then
			modelClone.PrimaryPart = modelClone:FindFirstChildWhichIsA("BasePart", true)
		end

		local FAR_POSITION = Vector3.new(0, 10000, 0)
		if modelClone.PrimaryPart then
			local offset = FAR_POSITION - modelClone.PrimaryPart.Position
			modelClone:SetPrimaryPartCFrame(CFrame.new(offset) * modelClone.PrimaryPart.CFrame)
			modelClone.PrimaryPart = basePrimaryPart
		end

		modelClone.Parent = viewportFrame
		local position3D = BabyCollection.getBaby3DPosition(babyName)

		local boundingCFrame, boundingSize = modelClone:GetBoundingBox()
		local modelCenter = boundingCFrame.Position
		local maxSize = math.max(boundingSize.X, boundingSize.Y, boundingSize.Z)
		local depthMultiplier = position3D == "center" and 1.2 or 1.0
		local distanceBack = (maxSize / math.tan(math.rad(camera.FieldOfView))) * depthMultiplier

		local center = CFrame.new(modelCenter)
		local cframeOffset = position3D == "center" and 
			CFrame.Angles(math.rad(Config.CameraXRotation), math.rad(Config.CameraYRotation), 0) or 
			CFrame.Angles(math.rad(Config.CameraXRotation), math.rad(Config.CameraYRotation), 0)

		camera.CFrame = center * cframeOffset * CFrame.new(0, 0, (maxSize/2) + distanceBack)
		camera.Focus = center

		return {
			model = modelClone,
			camera = camera,
			modelCenter = modelCenter,
			maxSize = maxSize,
			distanceBack = distanceBack
		}
	end)

	if success and viewportData then
		return viewportData
	end
	return nil
end

-- ================================
-- ENHANCED BATCH PROCESSING
-- ================================
local creationQueue = {}
local isProcessingQueue = false

function BabyCollection.queueTemplateCreation(babyName, layoutOrder, sortType)
	table.insert(creationQueue, {babyName = babyName, layoutOrder = layoutOrder, sortType = sortType})

	if not isProcessingQueue then
		BabyCollection.processCreationQueue()
	end
end

function BabyCollection.processCreationQueue()
	isProcessingQueue = true

	task.spawn(function()
		while #creationQueue > 0 do
			local batch = {}

			for i = 1, math.min(Config.MaxConcurrentCreations, #creationQueue) do
				table.insert(batch, table.remove(creationQueue, 1))
			end

			for _, item in pairs(batch) do
				task.spawn(function()
					BabyCollection.setupTemplateOptimized(item.babyName, item.layoutOrder, item.sortType)
				end)
			end

			task.wait(Config.CreationDelay)
		end

		isProcessingQueue = false
	end)
end

function BabyCollection.setupTemplateOptimized(babyName, layoutOrder, sortType)
	local success, result = pcall(function()
		local isOwned = BabyCollection.checkOwnership(babyName)

		local template = templateFrame:Clone()
		template.Name = babyName
		template.Visible = true
		template.Parent = listFrame

		local viewportFrame = Instance.new("ViewportFrame")
		viewportFrame.Name = "ViewportFrame"
		viewportFrame.Size = UDim2.new(1.0, 0, 1.0, 0)
		viewportFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		viewportFrame.Position = UDim2.new(0.5, 0, 0.35, 0)
		viewportFrame.BackgroundTransparency = 1
		viewportFrame.BorderSizePixel = 0
		viewportFrame.ZIndex = 1
		viewportFrame.Parent = template

		local viewportData = BabyCollection.setup3DModel(viewportFrame, babyName, isOwned)
		if viewportData then
			BabyCollection.viewportData[babyName] = viewportData
		end

		BabyCollection.updateLockedVisibility(template, isOwned, babyName)
		BabyCollection.setupLabels(template, babyName, isOwned)

		template.LayoutOrder = layoutOrder or BabyCollection.getBabyLayoutOrder(babyName, sortType)

		BabyCollection.updateTemplateAppearance(template, babyName, isOwned)

		BabyCollection.templates[babyName] = template

		return template
	end)

	return success and result or nil
end

-- ================================
-- ENHANCED TEMPLATE APPEARANCE
-- ================================
function BabyCollection.updateTemplateAppearance(template, babyName, isOwned)
	if not template then return end

	local babyData = BrainrotData.getBabyData(babyName)
	local rarity = (babyData and babyData.rarity) or "Common"
	local rarityInfo = BrainrotData.getRarityInfo(rarity)

	template.BackgroundTransparency = isOwned and 0.7 or 0.9
	template.BorderSizePixel = isOwned and 3 or 1

	if rarityInfo and rarityInfo.color then
		template.BorderColor3 = rarityInfo.color
	else
		template.BorderColor3 = Color3.fromRGB(255, 255, 255)
	end

	if rarity == "God" or rarity == "Secret" or rarity == "Brainrot God" then
		template.BorderSizePixel = isOwned and 4 or 2

		if rarity == "God" then
			local uiStroke = template:FindFirstChild("UIStroke")
			if not uiStroke then
				uiStroke = Instance.new("UIStroke")
				uiStroke.Parent = template
			end
			uiStroke.Color = Color3.fromRGB(255, 255, 255)
			uiStroke.Thickness = 2
			uiStroke.Transparency = 0.3
		end
	end
end

function BabyCollection.setupLabels(template, babyName, isOwned)
	local nameLabel = template:FindFirstChild("NameLabel", true)
	local rarityLabel = template:FindFirstChild("RarityLabel", true)
	local priceLabel = template:FindFirstChild("PriceLabel", true)

	local babyData = BrainrotData.getBabyData(babyName)
	local rarity = (babyData and babyData.rarity) or "Common"
	local rarityInfo = BrainrotData.getRarityInfo(rarity)

	if nameLabel then
		nameLabel.ZIndex = 2
		local labelSettings = BrainrotData.getNameLabelSettings(babyName)
		nameLabel.Text = labelSettings.text
		nameLabel.TextColor3 = labelSettings.textColor

		if labelSettings.isRainbow and not Config.ReducedQuality then
			BabyCollection.createRainbowTweenEffect(nameLabel)
		end
	end

	if rarityLabel then
		rarityLabel.ZIndex = 2
		rarityLabel.Text = rarity

		if rarityInfo then
			rarityLabel.TextColor3 = rarityInfo.textColor or rarityInfo.color

			if rarity == "God" and rarityInfo.isRainbow then
				BabyCollection.createRainbowTweenEffect(rarityLabel)
			elseif rarity == "Secret" and rarityInfo.isZebra then
				local uiGradient = rarityLabel:FindFirstChild("UIGradient")
				if not uiGradient then
					uiGradient = Instance.new("UIGradient")
					uiGradient.Parent = rarityLabel
				end
				BabyCollection.createMovingZebraEffect(uiGradient)

				local uiStroke = rarityLabel:FindFirstChild("UIStroke")
				if not uiStroke then
					uiStroke = Instance.new("UIStroke")
					uiStroke.Parent = rarityLabel
				end
				uiStroke.Color = rarityInfo.strokeColor or Color3.fromRGB(255, 255, 255)
				uiStroke.Thickness = 2
				uiStroke.Transparency = 0
			elseif rarity == "Youtuber" and rarityInfo.strokeColor then
				local uiStroke = rarityLabel:FindFirstChild("UIStroke")
				if not uiStroke then
					uiStroke = Instance.new("UIStroke")
					uiStroke.Parent = rarityLabel
				end
				uiStroke.Color = rarityInfo.strokeColor
				uiStroke.Thickness = 2
				uiStroke.Transparency = 0
			end
		else
			rarityLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		end
	end

	if priceLabel and babyData then
		priceLabel.ZIndex = 2
		priceLabel.Text = BrainrotData.formatCurrency(babyData.price)

		if rarityInfo then
			priceLabel.TextColor3 = rarityInfo.textColor or rarityInfo.color
		else
			priceLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		end
	end
end

-- ================================
-- ENHANCED BATCH UPDATE SYSTEM
-- ================================
local updateBatchTimer = nil

function BabyCollection.queueUpdate(babyName)
	table.insert(BabyCollection.updateQueue, babyName)

	if updateBatchTimer then
		task.cancel(updateBatchTimer)
	end

	updateBatchTimer = task.delay(0.1, function()
		BabyCollection.processBatchUpdates()
	end)
end

function BabyCollection.processBatchUpdates()
	local uniqueUpdates = {}

	for _, babyName in pairs(BabyCollection.updateQueue) do
		uniqueUpdates[babyName] = true
	end

	for babyName in pairs(uniqueUpdates) do
		BabyCollection.updateBaby(babyName)
	end

	BabyCollection.updateQueue = {}
end

function BabyCollection.updateBaby(babyName)
	local template = BabyCollection.templates[babyName]
	if not template then return end

	ownershipCache[babyName] = nil
	lastOwnershipCheck[babyName] = nil

	local isOwned = BabyCollection.checkOwnership(babyName)
	BabyCollection.updateLockedVisibility(template, isOwned, babyName)
	BabyCollection.updateTemplateAppearance(template, babyName, isOwned)
end

-- ================================
-- ENHANCED CLEANUP
-- ================================
function BabyCollection.cleanup()
	for babyName, viewportData in pairs(BabyCollection.viewportData) do
		if viewportData and viewportData.model and viewportData.model.Destroy then
			viewportData.model:Destroy()
		end
	end

	BabyCollection.templates = {}
	BabyCollection.viewportData = {}
	BabyCollection.updateQueue = {}

	ownershipCache = {}
	lastOwnershipCheck = {}
	calculationCache = {}
	positionCache = {}
	priceCache = {}
	indexCache = {}
	cacheTimestamps = {}
	sortCache = {}
end

-- ================================
-- ENHANCED POPULATE COLLECTION WITH ADVANCED SORTING
-- ================================
function BabyCollection.populateCollection(sortType, direction)
	sortType = sortType or Config.DefaultSortType
	direction = direction or Config.SortDirection

	templateFrame.Visible = false

	-- Clean existing templates
	for _, child in pairs(listFrame:GetChildren()) do
		if child ~= templateFrame and not child:IsA("UIListLayout") and not child:IsA("UIGridLayout") then
			child:Destroy()
		end
	end

	-- Get all babies
	local allBabiesFromFolder = {}
	for _, baby3DModel in pairs(Baby3DFolder:GetChildren()) do
		if baby3DModel:IsA("Model") then
			table.insert(allBabiesFromFolder, baby3DModel.Name)
		end
	end

	if #allBabiesFromFolder == 0 then return end

	-- Sort babies using enhanced sorting system
	allBabiesFromFolder = BabyCollection.sortBabies(allBabiesFromFolder, sortType, direction)

	-- Queue templates with proper layout order
	for i, babyName in ipairs(allBabiesFromFolder) do
		BabyCollection.queueTemplateCreation(babyName, i, sortType)
	end

	print("Collection populated with", #allBabiesFromFolder, "babies using", sortType, "sort in", direction, "order")
end

-- ================================
-- PUBLIC SORTING FUNCTIONS
-- ================================
function BabyCollection.sortByPrice(direction)
	BabyCollection.populateCollection("price", direction or "ascending")
end

function BabyCollection.sortByRarity(direction)
	BabyCollection.populateCollection("rarity", direction or "ascending")
end

function BabyCollection.sortByGeneration(direction)
	BabyCollection.populateCollection("generation", direction or "ascending")
end

function BabyCollection.sortByPerSec(direction)
	BabyCollection.populateCollection("perSec", direction or "descending")
end

function BabyCollection.sortByAlphabetical(direction)
	BabyCollection.populateCollection("alphabetical", direction or "ascending")
end

function BabyCollection.smartSort()
	BabyCollection.populateCollection("smart", "ascending")
end

-- ================================
-- OWNERSHIP LISTENER (UNCHANGED)
-- ================================
local ownershipConnections = {}

local function connectOwnershipListener()
	for _, connection in pairs(ownershipConnections) do
		if connection then
			connection:Disconnect()
		end
	end
	ownershipConnections = {}

	local allTimeBabies = player:FindFirstChild("AllTimeBabies")
	if not allTimeBabies then
		local connection = player.ChildAdded:Connect(function(child)
			if child.Name == "AllTimeBabies" then
				connectOwnershipListener()
			end
		end)
		table.insert(ownershipConnections, connection)
		return
	end

	for _, babyValue in pairs(allTimeBabies:GetChildren()) do
		if babyValue:IsA("StringValue") then
			local connection = babyValue.Changed:Connect(function()
				BabyCollection.queueUpdate(babyValue.Name)
			end)
			table.insert(ownershipConnections, connection)
		end
	end

	local connection = allTimeBabies.ChildAdded:Connect(function(child)
		if child:IsA("StringValue") then
			local childConnection = child.Changed:Connect(function()
				BabyCollection.queueUpdate(child.Name)
			end)
			table.insert(ownershipConnections, childConnection)

			task.wait(0.1)
			BabyCollection.queueUpdate(child.Name)
		end
	end)
	table.insert(ownershipConnections, connection)
end

-- ================================
-- INITIALIZATION
-- ================================
local function initialize()
	task.wait(0.5)
	connectOwnershipListener()

	task.wait(0.3)
	BabyCollection.populateCollection()

	-- Example usage - uncomment to test different sorting:
	-- BabyCollection.smartSort() -- Rarity first, then price within rarity
	-- BabyCollection.sortByRarity("ascending") -- Rarest first
	-- BabyCollection.sortByPrice("ascending") -- Cheapest first
	-- BabyCollection.sortByPerSec("descending") -- Highest income first
end

task.spawn(initialize)

script.AncestryChanged:Connect(function()
	if not script.Parent then
		BabyCollection.cleanup()
	end
end)

-- ================================
-- EXPORT FUNCTIONS FOR EXTERNAL USE
-- ================================
_G.BabyCollection = BabyCollection -- Make available globally if needed