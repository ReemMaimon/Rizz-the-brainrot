local TweenService = game:GetService("TweenService")
local textLabel = script.Parent

-- Bright rainbow colors
local rainbowColors = {
	Color3.fromRGB(255, 0, 0),    -- Red
	Color3.fromRGB(255, 128, 0),  -- Orange
	Color3.fromRGB(255, 255, 0),  -- Yellow
	Color3.fromRGB(0, 255, 0),    -- Green
	Color3.fromRGB(0, 255, 255),  -- Cyan
	Color3.fromRGB(0, 128, 255),  -- Blue
	Color3.fromRGB(128, 0, 255),  -- Purple
	Color3.fromRGB(255, 0, 255)   -- Magenta
}

local currentIndex = 1
local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

while true do
	local color = rainbowColors[currentIndex]
	local tween = TweenService:Create(textLabel, tweenInfo, {TextColor3 = color})
	tween:Play()

	currentIndex += 1
	if currentIndex > #rainbowColors then
		currentIndex = 1
	end

	task.wait(0.4)
end
