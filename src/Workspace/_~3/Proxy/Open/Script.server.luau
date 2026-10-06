-- Script (NOT LocalScript)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local prompt = script.Parent
local remote = ReplicatedStorage:WaitForChild("Open_Shop")

prompt.Triggered:Connect(function(player)
	remote:FireClient(player, "Shop")
end)