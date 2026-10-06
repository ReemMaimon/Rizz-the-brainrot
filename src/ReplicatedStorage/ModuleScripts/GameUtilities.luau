-- Place in ReplicatedStorage > ModuleScripts
-- Common utility functions used across the baby management system

local GameUtilities = {}

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local BrainrotConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("BrainrotConfig"))

local function getBrainrotDefinition(modelName)
	return BrainrotConfig.GetByModelName(modelName) or BrainrotConfig.Get(modelName)
end

local function findBrainrotTemplate(folder, modelName)
	if not folder then return nil end
	local direct = folder:FindFirstChild(modelName)
	if direct and direct:IsA("Model") then return direct end
	for _, descendant in ipairs(folder:GetDescendants()) do
		if descendant:IsA("Model") and descendant.Name == modelName then return descendant end
	end
	return nil
end

function GameUtilities.setBrainrotConfig(config)
	BrainrotConfig = config or BrainrotConfig
end

function GameUtilities.setBabiesData(config)
	GameUtilities.setBrainrotConfig(config)
end

-- Constants
GameUtilities.MAX_PLAYERS = 8
GameUtilities.MAX_STANDS = 10
GameUtilities.MOVE_DURATION = 45
GameUtilities.BABY_TO_BASE_SPEED = 8
GameUtilities.BASE_LOCK_DURATION = 40
GameUtilities.BABY_SPAWN_INTERVAL = 2

-- Hold durations
GameUtilities.STEAL_HOLD_DURATION = 1.5
GameUtilities.PURCHASE_HOLD_DURATION = 0.7
GameUtilities.SELL_HOLD_DURATION = 1.2

-- Animation ID
GameUtilities.STEALING_ANIMATION_ID = "rbxassetid://70837675618257"

-- Workspace references (initialize these in main script)
GameUtilities.workspace = nil
GameUtilities.basesFolder = nil
GameUtilities.babiesFolder = ServerStorage:WaitForChild("BrainrotsRarities")
GameUtilities.StartingLine = nil
GameUtilities.FinishLine = nil
GameUtilities.MovingOn = nil
GameUtilities.FORWARD_DIRECTION = nil

function GameUtilities.formatTime(seconds)
	if seconds >= 60 then
		local minutes = math.floor(seconds / 60)
		local remainingSeconds = seconds % 60
		if remainingSeconds > 0 then
			return minutes .. "m " .. remainingSeconds .. "s"
		else
			return minutes .. "m"
		end
	else
		return seconds .. "s"
	end
end

function GameUtilities.formatNumber(number)
	-- Add number formatting function if it doesn't exist
	if number >= 1e12 then
		return string.format("%.2fT", number / 1e12)
	elseif number >= 1e9 then
		return string.format("%.2fB", number / 1e9)
	elseif number >= 1e6 then
		return string.format("%.2fM", number / 1e6)
	elseif number >= 1e3 then
		return string.format("%.2fK", number / 1e3)
	else
		return tostring(math.floor(number))
	end
end

function GameUtilities.getActivePlayers(playerBases)
	local count = 0
	for _, _ in pairs(playerBases) do
		count = count + 1
	end
	return count
end

function GameUtilities.findAvailableBase(basePlayers)
	for i = 1, GameUtilities.MAX_PLAYERS do
		if not basePlayers[i] then
			return i
		end
	end
	return nil
end

function GameUtilities.getBaseSpawnPosition(baseNumber)
	local baseName = "Base" .. baseNumber
	local base = GameUtilities.basesFolder:FindFirstChild(baseName)
	if base then
		local touchingPart = base:FindFirstChild("TouchingPart")
		if touchingPart and touchingPart:IsA("BasePart") then
			return touchingPart.Position + Vector3.new(0, 5, 0)
		else
			local basePrimaryPart = base.PrimaryPart or base:FindFirstChildWhichIsA("BasePart")
			if basePrimaryPart then
				return basePrimaryPart.Position + Vector3.new(0, 5, 0)
			end
		end
	end
	return Vector3.new(0, 50, 0)
end

function GameUtilities.setupBabyAnchoring(babyModel, isMoving)
	if not babyModel or not babyModel.Parent then return false end

	-- Ensure PrimaryPart is set
	if not babyModel.PrimaryPart then
		local basePart = babyModel:FindFirstChildWhichIsA("BasePart")
		if basePart then
			babyModel.PrimaryPart = basePart
		else
			return false
		end
	end

	-- Set all parts properly
	for _, part in pairs(babyModel:GetDescendants()) do
		if part:IsA("BasePart") then
			if part == babyModel.PrimaryPart then
				part.Anchored = true
			else
				part.Anchored = false
			end
			part.CanCollide = false
			part.CanTouch = false

			-- Disable all physics for stability
			if part:IsA("BasePart") then
				part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
				part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
			end
		end
	end

	return true
end

-- All babies should face toward their collect area
function GameUtilities.getStandOrientation(standNumber)
	-- ALL stands face toward their collect area
	return "front" -- Always face toward collect
end

-- Calculate proper baby rotation for stands - ALL face toward collect
function GameUtilities.calculateBabyStandRotation(placeholder, collect, standNumber)
	local placeholderPos = placeholder.Position
	local collectPosition = collect.Position

	-- ALL babies face toward their collect area (green part)
	local lookDirection = (collectPosition - placeholderPos).Unit
	return CFrame.lookAt(Vector3.new(0, 0, 0), Vector3.new(lookDirection.X, 0, lookDirection.Z)) - Vector3.new(0, 0, 0)
end

-- Calculate baby rotation when moving to base (purchasing)
function GameUtilities.calculateBabyPurchaseRotation(startPos, basePos)
	-- When purchasing, face toward the base (front)
	local baseDirection = (basePos - startPos).Unit
	return CFrame.lookAt(Vector3.new(0, 0, 0), Vector3.new(baseDirection.X, 0, baseDirection.Z)) - Vector3.new(0, 0, 0)
end

-- Calculate carried baby rotation (when stealing) - OPPOSITE direction
function GameUtilities.calculateCarriedBabyRotation(characterCFrame)
	-- Face OPPOSITE direction of character (if player faces north, baby faces south)
	local characterDirection = characterCFrame.LookVector
	local oppositeDirection = -characterDirection -- OPPOSITE direction
	return CFrame.lookAt(Vector3.new(0, 0, 0), Vector3.new(oppositeDirection.X, 0, oppositeDirection.Z)) - Vector3.new(0, 0, 0)
end

-- SAFE validation functions that don't cause circular dependencies
function GameUtilities.isValidBabyModel(model)
	if not model or not model:IsA("Model") then return false end

	-- Basic structure check without requiring BabiesData
	local textPart = model:FindFirstChild("Text")
	if not textPart then return false end

	-- Must exist in ServerStorage babies folder
	if not GameUtilities.babiesFolder then return false end
	local template = findBrainrotTemplate(GameUtilities.babiesFolder, model.Name)
	if not template then return false end

	-- Must be in valid location
	if not GameUtilities.MovingOn or not GameUtilities.workspace then return false end
	if model.Parent ~= GameUtilities.MovingOn and model.Parent ~= GameUtilities.workspace then return false end

	local brainrotData = getBrainrotDefinition(model.Name)
	if not brainrotData then return false end
	if not brainrotData.Obtainable and (tonumber(brainrotData.SpawnChance) or 0) <= 0 then return false end

	return true
end

function GameUtilities.isValidMovingBaby(model, movingBabiesList)
	-- Must be in our moving babies list
	for _, movingBaby in ipairs(movingBabiesList) do
		if movingBaby == model then
			return true
		end
	end
	return false
end

function GameUtilities.getPlayerBabyCount(player, pendingBabies)
	local babiesFolder = player:FindFirstChild("Brainrots")
	local placedCount = 0
	if babiesFolder then
		for _, folder in pairs(babiesFolder:GetChildren()) do
			if folder:IsA("Folder") then
				placedCount = placedCount + 1
			end
		end
	end

	local pendingCount = pendingBabies[player.UserId] or 0
	local totalCount = placedCount + pendingCount
	return totalCount
end

function GameUtilities.canPlayerBuyBaby(player, pendingBabies)
	return GameUtilities.getPlayerBabyCount(player, pendingBabies) < GameUtilities.MAX_STANDS
end

function GameUtilities.findAvailableStand(player)
	local ownedBase = player:FindFirstChild("OwnedBase")
	if not ownedBase then return nil, nil end

	local baseNumber = ownedBase.Value
	local baseName = "Base" .. baseNumber
	local base = GameUtilities.basesFolder:FindFirstChild(baseName)
	if not base then return nil, nil end

	local standsFolder = base:FindFirstChild("Stands")
	if not standsFolder then return nil, nil end

	local babiesFolder = player:FindFirstChild("Brainrots")
	if not babiesFolder then return nil, nil end

	local usedStandNumbers = {}
	local totalBabies = 0

	for _, folder in pairs(babiesFolder:GetChildren()) do
		local standNumber = folder:FindFirstChild("StandNumber")
		if standNumber and typeof(standNumber.Value) == "number" then
			usedStandNumbers[standNumber.Value] = true
			totalBabies = totalBabies + 1
		end
	end

	if totalBabies >= GameUtilities.MAX_STANDS then
		return nil, nil
	end

	for i = 1, GameUtilities.MAX_STANDS do
		if not usedStandNumbers[i] then
			local stand = standsFolder:FindFirstChild("Stand" .. i)
			if stand then
				return stand, i
			end
		end
	end

	return nil, nil
end

-- SAFE baby selection that doesn't cause circular dependencies
function GameUtilities.getWeightedBaby()
	if not GameUtilities.babiesFolder then return nil end
	local candidates = {}
	local totalWeight = 0
	for modelName, definition in pairs(BrainrotConfig.ModelDefinitions or {}) do
		local weight = tonumber(definition.SpawnChance) or 0
		local template = findBrainrotTemplate(GameUtilities.babiesFolder, modelName)
		if template and definition.Obtainable and weight > 0 then
			table.insert(candidates, {template = template, weight = weight})
			totalWeight += weight
		end
	end
	if totalWeight <= 0 then return nil end
	local roll = math.random() * totalWeight
	local cumulative = 0
	for _, candidate in ipairs(candidates) do
		cumulative += candidate.weight
		if roll <= cumulative then return candidate.template end
	end
	return candidates[#candidates].template
end

function GameUtilities.createBabyDataFolder(player, babyName, standNumber)
	local babiesFolder = player:FindFirstChild("Brainrots")
	if not babiesFolder then
		babiesFolder = Instance.new("Folder")
		babiesFolder.Name = "Brainrots"
		babiesFolder.Parent = player
	end

	local babyData = getBrainrotDefinition(babyName)
	if not babyData then return end

	local folderName = babyName .. "_Stand" .. standNumber

	local existingFolder = babiesFolder:FindFirstChild(folderName)
	if existingFolder then
		existingFolder:Destroy()
	end

	local babyFolder = Instance.new("Folder")
	babyFolder.Name = folderName
	babyFolder.Parent = babiesFolder

	local nameValue = Instance.new("StringValue")
	nameValue.Name = "BabyName"
	nameValue.Value = babyName
	nameValue.Parent = babyFolder

	local perSecValue = Instance.new("NumberValue")
	perSecValue.Name = "PerSec"
	perSecValue.Value = babyData.perSec
	perSecValue.Parent = babyFolder

	local sellPriceValue = Instance.new("IntValue")
	sellPriceValue.Name = "SellPrice"
	sellPriceValue.Value = math.floor(babyData.price * 0.5)
	sellPriceValue.Parent = babyFolder

	local standValue = Instance.new("IntValue")
	standValue.Name = "StandNumber"
	standValue.Value = standNumber
	standValue.Parent = babyFolder
end

return GameUtilities
