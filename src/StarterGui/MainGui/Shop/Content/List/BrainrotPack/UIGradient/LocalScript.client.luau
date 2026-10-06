-- Optimized smooth UIGradient rotator using TweenService

local TweenService = game:GetService("TweenService")

local uigradient = script.Parent
local uigradient1 = uigradient.Parent:FindFirstChild("UIStroke"):FindFirstChild("UIGradient")
local uiGradient2 = uigradient.Parent:FindFirstChild("TitleName"):FindFirstChild("UIGradient")
local uiGradient3 = uiGradient2.Parent:FindFirstChild("UIStroke"):FindFirstChild("UIGradient")

-- Table of gradients to rotate
local gradients = {uigradient, uigradient1, uiGradient2, uiGradient3}

-- Create a tweening loop for rotation
local function rotateGradients()
	for _, gradient in pairs(gradients) do
		local goal = {Rotation = gradient.Rotation + 360}
		local tween = TweenService:Create(gradient, TweenInfo.new(10, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), goal)
		tween:Play()
	end
end

while true do
	rotateGradients()
	task.wait(10) -- matches the TweenInfo duration
end
