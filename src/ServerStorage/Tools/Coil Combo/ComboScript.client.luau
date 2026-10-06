local tool = script.Parent
local defaultSpeed = 25 -- Default walkspeed
local defaultGravity = 196.2 -- Default Roblox gravity
local defaultJumpPower = 50 -- Default Roblox jump power
local currentHumanoid = nil

tool.Equipped:Connect(function()
	-- Change gravity
	workspace.Gravity = 29

	-- Change walkspeed and jump power
	local player = game:GetService("Players").LocalPlayer
	local humanoid = player.Character:FindFirstChild("Humanoid")

	if humanoid then
		-- Store the current humanoid reference
		currentHumanoid = humanoid
		-- Set the new speed and jump power
		humanoid.WalkSpeed = 32
		humanoid.JumpPower = 130 -- Increased jump power
	end
end)

tool.Unequipped:Connect(function()
	-- Reset gravity
	workspace.Gravity = defaultGravity

	-- Reset walkspeed and jump power
	if currentHumanoid then
		currentHumanoid.WalkSpeed = defaultSpeed
		currentHumanoid.JumpPower = defaultJumpPower
		currentHumanoid = nil
	end
end)