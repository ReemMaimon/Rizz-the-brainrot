local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local config = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("RizzConfig"))
local trainingConfig = config.Training or {}
local remotes = ReplicatedStorage:WaitForChild("TrainingRemotes")
local actionRemote = remotes:WaitForChild("TrainingAction")
local stateRemote = remotes:WaitForChild("TrainingState")
local playerGui = player:WaitForChild("PlayerGui")

local gui = playerGui:WaitForChild("TrainingUI")
local panel = gui:WaitForChild("Panel")
local title = panel:WaitForChild("Title")
local stats = panel:WaitForChild("Stats")
local reward = panel:WaitForChild("Reward")
local progress = panel:WaitForChild("Progress")
local trainButton = panel:WaitForChild("TrainButton")
local popupLayer = gui:WaitForChild("PopupLayer")
popupLayer.BackgroundTransparency = 1
popupLayer.Size = UDim2.fromScale(1, 1)
popupLayer.Parent = gui

local function createTrainingParticles()
	if not trainingConfig.ParticleEnabled then return nil end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	local attachment = Instance.new("Attachment")
	attachment.Name = "SigmaTrainingParticles"
	attachment.Position = Vector3.new(0, 1.5, 0)
	attachment.Parent = root
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "SigmaMewingBurst"
	emitter.Color = ColorSequence.new(trainingConfig.ParticleColor or Color3.fromRGB(255, 221, 92), trainingConfig.ParticleSecondaryColor or Color3.fromRGB(255, 105, 202))
	emitter.LightEmission = 0.7
	emitter.Lifetime = trainingConfig.ParticleLifetime or NumberRange.new(0.35, 0.8)
	emitter.Speed = trainingConfig.ParticleSpeed or NumberRange.new(2, 5)
	emitter.Size = trainingConfig.ParticleSize or NumberSequence.new(0.25)
	emitter.Rate = trainingConfig.ParticleRate or 5
	emitter.SpreadAngle = Vector2.new(360, 360)
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Parent = attachment
	return attachment, emitter
end

local particleAttachment, particleEmitter
local function startParticles()
	if particleAttachment then return end
	particleAttachment, particleEmitter = createTrainingParticles()
end

local function stopParticles()
	if particleAttachment then
		particleAttachment:Destroy()
		particleAttachment = nil
		particleEmitter = nil
	end
end

local function showRizzPopup(amount)
	if not trainingConfig.PopupEnabled then return end
	local popup = Instance.new("TextLabel")
	popup.Name = "RizzPopup"
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.Position = UDim2.fromScale(0.5 + math.random(-8, 8) / 100, 0.48)
	popup.Size = UDim2.fromOffset(260, 48)
	popup.BackgroundTransparency = 1
	popup.Font = Enum.Font.GothamBlack
	popup.Text = string.format("+%d RIZZ", amount)
	popup.TextColor3 = trainingConfig.PopupColor or Color3.fromRGB(255, 221, 92)
	popup.TextStrokeColor3 = Color3.fromRGB(45, 20, 60)
	popup.TextStrokeTransparency = 0.15
	popup.TextTransparency = 0
	popup.TextScaled = true
	popup.ZIndex = 20
	popup.Parent = popupLayer
	local targetPosition = popup.Position + UDim2.fromOffset(0, -(trainingConfig.PopupRiseDistance or 70))
	local tween = TweenService:Create(popup, TweenInfo.new(trainingConfig.PopupDuration or 0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = targetPosition,
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	tween:Play()
	tween.Completed:Connect(function()
		popup:Destroy()
	end)
end

local localCooldown = 0
local active = false
local function sendTrain()
	if not active then return end
	local now = os.clock()
	if now - localCooldown < math.max(0.05, trainingConfig.Cooldown or 0.35) then return end
	localCooldown = now
	if particleEmitter then particleEmitter:Emit(trainingConfig.ParticleBurstCount or 12) end
	actionRemote:FireServer("Train")
end

trainButton.Activated:Connect(sendTrain)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not active then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonA then sendTrain() end
end)

local function update(rizz, level, amount)
	local levels = config.RizzLevels or {}
	local current = levels[level]
	local nextData = levels[level + 1]
	local nextRequirement = nextData and nextData.RequiredRizz or nil
	stats.Text = string.format("Level %d  |  Rizz %d", level, rizz)
	reward.Text = string.format("+%d Rizz / Click", amount)
	if nextRequirement then
		progress.Text = string.format("Next Level: %d Rizz  |  %d / %d", nextRequirement, rizz, nextRequirement)
	else
		progress.Text = "MAX LEVEL"
	end
end

stateRemote.OnClientEvent:Connect(function(event, a, b, c, d)
	if event == "Started" then
		active = true
		gui.Enabled = true
		startParticles()
		local levels = config.RizzLevels or {}
		local levelValue = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("RizzLevel")
		local rizzValue = player.leaderstats and player.leaderstats:FindFirstChild("Rizz")
		local level = levelValue and levelValue.Value or 1
		local rizz = rizzValue and rizzValue.Value or 0
		local data = levels[level]
		update(rizz, level, data and data.RizzPerClick or 1)
	elseif event == "Reward" then
		update(b, c, a)
		showRizzPopup(a)
		if d then
			title.Text = string.format("RIZZ LEVEL UP!  LEVEL %d", c)
			local pulse = TweenService:Create(title, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 2, true), {TextColor3 = Color3.fromRGB(255, 255, 255)})
			pulse:Play()
			task.delay(trainingConfig.LevelUpFeedbackDuration or 2, function()
				if active then title.Text = "RIZZ TRAINING" end
			end)
		end
	elseif event == "Stopped" then
		active = false
		gui.Enabled = false
		stopParticles()
	end
end)

ContextActionService:BindAction("TrainingGamepad", function(_, state)
	if state == Enum.UserInputState.Begin then sendTrain() end
	return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.ButtonA)