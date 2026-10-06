local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer
local workspace = game.Workspace

local CONFIG = {
	PROMPT_UPDATE_INTERVAL = 0.25,
	COLLECTION_UPDATE_INTERVAL = 0.5,
	CLEANUP_INTERVAL = 45,
	MAX_BABIES_TO_PROCESS = 12,
	MAX_SCAN_DISTANCE_SQUARED = 3600,
	UI_UPDATE_DISTANCE_SQUARED = 10000,
	CHARACTER_CACHE_TIME = 2,
	BASE_CACHE_TIME = 3,
	CLEANUP_TIMEOUT = 90,
	MAX_SOUND_CACHE = 10,
	MAX_ACTIVE_SOUNDS = 2,
	SOUND_TIMEOUT = 3,
	NEAREST_PROMPT_DISTANCE_SQUARED = 100
}

local refs = {}
task.spawn(function()
	refs.playerGui = player:WaitForChild("PlayerGui")
	refs.mainGui = refs.playerGui:WaitForChild("MainGui")
	refs.errorGui = refs.mainGui:WaitForChild("ErrorGui")
	refs.errorText = refs.errorGui:WaitForChild("ErrorText")
	refs.moduleScripts = ReplicatedStorage:WaitForChild("ModuleScripts")
	refs.ErrorHandler = require(refs.moduleScripts:WaitForChild("ErrorHandler"))
end)

local remotes = {}
task.spawn(function()
	remotes.updatePrompt = ReplicatedStorage:WaitForChild("UpdatePrompt")
	remotes.sound = ReplicatedStorage:WaitForChild("PlaySound")
	remotes.showError = ReplicatedStorage:WaitForChild("ShowErrorRemote")
	remotes.continuousSound = ReplicatedStorage:WaitForChild("ContinuousSound")
	for _ = 1, 50 do
		remotes.collectionUI = ReplicatedStorage:FindFirstChild("CollectionUIRemote")
		if remotes.collectionUI then break end
		task.wait(0.1)
	end
end)

local folders = {}
task.spawn(function()
	folders.bases = workspace:WaitForChild("Bases")
	folders.sounds = ReplicatedStorage:WaitForChild("Sounds")
	folders.movingBabies = workspace:FindFirstChild("MovingBabies") or workspace:FindFirstChild("MovingOn")
	folders.defeatedBrainrots = workspace:WaitForChild("DefeatedBrainrots", 20)
end)

local state = {
	disabledCollectionUIs = {},
	cachedPlayerBase = nil,
	lastBaseCheck = 0,
	cachedCharacter = nil,
	cachedHRP = nil,
	lastCharacterCheck = 0,
	billboardCache = {},
	trackedPrompts = {},
	nearbyBabies = {},
	isCurrentlyStealing = false,
	soundCache = {},
	activeSounds = {},
	continuousSound = nil,
	lastPromptUpdate = 0,
	lastCollectionUpdate = 0,
	standFolders = {},
	lastCleanup = 0
}

local currentTick = tick()
RunService.Heartbeat:Connect(function()
	currentTick = tick()
end)

local function getCachedHRP()
	if currentTick - state.lastCharacterCheck > CONFIG.CHARACTER_CACHE_TIME then
		state.lastCharacterCheck = currentTick
		state.cachedCharacter = player.Character
		state.cachedHRP = state.cachedCharacter and state.cachedCharacter:FindFirstChild("HumanoidRootPart")
	end
	return state.cachedHRP
end

local function isWithinRangeSquared(pos1, pos2, maxDistSquared)
	local dx = pos1.X - pos2.X
	local dz = pos1.Z - pos2.Z
	return (dx * dx + dz * dz) <= maxDistSquared
end

local function cleanupTrackedPrompts(babyModels)
	for _, babyModel in pairs(babyModels) do
		if babyModel then
			state.trackedPrompts[babyModel] = nil
			state.nearbyBabies[babyModel] = nil
		end
	end
end

local function isCarryingBaby()
	local hrp = getCachedHRP()
	if not hrp then return false end
	for _, model in pairs(workspace:GetChildren()) do
		if model:IsA("Model") and model.Name:find("_Carried") then
			local weld = model:FindFirstChildOfClass("WeldConstraint")
			if weld and (weld.Part0 == hrp or weld.Part1 == hrp) then
				return true
			end
		end
	end
	return false
end

local function cacheStandFolders()
	local newStandFolders = {}
	local count = 0
	for baseNum = 1, 8 do
		local base = folders.bases and folders.bases:FindFirstChild("Base" .. baseNum)
		if base then
			local standsFolder = base:FindFirstChild("Stands")
			if standsFolder then
				for standNum = 1, 10 do
					local stand = standsFolder:FindFirstChild("Stand" .. standNum)
					if stand then
						count += 1
						newStandFolders[count] = stand
					end
				end
			end
		end
	end
	state.standFolders = newStandFolders
end

local function initializeSoundCache()
	if not folders.sounds then return end
	for _, soundName in pairs({"Collecting_Coins", "Error", "Success", "ButtonPress"}) do
		local sound = folders.sounds:FindFirstChild(soundName)
		if sound then state.soundCache[soundName] = sound end
	end
end

local function playSound(soundName)
	local sound = state.soundCache[soundName] or (folders.sounds and folders.sounds:FindFirstChild(soundName))
	if not sound or not sound:IsA("Sound") then return end
	state.soundCache[soundName] = sound
	if #state.activeSounds >= CONFIG.MAX_ACTIVE_SOUNDS then
		local oldSound = table.remove(state.activeSounds, 1)
		if oldSound and oldSound.Parent then oldSound:Destroy() end
	end
	local soundClone = sound:Clone()
	soundClone.Parent = workspace.CurrentCamera or workspace
	soundClone:Play()
	table.insert(state.activeSounds, soundClone)
	local function cleanup()
		for i, activeSound in pairs(state.activeSounds) do
			if activeSound == soundClone then
				table.remove(state.activeSounds, i)
				break
			end
		end
		if soundClone.Parent then soundClone:Destroy() end
	end
	soundClone.Ended:Connect(cleanup)
	task.delay(CONFIG.SOUND_TIMEOUT, cleanup)
end

local function handleContinuousSound(action, soundName)
	if state.continuousSound then
		state.continuousSound:Stop()
		state.continuousSound:Destroy()
		state.continuousSound = nil
	end
	if action == "start" and soundName then
		local sound = state.soundCache[soundName] or (folders.sounds and folders.sounds:FindFirstChild(soundName))
		if sound and sound:IsA("Sound") then
			state.continuousSound = sound:Clone()
			state.continuousSound.Parent = workspace.CurrentCamera or workspace
			state.continuousSound.Looped = true
			state.continuousSound.Volume = 0.3
			state.continuousSound:Play()
		end
	end
end

local function updatePlayerBaseCache()
	if currentTick - state.lastBaseCheck > CONFIG.BASE_CACHE_TIME then
		state.lastBaseCheck = currentTick
		local ownedBase = player:FindFirstChild("OwnedBase")
		state.cachedPlayerBase = ownedBase and ownedBase.Value or nil
	end
end

local function initializeBillboardCache()
	if state.billboardCache[1] or not folders.bases then return end
	for i = 1, 8 do
		local base = folders.bases:FindFirstChild("Base" .. i)
		if base then
			local baseNameParent = base:FindFirstChild("BaseNameParent")
			local yourBase = baseNameParent and baseNameParent:FindFirstChild("YourBase")
			if yourBase then state.billboardCache[i] = yourBase:FindFirstChild("BillboardGui") end
		end
	end
end

local function setBillboardGuiStates(playerBaseNumber)
	initializeBillboardCache()
	for i = 1, 8 do
		local billboardGui = state.billboardCache[i]
		if billboardGui then billboardGui.Enabled = (i == playerBaseNumber) end
	end
end

local function updateCollectionVisibility()
	updatePlayerBaseCache()
	if not state.cachedPlayerBase or not folders.bases then return end
	local base = folders.bases:FindFirstChild("Base" .. state.cachedPlayerBase)
	local standsFolder = base and base:FindFirstChild("Stands")
	if not standsFolder then return end
	for _, stand in pairs(standsFolder:GetChildren()) do
		if stand.Name:match("^Stand%d+$") then
			local collect = stand:FindFirstChild("Collect")
			local text = collect and collect:FindFirstChild("Text")
			local billboardGui = text and text:FindFirstChild("BillboardGui")
			if billboardGui then
				local hasBaby = false
				for _, child in pairs(stand:GetChildren()) do
					if child:IsA("Model") and child.Name ~= "Collect" and child.Name ~= "Part" then
						hasBaby = true
						break
					end
				end
				local standNumber = tonumber(stand.Name:match("%d+"))
				billboardGui.Enabled = hasBaby and not state.disabledCollectionUIs[standNumber]
			end
		end
	end
end

local function getDeliveredPrompt(model)
	if not model or model:GetAttribute("DeliveredBrainrot") ~= true then return nil end
	local prompt = model:FindFirstChild("PurchaseBrainrotPrompt", true) or model:FindFirstChild("PurchasePrompt", true)
	return prompt and prompt:IsA("ProximityPrompt") and prompt or nil
end

local function enforceDeliveredPrompt(prompt)
	prompt.Enabled = true
	prompt.MaxActivationDistance = 24
	prompt.RequiresLineOfSight = false
	prompt.ActionText = "BUY"
	prompt.HoldDuration = 0
end

local function monitorDeliveredBrainrots()
	local folder = folders.defeatedBrainrots
	if not folder then return end
	for _, model in ipairs(folder:GetChildren()) do
		if model:IsA("Model") then
			local prompt = getDeliveredPrompt(model)
			local root = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
			if prompt and root then
				enforceDeliveredPrompt(prompt)
				state.nearbyBabies[model] = {isMoving = false, owner = nil, prompt = prompt}
				state.trackedPrompts[model] = currentTick
			end
		end
	end
end

local function monitorBabiesInBatches()
	if state.isCurrentlyStealing or isCarryingBaby() then return end
	monitorDeliveredBrainrots()
	local hrp = getCachedHRP()
	if not hrp then return end
	local playerPosition = hrp.Position
	local processed = 0
	local toCleanup = {}
	for babyModel in pairs(state.trackedPrompts) do
		if not babyModel.Parent then table.insert(toCleanup, babyModel) end
	end
	cleanupTrackedPrompts(toCleanup)

	for i = 1, #state.standFolders do
		if processed >= CONFIG.MAX_BABIES_TO_PROCESS then break end
		local standFolder = state.standFolders[i]
		if standFolder and standFolder.Parent then
			for _, model in ipairs(standFolder:GetChildren()) do
				if processed >= CONFIG.MAX_BABIES_TO_PROCESS then break end
				if model:IsA("Model") and not model.Name:find("_Carried") and model.Name ~= "Collect" and model.Name ~= "Part" then
					local proxy = model:FindFirstChild("Proxy")
					if proxy and isWithinRangeSquared(playerPosition, proxy.Position, CONFIG.MAX_SCAN_DISTANCE_SQUARED) then
						local prompt = proxy:FindFirstChild("ProximityPrompt")
						if prompt and isWithinRangeSquared(playerPosition, proxy.Position, CONFIG.UI_UPDATE_DISTANCE_SQUARED) then
							state.nearbyBabies[model] = {isMoving = false, owner = (model:FindFirstChild("Owner") and model.Owner.Value or nil), prompt = prompt}
							state.trackedPrompts[model] = currentTick
							processed += 1
						end
					end
				end
			end
		end
	end

	if folders.movingBabies and folders.movingBabies ~= folders.defeatedBrainrots and processed < CONFIG.MAX_BABIES_TO_PROCESS then
		for _, model in ipairs(folders.movingBabies:GetChildren()) do
			if processed >= CONFIG.MAX_BABIES_TO_PROCESS then break end
			if model:IsA("Model") and not model.Name:find("_Carried") then
				local proxy = model:FindFirstChild("Proxy")
				local prompt = proxy and proxy:FindFirstChild("ProximityPrompt")
				if proxy and prompt and isWithinRangeSquared(playerPosition, proxy.Position, CONFIG.MAX_SCAN_DISTANCE_SQUARED) then
					state.nearbyBabies[model] = {isMoving = true, owner = nil, prompt = prompt}
					state.trackedPrompts[model] = currentTick
					processed += 1
				end
			end
		end
	end
end

local promptActions = {
	steal = function(prompt, actionText)
		prompt.ActionText = "Steal"
		prompt.ObjectText = actionText or "Baby"
		prompt.HoldDuration = 1.5
		prompt.Enabled = true
		state.isCurrentlyStealing = false
	end,
	sell = function(prompt, actionText)
		prompt.ActionText = actionText or "Sell"
		prompt.ObjectText = "Your Baby"
		prompt.HoldDuration = 1.2
		prompt.Enabled = true
		state.isCurrentlyStealing = false
	end,
	purchase = function(prompt, actionText)
		prompt.ActionText = actionText or "Purchase"
		prompt.ObjectText = "Baby"
		prompt.HoldDuration = 0.7
		prompt.Enabled = true
		state.isCurrentlyStealing = false
	end,
	disabled = function(prompt, actionText)
		prompt.ActionText = actionText or "Disabled"
		prompt.ObjectText = ""
		prompt.Enabled = false
	end,
	stealing = function(prompt)
		state.isCurrentlyStealing = true
		prompt.ActionText = "Being Stolen"
		prompt.ObjectText = ""
		prompt.Enabled = false
	end,
	restored = function(prompt, _, babyModel)
		state.isCurrentlyStealing = false
		prompt.Enabled = true
		task.defer(function()
			if remotes.updatePrompt then remotes.updatePrompt:FireServer(babyModel, "updatePrompt") end
		end)
	end
}

local function handlePromptUpdate(babyModel, actionType, actionText)
	if not babyModel or not babyModel.Parent then
		cleanupTrackedPrompts({babyModel})
		return
	end
	local proxy = babyModel:FindFirstChild("Proxy")
	local prompt = proxy and proxy:FindFirstChild("ProximityPrompt")
	local action = prompt and promptActions[actionType]
	if action then action(prompt, actionText, babyModel) end
end

local function resetState()
	state.isCurrentlyStealing = false
	state.billboardCache = {}
	state.disabledCollectionUIs = {}
	state.trackedPrompts = {}
	state.nearbyBabies = {}
	if state.continuousSound then
		state.continuousSound:Stop()
		state.continuousSound:Destroy()
		state.continuousSound = nil
	end
	cacheStandFolders()
end

local function onCharacterAdded(character)
	resetState()
	state.cachedCharacter = character
	state.cachedHRP = character:WaitForChild("HumanoidRootPart", 10)
	state.lastCharacterCheck = currentTick
	local humanoid = character:WaitForChild("Humanoid", 15)
	if humanoid then humanoid.WalkSpeed = 25 end
	task.wait(1)
	local ownedBase = player:FindFirstChild("OwnedBase")
	if ownedBase then
		setBillboardGuiStates(ownedBase.Value)
		state.cachedPlayerBase = ownedBase.Value ~= 0 and ownedBase.Value or nil
	end
end

local function handleEKeyPress()
	local hrp = getCachedHRP()
	if not hrp then return end
	local playerPos = hrp.Position
	local nearestBaby
	local nearestDistanceSquared = CONFIG.NEAREST_PROMPT_DISTANCE_SQUARED
	for baby, data in pairs(state.nearbyBabies) do
		if baby.Parent and data.prompt and data.prompt.Enabled then
			local root = baby.PrimaryPart or baby:FindFirstChildWhichIsA("BasePart", true)
			if root then
				local distanceSquared = (playerPos - root.Position).Magnitude ^ 2
				if distanceSquared < nearestDistanceSquared then
					nearestDistanceSquared = distanceSquared
					nearestBaby = baby
				end
			end
		end
	end
	if nearestBaby then fireproximityprompt(state.nearbyBabies[nearestBaby].prompt) end
end

local function performCleanup()
	if currentTick - state.lastCleanup < CONFIG.CLEANUP_INTERVAL then return end
	state.lastCleanup = currentTick
	local toRemove = {}
	for babyModel, timestamp in pairs(state.trackedPrompts) do
		if not babyModel.Parent or currentTick - timestamp > CONFIG.CLEANUP_TIMEOUT then table.insert(toRemove, babyModel) end
	end
	cleanupTrackedPrompts(toRemove)
	local cacheSize = 0
	for _ in pairs(state.soundCache) do cacheSize += 1 end
	if cacheSize > CONFIG.MAX_SOUND_CACHE then
		state.soundCache = {}
		initializeSoundCache()
	end
end

task.spawn(function()
	while not remotes.showError or not remotes.sound or not remotes.continuousSound or not remotes.updatePrompt do task.wait(0.1) end
	remotes.showError.OnClientEvent:Connect(function(...)
		if refs.ErrorHandler then refs.ErrorHandler.GetDisplayFunction()(...) end
	end)
	remotes.sound.OnClientEvent:Connect(playSound)
	remotes.continuousSound.OnClientEvent:Connect(handleContinuousSound)
	remotes.updatePrompt.OnClientEvent:Connect(handlePromptUpdate)
	if remotes.collectionUI then
		remotes.collectionUI.OnClientEvent:Connect(function(action, standNumber)
			if action == "disable" then state.disabledCollectionUIs[standNumber] = true
			elseif action == "enable" then state.disabledCollectionUIs[standNumber] = false
			elseif action == "clear_all" then state.disabledCollectionUIs = {} end
		end)
	end
end)

ProximityPromptService.PromptShown:Connect(function(prompt)
	if prompt:GetAttribute("BrainrotPurchasePrompt") == true or prompt.Name == "PurchasePrompt" or prompt.Name == "PurchaseBrainrotPrompt" then
		prompt.Enabled = true
		prompt.RequiresLineOfSight = false
	end
end)

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then onCharacterAdded(player.Character) end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.E then handleEKeyPress() end
end)

player.AncestryChanged:Connect(function()
	if not player.Parent and state.continuousSound then
		state.continuousSound:Stop()
		state.continuousSound:Destroy()
		state.continuousSound = nil
	end
end)

RunService.Heartbeat:Connect(function(deltaTime)
	if deltaTime > 0.15 then return end
	if currentTick - state.lastPromptUpdate > CONFIG.PROMPT_UPDATE_INTERVAL then
		state.lastPromptUpdate = currentTick
		task.spawn(monitorBabiesInBatches)
	end
	if currentTick - state.lastCollectionUpdate > CONFIG.COLLECTION_UPDATE_INTERVAL then
		state.lastCollectionUpdate = currentTick
		task.spawn(updateCollectionVisibility)
	end
	performCleanup()
end)

task.spawn(function()
	while not folders.sounds or not folders.bases do task.wait(0.1) end
	initializeSoundCache()
	cacheStandFolders()
	-- OwnedBase only exists once the player claims a base at a collect-zone pad
	local ownedBaseConnection
	local function watchOwnedBase()
		if ownedBaseConnection then
			ownedBaseConnection:Disconnect()
			ownedBaseConnection = nil
		end
		local ownedBase = player:FindFirstChild("OwnedBase")
		if ownedBase then
			local function onOwnedBaseChanged()
				local baseNumber = ownedBase.Value or 0
				setBillboardGuiStates(baseNumber)
				state.cachedPlayerBase = baseNumber ~= 0 and baseNumber or nil
			end
			onOwnedBaseChanged()
			ownedBaseConnection = ownedBase.Changed:Connect(onOwnedBaseChanged)
		else
			setBillboardGuiStates(0)
			state.cachedPlayerBase = nil
		end
	end
	watchOwnedBase()
	player.ChildAdded:Connect(function(child)
		if child.Name == "OwnedBase" then
			task.wait()
			watchOwnedBase()
		end
	end)
	player.ChildRemoved:Connect(function(child)
		if child.Name == "OwnedBase" then
			watchOwnedBase()
		end
	end)
	setBillboardGuiStates(0)
end)