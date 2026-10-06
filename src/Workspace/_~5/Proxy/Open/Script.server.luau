


-- Script under the Proxy
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local prompt = script.Parent
local remote = ReplicatedStorage:WaitForChild("Open_ToolsShop")

prompt.Triggered:Connect(function(player)
	remote:FireClient(player, "CoinsShop") -- internal signal name
end)
