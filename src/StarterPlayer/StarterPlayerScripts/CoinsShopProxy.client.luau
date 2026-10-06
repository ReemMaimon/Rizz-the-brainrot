-- LocalScript
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remote = ReplicatedStorage:WaitForChild("Open_ToolsShop")

remote.OnClientEvent:Connect(function(frameName)
	if _G.OpenMainGuiFrame then
		_G.OpenMainGuiFrame(frameName)
	end
end)
