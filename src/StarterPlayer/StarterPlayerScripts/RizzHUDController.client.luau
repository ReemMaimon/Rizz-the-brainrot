local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local modules = ReplicatedStorage:WaitForChild("ModuleScripts")
local UIConfig = require(modules:WaitForChild("UIConfig"))
local RizzConfig = require(modules:WaitForChild("RizzConfig"))
local config = UIConfig
local theme = config.Theme
local hudConfig = config.HUD

local gui = playerGui:WaitForChild("RizzHUD")
gui.Enabled = config.Enabled ~= false

local root = gui:WaitForChild("HUD")
local scale = root:WaitForChild("ResponsiveScale")
local panel = root:WaitForChild("StatusPanel")
local content = panel:WaitForChild("Content")

local function label(parent, name, text, size, color, bold)
	local object = Instance.new("TextLabel")
	object.Name = name
	object.BackgroundTransparency = 1
	object.Size = UDim2.new(1, 0, 0, size + 5)
	object.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	object.Text = text
	object.TextColor3 = color
	object.TextSize = size
	object.TextXAlignment = Enum.TextXAlignment.Left
	object.TextTruncate = Enum.TextTruncate.AtEnd
	object.Parent = parent
	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MinTextSize = math.max(10, size - 4)
	constraint.MaxTextSize = size
	constraint.Parent = object
	return object
end

local function formatNumber(value)
	local number = tonumber(value) or 0
	if hudConfig.NumberFormat ~= "abbreviated" then return tostring(math.floor(number)) end
	local absolute = math.abs(number)
	if absolute >= 1000000000 then return string.format("%.1fB", number / 1000000000) end
	if absolute >= 1000000 then return string.format("%.1fM", number / 1000000) end
	if absolute >= 1000 then return string.format("%.1fK", number / 1000) end
	return tostring(math.floor(number))
end

local function getValue(groupName, valueName)
	local group = player:FindFirstChild(groupName)
	return group and group:FindFirstChild(valueName)
end

local function statRow(name)
	local container = content:WaitForChild(name)
	return {Container = container, Text = container:WaitForChild("Value")}
end

local function bar(name)
	local container = content:WaitForChild(name)
	local background = container:WaitForChild("BarBackground")
	return {Container = container, Text = container:WaitForChild("Value"), Fill = background:WaitForChild("Fill")}
end

local coins = statRow("Coins")
local rizz = statRow("Rizz")
local level = statRow("RizzLevel")
local hp = bar("HP")
local mana = bar("Mana")
local progress = bar("RizzProgress")

coins.Container.Visible = hudConfig.ShowCoins
rizz.Container.Visible = hudConfig.ShowRizz
level.Container.Visible = hudConfig.ShowRizzLevel
hp.Container.Visible = hudConfig.ShowHP
mana.Container.Visible = hudConfig.ShowMana
progress.Container.Visible = hudConfig.ShowRizzProgress
content.Coins.Icon.Image = config.Icons.Coins
content.Rizz.Icon.Image = config.Icons.Rizz
content.RizzLevel.Icon.Image = config.Icons.Level

local notifications = root:WaitForChild("Notifications")
local function notify(message, color)
	local item = label(notifications, "Notification", message, 18, color or theme.Text, true)
	item.AutomaticSize = Enum.AutomaticSize.X
	item.Size = UDim2.fromOffset(0, 30)
	item.BackgroundTransparency = 1
	item.TextTransparency = 1
	local itemStroke = Instance.new("UIStroke")
	itemStroke.Color = theme.Background
	itemStroke.Thickness = 2
	itemStroke.Transparency = 0.15
	itemStroke.Parent = item
	while #notifications:GetChildren() > config.Notifications.MaximumVisible + 1 do
		local oldest = notifications:GetChildren()[1]
		if oldest:IsA("TextLabel") then oldest:Destroy() else break end
	end
	local duration = config.Notifications.Duration
	local enter = TweenService:Create(item, TweenInfo.new(config.Animations.FeedbackDuration, config.Animations.EasingStyle), {TextTransparency = 0})
	enter:Play()
	task.delay(duration, function()
		if item.Parent then
			local exit = TweenService:Create(item, TweenInfo.new(config.Animations.CloseDuration, config.Animations.EasingStyle), {TextTransparency = 1})
			exit.Completed:Connect(function() item:Destroy() end)
			exit:Play()
		end
	end)
end

local function updateBar(bar, current, maximum, text)
	local maxValue = math.max(tonumber(maximum) or 0, 1)
	local currentValue = math.clamp(tonumber(current) or 0, 0, maxValue)
	bar.Text.Text = text
	bar.Fill.Size = UDim2.fromScale(currentValue / maxValue, 1)
end

local function refresh()
	local coinsValue = getValue("leaderstats", "Coins")
	local rizzValue = getValue("leaderstats", "Rizz")
	local levelValue = getValue("leaderstats", "RizzLevel")
	local hpValue = getValue("PlayerStats", "HP")
	local maxHP = getValue("PlayerStats", "MaxHP")
	local manaValue = getValue("PlayerStats", "Mana")
	local maxMana = getValue("PlayerStats", "MaxMana")
	coins.Text.Text = "Coins  " .. formatNumber(coinsValue and coinsValue.Value)
	rizz.Text.Text = "Rizz  " .. formatNumber(rizzValue and rizzValue.Value)
	level.Text.Text = "Level  " .. formatNumber(levelValue and levelValue.Value)
	updateBar(hp, hpValue and hpValue.Value, maxHP and maxHP.Value, "HP  " .. formatNumber(hpValue and hpValue.Value) .. " / " .. formatNumber(maxHP and maxHP.Value))
	updateBar(mana, manaValue and manaValue.Value, maxMana and maxMana.Value, "Mana  " .. formatNumber(manaValue and manaValue.Value) .. " / " .. formatNumber(maxMana and maxMana.Value))
	local currentRizz = tonumber(rizzValue and rizzValue.Value) or 0
	local currentLevel = tonumber(levelValue and levelValue.Value) or 1
	local requirements = RizzConfig.LevelRequirements or {}
	local nextRequirement = requirements[currentLevel + 1]
	if nextRequirement then
		local previousRequirement = requirements[currentLevel] or 0
		local span = math.max(nextRequirement - previousRequirement, 1)
		updateBar(progress, currentRizz - previousRequirement, span, "Next Level  " .. formatNumber(currentRizz) .. " / " .. formatNumber(nextRequirement))
	else
		updateBar(progress, 1, 1, "MAX RIZZ LEVEL")
	end
end

local watched = {}
local function watchValue(value)
	if value and not watched[value] then
		watched[value] = value:GetPropertyChangedSignal("Value"):Connect(refresh)
	end
end
local function connectGroup(group)
	if not group then return end
	for _, child in group:GetChildren() do watchValue(child) end
	group.ChildAdded:Connect(function(child) watchValue(child) refresh() end)
end
player.ChildAdded:Connect(function(child)
	if child.Name == "leaderstats" or child.Name == "PlayerStats" then connectGroup(child) refresh() end
end)
player:GetAttributeChangedSignal("LastTrainingReward"):Connect(function()
	local reward = player:GetAttribute("LastTrainingReward")
	if typeof(reward) == "number" then notify("+" .. formatNumber(reward) .. " Rizz", theme.Rizz) end
end)
player:GetAttributeChangedSignal("LastRizzLevelUp"):Connect(function()
	local newLevel = player:GetAttribute("LastRizzLevelUp")
	if typeof(newLevel) == "number" then notify("Rizz Level Up!  " .. formatNumber(newLevel), theme.Level) end
end)

local function updateScale()
	local camera = workspace.CurrentCamera
	local width = camera and camera.ViewportSize.X or 1280
	local touch = UserInputService.TouchEnabled
	local gamepad = UserInputService.GamepadEnabled
	if gamepad then scale.Scale = config.Responsive.ConsoleScale
	elseif touch and width <= config.Responsive.BreakpointMobile then scale.Scale = config.Responsive.MobileScale
	elseif width <= config.Responsive.BreakpointTablet then scale.Scale = config.Responsive.TabletScale
	else scale.Scale = config.Responsive.DesktopScale end
end
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale) end
UserInputService:GetPropertyChangedSignal("GamepadEnabled"):Connect(updateScale)
updateScale()
connectGroup(player:FindFirstChild("leaderstats"))
connectGroup(player:FindFirstChild("PlayerStats"))
refresh()
