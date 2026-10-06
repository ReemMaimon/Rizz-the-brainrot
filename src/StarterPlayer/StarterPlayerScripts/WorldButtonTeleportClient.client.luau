local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local worldButtonGui = playerGui:WaitForChild("WorldButtonGui")
local worldButton = worldButtonGui:WaitForChild("WorldButton")
local teleportEvent = ReplicatedStorage:WaitForChild("WorldButtonTeleport")

worldButton.Activated:Connect(function()
	teleportEvent:FireServer()
end)
