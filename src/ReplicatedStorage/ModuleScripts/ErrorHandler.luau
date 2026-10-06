-- ReplicatedStorage > ModuleScripts > ErrorHandler (COMPLETE VERSION - ALL ERRORS WORKING)
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ErrorHandler = {}

-- Configuration
local TWEEN_DURATION = 0.8
local BOUNCE_INTENSITY = 0.15
local DISPLAY_DURATION = 3

-- Track persistent errors
local persistentErrors = {}

-- ALL Error Types and Colors (COMPLETE VERSION)
local ERROR_TYPES = {
	STEALING = {
		text = "STEALING A BABY, GO TO YOUR BASE!",
		color = "rainbow",
		sound = "Stealing_From_Someone"
	},
	STEALING_PERSISTENT = {
		text = "STEALING A BABY, GO TO YOUR BASE!",
		color = "rainbow",
		sound = "Stealing_From_Someone",
		persistent = true
	},
	BEING_STOLEN_PERSISTENT = {
		text = "%s IS BEING STOLEN!",
		color = "white_with_red_name",
		sound = "Getting_Stoled",
		persistent = true
	},
	NO_MONEY = {
		text = "Need %s More Coins To Buy This!",
		color = Color3.fromRGB(255, 100, 100), -- Red
		sound = "Error"
	},
	TOO_MANY_BABIES = {
		text = "Maximum 10 Babies Per Base! (You Have 10/10)",
		color = Color3.fromRGB(255, 150, 50), -- Orange
		sound = "Error"
	},
	TOO_MANY_BABIES_STEAL = {
		text = "Can't Steal! Maximum 10 Babies Per Base!",
		color = Color3.fromRGB(255, 150, 50), -- Orange
		sound = "Error"
	},
	TOO_MANY_BABIES_PURCHASE = {
		text = "Can't Purchase! Maximum 10 Babies Per Base!",
		color = Color3.fromRGB(255, 150, 50), -- Orange
		sound = "Error"
	},
	BEING_STOLEN = {
		text = "%s IS BEING STOLEN!",
		color = Color3.fromRGB(255, 100, 100), -- Red
		sound = "Getting_Stoled"
	},
	BASE_ALREADY_LOCKED = {
		text = "Base Is Already Locked For %s!",
		color = Color3.fromRGB(255, 100, 100), -- Red
		sound = "Error"
	},
	BASE_LOCKED_SUCCESS = {
		text = "Successfully Locked The Base For %s!",
		color = Color3.fromRGB(100, 255, 100), -- Green
		sound = "Success"
	},
	BASE_UNLOCKED = {
		text = "Your Base Is Now Unlocked!",
		color = Color3.fromRGB(100, 255, 255), -- Cyan
		sound = "Success"
	},
	BASE_CLAIMED = {
		text = "Base Claimed! Welcome To Your Base!",
		color = Color3.fromRGB(100, 255, 100), -- Green
		sound = "Success"
	},
	BASE_ALREADY_CLAIMED = {
		text = "You Already Have A Base!",
		color = Color3.fromRGB(255, 100, 100), -- Red
		sound = "Error"
	},
	BASE_NOT_AVAILABLE = {
		text = "That Base Is Already Claimed!",
		color = Color3.fromRGB(255, 150, 50), -- Orange
		sound = "Error"
	},
	CANT_STEAL_OWN = {
		text = "Can't Steal Your Own Baby!",
		color = Color3.fromRGB(255, 150, 50), -- Orange
		sound = "Error"
	},
	CANNOT_STEAL_OWN_BASE = {
		text = "Can't Steal From Your Own Base! Use Sell Instead!",
		color = Color3.fromRGB(255, 150, 50), -- Orange
		sound = "Error"
	},
	BEING_HIT = {
		text = "💥 You Were Hit! Baby Returned To Owner!",
		color = Color3.fromRGB(255, 100, 100), -- Red
		sound = "Error"
	},
	BABY_SAVED = {
		text = "✅ Your Baby Was Saved!",
		color = Color3.fromRGB(100, 255, 100), -- Green
		sound = "Success"
	},
	ALREADY_CARRYING = {
		text = "Already Carrying A Baby!",
		color = Color3.fromRGB(255, 200, 100), -- Light Orange
		sound = "Error"
	},
	NO_STANDS_AVAILABLE = {
		text = "No Available Stands In Your Base!",
		color = Color3.fromRGB(255, 150, 50), -- Orange
		sound = "Error"
	},
	BABY_BEING_STOLEN = {
		text = "This Baby Is Being Stolen!",
		color = Color3.fromRGB(255, 100, 100), -- Red
		sound = "Error"
	},
	SUCCESS_PURCHASE = {
		text = "Successfully Purchased Baby!",
		color = Color3.fromRGB(100, 255, 100), -- Green
		sound = "Collecting_Coins"
	},
	SUCCESS_SELL = {
		text = "Successfully Sold Baby!",
		color = Color3.fromRGB(100, 255, 100), -- Green
		sound = "Success"
	},
	SUCCESS_STEAL = {
		text = "Successfully Stole Baby!",
		color = Color3.fromRGB(255, 255, 100), -- Yellow
		sound = "Success"
	},
	LOCKED_BASE_STEAL = {
		text = "Base Is Locked! Can't Steal!",
		color = Color3.fromRGB(255, 150, 50), -- Orange
		sound = "Error"
	},
	SERVER_FULL = {
		text = "Server Is Full!",
		color = Color3.fromRGB(255, 100, 100), -- Red
		sound = "Error"
	},
	WELCOME_BACK = {
		text = "Welcome Back! Check Your Collection Stands!",
		color = Color3.fromRGB(100, 255, 255), -- Cyan
		sound = "Success"
	},
	OFFLINE_EARNINGS = {
		text = "💰 Offline Earnings: %s! Check Your Stands! 💰",
		color = Color3.fromRGB(255, 215, 0), -- Gold
		sound = "Collecting_Coins",
		duration = 7
	},
	HINT_SELL_BABIES = {
		text = "Hint: Sell Some Babies To Make Room!",
		color = Color3.fromRGB(200, 200, 255), -- Light blue
		sound = "Info"
	},
	BABY_COUNT_STATUS = {
		text = "Babies: %d/10 - %d Slots Available",
		color = Color3.fromRGB(200, 255, 200), -- Light green
		sound = "Info"
	}
}

-- Rainbow effect function
local function createRainbowEffect(textLabel)
	local rainbowConnection
	local function startRainbow()
		if rainbowConnection then
			rainbowConnection:Disconnect()
		end

		local function updateColor()
			local time = tick() * 2
			local r = math.sin(time) * 0.5 + 0.5
			local g = math.sin(time + 2) * 0.5 + 0.5
			local b = math.sin(time + 4) * 0.5 + 0.5
			textLabel.TextColor3 = Color3.fromRGB(r * 255, g * 255, b * 255)
		end

		rainbowConnection = RunService.Heartbeat:Connect(updateColor)
		return rainbowConnection
	end

	return startRainbow()
end

-- Function to set white text with red baby name
local function setWhiteTextWithRedName(textLabel, fullText, babyName)
	local babyNameStart, babyNameEnd = string.find(fullText, babyName)

	if babyNameStart and babyNameEnd then
		local beforeName = string.sub(fullText, 1, babyNameStart - 1)
		local afterName = string.sub(fullText, babyNameEnd + 1)

		local richText = string.format(
			'<font color="rgb(255,255,255)">%s</font><font color="rgb(255,0,0)">%s</font><font color="rgb(255,255,255)">%s</font>',
			beforeName,
			babyName,
			afterName
		)

		textLabel.RichText = true
		textLabel.Text = richText
	else
		textLabel.RichText = false
		textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		textLabel.Text = fullText
	end
end

-- SERVER-SIDE: Show error function (ALL ERRORS ENABLED)
function ErrorHandler.ShowError(player, errorType, ...)
	local args = {...}

	if not ERROR_TYPES[errorType] then
		warn("Unknown error type:", errorType)
		return
	end

	local errorData = ERROR_TYPES[errorType]
	local errorText = errorData.text

	-- Format text with arguments
	if #args > 0 then
		errorText = string.format(errorText, unpack(args))
	end

	-- Fire to client
	local remoteEvent = ReplicatedStorage:FindFirstChild("ShowErrorRemote")
	if not remoteEvent then
		remoteEvent = Instance.new("RemoteEvent")
		remoteEvent.Name = "ShowErrorRemote"
		remoteEvent.Parent = ReplicatedStorage
	end

	local isPersistent = errorData.persistent or false
	local customDuration = errorData.duration or nil
	local babyName = nil

	-- Extract baby name for special formatting
	if errorData.color == "white_with_red_name" and #args > 0 then
		babyName = args[1]
	end

	remoteEvent:FireClient(player, errorText, errorData.color, errorData.sound, isPersistent, false, customDuration, babyName)
end

-- CLIENT-SIDE: Display error function
function ErrorHandler.GetDisplayFunction()
	return function(errorText, errorColor, soundName, isPersistent, clearPersistent, customDuration, babyName)
		local player = Players.LocalPlayer

		-- Handle clear persistent request
		if clearPersistent then
			if persistentErrors[player.UserId] then
				if persistentErrors[player.UserId].rainbowConnection then
					persistentErrors[player.UserId].rainbowConnection:Disconnect()
				end
				persistentErrors[player.UserId] = nil
			end

			local playerGui = player:WaitForChild("PlayerGui")
			local mainGui = playerGui:FindFirstChild("MainGui")
			if mainGui then
				local errorGui = mainGui:FindFirstChild("ErrorGui")
				if errorGui then
					errorGui.Visible = false
				end
			end
			return
		end

		-- Use existing GUI structure
		local playerGui = player:WaitForChild("PlayerGui")
		local mainGui = playerGui:FindFirstChild("MainGui")

		if not mainGui then
			warn("MainGui not found in PlayerGui - make sure it exists!")
			return
		end

		local errorGui = mainGui:FindFirstChild("ErrorGui")
		if not errorGui then
			warn("ErrorGui not found in MainGui - make sure it exists!")
			return
		end

		local errorTextLabel = errorGui:FindFirstChild("ErrorText")
		if not errorTextLabel then
			warn("ErrorText not found in ErrorGui - make sure it exists!")
			return
		end

		-- Clear any existing persistent error
		if persistentErrors[player.UserId] then
			if persistentErrors[player.UserId].rainbowConnection then
				persistentErrors[player.UserId].rainbowConnection:Disconnect()
			end
			persistentErrors[player.UserId] = nil
		end

		-- Set text and color
		local rainbowConnection = nil

		if errorColor == "rainbow" then
			errorTextLabel.RichText = false
			errorTextLabel.Text = errorText
			rainbowConnection = createRainbowEffect(errorTextLabel)
		elseif errorColor == "white_with_red_name" and babyName then
			setWhiteTextWithRedName(errorTextLabel, errorText, babyName)
		else
			errorTextLabel.RichText = false
			errorTextLabel.Text = errorText
			errorTextLabel.TextColor3 = errorColor
		end

		-- Store persistent error data if needed
		if isPersistent then
			persistentErrors[player.UserId] = {
				rainbowConnection = rainbowConnection,
				errorGui = errorGui,
				errorText = errorText,
				errorColor = errorColor,
				babyName = babyName
			}
		end

		-- Play sound locally
		if soundName then
			local soundsFolder = ReplicatedStorage:WaitForChild("Sounds")
			local sound = soundsFolder:FindFirstChild(soundName)
			if sound and sound:IsA("Sound") then
				local soundClone = sound:Clone()
				soundClone.Parent = game.Workspace.CurrentCamera
				soundClone:Play()

				soundClone.Ended:Connect(function()
					soundClone:Destroy()
				end)

				task.delay(10, function()
					if soundClone and soundClone.Parent then
						soundClone:Destroy()
					end
				end)
			end
		end

		-- Store original position
		local originalPosition = errorGui.Position
		local startPosition = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset, 1.2, originalPosition.Y.Offset)

		-- Set to start position
		errorGui.Position = startPosition
		errorGui.Visible = true

		-- Create smooth tween with bounce
		local tweenInfo = TweenInfo.new(
			TWEEN_DURATION,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.Out,
			0,
			false,
			0
		)

		local tween = TweenService:Create(errorGui, tweenInfo, {
			Position = originalPosition
		})

		tween:Play()

		-- Hide after duration if not persistent
		if not isPersistent then
			local displayTime = customDuration or DISPLAY_DURATION

			task.delay(displayTime, function()
				if errorGui.Visible and errorTextLabel.Text == errorText then
					if rainbowConnection then
						rainbowConnection:Disconnect()
					end

					-- Animate UP then DOWN
					local upPosition = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset, originalPosition.Y.Scale - 0.05, originalPosition.Y.Offset)
					local downPosition = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset, 1.2, originalPosition.Y.Offset)

					local upTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
					local upTween = TweenService:Create(errorGui, upTweenInfo, {
						Position = upPosition
					})

					upTween:Play()
					upTween.Completed:Connect(function()
						local downTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
						local downTween = TweenService:Create(errorGui, downTweenInfo, {
							Position = downPosition
						})

						downTween:Play()
						downTween.Completed:Connect(function()
							if errorTextLabel.Text == errorText then
								errorGui.Visible = false
								errorGui.Position = originalPosition
							end
						end)
					end)
				end
			end)
		end
	end
end

-- UTILITY: Clear persistent message
function ErrorHandler.ClearPersistentMessage(player)
	local remoteEvent = ReplicatedStorage:FindFirstChild("ShowErrorRemote")
	if not remoteEvent then
		remoteEvent = Instance.new("RemoteEvent")
		remoteEvent.Name = "ShowErrorRemote"
		remoteEvent.Parent = ReplicatedStorage
	end

	remoteEvent:FireClient(player, "", Color3.new(1,1,1), "", false, true, nil, nil)
end

-- UTILITY: Get error types
function ErrorHandler.GetErrorTypes()
	return ERROR_TYPES
end

-- UTILITY: Add custom error type
function ErrorHandler.AddErrorType(errorName, errorData)
	ERROR_TYPES[errorName] = errorData
end

-- Helper function to show baby count status
function ErrorHandler.ShowBabyCountStatus(player, currentCount, maxCount)
	local availableSlots = maxCount - currentCount
	ErrorHandler.ShowError(player, "BABY_COUNT_STATUS", currentCount, maxCount, availableSlots)
end

-- Validation functions (that can still show errors)
function ErrorHandler.ValidateAndShowError(player, validationType, ...)
	local args = {...}

	if validationType == "money" then
		local cost = args[1]
		local leaderstats = player:FindFirstChild("leaderstats")
		if not leaderstats then return false end
		local coins = leaderstats:FindFirstChild("Coins")
		if not coins or coins.Value < cost then
			local needed = cost - (coins and coins.Value or 0)
			ErrorHandler.ShowError(player, "NO_MONEY", tostring(needed))
			return false
		end
		return true

	elseif validationType == "baby_space" then
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
			ErrorHandler.ShowError(player, "TOO_MANY_BABIES")
			return false
		end
		return true

	elseif validationType == "carrying" then
		if not player.Character then return true end
		local hrp = player.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then return true end

		for _, model in pairs(game.Workspace:GetChildren()) do
			if model:IsA("Model") and model.Name:find("_Carried") then
				for _, part in pairs(model:GetDescendants()) do
					if part:IsA("WeldConstraint") then
						if part.Part0 == hrp or part.Part1 == hrp then
							ErrorHandler.ShowError(player, "ALREADY_CARRYING")
							return false
						end
					end
				end
			end
		end
		return true
	end

	return true
end

return ErrorHandler
