local tool = script.Parent
local defaultSpeed = 25 -- Default Roblox walkspeed
local currentHumanoid = nil

tool.Equipped:Connect(function()
	local player = game:GetService("Players").LocalPlayer
	local humanoid = player.Character:FindFirstChild("Humanoid")

	if humanoid then
		-- Store the current humanoid reference
		currentHumanoid = humanoid
		-- Store the default speed if we haven't already
		if defaultSpeed == 16 then
			defaultSpeed = humanoid.WalkSpeed
		end
		-- Set the new speed
		humanoid.WalkSpeed = 28
	end
end)

tool.Unequipped:Connect(function()
	if currentHumanoid then
		-- Reset to default speed
		currentHumanoid.WalkSpeed = defaultSpeed
		currentHumanoid = nil
	end
end)