local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RarityConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("RarityConfig"))
local EncounterConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("EncounterConfig"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local startEncounter = ReplicatedStorage:WaitForChild("StartEncounter")
local encounterFeedback = ReplicatedStorage:WaitForChild("EncounterFeedback")
local activeFolder = Workspace:WaitForChild("ActiveBrainrots")

local function createFallbackPanel()
	local mainGui = Instance.new("ScreenGui")
	mainGui.Name = "EncounterFallbackGui"
	mainGui.ResetOnSpawn = false
	mainGui.IgnoreGuiInset = true
	mainGui.DisplayOrder = 10
	mainGui.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.Name = "BrainrotInfoPanel"
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.Position = UDim2.fromScale(0.5, 0.94)
	panel.Size = UDim2.fromOffset(320, 190)
	panel.BackgroundColor3 = Color3.fromRGB(28, 32, 46)
	panel.BackgroundTransparency = 0.08
	panel.Visible = false
	panel.Parent = mainGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel

	local function label(name, position, size, text)
		local item = Instance.new("TextLabel")
		item.Name = name
		item.Position = position
		item.Size = size
		item.BackgroundTransparency = 1
		item.TextColor3 = Color3.new(1, 1, 1)
		item.Font = Enum.Font.SourceSansBold
		item.TextScaled = true
		item.Text = text
		item.Parent = panel
		return item
	end

	local nameLabel = label("BrainrotName", UDim2.fromScale(0.08, 0.06), UDim2.fromScale(0.84, 0.2), "Brainrot")
	local rarityLabel = label("Rarity", UDim2.fromScale(0.08, 0.25), UDim2.fromScale(0.84, 0.15), "Unknown")
	local hintLabel = label("Hint", UDim2.fromScale(0.08, 0.42), UDim2.fromScale(0.84, 0.14), "Approach")
	local activateButton = Instance.new("TextButton")
	activateButton.Name = "StartEncounterButton"
	activateButton.Position = UDim2.fromScale(0.1, 0.62)
	activateButton.Size = UDim2.fromScale(0.8, 0.22)
	activateButton.BackgroundColor3 = Color3.fromRGB(110, 55, 205)
	activateButton.TextColor3 = Color3.new(1, 1, 1)
	activateButton.Font = Enum.Font.SourceSansBold
	activateButton.TextScaled = true
	activateButton.Text = "RIZZ BATTLE"
	activateButton.Parent = panel
	local feedbackLabel = label("Feedback", UDim2.fromScale(0.06, 0.84), UDim2.fromScale(0.88, 0.12), "")
	feedbackLabel.Visible = false
	return mainGui, panel, nameLabel, rarityLabel, hintLabel, activateButton, feedbackLabel
end

local mainGui = playerGui:FindFirstChild("MainGui")
local panel = mainGui and mainGui:FindFirstChild("BrainrotInfoPanel")
local nameLabel = panel and panel:FindFirstChild("BrainrotName")
local rarityLabel = panel and panel:FindFirstChild("Rarity")
local hintLabel = panel and panel:FindFirstChild("Hint")
local activateButton = panel and panel:FindFirstChild("StartEncounterButton")
local feedbackLabel = panel and panel:FindFirstChild("Feedback")

if not panel or not nameLabel or not rarityLabel or not hintLabel or not activateButton then
	mainGui, panel, nameLabel, rarityLabel, hintLabel, activateButton, feedbackLabel = createFallbackPanel()
	warn("[BrainrotEncounterClient] MainGui was not replicated; created encounter fallback UI")
end

local maxDisplayDistance = math.max(0, tonumber(EncounterConfig.UI.PanelVisibleDistance) or 20)
local interactionDistance = math.max(0, tonumber(EncounterConfig.InteractionDistance) or 12)
local selectedModel
local feedbackToken = 0

local function getNearest()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil, math.huge
	end
	local nearest
	local nearestDistance = math.huge
	for _, model in ipairs(activeFolder:GetChildren()) do
		if model:IsA("Model") and model:GetAttribute("BrainrotName") then
			local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
			if part then
				local distance = (part.Position - root.Position).Magnitude
				if distance < nearestDistance and distance <= maxDisplayDistance then
					nearest = model
					nearestDistance = distance
				end
			end
		end
	end
	return nearest, nearestDistance
end

local function showFeedback(message, success)
	if not feedbackLabel then return end
	feedbackToken += 1
	local token = feedbackToken
	feedbackLabel.Text = message
	feedbackLabel.TextColor3 = success and Color3.fromRGB(120, 255, 150) or Color3.fromRGB(255, 150, 150)
	feedbackLabel.Visible = true
	task.delay(math.max(0.1, tonumber(EncounterConfig.UI.FeedbackDuration) or 3), function()
		if token == feedbackToken and feedbackLabel.Parent then
			feedbackLabel.Visible = false
		end
	end)
end

activateButton.Activated:Connect(function()
	if selectedModel and activateButton.Active then
		startEncounter:FireServer(selectedModel)
	end
end)

encounterFeedback.OnClientEvent:Connect(function(result)
	if typeof(result) ~= "table" then return end
	showFeedback(tostring(result.Message or ""), result.Success == true)
	if result.Success == true then
		activateButton.Active = false
		activateButton.AutoButtonColor = false
	end
end)

RunService.Heartbeat:Connect(function()
	local model, distance = getNearest()
	selectedModel = model
	if not model then
		panel.Visible = false
		return
	end

	nameLabel.Text = tostring(model:GetAttribute("BrainrotName") or model.Name)
	local rarityName = tostring(model:GetAttribute("BrainrotRarity") or "Unknown")
	local rarityDefinition = RarityConfig.Definitions[rarityName]
	rarityLabel.Text = rarityDefinition and tostring(rarityDefinition.DisplayName or rarityName) or rarityName
	if rarityDefinition and rarityDefinition.Color then
		local c = rarityDefinition.Color
		rarityLabel.TextColor3 = Color3.fromRGB(c[1], c[2], c[3])
	end

	local state = model:GetAttribute("EncounterState")
	local available = state == nil or state == EncounterConfig.Encounter.StateAvailable
	local closeEnough = distance <= interactionDistance
	activateButton.Visible = available and closeEnough
	activateButton.Active = available and closeEnough
	activateButton.AutoButtonColor = available and closeEnough
	if state == EncounterConfig.Encounter.StateInEncounter then
		hintLabel.Text = EncounterConfig.UI.UnavailableText
	elseif closeEnough then
		hintLabel.Text = EncounterConfig.UI.ActivateText
	else
		hintLabel.Text = EncounterConfig.UI.ApproachText
	end
	panel.Visible = true
end)

print("[BrainrotEncounterClient] Interaction UI ready")