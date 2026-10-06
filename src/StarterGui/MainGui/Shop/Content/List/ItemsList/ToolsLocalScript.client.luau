-- LocalScript - Tool Purchase UI Handler (Developer Products)
-- Place this in StarterPlayerScripts or in the UI frame

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

-- ======== CONFIGURATION ========
local TOOL_PRODUCTS = {
	["Blackhole Slap"] = {id = 3312807937, price = "29"},
	["Flying Carpet"] = {id = 3312808432, price = "9"},
	["Lazer Gun"] = {id = 3312809628, price = "49"},
	["Ban Hammer"] = {id = 3312810584, price = "99"}
}

local player = Players.LocalPlayer
local parentFrame = script.Parent -- ItemsList or similar

-- Sound loading
local function getSound(name)
	local sounds = ReplicatedStorage:FindFirstChild("Assets") 
		and ReplicatedStorage.Assets:FindFirstChild("Sounds")
	if not sounds then
		sounds = ReplicatedStorage:FindFirstChild("Sounds")
	end
	if sounds then
		return sounds:FindFirstChild(name)
	end
	return nil
end

local SOUNDS = {
	HOVER = getSound("ButtonHover"),
	PRESS = getSound("ButtonPress"),
	SUCCESS = getSound("MilestoneSound")
}

-- Play sound function
local function playSound(soundName)
	local soundObj = SOUNDS[soundName]
	if not soundObj then return end
	local sound = soundObj:Clone()
	sound.Parent = parentFrame
	sound.Volume = .5
	sound:Play()
	game.Debris:AddItem(sound, sound.TimeLength)
end

-- Wait for RemoteEvent to exist
local toolPurchaseEvent
repeat
	toolPurchaseEvent = ReplicatedStorage:FindFirstChild("ToolPurchaseEvent")
	if not toolPurchaseEvent then task.wait(0.1) end
until toolPurchaseEvent

-- Gradient colors (removed OWNED state)
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

-- Purchase animation
local function playPurchaseAnimation(button)
	if SOUNDS.SUCCESS then
		local successSound = SOUNDS.SUCCESS:Clone()
		successSound.Parent = button
		successSound:Play()
		game.Debris:AddItem(successSound, successSound.TimeLength)
	end

	-- Particle effect
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

	-- Button effects
	local uiScale = button:FindFirstChild("UIScale")
	if uiScale then
		local originalScale = uiScale.Scale
		TweenService:Create(uiScale, TweenInfo.new(0.05), {Scale = originalScale * 1.3}):Play()
		particleEmitter:Emit(50)

		task.spawn(function()
			task.wait(0.05)
			TweenService:Create(uiScale, TweenInfo.new(0.2), {Scale = originalScale}):Play()
		end)
	end

	game.Debris:AddItem(flashFrame, 0.3)
	TweenService:Create(flashFrame, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
end

-- Find buy button with multiple search methods
local function findBuyButton(toolFrame, toolName)
	-- Method 1: Direct child named "Buy"
	local buyButton = toolFrame:FindFirstChild("Buy")
	if buyButton then
		return buyButton
	end

	-- Method 2: Look for any GuiButton with "buy" in the name (case insensitive)
	for _, child in pairs(toolFrame:GetDescendants()) do
		if child:IsA("GuiButton") or child:IsA("TextButton") or child:IsA("ImageButton") then
			if string.lower(child.Name):find("buy") then
				return child
			end
		end
	end

	-- Method 3: Look for button with purchase-related text
	for _, child in pairs(toolFrame:GetDescendants()) do
		if child:IsA("TextButton") then
			local text = string.lower(child.Text or "")
			if text:find("buy") or text:find("purchase") or text:find("robux") then
				return child
			end
		end
	end

	-- Method 4: Look for ImageButton that might be the purchase button
	for _, child in pairs(toolFrame:GetDescendants()) do
		if child:IsA("ImageButton") then
			return child
		end
	end

	-- Method 5: Just get the first clickable button
	for _, child in pairs(toolFrame:GetDescendants()) do
		if child:IsA("GuiButton") or child:IsA("TextButton") or child:IsA("ImageButton") then
			return child
		end
	end

	return nil
end

-- Setup button for a tool
local function setupToolButton(toolFrame, toolName, toolData)
	-- Find the Buy button inside the tool frame
	local buyButton = findBuyButton(toolFrame, toolName)

	if not buyButton then
		warn("No Buy button found for " .. toolName)
		return
	end

	-- Create UI components
	local uiGradient = buyButton:FindFirstChild("UIGradient")
	if not uiGradient then
		uiGradient = Instance.new("UIGradient")
		uiGradient.Parent = buyButton
	end

	local uiScale = buyButton:FindFirstChild("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Scale = 1
		uiScale.Parent = buyButton
	end

	-- Set initial button state
	buyButton.Active = true
	uiGradient.Color = GRADIENTS.DEFAULT

	-- Button effects
	local function setupEffects()
		buyButton.MouseEnter:Connect(function()
			playSound("HOVER")
			TweenService:Create(uiScale, TweenInfo.new(0.18), {Scale = 1.05}):Play()
			uiGradient.Color = GRADIENTS.HOVER
		end)

		buyButton.MouseLeave:Connect(function()
			TweenService:Create(uiScale, TweenInfo.new(0.18), {Scale = 1}):Play()
			uiGradient.Color = GRADIENTS.DEFAULT
		end)

		buyButton.MouseButton1Down:Connect(function()
			playSound("PRESS")
			TweenService:Create(uiScale, TweenInfo.new(0.18), {Scale = 0.95}):Play()
			uiGradient.Color = GRADIENTS.DOWN
		end)

		buyButton.MouseButton1Up:Connect(function()
			TweenService:Create(uiScale, TweenInfo.new(0.18), {Scale = 1.05}):Play()
			uiGradient.Color = GRADIENTS.HOVER
		end)

		buyButton.MouseButton1Click:Connect(function()
			local productId = toolData.id
			if productId then
				pcall(function()
					-- Changed to PromptProductPurchase for developer products
					MarketplaceService:PromptProductPurchase(player, productId)
				end)
			end
		end)

		-- Mobile support
		buyButton.TouchTap:Connect(function()
			local productId = toolData.id
			if productId then
				pcall(function()
					MarketplaceService:PromptProductPurchase(player, productId)
				end)
			end
		end)
	end

	setupEffects()

	-- Store reference
	buyButton:SetAttribute("ToolName", toolName)
	buyButton:SetAttribute("SetupComplete", true)
end

-- Initialize all tool buttons
local function initializeAllTools()
	for toolName, toolData in pairs(TOOL_PRODUCTS) do
		local toolFrame = parentFrame:FindFirstChild(toolName)
		if toolFrame then
			setupToolButton(toolFrame, toolName, toolData)
		else
			-- Try case-insensitive search
			for _, child in pairs(parentFrame:GetChildren()) do
				if string.lower(child.Name) == string.lower(toolName) then
					setupToolButton(child, toolName, toolData)
					break
				end
			end
		end
	end
end

-- Handle purchase success from server (simplified - just plays animation)
toolPurchaseEvent.OnClientEvent:Connect(function(success, purchasedToolName)
	if success and purchasedToolName then
		local toolFrame = parentFrame:FindFirstChild(purchasedToolName)
		if toolFrame then
			local buyButton = findBuyButton(toolFrame, purchasedToolName)
			if buyButton then
				playPurchaseAnimation(buyButton)
			end
		end
	end
end)

-- Start initialization
task.spawn(function()
	task.wait(1) -- Wait for UI to load
	initializeAllTools()
end)