-- TheftManager.lua - OPTIMIZED WITH BUG FIXES
local TheftManager = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

-- Dependencies
local GameUtilities = require(game:GetService("ReplicatedStorage"):WaitForChild("ModuleScripts"):WaitForChild("GameUtilities"))
local UIManager = require(game:GetService("ReplicatedStorage"):WaitForChild("ModuleScripts"):WaitForChild("UIManager"))
local BabyManager = require(game:GetService("ServerScriptService"):WaitForChild("ModuleScripts"):WaitForChild("BabyManager"))
local CollectionManager = require(game:GetService("ServerScriptService"):WaitForChild("ModuleScripts"):WaitForChild("CollectionManager"))
local ErrorHandler = require(game:GetService("ReplicatedStorage"):WaitForChild("ModuleScripts"):WaitForChild("ErrorHandler"))

-- Initialize workspace references
TheftManager.babiesFolder = game:GetService("ServerStorage"):WaitForChild("BrainrotsRarities")
TheftManager.soundRemote = nil
TheftManager.continuousSoundRemote = nil

-- Constants
local DEFAULT_WALK_SPEED = 26
local STEALING_WALK_SPEED = 17
local SPEED_TRANSITION_TIME = 0.1

-- Theft state storage
local carriedBabies = {}
local activeThefts = {}
local persistentErrors = {}
local continuousSounds = {}
local speedTransitions = {}

-- Helper function to safely and smoothly change player speed
local function changePlayerSpeed(player, targetSpeed, immediate)
	if not player or not player.Parent then return end

	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Cancel any existing speed transition
	if speedTransitions[player] then
		speedTransitions[player]:Disconnect()
		speedTransitions[player] = nil
	end

	if immediate then
		humanoid.WalkSpeed = targetSpeed
		return
	end

	-- Smooth speed transition to prevent character bugs
	local startSpeed = humanoid.WalkSpeed
	local startTime = tick()

	speedTransitions[player] = RunService.Heartbeat:Connect(function()
		local elapsed = tick() - startTime
		local alpha = math.min(elapsed / SPEED_TRANSITION_TIME, 1)

		if player.Parent and character.Parent and humanoid.Parent then
			local currentSpeed = startSpeed + (targetSpeed - startSpeed) * alpha
			humanoid.WalkSpeed = currentSpeed

			if alpha >= 1 then
				speedTransitions[player]:Disconnect()
				speedTransitions[player] = nil
			end
		else
			speedTransitions[player]:Disconnect()
			speedTransitions[player] = nil
		end
	end)
end

-- Helper function to safely restore player speed
local function restorePlayerSpeed(player)
	changePlayerSpeed(player, DEFAULT_WALK_SPEED, false)
end

-- Helper function to safely set stealing speed
local function setStealingSpeed(player)
	changePlayerSpeed(player, STEALING_WALK_SPEED, false)
end

-- Enhanced player validation
local function validatePlayer(player)
	return player and player.Parent and player.Character and player.Character:FindFirstChildOfClass("Humanoid")
end

-- Enhanced character validation
local function validateCharacter(character)
	return character and character.Parent and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChildOfClass("Humanoid")
end

function TheftManager.showPersistentError(player, errorType, ...)
	if not validatePlayer(player) then return end

	local errorKey = player.UserId .. "_" .. errorType
	persistentErrors[errorKey] = true
	ErrorHandler.ShowError(player, errorType, ...)
end

function TheftManager.clearPersistentError(player, errorType)
	if not validatePlayer(player) then return end

	local errorKey = player.UserId .. "_" .. errorType
	if persistentErrors[errorKey] then
		persistentErrors[errorKey] = nil
		ErrorHandler.ClearPersistentMessage(player)
	end
end

function TheftManager.startContinuousSound(player, soundName)
	if not validatePlayer(player) then return end

	if continuousSounds[player.UserId] then return end

	continuousSounds[player.UserId] = true
	if TheftManager.continuousSoundRemote then
		TheftManager.continuousSoundRemote:FireClient(player, "start", soundName)
	end
end

function TheftManager.stopContinuousSound(player)
	if not player then return end

	if continuousSounds[player.UserId] then
		continuousSounds[player.UserId] = nil
		if TheftManager.continuousSoundRemote then
			TheftManager.continuousSoundRemote:FireClient(player, "stop")
		end
	end
end

-- Enhanced cleanup function
local function cleanupCarriedBaby(carriedData)
	if not carriedData then return end

	-- Clean up model
	if carriedData.model and carriedData.model.Parent then
		carriedData.model:Destroy()
	end

	-- Clean up animation safely
	if carriedData.animation then
		pcall(function()
			if carriedData.animation.IsPlaying then
				carriedData.animation:Stop()
			end
			carriedData.animation:Destroy()
		end)
	end

	-- Clean up original baby attributes
	if carriedData.originalBaby and carriedData.originalBaby.Parent then
		carriedData.originalBaby:SetAttribute("IsBeingStolen", nil)
		carriedData.originalBaby:SetAttribute("ThiefUserId", nil)
	end
end

function TheftManager.detachBabyFromPlayer(player)
	local carriedData = carriedBabies[player]
	if not carriedData then return end

	-- Remove from pending babies
	if BabyManager and BabyManager.removePendingBaby then
		BabyManager.removePendingBaby(player)
	end

	-- Clean up carried baby
	cleanupCarriedBaby(carriedData)

	-- Clear owner error messages
	local originalOwner = carriedData.originalOwner
	if originalOwner and originalOwner.Parent then
		TheftManager.clearPersistentError(originalOwner, "BEING_STOLEN_PERSISTENT")
		TheftManager.stopContinuousSound(originalOwner)
	end

	-- Clear thief messages
	TheftManager.clearPersistentError(player, "STEALING_PERSISTENT")
	TheftManager.stopContinuousSound(player)

	-- Restore speed smoothly
	restorePlayerSpeed(player)

	-- Clear carried baby data
	carriedBabies[player] = nil
end

-- Enhanced baby physics setup
local function setupCarriedBabyPhysics(carriedBaby)
	-- Wait one frame to ensure proper physics setup
	RunService.Heartbeat:Wait()

	for _, part in ipairs(carriedBaby:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
			part.CanTouch = false
			part.Massless = true

			-- Reset velocities to prevent physics conflicts
			part.AssemblyLinearVelocity = Vector3.zero
			part.AssemblyAngularVelocity = Vector3.zero

			-- Disable all constraints except the main weld
			for _, constraint in ipairs(part:GetChildren()) do
				if constraint:IsA("Constraint") and not constraint:IsA("WeldConstraint") then
					constraint.Enabled = false
				end
			end
		end
	end
end

function TheftManager.attachBabyToPlayer(babyModel, player, originalOwner)
	local character = player.Character
	if not validateCharacter(character) then return false end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

	if carriedBabies[player] then return false end

	-- Set stealing speed smoothly
	setStealingSpeed(player)

	if BabyManager and BabyManager.addPendingBaby then
		BabyManager.addPendingBaby(player)
	end

	-- Create and setup animation
	local track = nil
	if GameUtilities.STEALING_ANIMATION_ID then
		local animation = Instance.new("Animation")
		animation.AnimationId = GameUtilities.STEALING_ANIMATION_ID
		track = humanoid:LoadAnimation(animation)
		track.Priority = Enum.AnimationPriority.Action
		track.Looped = true -- Changed to looped for better stability
		track:Play()

		-- Adjust animation speed after a short delay
		task.delay(0.1, function()
			if track and track.IsPlaying and player.Parent then
				track:AdjustSpeed(0.5) -- Slower speed instead of 0 to prevent freezing
			end
		end)
	end

	local babyName = babyModel.Name
	local babyTemplate = TheftManager.babiesFolder:FindFirstChild(babyName, true)
	if not babyTemplate then return false end

	local carriedBaby = babyTemplate:Clone()
	carriedBaby.Name = babyName .. "_Carried"
	carriedBaby.Parent = workspace

	if not GameUtilities.setupBabyAnchoring(carriedBaby, false) then
		carriedBaby:Destroy()
		return false
	end

	-- Remove proxy to prevent interaction conflicts
	local proxy = carriedBaby:FindFirstChild("Proxy")
	if proxy then
		proxy:Destroy()
	end

	-- Setup physics after model is fully loaded
	setupCarriedBabyPhysics(carriedBaby)

	-- Position and attach baby
	local offset = CFrame.new(0, 1.1, -2.2)
	local carriedCFrame = humanoidRootPart.CFrame * offset

	if GameUtilities.calculateCarriedBabyRotation then
		local rotationCFrame = GameUtilities.calculateCarriedBabyRotation(humanoidRootPart.CFrame)
		carriedCFrame = carriedCFrame * rotationCFrame
	end

	carriedBaby:PivotTo(carriedCFrame)

	-- Create stable weld
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = humanoidRootPart
	weld.Part1 = carriedBaby.PrimaryPart
	weld.Parent = carriedBaby.PrimaryPart

	-- Store carried baby data
	carriedBabies[player] = {
		model = carriedBaby,
		originalBaby = babyModel,
		animation = track,
		babyName = babyName,
		originalOwner = originalOwner,
		weld = weld
	}

	-- Set baby attributes
	babyModel:SetAttribute("IsBeingStolen", true)
	babyModel:SetAttribute("ThiefUserId", player.UserId)

	-- Update UI
	if UIManager.setBabyAsStolen then
		UIManager.setBabyAsStolen(babyModel, false)
		UIManager.setBabyAsStolen(carriedBaby, true)
	end

	-- Play sounds
	if TheftManager.soundRemote then
		TheftManager.soundRemote:FireClient(player, "Stealing_From_Someone")
		if originalOwner and originalOwner.Parent then
			TheftManager.soundRemote:FireClient(originalOwner, "Getting_Stoled")
		end
	end

	-- Show persistent messages
	if originalOwner and originalOwner.Parent then
		TheftManager.showPersistentError(originalOwner, "BEING_STOLEN_PERSISTENT", babyName)
		TheftManager.startContinuousSound(originalOwner, "Getting_Stoled")
	end

	TheftManager.showPersistentError(player, "STEALING_PERSISTENT")
	TheftManager.startContinuousSound(player, "Stealing_From_Someone")

	return true
end

function TheftManager.canStealBaby(babyModel, thief)
	if not babyModel or not validatePlayer(thief) then
		return false, "Invalid parameters"
	end

	local owner = babyModel:FindFirstChild("Owner")
	if not owner or not owner.Value then
		return false, "No owner found"
	end

	local babyOwner = owner.Value

	-- Prevent stealing from own base
	if babyOwner == thief then
		return false, "CANNOT_STEAL_OWN_BASE"
	end

	-- Check if baby is already being stolen
	if babyModel:GetAttribute("IsBeingStolen") then
		return false, "BABY_BEING_STOLEN"
	end

	-- Check if thief is already carrying a baby
	if carriedBabies[thief] then
		return false, "ALREADY_CARRYING"
	end

	-- Check baby limit
	if GameUtilities.canPlayerBuyBaby and BabyManager.pendingBabies then
		if not GameUtilities.canPlayerBuyBaby(thief, BabyManager.pendingBabies) then
			return false, "TOO_MANY_BABIES_STEAL"
		end
	end

	return true, "Can steal"
end

function TheftManager.startTheft(babyModel, thief, originalOwner, babyName, standNumber)
	local canSteal, reason = TheftManager.canStealBaby(babyModel, thief)
	if not canSteal then
		ErrorHandler.ShowError(thief, reason)
		return false
	end

	if TheftManager.attachBabyToPlayer(babyModel, thief, originalOwner) then
		activeThefts[thief] = {
			baby = babyModel,
			originalOwner = originalOwner,
			babyName = babyName,
			standNumber = standNumber,
			startTime = tick()
		}
		return true
	else
		ErrorHandler.ShowError(thief, "BABY_BEING_STOLEN")
		return false
	end
end

function TheftManager.completeTheft(thief, babyName)
	local carriedData = carriedBabies[thief]
	if not carriedData then return false end

	local originalBaby = carriedData.originalBaby
	local originalOwner = carriedData.originalOwner

	if originalBaby and originalBaby.Parent then
		-- Clean up moving babies references
		if BabyManager.movingBabiesList then
			for i, movingBaby in ipairs(BabyManager.movingBabiesList) do
				if movingBaby == originalBaby then
					table.remove(BabyManager.movingBabiesList, i)
					break
				end
			end
		end

		if BabyManager.movingBabies and BabyManager.movingBabies[originalBaby] then
			BabyManager.movingBabies[originalBaby]:Disconnect()
			BabyManager.movingBabies[originalBaby] = nil
		end

		originalBaby:Destroy()
	end

	-- Clean up theft data
	TheftManager.detachBabyFromPlayer(thief)
	activeThefts[thief] = nil

	if originalOwner and originalOwner.Parent then
		TheftManager.clearPersistentError(originalOwner, "BEING_STOLEN_PERSISTENT")
		TheftManager.stopContinuousSound(originalOwner)
	end

	local babyTemplate = TheftManager.babiesFolder:FindFirstChild(babyName, true)
	if not babyTemplate then
		if BabyManager.removePendingBaby then
			BabyManager.removePendingBaby(thief)
		end
		ErrorHandler.ShowError(thief, "BABY_BEING_STOLEN")
		return false
	end

	local newBaby = babyTemplate:Clone()
	newBaby.Parent = workspace

	if not GameUtilities.setupBabyAnchoring(newBaby, false) then
		newBaby:Destroy()
		if BabyManager.removePendingBaby then
			BabyManager.removePendingBaby(thief)
		end
		ErrorHandler.ShowError(thief, "BABY_BEING_STOLEN")
		return false
	end

	if BabyManager.processBabyAtLaser then
		BabyManager.processBabyAtLaser(newBaby, thief, babyName)
	end

	-- Update steals stat
	if _G.DataManager and _G.DataManager.addSteals then
		_G.DataManager.addSteals(thief, 1)
	else
		local leaderstats = thief:FindFirstChild("leaderstats")
		if leaderstats then
			local steals = leaderstats:FindFirstChild("Steals")
			if steals then
				steals.Value = steals.Value + 1
			end
		end
	end

	ErrorHandler.ShowError(thief, "SUCCESS_STEAL")
	return true
end

function TheftManager.forceReturnStolenBaby(player)
	local carriedData = carriedBabies[player]
	if not carriedData then return false end

	local originalBaby = carriedData.originalBaby
	local originalOwner = carriedData.originalOwner
	local rawBabyName = carriedData.babyName

	if not originalBaby or not originalBaby.Parent then return false end
	if not originalOwner or not originalOwner.Parent then return false end

	local standNumber = originalBaby:FindFirstChild("StandNumber")
	if not standNumber then return false end

	local standNum = standNumber.Value
	local cleanBabyName = rawBabyName:gsub("_Carried", ""):gsub("_Stolen", "")

	-- Get stand location
	local ownedBase = originalOwner:FindFirstChild("OwnedBase")
	if not ownedBase then return false end

	local base = workspace.Bases:FindFirstChild("Base" .. ownedBase.Value)
	if not base then return false end

	local stands = base:FindFirstChild("Stands")
	if not stands then return false end

	local stand = stands:FindFirstChild("Stand" .. standNum)
	if not stand then return false end

	-- Clean up theft data first
	TheftManager.detachBabyFromPlayer(player)
	activeThefts[player] = nil

	-- Clear owner messages
	if originalOwner and originalOwner.Parent then
		TheftManager.clearPersistentError(originalOwner, "BEING_STOLEN_PERSISTENT")
		TheftManager.stopContinuousSound(originalOwner)
	end

	-- Return baby to stand
	originalBaby.Parent = stand
	if originalBaby.PrimaryPart and stand.PrimaryPart then
		originalBaby:SetPrimaryPartCFrame(stand.PrimaryPart.CFrame * CFrame.new(0, 3, 0))
	end

	-- Clear all theft attributes
	originalBaby:SetAttribute("IsBeingStolen", nil)
	originalBaby:SetAttribute("ThiefUserId", nil)
	originalBaby:SetAttribute("CollectionActive", nil)
	stand:SetAttribute("BeingStolen", false)
	stand:SetAttribute("Locked", false)
	stand:SetAttribute("Collected", false)

	-- Re-enable proximity prompt
	local proxy = originalBaby:FindFirstChild("Proxy")
	if proxy then
		local prompt = proxy:FindFirstChild("ProximityPrompt")
		if prompt then
			prompt.Enabled = true
		end
	end

	-- Restore UI
	if UIManager.restoreBabyFromStolen then
		UIManager.restoreBabyFromStolen(originalBaby, cleanBabyName)
	end

	-- Ensure baby data folder exists
	if GameUtilities and GameUtilities.createBabyDataFolder then
		GameUtilities.createBabyDataFolder(originalOwner, cleanBabyName, standNum)
	end

	-- Wait for systems to stabilize
	task.wait(0.1)

	-- Restart income generation
	if _G.CreateStandIncomeTimer then
		_G.CreateStandIncomeTimer(originalOwner, standNum, cleanBabyName, originalBaby)
	end

	-- Setup collection system
	if CollectionManager and CollectionManager.setupStandCollection then
		CollectionManager.setupStandCollection(originalOwner, standNum, cleanBabyName, originalBaby)
	end

	-- Fire baby spawned event
	if _G.BabySpawned then
		_G.BabySpawned:Fire(originalOwner, originalBaby, cleanBabyName, standNum)
	end

	return true
end

function TheftManager.clearPlayerTheftData(player)
	if not player then return end

	-- Clean up speed transitions
	if speedTransitions[player] then
		speedTransitions[player]:Disconnect()
		speedTransitions[player] = nil
	end

	-- Restore speed immediately for cleanup
	if validatePlayer(player) then
		changePlayerSpeed(player, DEFAULT_WALK_SPEED, true)
	end

	-- Clean up active theft
	if activeThefts[player] then
		local theftData = activeThefts[player]
		if theftData.baby and theftData.baby.Parent then
			TheftManager.detachBabyFromPlayer(player)
			local proxy = theftData.baby:FindFirstChild("Proxy")
			if proxy then
				local prompt = proxy:FindFirstChild("ProximityPrompt")
				if prompt then
					prompt.Enabled = true
				end
			end
			if UIManager.restoreBabyFromStolen then
				UIManager.restoreBabyFromStolen(theftData.baby, theftData.babyName)
			end
		end
		activeThefts[player] = nil
	end

	-- Clean up carried baby
	if carriedBabies[player] then
		TheftManager.detachBabyFromPlayer(player)
	end

	-- Clean up persistent errors
	for errorKey, _ in pairs(persistentErrors) do
		if errorKey:find(tostring(player.UserId) .. "_") then
			persistentErrors[errorKey] = nil
			ErrorHandler.ClearPersistentMessage(player)
		end
	end

	TheftManager.stopContinuousSound(player)
end

-- Utility functions
function TheftManager.restorePlayerSpeed(player)
	restorePlayerSpeed(player)
end

function TheftManager.isPlayerStealing(player)
	return carriedBabies[player] ~= nil
end

function TheftManager.getCarriedBaby(player)
	return carriedBabies[player] and carriedBabies[player].model or nil
end

function TheftManager.getTheftStatus(player)
	return {
		isCarrying = carriedBabies[player] ~= nil,
		theftData = activeThefts[player],
		carriedBaby = carriedBabies[player]
	}
end

-- Cleanup on player leaving
Players.PlayerRemoving:Connect(function(player)
	TheftManager.clearPlayerTheftData(player)
end)

-- Export state for other modules
TheftManager.carriedBabies = carriedBabies
TheftManager.activeThefts = activeThefts
TheftManager.persistentErrors = persistentErrors

return TheftManager