local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local config = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("BattleConfig"))
local remotes = ReplicatedStorage:WaitForChild("BattleRemotes")
local battleState = remotes:WaitForChild("BattleState")
local battleCamera = remotes:WaitForChild("BattleCamera")
local abilityRequest = remotes:WaitForChild("AbilityRequest")
local abilityResponse = remotes:WaitForChild("AbilityResponse")
local abilityConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("AbilityConfig"))
local presentationConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("AbilityPresentationConfig"))
local VFXService = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("VFXService"))
local AnimationService = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("AnimationService"))
local presentationRemote = ReplicatedStorage:WaitForChild("AbilityPresentation")

local function createFallbackBattleGui()
	local gui = Instance.new("ScreenGui")
	gui.Name = "RizzBattleGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 25
	gui.Enabled = false
	gui.Parent = playerGui
	local root = Instance.new("Frame")
	root.Name = "BattleFrame"
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(0.5, 0.72)
	root.Size = UDim2.fromScale(0.48, 0.30)
	root.BackgroundColor3 = Color3.fromRGB(24, 28, 42)
	root.BackgroundTransparency = 0.08
	root.Parent = gui
	local function makeLabel(name, position, size, text)
		local label = Instance.new("TextLabel")
		label.Name = name
		label.Position = position
		label.Size = size
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Font = Enum.Font.SourceSansBold
		label.TextScaled = true
		label.Text = text
		label.Parent = root
		return label
	end
	makeLabel("PlayerStats", UDim2.fromScale(0.04, 0.08), UDim2.fromScale(0.28, 0.22), "Player")
	makeLabel("BrainrotStats", UDim2.fromScale(0.68, 0.08), UDim2.fromScale(0.28, 0.22), "Opponent")
	makeLabel("TurnLabel", UDim2.fromScale(0.32, 0.03), UDim2.fromScale(0.36, 0.1), "WAITING")
	makeLabel("TimerLabel", UDim2.fromScale(0.32, 0.14), UDim2.fromScale(0.36, 0.08), "")
	makeLabel("StatusLabel", UDim2.fromScale(0.08, 0.33), UDim2.fromScale(0.84, 0.12), "")
	local abilityPanel = Instance.new("Frame")
	abilityPanel.Name = "AbilityPanel"
	abilityPanel.Position = UDim2.fromScale(0.08, 0.69)
	abilityPanel.Size = UDim2.fromScale(0.84, 0.24)
	abilityPanel.BackgroundColor3 = Color3.fromRGB(44, 31, 72)
	abilityPanel.BackgroundTransparency = 0.15
	abilityPanel.Parent = root
	local layout = Instance.new("UIGridLayout")
	layout.Name = "Layout"
	layout.CellPadding = UDim2.fromOffset(8, 8)
	layout.CellSize = UDim2.fromScale(0.23, 0.8)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = abilityPanel
	return gui, root, abilityPanel
end

local gui = playerGui:FindFirstChild("RizzBattleGui")
local root = gui and gui:FindFirstChild("BattleFrame")
local abilityPanel = root and root:FindFirstChild("AbilityPanel")
if not gui or not root or not abilityPanel then
	gui, root, abilityPanel = createFallbackBattleGui()
	warn("[BattleClient] RizzBattleGui was not replicated; created a runtime fallback UI")
end

local playerStats = root:WaitForChild("PlayerStats")
local brainrotStats = root:WaitForChild("BrainrotStats")
local turnLabel = root:WaitForChild("TurnLabel")
local timerLabel = root:WaitForChild("TimerLabel")
local statusLabel = root:WaitForChild("StatusLabel")
local abilityButtons = {}
local current = nil
local presentationToken = 0
local presentationContexts = {}
local faceStates = {}
local camera = Workspace.CurrentCamera
local savedMovement = nil
local cameraShake = {Position = 0, Rotation = 0, EndsAt = 0, Seed = 0}
local hitStop = {EndsAt = 0, CFrame = nil}

local function triggerImpactFeedback()
	camera = Workspace.CurrentCamera
	if not camera then return end
	local now = os.clock()
	local duration = 0.16
	local shakeDuration = 0.28
	if now >= hitStop.EndsAt then hitStop.CFrame = camera.CFrame end
	hitStop.EndsAt = math.max(hitStop.EndsAt, now + duration)
	cameraShake.Position = math.max(cameraShake.Position, 0.22)
	cameraShake.Rotation = math.max(cameraShake.Rotation, 1.8)
	cameraShake.EndsAt = math.max(cameraShake.EndsAt, now + shakeDuration)
	cameraShake.Seed += 1
end

RunService:BindToRenderStep("AbilityImpactCameraFeedback", Enum.RenderPriority.Camera.Value + 1, function()
	camera = Workspace.CurrentCamera
	if not camera then return end
	local now = os.clock()
	local baseCFrame = camera.CFrame
	if now < hitStop.EndsAt and hitStop.CFrame then
		baseCFrame = hitStop.CFrame
	else
		hitStop.CFrame = nil
	end
	if now < cameraShake.EndsAt then
		local remaining = math.clamp((cameraShake.EndsAt - now) / 0.28, 0, 1)
		local noise = math.sin(now * 115 + cameraShake.Seed * 2.7)
		local noise2 = math.cos(now * 91 + cameraShake.Seed * 1.9)
		local position = cameraShake.Position * remaining
		local rotation = math.rad(cameraShake.Rotation * remaining)
		camera.CFrame = baseCFrame
			* CFrame.new(noise * position, noise2 * position, 0)
			* CFrame.Angles(noise2 * rotation, noise * rotation, noise * rotation * 0.5)
	else
		cameraShake.Position = 0
		cameraShake.Rotation = 0
		camera.CFrame = baseCFrame
	end
end)

local function rootOf(model)
	if not model then return nil end
	return model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
end

local function setMovementLocked(locked)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if locked then
		if humanoid and not savedMovement then
			savedMovement = {Humanoid = humanoid, WalkSpeed = humanoid.WalkSpeed, AutoRotate = humanoid.AutoRotate, JumpPower = humanoid.JumpPower, JumpHeight = humanoid.JumpHeight}
		end
		if humanoid then humanoid.WalkSpeed = 0; humanoid.AutoRotate = false end
	elseif savedMovement then
		local savedHumanoid = savedMovement.Humanoid
		if savedHumanoid and savedHumanoid.Parent then
			savedHumanoid.WalkSpeed = savedMovement.WalkSpeed
			savedHumanoid.AutoRotate = savedMovement.AutoRotate
			savedHumanoid.JumpPower = savedMovement.JumpPower
			savedHumanoid.JumpHeight = savedMovement.JumpHeight
		end
		savedMovement = nil
	end
end

local function clearFace(abilityId)
	local state = faceStates[abilityId]
	if not state then return end
	if state.Face and state.Face.Parent then state.Face:Destroy() end
	if state.Head and state.Head.Parent then state.Head.Transparency = state.HeadTransparency; state.Head.CanQuery = state.HeadCanQuery end
	faceStates[abilityId] = nil
end

local function playFace(abilityId, configured)
	local face = configured.Face
	if type(face) ~= "table" or type(face.Model) ~= "string" or face.Model == "" then return end
	local character = player.Character
	local head = character and character:FindFirstChild(face.AttachTo or "Head")
	local folder = ReplicatedStorage:FindFirstChild("AbilityFaces")
	local template = folder and (folder:FindFirstChild(face.Model, true) or (function()
		local wanted = tostring(face.Model):lower():gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
		for _, item in ipairs(folder:GetDescendants()) do
			local candidate = item.Name:lower():gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
			if candidate == wanted or candidate:sub(1, #wanted) == wanted then return item end
		end
	end)())
	if not head or not head:IsA("BasePart") or not template then warn("[BattleClient] Missing face model or head for " .. tostring(abilityId)); return end
	clearFace(abilityId)
	local clone = template:Clone()
	clone.Name = "AbilityFace_" .. abilityId
	clone.Parent = character
	local facePart = clone:IsA("BasePart") and clone or clone.PrimaryPart or clone:FindFirstChildWhichIsA("BasePart", true)
	if not facePart then clone:Destroy(); warn("[BattleClient] Face model has no BasePart: " .. face.Model); return end
	for _, item in ipairs(clone:GetDescendants()) do if item:IsA("BasePart") then item.Anchored = false; item.CanCollide = false; item.CanTouch = false; item.CanQuery = false; item.Massless = true end end
	clone:PivotTo(head.CFrame)
	local weld = Instance.new("WeldConstraint")
	weld.Name = "AbilityFaceWeld"
	weld.Part0 = head
	weld.Part1 = facePart
	weld.Parent = facePart
	local state = {Face = clone, Head = head, HeadTransparency = head.Transparency, HeadCanQuery = head.CanQuery}
	faceStates[abilityId] = state
	head.Transparency = 1
	head.CanQuery = false
	local lifetime = math.max(0, tonumber(face.Lifetime) or 0)
	if lifetime > 0 then task.delay(lifetime, function() if faceStates[abilityId] == state then clearFace(abilityId) end end) end
end

local function isConfigured(value)
	if type(value) == "string" then return value ~= "" end
	return type(value) == "table" and next(value) ~= nil
end

local function executeSequence(abilityId, configured, phase, context)
	local sequence = configured.Sequence and configured.Sequence[phase]
	if type(sequence) ~= "table" then return end
	for _, step in ipairs(sequence) do
		if type(step) == "table" then
			task.delay(math.max(0, tonumber(step.Delay) or 0), function()
				local actionName = step.Action
				if actionName == "Jump" then
					local character = player.Character
					local humanoid = character and character:FindFirstChildOfClass("Humanoid")
					if humanoid and humanoid.Health > 0 then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
				elseif actionName == "Animation" and isConfigured(step.Animation) then
					AnimationService:PlayAbilityAnimation(player, abilityId, step.AnimationName or phase, step.Animation)
				elseif actionName == "Sound" and isConfigured(step.Sound) then
					AnimationService:PlayAbilitySound(abilityId, step.SoundName or phase, context, step.Sound)
				elseif actionName == "VFX" and isConfigured(step.VFX) then
					VFXService:Play(abilityId, step.EffectName or phase, context, step.VFX)
				elseif actionName == "Face" and type(step.Face) == "table" then
					playFace(abilityId, {Face = step.Face})
				elseif actionName == "StopAnimation" then
					AnimationService:StopAbilityAnimation(player)
				end
			end)
		end
	end
end

local function playPresentation(action, abilityId, serverPresentation, target)
	presentationToken += 1
	local token = presentationToken
	local configured = presentationConfig.Get(abilityId, serverPresentation)
	local context = {Player = player, Character = player.Character, Target = target, RootPart = rootOf(player.Character), Presentation = configured, Token = token}
	presentationContexts[abilityId] = context
	local phase = action == "Impact" and "Impact" or action
	if action == "Cast" then playFace(abilityId, configured) end
	if action == "Impact" then
		VFXService:Stop(abilityId, "Cast", context)
		triggerImpactFeedback()
	end
	executeSequence(abilityId, configured, phase, context)
	local animationEntry = configured.Animation and configured.Animation[phase]
	if isConfigured(animationEntry) then AnimationService:PlayAbilityAnimation(player, abilityId, phase, configured) end
	if isConfigured(configured.VFX and configured.VFX[phase]) then VFXService:Play(abilityId, phase, context) end
	local soundName = phase == "Impact" and "Hit" or phase
	if isConfigured(configured.Sounds and configured.Sounds[soundName]) then AnimationService:PlayAbilitySound(abilityId, soundName, context) end
end

local function renderAbilities(snapshot)
	abilityPanel.Visible = true
	for _, button in ipairs(abilityButtons) do button:Destroy() end
	table.clear(abilityButtons)
	local equipped = snapshot.EquippedAbilities or {}
	for slot = 1, math.max(tonumber(snapshot.MaxEquippedAbilities) or 0, 4) do
		local abilityId = equipped[slot] or equipped[tostring(slot)]
		if abilityId then
			local definition = abilityConfig.Abilities[abilityId]
			local button = Instance.new("TextButton")
			button.Name = "Ability_" .. abilityId
			button.Text = definition and definition.DisplayName or abilityId
			button.TextColor3 = Color3.new(1, 1, 1)
			button.BackgroundColor3 = Color3.fromRGB(115, 75, 180)
			button.Font = Enum.Font.SourceSansBold
			button.TextSize = 14
			button.TextWrapped = true
			button.Parent = abilityPanel
			local cooldown = snapshot.AbilityCooldowns and snapshot.AbilityCooldowns[abilityId] or 0
			local manaCost = definition and definition.ManaCost or 0
			local canUse = snapshot.BattleStatus == config.Statuses.PlayerTurn and (snapshot.Mana or 0) >= manaCost and cooldown <= 0
			button.Active, button.AutoButtonColor = canUse, canUse
			button.Activated:Connect(function() if current and current.BattleStatus == config.Statuses.PlayerTurn and button.Active then abilityRequest:FireServer(abilityId) end end)
			table.insert(abilityButtons, button)
		end
	end
end

local function restoreCamera()
	camera = Workspace.CurrentCamera
	if camera then camera.CameraType = Enum.CameraType.Custom; camera.CameraSubject = player.Character and player.Character:FindFirstChildOfClass("Humanoid") end
end

local function setBattleCamera(snapshot)
	camera = Workspace.CurrentCamera
	local characterRoot, brainrotRoot = rootOf(player.Character), rootOf(snapshot and snapshot.Brainrot)
	if not camera or not characterRoot or not brainrotRoot then return end
	local midpoint = (characterRoot.Position + brainrotRoot.Position) * 0.5 + Vector3.new(0, 1.7, 0)
	local direction = brainrotRoot.Position - characterRoot.Position
	if direction.Magnitude < 0.1 then direction = characterRoot.CFrame.LookVector else direction = direction.Unit end
	local side = direction:Cross(Vector3.yAxis)
	if side.Magnitude < 0.1 then side = characterRoot.CFrame.RightVector else side = side.Unit end
	local position = characterRoot.Position + direction * 12 + side * 4 + Vector3.new(0, 3.8, 0)
	camera.CameraType = Enum.CameraType.Scriptable
	TweenService:Create(camera, TweenInfo.new(0.22), {CFrame = CFrame.lookAt(position, midpoint)}):Play()
end

local function isBattleActive(snapshot)
	if not snapshot then return false end
	local status = snapshot.BattleStatus
	return status ~= config.Statuses.Victory and status ~= config.Statuses.Defeat and status ~= config.Statuses.Cancelled and status ~= "Rejected"
end

local function render(snapshot)
	if snapshot.BattleStatus == "Rejected" then statusLabel.Text = tostring(snapshot.Message or "Battle request rejected"); return end
	if not isBattleActive(snapshot) then
		current = nil; gui.Enabled = false; setMovementLocked(false)
		for abilityId in pairs(faceStates) do clearFace(abilityId) end
		restoreCamera()
		return
	end
	current = snapshot; gui.Enabled, root.Visible = true, true; setMovementLocked(true); renderAbilities(snapshot)
	playerStats.Text = string.format("HP: %d / %d\nRizz: %d\nRizz Level: %d\nMana: %d / %d", snapshot.PlayerHP or 0, snapshot.PlayerMaxHP or 0, snapshot.Rizz or 0, snapshot.RizzLevel or 1, snapshot.Mana or 0, snapshot.MaxMana or 0)
	brainrotStats.Text = string.format("%s\n%s\nHP: %d / %d", snapshot.BrainrotName or "Brainrot", snapshot.BrainrotRarity or "Unknown", snapshot.BrainrotHP or 0, snapshot.BrainrotMaxHP or 0)
	local status = tostring(snapshot.BattleStatus or "")
	turnLabel.Text = status == config.Statuses.PlayerTurn and "PLAYER TURN" or status == config.Statuses.BrainrotTurn and "BRAINROT TURN" or string.upper(status)
	statusLabel.Text = tostring(snapshot.Message or "")
	if status == config.Statuses.PlayerTurn or status == config.Statuses.BrainrotTurn then setBattleCamera(snapshot) else restoreCamera() end
end

battleState.OnClientEvent:Connect(render)
presentationRemote.OnClientEvent:Connect(playPresentation)
abilityResponse.OnClientEvent:Connect(function(success, _, message) if not success then statusLabel.Text = tostring(message or "Ability rejected") end end)
battleCamera.OnClientEvent:Connect(function(action, snapshot) if action == "Start" then setBattleCamera(snapshot) else restoreCamera() end end)
player.CharacterAdded:Connect(function() if isBattleActive(current) then task.wait(0.2); setMovementLocked(true); setBattleCamera(current) end end)
RunService.Heartbeat:Connect(function() if isBattleActive(current) then setMovementLocked(true) end end)
print("[BattleClient] Battle UI and configurable ability presentation ready")