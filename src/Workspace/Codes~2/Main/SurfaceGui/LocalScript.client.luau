local ReplicatedStorage = game:GetService("ReplicatedStorage")
local updateEvent = ReplicatedStorage:WaitForChild("UpdateLikes")

local likeText = script.Parent:WaitForChild("LikeText")
local barFill = script.Parent:WaitForChild("ProgressBar"):WaitForChild("Fill")

updateEvent.OnClientEvent:Connect(function(currentLikes, goal)
	local progress = math.clamp(currentLikes / goal, 0, 1)
	likeText.Text = currentLikes .. "/" .. goal
	barFill.Size = UDim2.new(progress, 0, 1, 0)

	if progress >= 1 then
		barFill.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
	elseif progress >= 0.5 then
		barFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	else
		barFill.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	end
end)
