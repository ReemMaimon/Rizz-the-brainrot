--[[
	SigmaFaceService (server authority)
	Rizz Level (leaderstats.RizzLevel via RizzLevelService) -> SigmaFaceConfig -> face model on the character.
	Event driven only: character load/respawn and RizzLevel value changes. No polling, no Heartbeat.
	Scenes reuse the existing Ability Scene system: the AbilityPresentation RemoteEvent handled by BattleClient
	(VFXService / AnimationService / camera feedback). Clients never choose a face.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("SigmaFaceConfig"))
local RizzLevelService = require(script.Parent:WaitForChild("RizzLevelService"))
local presentationRemote = ReplicatedStorage:WaitForChild("AbilityPresentation")

local FACE_NAME = "SigmaFace" -- name of the face on the character (BattleClient's reveal action looks for it)

local SigmaFaceService = {}
local states = {}
local resolvers = {}
local templateFolder
local warned = {}

local function merge(base, override)
	local result = table.clone(base or {})
	for key, value in pairs(override or {}) do result[key] = value end
	return result
end

local function warnOnce(key, message)
	if warned[key] then return end
	warned[key] = true
	warn("[SigmaFaceService] " .. message)
end

-- Configured levels, highest first (built once; any number of levels supported)
local sortedLevels = {}
for level in pairs(Config.SigmaFaces or {}) do
	if typeof(level) == "number" and level > (Config.DefaultLevel or 1) then table.insert(sortedLevels, level) end
end
table.sort(sortedLevels, function(a, b) return a > b end)

local function getTemplate(name)
	if typeof(name) ~= "string" or name == "" then return nil end
	if not templateFolder or not templateFolder.Parent then
		local folder = ReplicatedStorage
		for segment in string.gmatch(Config.AssetFolder or "Assets/SigmaFaces", "[^/]+") do
			folder = folder and folder:FindFirstChild(segment)
		end
		templateFolder = folder
	end
	if not templateFolder then warnOnce("folder", "Missing asset folder ReplicatedStorage/" .. tostring(Config.AssetFolder)); return nil end
	local template = templateFolder:FindFirstChild(name)
	if not template then warnOnce("model_" .. name, "Missing Sigma Face model '" .. name .. "'") end
	return template
end

local function describe(key, entry)
	if typeof(entry) == "string" then entry = {Model = entry} end
	if typeof(entry) ~= "table" then return nil end
	local template = getTemplate(entry.Model)
	if not template then return nil end
	return {
		Key = key,
		Template = template,
		Attachment = merge(Config.Attachment, entry.Attachment),
		Scene = merge(Config.Scene, entry.Scene),
	}
end

-- Level -> face. Level 1 (<= DefaultLevel) is always "no face". Missing level -> closest lower configured face.
-- Extra resolvers (event/VIP/temporary/seasonal faces) run first and return {Key=, Model=, Attachment=?, Scene=?}.
function SigmaFaceService:Resolve(player, level)
	if level <= (Config.DefaultLevel or 1) then return nil end
	for _, resolver in ipairs(resolvers) do
		local ok, entry = pcall(resolver, player, level)
		if ok and typeof(entry) == "table" and entry.Model then
			local resolved = describe("custom:" .. tostring(entry.Key or entry.Model), entry)
			if resolved then return resolved end
		end
	end
	for _, configuredLevel in ipairs(sortedLevels) do
		if configuredLevel <= level then
			local resolved = describe("level:" .. configuredLevel, Config.SigmaFaces[configuredLevel])
			if resolved then return resolved end
		end
	end
	return nil
end

function SigmaFaceService:RegisterResolver(resolver)
	table.insert(resolvers, resolver)
end

local function removeFace(state)
	if state.Face then state.Face:Destroy(); state.Face = nil end
	if state.Weld then state.Weld:Destroy(); state.Weld = nil end
	if state.HiddenPart then
		if state.HiddenPart.Parent then state.HiddenPart.Transparency = state.HiddenOriginal end
		state.HiddenPart, state.HiddenOriginal = nil, nil
	end
end

local function attachFace(state, resolved, scale)
	local character = state.Character
	if not character or not character.Parent then return false end
	local attachment = resolved.Attachment
	local parentPart = character:FindFirstChild(attachment.ParentPart or "Head")
	if not parentPart or not parentPart:IsA("BasePart") then return false end

	local face = resolved.Template:Clone()
	if face:IsA("BasePart") then
		local wrapper = Instance.new("Model")
		face.Parent = wrapper
		wrapper.PrimaryPart = face
		face = wrapper
	end
	local facePart = face.PrimaryPart or face:FindFirstChildWhichIsA("BasePart", true)
	if not facePart then face:Destroy(); warnOnce("nopart_" .. resolved.Key, "Face model has no BasePart: " .. resolved.Key); return false end
	face.PrimaryPart = facePart
	face.Name = FACE_NAME

	for _, item in ipairs(face:GetDescendants()) do
		if item:IsA("BasePart") then
			item.Anchored = false
			item.CanCollide = false
			item.CanTouch = false
			item.CanQuery = false
			item.Massless = true
		elseif (item:IsA("Weld") or item:IsA("WeldConstraint") or item:IsA("Motor6D")) and (item.Part0 == nil or item.Part1 == nil) then
			item:Destroy() -- dangling joints from the source model would fight our attachment weld
		end
	end

	local offset = attachment.Offset or CFrame.new()
	local faceAttachment = attachment.FaceAttachment and facePart:FindFirstChild(attachment.FaceAttachment)
	local targetAttachment = attachment.TargetAttachment and parentPart:FindFirstChild(attachment.TargetAttachment)
	local hasFaceAttachment = faceAttachment ~= nil and faceAttachment:IsA("Attachment")
	local anchor = hasFaceAttachment and targetAttachment and targetAttachment:IsA("Attachment") and targetAttachment.WorldCFrame or parentPart.CFrame
	local target = anchor * offset
	if hasFaceAttachment then
		target = target * faceAttachment.CFrame:Inverse() -- snap the face's own pivot attachment onto the anchor
	end
	face:PivotTo(target * facePart.CFrame:ToObjectSpace(face:GetPivot()))
	if scale and scale ~= 1 then face:ScaleTo(scale) end

	-- Weld lives on the character part (not the face) so Model:ScaleTo never distorts the attach offset.
	local weld = Instance.new("Weld")
	weld.Name = "SigmaFaceWeld"
	weld.Part0 = parentPart
	weld.Part1 = facePart
	weld.C0 = parentPart.CFrame:ToObjectSpace(facePart.CFrame)
	weld.Parent = parentPart
	face.Parent = character

	state.Face, state.Weld = face, weld
	if attachment.HideHead ~= false then
		state.HiddenPart, state.HiddenOriginal = parentPart, parentPart.Transparency
		parentPart.Transparency = 1
	end
	return true
end

local function buildScene(scene, revealTime)
	local reveal = math.max(0.2, (scene.Duration or 1.5) - revealTime)
	local lifetime = scene.Duration or 1.5
	local presentation = {Animation = {}, VFX = {}, Sounds = {}, Timing = {Cast = lifetime}, Sequence = {Cast = {}}}
	local sequence = presentation.Sequence.Cast
	if scene.VFX and scene.StartVFX then
		presentation.VFX.Cast = merge(scene.StartVFX, {Lifetime = scene.StartVFX.Lifetime or lifetime})
	end
	if scene.Sound and scene.StartSound then presentation.Sounds.Cast = scene.StartSound end
	if scene.CameraEffect then table.insert(sequence, {Delay = revealTime, Action = "CameraEffect"}) end
	if scene.VFX and scene.RevealVFX then
		table.insert(sequence, {Delay = revealTime, Action = "VFX", EffectName = "Reveal", VFX = merge(scene.RevealVFX, {Lifetime = scene.RevealVFX.Lifetime or reveal})})
	end
	if scene.Sound and scene.RevealSound then
		table.insert(sequence, {Delay = revealTime, Action = "Sound", SoundName = "Reveal", Sound = scene.RevealSound})
	end
	if scene.Animation then presentation.Animation.Cast = scene.Animation end
	if scene.FaceAnimation then
		table.insert(sequence, {Delay = revealTime, Action = "FaceReveal", Reveal = {
			FaceName = FACE_NAME,
			EntranceScale = scene.EntranceScale or 0.5,
			FinalScale = scene.FinalScale or 1,
			Duration = reveal,
			Bounce = scene.Bounce == true,
		}})
	end
	return presentation, reveal
end

local function isCurrent(player, state, character, token)
	return states[player] == state and state.Character == character and state.Token == token and character.Parent ~= nil
end

local function refresh(player, animate)
	local state = states[player]
	if not state or not state.Ready then return end
	local character = state.Character
	local resolved = SigmaFaceService:Resolve(player, RizzLevelService:GetRizzLevel(player))
	local key = resolved and resolved.Key or false
	if key == state.TargetKey and (state.Pending or key == false or (state.Face and state.Face.Parent == character)) then return end
	state.TargetKey = key
	state.Token += 1
	local token = state.Token
	state.Pending = false

	if not resolved then removeFace(state); return end
	local scene = resolved.Scene
	if not animate or scene.Enabled == false then
		removeFace(state)
		if not attachFace(state, resolved, scene.FinalScale or 1) then state.TargetKey = nil end
		return
	end

	local swapDelay = math.clamp(scene.SwapDelay or 0, 0, scene.Duration or 1.5)
	local presentation, reveal = buildScene(scene, swapDelay)
	state.Pending = true
	if scene.RemoveOldFace ~= false then removeFace(state) end
	presentationRemote:FireClient(player, "Cast", scene.SceneId or "SigmaFaceChange", presentation)

	local function swap()
		if not isCurrent(player, state, character, token) then return end
		state.Pending = false
		removeFace(state)
		local startScale = scene.FaceAnimation and (scene.EntranceScale or 0.5) or (scene.FinalScale or 1)
		if not attachFace(state, resolved, startScale) then state.TargetKey = nil; return end
		if scene.FaceAnimation then
			local face = state.Face
			-- Safety net: if the client never plays the reveal, the face still ends at its final scale.
			task.delay(reveal + 0.5, function()
				if state.Face == face and face.Parent then face:ScaleTo(scene.FinalScale or 1) end
			end)
		end
	end
	if swapDelay > 0 then task.delay(swapDelay, swap) else swap() end
end

local function onCharacter(player, character)
	local state = states[player]
	if not state then return end
	removeFace(state) -- face of the previous character is gone with it; drop references
	state.Character = character
	state.Ready = false
	state.TargetKey = nil
	state.Pending = false
	state.Token += 1
	task.spawn(function()
		local parentName = (Config.Attachment and Config.Attachment.ParentPart) or "Head"
		local humanoid = character:WaitForChild("Humanoid", 10)
		local root = character:WaitForChild("HumanoidRootPart", 10)
		local part = character:WaitForChild(parentName, 10)
		if states[player] ~= state or state.Character ~= character or not character.Parent then return end
		if not humanoid or not root or not part then warnOnce("char_" .. player.UserId, "Character missing Humanoid/HumanoidRootPart/" .. parentName); return end
		state.Ready = true
		refresh(player, false) -- join / respawn: apply the face for the current level, no scene
	end)
end

local function onCharacterRemoving(player, character)
	local state = states[player]
	if not state or state.Character ~= character then return end
	removeFace(state)
	state.Character = nil
	state.Ready = false
	state.TargetKey = nil
	state.Pending = false
	state.Token += 1
end

local function bindLevelValue(player, state, value)
	if not value:IsA("ValueBase") then return end
	state.Connections[#state.Connections + 1] = value:GetPropertyChangedSignal("Value"):Connect(function()
		refresh(player, true)
	end)
	refresh(player, false) -- level loaded (DataStore) before/after the character
end

local function watchLeaderstats(player, state, leaderstats)
	local existing = leaderstats:FindFirstChild("RizzLevel")
	if existing then bindLevelValue(player, state, existing) end
	state.Connections[#state.Connections + 1] = leaderstats.ChildAdded:Connect(function(child)
		if child.Name == "RizzLevel" then bindLevelValue(player, state, child) end
	end)
end

local function onPlayerAdded(player)
	if states[player] then return end
	local state = {Connections = {}, Token = 0, Ready = false, Pending = false}
	states[player] = state
	state.Connections[#state.Connections + 1] = player.CharacterAdded:Connect(function(character) onCharacter(player, character) end)
	state.Connections[#state.Connections + 1] = player.CharacterRemoving:Connect(function(character) onCharacterRemoving(player, character) end)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		watchLeaderstats(player, state, leaderstats)
	else
		state.Connections[#state.Connections + 1] = player.ChildAdded:Connect(function(child)
			if child.Name == "leaderstats" then watchLeaderstats(player, state, child) end
		end)
	end
	if player.Character then onCharacter(player, player.Character) end
end

local function onPlayerRemoving(player)
	local state = states[player]
	if not state then return end
	removeFace(state)
	state.Token += 1
	for _, connection in ipairs(state.Connections) do connection:Disconnect() end
	states[player] = nil
end

function SigmaFaceService:Refresh(player)
	refresh(player, false)
end

local started = false
function SigmaFaceService:Start()
	if started then return end
	started = true
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in ipairs(Players:GetPlayers()) do task.spawn(onPlayerAdded, player) end
end

return SigmaFaceService
