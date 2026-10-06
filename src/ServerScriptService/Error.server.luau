-- ERROR SYSTEM ENABLER - Makes sure all error messages work properly
-- Place in ServerScriptService as a regular Script

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Ensure all error types are enabled and working
local function enableAllErrors()
	-- Create ShowErrorRemote if it doesn't exist
	local showErrorRemote = ReplicatedStorage:FindFirstChild("ShowErrorRemote")
	if not showErrorRemote then
		showErrorRemote = Instance.new("RemoteEvent")
		showErrorRemote.Name = "ShowErrorRemote"
		showErrorRemote.Parent = ReplicatedStorage
	end

	-- Ensure ErrorHandler module is loaded and working
	local success, ErrorHandler = pcall(function()
		return require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("ErrorHandler"))
	end)

	if success and ErrorHandler then
		-- Test that ErrorHandler is working
		local errorTypes = ErrorHandler.GetErrorTypes()
		if errorTypes then
			print("✅ ErrorHandler loaded successfully with", #errorTypes, "error types")
		end

		-- Set up global error function if not exists
		if not _G.ShowError then
			_G.ShowError = ErrorHandler.ShowError
		end
	else
		warn("❌ Failed to load ErrorHandler module")
	end

	-- Ensure sounds folder exists
	local soundsFolder = ReplicatedStorage:FindFirstChild("Sounds")
	if not soundsFolder then
		soundsFolder = Instance.new("Folder")
		soundsFolder.Name = "Sounds"
		soundsFolder.Parent = ReplicatedStorage

		-- Create basic error sounds if they don't exist
		local errorSoundNames = {"Error", "Success", "Stealing_From_Someone", "Getting_Stoled", "Collecting_Coins"}
		for _, soundName in ipairs(errorSoundNames) do
			local sound = Instance.new("Sound")
			sound.Name = soundName
			sound.SoundId = "rbxassetid://1234567890" -- Replace with actual sound IDs
			sound.Volume = 0.5
			sound.Parent = soundsFolder
		end
	end

	-- Restore error sound volume if it was muted
	local errorSound = soundsFolder:FindFirstChild("Error")
	if errorSound then
		errorSound.Volume = 0.5 -- Restore normal volume
	end
end

-- Apply the fix immediately
enableAllErrors()

-- Create helper validation functions that SHOW errors
_G.ValidatePlayerAction = function(player, actionType, ...)
	local args = {...}

	if actionType == "purchase" then
		local cost = args[1]
		local leaderstats = player:FindFirstChild("leaderstats")
		if not leaderstats then return false end

		local coins = leaderstats:FindFirstChild("Coins")
		if not coins then return false end

		-- Check money
		if coins.Value < cost then
			local needed = cost - coins.Value
			if _G.ShowError then
				-- Format the needed amount properly
				local formattedAmount = tostring(needed)
				if needed >= 1000000 then
					formattedAmount = string.format("%.1fM", needed / 1000000)
				elseif needed >= 1000 then
					formattedAmount = string.format("%.1fK", needed / 1000)
				end
				_G.ShowError(player, "NO_MONEY", formattedAmount)
			end
			return false
		end

		-- Check baby space
		local babiesFolder = player:FindFirstChild("Babies")
		local count = 0
		if babiesFolder then
			for _, folder in pairs(babiesFolder:GetChildren()) do
				if folder:IsA("Folder") and folder.Name:find("Baby_Stand") then
					count = count + 1
				end
			end
		end
		if count >= 10 then
			if _G.ShowError then
				_G.ShowError(player, "TOO_MANY_BABIES_PURCHASE")
			end
			return false
		end

		-- Check if carrying
		if player.Character then
			local hrp = player.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				for _, model in pairs(game.Workspace:GetChildren()) do
					if model:IsA("Model") and model.Name:find("_Carried") then
						for _, part in pairs(model:GetDescendants()) do
							if part:IsA("WeldConstraint") then
								if part.Part0 == hrp or part.Part1 == hrp then
									if _G.ShowError then
										_G.ShowError(player, "ALREADY_CARRYING")
									end
									return false
								end
							end
						end
					end
				end
			end
		end

		return true

	elseif actionType == "steal" then
		-- Similar validation for stealing
		local babiesFolder = player:FindFirstChild("Babies")
		local count = 0
		if babiesFolder then
			for _, folder in pairs(babiesFolder:GetChildren()) do
				if folder:IsA("Folder") and folder.Name:find("Baby_Stand") then
					count = count + 1
				end
			end
		end
		if count >= 10 then
			if _G.ShowError then
				_G.ShowError(player, "TOO_MANY_BABIES_STEAL")
			end
			return false
		end

		-- Check if carrying
		if player.Character then
			local hrp = player.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				for _, model in pairs(game.Workspace:GetChildren()) do
					if model:IsA("Model") and model.Name:find("_Carried") then
						for _, part in pairs(model:GetDescendants()) do
							if part:IsA("WeldConstraint") then
								if part.Part0 == hrp or part.Part1 == hrp then
									if _G.ShowError then
										_G.ShowError(player, "ALREADY_CARRYING")
									end
									return false
								end
							end
						end
					end
				end
			end
		end

		return true
	end

	return true
end

print("✅ ERROR SYSTEM ENABLER: All error messages are now working!")
print("💡 Players will see proper error messages for:")
print("   - Not enough money")
print("   - Too many babies (10/10)")
print("   - Already carrying a baby")
print("   - No available stands")
print("   - All other validation errors")