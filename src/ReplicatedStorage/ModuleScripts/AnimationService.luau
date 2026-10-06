local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local Debris = game:GetService("Debris")
local AbilityPresentationConfig = require(script.Parent:WaitForChild("AbilityPresentationConfig"))
local AnimationController = require(ReplicatedStorage:WaitForChild("AnimationController"))

local AnimationService = {}
local active = {}

local function resolveId(value)
	if type(value) ~= "string" or value == "" then return nil end
	if value:find("rbxassetid://", 1, true) then return value end
	if tonumber(value) then return "rbxassetid://" .. value end
	return value
end

local function normalizedName(value)
	return tostring(value):lower():gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
end

local function findNamed(folder, requested)
	if not folder or type(requested) ~= "string" or requested == "" then return nil end
	local exact = folder:FindFirstChild(requested, true)
	if exact then return exact end
	local wanted = normalizedName(requested)
	for _, item in ipairs(folder:GetDescendants()) do if normalizedName(item.Name) == wanted then return item end end
	for _, item in ipairs(folder:GetDescendants()) do if normalizedName(item.Name):sub(1, #wanted) == wanted then return item end end
	return nil
end

local function animationValue(configured)
	if type(configured) == "string" then return configured, {} end
	if type(configured) ~= "table" then return nil, {} end
	return configured.Name or configured.Module or configured.Id or configured.AnimationId, configured
end

function AnimationService:PlayAbilityAnimation(player, abilityId, animationName, overrides, callbacks)
	local definition = AbilityPresentationConfig.Get(abilityId, overrides)
	local configured = definition.Animation and definition.Animation[animationName]
	local animationNameOrId, settings = animationValue(configured)
	if not animationNameOrId or animationNameOrId == "" then return false end
	local mergedSettings = {}
	for key, value in pairs(settings) do mergedSettings[key] = value end
	for key, value in pairs(type(overrides) == "table" and overrides.Animation and overrides.Animation[animationName] or {}) do mergedSettings[key] = value end
	local connections = {}
	local markerNames = mergedSettings.Markers or definition.Markers or {"Cast", "Charge", "Attack", "Hit", "Impact", "End"}
	local markerCallbacks = callbacks or {}
	local assetId = resolveId(animationNameOrId)
	if assetId and (assetId:find("rbxassetid://", 1, true) or tonumber(animationNameOrId)) then
		local character = player and player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
		if humanoid and not animator then animator = Instance.new("Animator"); animator.Parent = humanoid end
		if not animator then return false end
		local animation = Instance.new("Animation")
		animation.AnimationId = assetId
		local ok, track = pcall(function() return animator:LoadAnimation(animation) end)
		if not ok or not track then animation:Destroy(); return false end
		track.Priority = mergedSettings.Priority or Enum.AnimationPriority.Action
		track.Looped = mergedSettings.Looped == true or mergedSettings.Loop == true
		for _, marker in ipairs(markerNames) do
			local name = type(marker) == "string" and marker or marker.Name
			if markerCallbacks[name] then connections[name] = track:GetMarkerReachedSignal(name):Connect(function(parameter) markerCallbacks[name](parameter, track) end) end
		end
		track.Stopped:Connect(function()
			for _, connection in pairs(connections) do connection:Disconnect() end
			animation:Destroy()
		end)
		track:Play(tonumber(mergedSettings.FadeTime) or 0.1, tonumber(mergedSettings.Weight) or 1, tonumber(mergedSettings.Speed) or 1)
		active[player] = {Track = track, Animation = animation, Connections = connections}
		return true
	end
	local animationFolder = ReplicatedStorage:FindFirstChild("Animations")
	local resolvedAsset = findNamed(animationFolder, animationNameOrId)
	if not resolvedAsset then
		warn("[AnimationService] Animation asset not found: " .. tostring(animationNameOrId))
		return false
	end
	local controllerName = resolvedAsset.Name
	local ok, result = pcall(function() return AnimationController.Play(controllerName, mergedSettings) end)
	if ok and result == true then active[player] = {Custom = true}; return true end
	if not ok then warn("[AnimationService] Animation failed: " .. tostring(result)) end
	return false
end

function AnimationService:StopAbilityAnimation(player)
	local state = active[player]
	if state and state.Track then state.Track:Stop() end
	if state then for _, connection in pairs(state.Connections or {}) do connection:Disconnect() end end
	active[player] = nil
	AnimationController.Stop()
end

function AnimationService:PlayAbilitySound(abilityId, soundName, context, override)
	local definition = AbilityPresentationConfig.Get(abilityId, context and context.Presentation)
	local configured = override or definition.Sounds and definition.Sounds[soundName]
	if type(configured) == "table" then configured = configured.Name or configured.Id or configured.SoundId end
	if type(configured) ~= "string" or configured == "" then return nil end
	local folder = ReplicatedStorage:FindFirstChild("AbilitySounds")
	local source = findNamed(folder, configured)
	local sound
	if source and source:IsA("Sound") then sound = source:Clone() else sound = Instance.new("Sound"); sound.SoundId = resolveId(configured) or "" end
	if sound.SoundId == "" then sound:Destroy(); return nil end
	sound.Name = "AbilitySound_" .. tostring(soundName)
	sound.Volume = tonumber(type(override) == "table" and override.Volume) or (sound.Volume > 0 and sound.Volume or 1)
	sound.PlaybackSpeed = tonumber(type(override) == "table" and override.PlaybackSpeed) or (sound.PlaybackSpeed > 0 and sound.PlaybackSpeed or 1)
	sound.Parent = SoundService
	local loaded = pcall(function() ContentProvider:PreloadAsync({sound}) end)
	if not loaded then warn("[AnimationService] Could not preload sound: " .. configured) end
	sound.Ended:Connect(function() if sound.Parent then sound:Destroy() end end)
	sound:Play()
	Debris:AddItem(sound, 10)
	return sound
end

return AnimationService