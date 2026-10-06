local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RarityConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("RarityConfig"))
local EncounterConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("EncounterConfig"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mainGui = playerGui:WaitForChild("MainGui")
local panel = mainGui:WaitForChild("BrainrotInfoPanel")

local nameLabel = panel:WaitForChild("BrainrotName")
local rarityLabel = panel:WaitForChild("Rarity")
local hintLabel = panel:WaitForChild("Hint")
local activateButton = panel:FindFirstChild(EncounterConfig.UI.ButtonName)
local feedbackLabel = panel:FindFirstChild("Feedback")

local maxDisplayDistance = math.max(0, tonumber(EncounterConfig.UI.PanelVisibleDistance) or 20)
local interactionDistance = math.max(0, tonumber(EncounterConfig.InteractionDistance) or 12)
local startEncounter = ReplicatedStorage:WaitForChild("StartEncounter")
local encounterFeedback = ReplicatedStorage:WaitForChild("EncounterFeedback")

local selectedModel
local feedbackToken = 0

local function getNearest()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local folder = Workspace:FindFirstChild("ActiveBrainrots")
	if not root or not folder then
		return nil, math.huge
	end
	local nearest
	local nearestDistance = math.huge
	for _, model in ipairs(folder:GetChildren()) do
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
	if not feedbackLabel then
		return
	end
	feedbackToken += 1
	local token = feedbackToken
	feedbackLabel.Text = message
	feedbackLabel.TextColor3 = success and Color3.fromRGB(120, 255, 150) or Color3.fromRGB(255, 150, 150)
	feedbackLabel.Visible = true
	task.delay(math.max(0.1, tonumber(EncounterConfig.UI.FeedbackDuration) or 3), function()
		if token == feedbackToken then
			feedbackLabel.Visible = false
		end
	end)
end

local function requestEncounter()
	if not selectedModel then
		return
	end
	startEncounter:FireServer(selectedModel)
end

if activateButton and activateButton:IsA("GuiButton") then
	activateButton.Activated:Connect(requestEncounter)
end

encounterFeedback.OnClientEvent:Connect(function(result)
	if typeof(result) ~= "table" then
		return
	end
	showFeedback(tostring(result.Message or ""), result.Success == true)
	if result.Success == true and activateButton then
		activateButton.Active = false
		activateButton.AutoButtonColor = false
	end
end)

local function update()
	local model, distance = getNearest()
	selectedModel = model
	if not model then
		panel.Visible = false
		return
	end

	local brainrotName = model:GetAttribute("BrainrotName") or model.Name
	local brainrotRarity = model:GetAttribute("BrainrotRarity") or "Unknown"
	nameLabel.Text = brainrotName

	local rarityDef = RarityConfig.Definitions[brainrotRarity]
	if rarityDef then
		local c = rarityDef.Color
		rarityLabel.TextColor3 = Color3.fromRGB(c[1], c[2], c[3])
		rarityLabel.Text = rarityDef.DisplayName or brainrotRarity
	else
		rarityLabel.TextColor3 = Color3.fromRGB(170, 220, 255)
		rarityLabel.Text = brainrotRarity
	end

	local state = model:GetAttribute("EncounterState")
	local available = state == nil or state == EncounterConfig.Encounter.StateAvailable
	if activateButton then
		activateButton.Visible = available and distance <= interactionDistance
		activateButton.Active = available
		activateButton.AutoButtonColor = available
	end
	if distance <= interactionDistance and available then
		hintLabel.Text = EncounterConfig.UI.ActivateText
	elseif not available then
		hintLabel.Text = EncounterConfig.UI.UnavailableText
	else
		hintLabel.Text = EncounterConfig.UI.ApproachText
	end
	panel.Visible = true
end

RunService.Heartbeat:Connect(update)