-- Local Script for Boost Multiplier Button - Clean Version
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

-- ======== CONFIGURATION ========
local CONFIG = {
	-- Product mapping - current multiplier to next product ID and price
	PRODUCTS = {
		[1] = {id = 3703896099, price = 99, toLevel = 2},  
		[3] = {id = 3704164296, price = 5, toLevel = 4}, 
		[7] = {id = 3704165596, price = 9, toLevel = 8}, 
	},

	-- Text formatting
	TEXT = {
		BUTTON_FORMAT = "{current}x > <font color=\"rgb(255,255,0)\">{next}x</font>",
		MAX_FORMAT = "<font color=\"rgb(0,255,0)\">MAX {current}x</font>"
	},

	-- Animation settings
	ANIMATION = {
		TEXT_GROW_FACTOR = 1.6,
		BUTTON_GROW_FACTOR = 1.3
	}
}

-- Find UI elements
local function findPriceLabel()
	-- Price is at the Frame level (script.Parent.Parent.Price)
	if script.Parent.Parent and script.Parent.Parent:FindFirstChild("Price") then
		return script.Parent.Parent.Price
	end

	-- Fallback: search in descendants
	for _, obj in pairs(script.Parent.Parent:GetDescendants()) do
		if obj:IsA("TextLabel") and (obj.Name == "Price" or obj.Name:match("Price")) then
			return obj
		end
	end

	return nil
end

local player = Players.LocalPlayer
local button = script.Parent -- This should be Buy or Buy.ServerLuck
local boostAmount = button.Parent:FindFirstChild("BoostAmount") -- Frame.BoostAmount
local priceLabel = findPriceLabel() -- Frame.Price

-- Function to get the current product ID based on multiplier
local function getCurrentProductInfo()
	local boostLevel = 1 -- Default multiplier is 1

	-- Look in GameData folder for boost level
	if player and player:FindFirstChild("GameData") and player.GameData:FindFirstChild("BoostLevel") then
		boostLevel = player.GameData.BoostLevel.Value
	end

	-- Get product info for current multiplier
	if CONFIG.PRODUCTS[boostLevel] then
		return CONFIG.PRODUCTS[boostLevel].id, CONFIG.PRODUCTS[boostLevel].price, boostLevel, CONFIG.PRODUCTS[boostLevel].toLevel
	else
		-- Find the closest lower tier
		local closestLevel = 1
		for level, _ in pairs(CONFIG.PRODUCTS) do
			if level <= boostLevel and level > closestLevel then
				closestLevel = level
			end
		end

		if CONFIG.PRODUCTS[closestLevel] then
			return CONFIG.PRODUCTS[closestLevel].id, CONFIG.PRODUCTS[closestLevel].price, boostLevel, CONFIG.PRODUCTS[closestLevel].toLevel
		else
			return nil, nil, boostLevel, nil -- Max level reached
		end
	end
end

-- Sound loading from Assets.Sounds
local function getSound(name)
	local sounds = ReplicatedStorage:FindFirstChild("Assets") 
		and ReplicatedStorage.Assets:FindFirstChild("Sounds")

	if not sounds then
		-- Fallback to ReplicatedStorage.Sounds
		sounds = ReplicatedStorage:FindFirstChild("Sounds")
	end

	if sounds then
		return sounds:FindFirstChild(name)
	end

	return nil
end

-- Sound references
local SOUNDS = {
	HOVER = getSound("ButtonHover"),
	PRESS = getSound("ButtonPress"),
	SUCCESS = getSound("MilestoneSound") -- For successful purchase
}

-- Play sound function
local function playSound(soundName)
	local soundObj = SOUNDS[soundName]
	if not soundObj then
		return
	end

	local sound = soundObj:Clone()
	sound.Parent = button
	sound:Play()
	game.Debris:AddItem(sound, sound.TimeLength)
end

-- Create Boost RemoteEvent if it doesn't exist
local boostEvent = ReplicatedStorage:FindFirstChild("BoostEvent")
if not boostEvent then
	boostEvent = Instance.new("RemoteEvent")
	boostEvent.Name = "BoostEvent"
	boostEvent.Parent = ReplicatedStorage
end

-- Create or get UIGradient and UIScale
local uiGradient = button:FindFirstChild("UIGradient")
if not uiGradient then
	uiGradient = Instance.new("UIGradient")
	uiGradient.Parent = button
end

local uiScale = button:FindFirstChild("UIScale")
if not uiScale then
	uiScale = Instance.new("UIScale")
	uiScale.Scale = 1
	uiScale.Parent = button
end

-- Gradient colors
local GRADIENTS = {
	DEFAULT = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(38, 230, 38)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(208, 255, 0))
	}),
	HOVER = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(58, 250, 58)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(228, 255, 20))
	}),
	DOWN = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(251, 255, 24)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 166, 94))
	})
}

-- Apply default gradient
uiGradient.Color = GRADIENTS.DEFAULT

-- Text animation for level up
local function playTextAnimation()
	if not boostAmount then return end

	local originalPosition = boostAmount.Position
	local originalTextSize = boostAmount.TextSize

	-- Move upward with growth
	local upTween = TweenService:Create(boostAmount, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset, 
			originalPosition.Y.Scale - 0.3, originalPosition.Y.Offset),
		TextSize = originalTextSize * CONFIG.ANIMATION.TEXT_GROW_FACTOR,
		TextTransparency = 0
	})

	upTween:Play()

	upTween.Completed:Connect(function()
		-- Bounce down
		local bounceTween = TweenService:Create(boostAmount, TweenInfo.new(0.25, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
			Position = originalPosition,
			TextSize = originalTextSize * 1.3
		})

		bounceTween:Play()

		bounceTween.Completed:Connect(function()
			-- Return to normal
			TweenService:Create(boostAmount, TweenInfo.new(0.15), {
				TextSize = originalTextSize
			}):Play()
		end)
	end)
end

-- Purchase animation effects
local function playPurchaseAnimation()
	-- Play success sound immediately
	if SOUNDS.SUCCESS then
		local successSound = SOUNDS.SUCCESS:Clone()
		successSound.Parent = button
		successSound:Play()
		game.Debris:AddItem(successSound, successSound.TimeLength)
	end

	-- Create particle effect
	local particleEmitter = button:FindFirstChild("PurchaseParticles")
	if not particleEmitter then
		particleEmitter = Instance.new("ParticleEmitter")
		particleEmitter.Name = "PurchaseParticles"
		particleEmitter.Texture = "rbxassetid://6337354639"
		particleEmitter.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 120)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 200, 50)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 50))
		})
		particleEmitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(0.5, 0.5),
			NumberSequenceKeypoint.new(1, 0.1)
		})
		particleEmitter.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.8, 0.5),
			NumberSequenceKeypoint.new(1, 1)
		})
		particleEmitter.Speed = NumberRange.new(5, 10)
		particleEmitter.Lifetime = NumberRange.new(0.5, 1)
		particleEmitter.Rate = 0
		particleEmitter.SpreadAngle = Vector2.new(180, 180)
		particleEmitter.Parent = button
	end

	-- Flash effect
	local flashFrame = Instance.new("Frame")
	flashFrame.Size = UDim2.new(20, 0, 20, 0)
	flashFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	flashFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	flashFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	flashFrame.BackgroundTransparency = 0.2
	flashFrame.ZIndex = 10
	flashFrame.Parent = button.Parent

	-- Button bounce
	local originalScale = uiScale.Scale
	TweenService:Create(uiScale, TweenInfo.new(0.05), {Scale = originalScale * CONFIG.ANIMATION.BUTTON_GROW_FACTOR}):Play()
	particleEmitter:Emit(50)

	-- Flash fade
	game.Debris:AddItem(flashFrame, 0.3)
	TweenService:Create(flashFrame, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()

	-- Return to normal size
	task.spawn(function()
		task.wait(0.05)
		TweenService:Create(uiScale, TweenInfo.new(0.2), {Scale = originalScale}):Play()
	end)

	-- Play text animation
	playTextAnimation()
end

-- Update display text and price
local function updateDisplays()
	if not boostAmount then
		return
	end

	local boostLevel = 1

	-- Look in GameData folder
	if player and player:FindFirstChild("GameData") and player.GameData:FindFirstChild("BoostLevel") then
		boostLevel = player.GameData.BoostLevel.Value
	end

	local productId, price, currentLevel, nextLevel = getCurrentProductInfo()

	if nextLevel then
		-- Show current → next format
		local buttonText = CONFIG.TEXT.BUTTON_FORMAT
			:gsub("{current}", currentLevel)
			:gsub("{next}", nextLevel)
		boostAmount.Text = buttonText
		boostAmount.RichText = true

		-- Update price
		if priceLabel and price then
			priceLabel.Text = "" .. tostring(price)
			priceLabel.Visible = true
		end
	else
		-- Max level reached
		local buttonText = CONFIG.TEXT.MAX_FORMAT:gsub("{current}", currentLevel)
		boostAmount.Text = buttonText
		boostAmount.RichText = true

		if priceLabel then
			priceLabel.Text = "MAX"
			priceLabel.Visible = true
		end
	end
end

-- Button effects
local function setupButtonEffects()
	-- Hover effects
	button.MouseEnter:Connect(function()
		playSound("HOVER")
		TweenService:Create(uiScale, TweenInfo.new(0.18), {Scale = 1.05}):Play()
		uiGradient.Color = GRADIENTS.HOVER
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(uiScale, TweenInfo.new(0.18), {Scale = 1}):Play()
		uiGradient.Color = GRADIENTS.DEFAULT
	end)

	button.MouseButton1Down:Connect(function()
		playSound("PRESS")
		TweenService:Create(uiScale, TweenInfo.new(0.18), {Scale = 0.95}):Play()
		uiGradient.Color = GRADIENTS.DOWN
	end)

	button.MouseButton1Up:Connect(function()
		TweenService:Create(uiScale, TweenInfo.new(0.18), {Scale = 1.05}):Play()
		uiGradient.Color = GRADIENTS.HOVER
	end)

	-- Mobile support
	button.TouchTap:Connect(function()
		playSound("PRESS")
		TweenService:Create(uiScale, TweenInfo.new(0.05), {Scale = 0.95}):Play()
		task.spawn(function()
			task.wait(0.1)
			uiGradient.Color = GRADIENTS.DEFAULT
			TweenService:Create(uiScale, TweenInfo.new(0.18), {Scale = 1}):Play()
		end)
	end)
end

-- Event handler for server responses
local function setupEventHandler()
	if boostEvent then
		boostEvent.OnClientEvent:Connect(function(success, newLevel)
			if success then
				playPurchaseAnimation()
				updateDisplays()
			end
		end)
	end
end

-- Purchase button setup
local function setupPurchaseButton()
	button.MouseButton1Click:Connect(function()
		local productId, price, currentLevel, nextLevel = getCurrentProductInfo()

		if not productId then
			return
		end

		local success = pcall(function()
			MarketplaceService:PromptProductPurchase(player, productId)
		end)
	end)

	-- Mobile support
	button.TouchTap:Connect(function()
		local productId = getCurrentProductInfo()
		if productId then
			pcall(function()
				MarketplaceService:PromptProductPurchase(player, productId)
			end)
		end
	end)
end

-- Purchase completion handler
local function setupPurchaseHandler()
	MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, isPurchased)
		-- Check if this is one of our boost products
		local isBoostProduct = false
		for level, productInfo in pairs(CONFIG.PRODUCTS) do
			if productId == productInfo.id then
				isBoostProduct = true
				break
			end
		end

		if userId == player.UserId and isBoostProduct and isPurchased then
			-- Purchase successful, wait for server confirmation
		end
	end)
end

-- Listen for GameData changes
local function setupGameDataListeners()
	if player:FindFirstChild("GameData") then
		if player.GameData:FindFirstChild("BoostLevel") then
			player.GameData.BoostLevel:GetPropertyChangedSignal("Value"):Connect(function()
				updateDisplays()
			end)
		else
			player.GameData.ChildAdded:Connect(function(child)
				if child.Name == "BoostLevel" then
					child:GetPropertyChangedSignal("Value"):Connect(function()
						updateDisplays()
					end)
					updateDisplays()
				end
			end)
		end
	else
		player.ChildAdded:Connect(function(child)
			if child.Name == "GameData" then
				child.ChildAdded:Connect(function(grandchild)
					if grandchild.Name == "BoostLevel" then
						grandchild:GetPropertyChangedSignal("Value"):Connect(function()
							updateDisplays()
						end)
						updateDisplays()
					end
				end)
			end
		end)
	end
end

-- Initialize the button
local function initialize()
	setupButtonEffects()
	setupEventHandler()
	setupPurchaseButton()
	setupPurchaseHandler()
	setupGameDataListeners()
	updateDisplays()
end

-- Start initialization
task.spawn(function()
	task.wait(0.5)
	if player then
		initialize()
	else
		repeat task.wait(0.5) until player
		initialize()
	end
end)