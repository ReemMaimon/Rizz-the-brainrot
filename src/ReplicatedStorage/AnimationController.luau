local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AnimationsFolder = ReplicatedStorage:WaitForChild("Animations")
local ConfigModule = ReplicatedStorage:FindFirstChild("AnimationConfig")
local Config = ConfigModule and require(ConfigModule) or {}
Config.Defaults = Config.Defaults or {Loop = false, Looped = false, Priority = Enum.AnimationPriority.Action, Speed = 1, FadeTime = 0.1, CounterRotateLegs = true}
Config.Animations = Config.Animations or {}
Config.Actions = Config.Actions or {}

local AnimationExecutor = {}
AnimationExecutor.__index = AnimationExecutor

function AnimationExecutor.new(character)
	local self = setmetatable({}, AnimationExecutor)
	self.Character = character
	self.Joints = {}
	self.CurrentTime = 0
	self.Connection = nil
	self.IsPlaying = false
	self.CurrentAnimation = nil
	self.CurrentSettings = nil
	for _, desc in ipairs(character:GetDescendants()) do
		if desc:IsA("Motor6D") and desc.Part1 then self.Joints[desc.Part1.Name] = desc end
	end
	return self
end

function AnimationExecutor:Stop()
	self.IsPlaying = false
	self.CurrentAnimation = nil
	self.CurrentSettings = nil
	if self.Connection then self.Connection:Disconnect(); self.Connection = nil end
	for _, joint in pairs(self.Joints) do joint.Transform = CFrame.identity end
end

function AnimationExecutor:PlayFromTable(name, animTable, settings)
	self:Stop()
	local timestamps = {}
	for timestamp in pairs(animTable.Timestamps or {}) do table.insert(timestamps, tonumber(timestamp) or timestamp) end
	table.sort(timestamps)
	if #timestamps < 2 then warn("AnimationController: animation needs at least two timestamps", name); return false end
	local normalized = {}
	for key, value in pairs(animTable.Timestamps) do normalized[tonumber(key) or key] = value end
	self.CurrentTime = 0
	self.IsPlaying = true
	self.CurrentAnimation = name
	self.CurrentSettings = settings
	local maxTime = timestamps[#timestamps]
	local speed = math.max(0, tonumber(settings.Speed) or 1)
	local isLooping = settings.Looped == true or settings.Loop == true
	self.Connection = RunService.PreSimulation:Connect(function(dt)
		if not self.IsPlaying then return end
		self.CurrentTime += dt * speed
		local reachedEnd = self.CurrentTime >= maxTime
		if reachedEnd and isLooping and maxTime > 0 then self.CurrentTime %= maxTime; reachedEnd = false elseif reachedEnd then self.CurrentTime = maxTime end
		local tStart, tEnd = timestamps[1], timestamps[#timestamps]
		for i = 1, #timestamps - 1 do
			if self.CurrentTime >= timestamps[i] and self.CurrentTime < timestamps[i + 1] then tStart = timestamps[i]; tEnd = timestamps[i + 1]; break end
		end
		local segmentDuration = tEnd - tStart
		local alpha = segmentDuration > 0 and math.clamp((self.CurrentTime - tStart) / segmentDuration, 0, 1) or 0
		local dataStart, dataEnd = normalized[tStart] or {}, normalized[tEnd] or {}
		for partName, joint in pairs(self.Joints) do
			local startCFrame = dataStart[partName] or CFrame.identity
			local endCFrame = dataEnd[partName] or startCFrame
			joint.Transform = startCFrame:Lerp(endCFrame, alpha)
		end
		if settings.CounterRotateLegs ~= false then
			local lowerTorso = self.Joints.LowerTorso
			if lowerTorso then
				local invRot = (lowerTorso.Transform - lowerTorso.Transform.Position):Inverse()
				for _, legName in ipairs({"LeftUpperLeg", "RightUpperLeg"}) do if self.Joints[legName] then self.Joints[legName].Transform = invRot * self.Joints[legName].Transform end end
			end
		end
		if reachedEnd then self:Stop() end
	end)
	return true
end

local AnimationController = {}
local executor
local currentCharacter
local currentSettings = {}

local function mergeSettings(name, animTable, overrides)
	local result = {}
	for key, value in pairs(Config.Defaults) do result[key] = value end
	for key, value in pairs(animTable.Settings or {}) do result[key] = value end
	local configured = Config.Animations[name] or {}
	for key, value in pairs(configured) do result[key] = value end
	for key, value in pairs(overrides or {}) do result[key] = value end
	return result
end

local function normalizeName(value)
	return tostring(value):lower():gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
end

local function findAnimation(value)
	if type(value) ~= "string" or value == "" then return nil end
	local exact = AnimationsFolder:FindFirstChild(value, true)
	if exact then return exact end
	local wanted = normalizeName(value)
	for _, item in ipairs(AnimationsFolder:GetDescendants()) do if normalizeName(item.Name) == wanted then return item end end
	for _, item in ipairs(AnimationsFolder:GetDescendants()) do if normalizeName(item.Name):sub(1, #wanted) == wanted then return item end end
	return nil
end

local function resolveName(value)
	if type(value) ~= "string" or value == "" then return nil end
	if Config.Actions[value] then return resolveName(Config.Actions[value]) end
	local definition = Config.Animations[value]
	if type(definition) == "table" then return definition.Name or definition.Module or definition.Id or definition.AnimationId or value end
	return value
end

local function keyframeSequenceToTable(sequence)
	local timestamps = {}
	for _, keyframe in ipairs(sequence:GetKeyframes()) do
		local poses = {}
		local function collectPose(pose, parentTransform)
			if not pose:IsA("Pose") then return end
			local transform = parentTransform * pose.CFrame
			poses[pose.Name] = transform
			for _, child in ipairs(pose:GetChildren()) do collectPose(child, transform) end
		end
		for _, child in ipairs(keyframe:GetChildren()) do collectPose(child, CFrame.identity) end
		timestamps[keyframe.Time] = poses
	end
	return {Timestamps = timestamps}
end

local function ensureExecutor()
	local player = Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	if character ~= currentCharacter then currentCharacter = character; executor = AnimationExecutor.new(character) end
	return executor
end

Players.LocalPlayer.CharacterAdded:Connect(function() executor = nil; currentCharacter = nil end)

function AnimationController.Play(name, overrides)
	local animationName = resolveName(name)
	if not animationName then return false end
	local animationAsset = findAnimation(animationName)
	if not animationAsset then warn("AnimationController: no animation named", animationName); return false end
	local settings
	local animTable
	local ok
	if animationAsset:IsA("Animation") then
		local player = Players.LocalPlayer
		local character = player.Character or player.CharacterAdded:Wait()
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
		if humanoid and not animator then animator = Instance.new("Animator"); animator.Parent = humanoid end
		if not animator then return false end
		settings = mergeSettings(animationName, {}, overrides)
		local trackOk, track = pcall(function() return animator:LoadAnimation(animationAsset) end)
		if not trackOk or not track then warn("AnimationController: failed to load animation", animationName); return false end
		track.Priority = settings.Priority or Enum.AnimationPriority.Action
		track.Looped = settings.Looped == true or settings.Loop == true
		track:Play(tonumber(settings.FadeTime) or 0.1, tonumber(settings.Weight) or 1, tonumber(settings.Speed) or 1)
		currentSettings = settings
		return true
	elseif animationAsset:IsA("ModuleScript") then ok, animTable = pcall(require, animationAsset)
	elseif animationAsset:IsA("KeyframeSequence") then ok, animTable = pcall(keyframeSequenceToTable, animationAsset)
	else warn("AnimationController: unsupported animation type", animationAsset.ClassName, animationName); return false end
	if not ok or type(animTable) ~= "table" or type(animTable.Timestamps) ~= "table" then warn("AnimationController: invalid animation", animationName); return false end
	settings = mergeSettings(animationName, animTable, overrides)
	currentSettings = settings
	return ensureExecutor():PlayFromTable(animationName, animTable, settings)
end

function AnimationController.Stop() if executor then executor:Stop() end end
function AnimationController.IsPlaying() return executor ~= nil and executor.IsPlaying == true end
function AnimationController.SetConfig(newConfig) assert(type(newConfig) == "table", "AnimationController.SetConfig expects a table"); for key, value in pairs(newConfig) do Config[key] = value end end
function AnimationController.GetAnimation(name)
	local animationName = resolveName(name)
	if not animationName then return nil end
	local definition = Config.Animations[animationName]
	if definition then return definition, animationName end
	local animationAsset = findAnimation(animationName)
	if animationAsset and animationAsset:IsA("ModuleScript") then local ok, data = pcall(require, animationAsset); if ok then return data.Settings or {}, animationName end end
	return nil, animationName
end
function AnimationController.GetCurrentSettings() return currentSettings end
return AnimationController