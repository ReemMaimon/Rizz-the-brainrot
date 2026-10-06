-- LocalScript
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remote = ReplicatedStorage:WaitForChild("Open_Shop")

remote.OnClientEvent:Connect(function(signalName)
	while not _G.OpenMainGuiFrame do
		task.wait()
	end

	if signalName == "Shop" then
		_G.OpenMainGuiFrame("Shop")
	end
end)
