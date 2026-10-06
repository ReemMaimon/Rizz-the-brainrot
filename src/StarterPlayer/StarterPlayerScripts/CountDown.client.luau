local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- GUI Setup
local countdownModel = Workspace:WaitForChild("BloodmoonCountdown")
local guiPart = countdownModel:WaitForChild("GuiPart")
local billboardGui = guiPart:WaitForChild("BillboardGui")
local label = billboardGui:WaitForChild("Countdown")

local timerValue = ReplicatedStorage:WaitForChild("BloodMoonTimer")
local isBloodMoon = ReplicatedStorage:WaitForChild("IsBloodMoon")

local function updateText()
	local seconds = timerValue.Value
	local minutes = math.floor(seconds / 60)
	local sec = seconds % 60
	local prefix = isBloodMoon.Value and "Ends in:" or "Starting in:"
	label.Text = string.format("%s %dm %ds", prefix, minutes, sec)
end

timerValue:GetPropertyChangedSignal("Value"):Connect(updateText)
isBloodMoon:GetPropertyChangedSignal("Value"):Connect(updateText)
updateText()

