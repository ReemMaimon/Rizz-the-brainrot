local ReplicatedStorage = game:GetService("ReplicatedStorage")

local rebirthRemote = ReplicatedStorage:FindFirstChild("RebirthRemote") or Instance.new("RemoteEvent")
rebirthRemote.Name = "RebirthRemote"
rebirthRemote.Parent = ReplicatedStorage

rebirthRemote.OnServerEvent:Connect(function(player)
	if player and player.Parent then
		warn("Rebirth request ignored during Rizz The Brainrot Phase 1:", player.Name)
	end
end)
