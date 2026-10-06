-- CLIENT SCRIPT (StarterPlayerScripts)
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local workspaceBases = workspace:WaitForChild("Bases")

-- Wait for everything to load
player.CharacterAdded:Wait()
task.wait(5) -- Give extra time for data to sync

local ownedBase = player:FindFirstChild("OwnedBase")
if ownedBase and ownedBase.Value and ownedBase.Value > 0 then
	local baseName = "Base" .. tostring(ownedBase.Value)
	local base = workspaceBases:FindFirstChild(baseName)

	if base then
		local unlockBase = base:FindFirstChild("UnlockBase")
		if unlockBase then
			unlockBase:Destroy()
			print("✅ CLIENT: Removed UnlockBase from my base: " .. baseName)
		else
			print("ℹ️ No UnlockBase found in my base: " .. baseName)
		end
	else
		print("❌ My base not found: " .. baseName)
	end
else
	print("ℹ️ No owned base found")
end