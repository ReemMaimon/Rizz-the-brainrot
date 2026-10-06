-- OPTIMIZED SHOP LOCALSCRIPT - REBIRTH 0-10 DISTRIBUTION (FIXED TO USE MODULE)
-- Place this LocalScript inside the shop frame

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Get services and modules
local ItemsData = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("ItemsData"))
local Module3D = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("Module3D"))

-- Wait a moment for modules to fully load
task.wait(0.1)

-- Wait for remote events
local remotesFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local purchaseItemRemote = remotesFolder:WaitForChild("PurchaseItem")
local getPlayerDataRemote = remotesFolder:WaitForChild("GetPlayerData")

-- Get sounds with error handling
local sounds = ReplicatedStorage:FindFirstChild("Sounds")

-- Get shop frame structure
local shopFrame = script.Parent
local contentFrame = shopFrame:FindFirstChild("Content") or shopFrame:FindFirstChild("ScrollingFrame")
local itemsFrame = contentFrame:FindFirstChild("Items")
local template = itemsFrame:FindFirstChild("Template")

-- Player data cache
local playerData = {
	coins = 0,
	rebirth = 0,
	ownedTools = {}
}

-- UI State Management
local isUpdating = false
local purchaseCooldowns = {}
local lastUpdateTime = 0
local UPDATE_COOLDOWN = 0.5

-- Optimized button colors
local BUTTON_COLORS = {
	DEFAULT = Color3.fromRGB(59, 220, 0),
	HOVER = Color3.fromRGB(79, 240, 20),
	PRESS = Color3.fromRGB(42, 149, 0),
	OWNED = Color3.fromRGB(100, 255, 100),
	CANNOT_AFFORD = Color3.fromRGB(221, 0, 4),
	LOCKED = Color3.fromRGB(100, 100, 100)
}

-- Cache for UI elements
local uiCache = {}
local buttonUpdateFunctions = {}

-- Function to check if tool is unlocked (USES MODULE)
local function isToolUnlocked(toolName)
	local requiredRebirth = ItemsData:GetToolRebirthRequirement(toolName)
	return tonumber(playerData.rebirth) >= tonumber(requiredRebirth)  -- ENSURE NUMBERS
end

-- Optimized sound playing
local function playSound(soundName)
	if sounds then
		local sound = sounds:FindFirstChild(soundName)
		if sound and sound.Play then
			sound:Play()
		end
	end
end

-- Safe tween function with error handling
local function safeTween(object, tweenInfo, properties)
	if not object or not object.Parent then return end

	local success, tween = pcall(TweenService.Create, TweenService, object, tweenInfo, properties)
	if success then
		tween:Play()
		return tween
	end
end

-- Optimized player data update
local function updatePlayerData()
	local currentTime = tick()
	if isUpdating or currentTime - lastUpdateTime < UPDATE_COOLDOWN then 
		return false 
	end

	lastUpdateTime = currentTime
	isUpdating = true

	local success, data = pcall(function()
		return getPlayerDataRemote:InvokeServer()
	end)

	if success and data then
		-- CONVERT TO NUMBERS TO PREVENT STRING COMPARISON ERRORS
		local newCoins = tonumber(data.money) or 0
		local newRebirth = tonumber(data.rebirth) or 0

		local hasChanged = playerData.coins ~= newCoins or playerData.rebirth ~= newRebirth

		playerData.coins = newCoins
		playerData.rebirth = newRebirth
		playerData.ownedTools = data.ownedTools or {}

		-- Update money display
		local moneyLabel = shopFrame:FindFirstChild("MoneyLabel")
		if moneyLabel then
			local success2, formattedCoins = pcall(function()
				return ItemsData:FormatCurrency(playerData.coins)
			end)
			if success2 then
				moneyLabel.Text = formattedCoins
			else
				moneyLabel.Text = tostring(playerData.coins) .. " Coins"
			end
		end

		isUpdating = false
		return hasChanged
	else
		warn("Failed to get player data: " .. tostring(data))
	end

	isUpdating = false
	return false
end

-- Optimized viewport creation
local function createViewportFrame(parent, toolName)
	local viewportFrame = parent:FindFirstChild("ViewportFrame")
	if not viewportFrame then return end

	-- Clear existing content efficiently
	for _, child in ipairs(viewportFrame:GetChildren()) do
		if child.ClassName == "Model" or child.ClassName == "Camera" or child.Name:find("Model3D") then
			child:Destroy()
		end
	end

	local toolsModels = ReplicatedStorage:FindFirstChild("ToolsModels")
	if not toolsModels then return end

	local foundModel = toolsModels:FindFirstChild(toolName)
	if not foundModel then return end

	local success = pcall(function()
		local toolModel = foundModel:Clone()
		local model3D = Module3D:Attach3D(viewportFrame, toolModel)
		model3D.Visible = true
		model3D:SetCFrame(CFrame.Angles(math.rad(-15), math.rad(30), 0))
		model3D:SetDepthMultiplier(1.2)
	end)
end

-- Optimized locked overlay (USES MODULE)
local function createLockedOverlay(itemFrame, toolName)
	local toolUnlocked = isToolUnlocked(toolName)
	local lockedFrame = itemFrame:FindFirstChild("Locked")

	if not toolUnlocked then
		if not lockedFrame then
			lockedFrame = Instance.new("Frame")
			lockedFrame.Name = "Locked"
			lockedFrame.Size = UDim2.new(1, 0, 1, 0)
			lockedFrame.Position = UDim2.new(0, 0, 0, 0)
			lockedFrame.BackgroundColor3 = Color3.new(0, 0, 0)
			lockedFrame.BackgroundTransparency = 0.6
			lockedFrame.BorderSizePixel = 0
			lockedFrame.ZIndex = 10
			lockedFrame.Parent = itemFrame

			local lockText = Instance.new("TextLabel")
			lockText.Name = "Txt"  -- CHANGED FROM "LockText" TO "Txt" FOR CONSISTENCY
			lockText.Size = UDim2.new(0.9, 0, 0.3, 0)
			lockText.Position = UDim2.new(0.05, 0, 0.35, 0)
			lockText.BackgroundTransparency = 1
			lockText.TextColor3 = Color3.new(1, 1, 1)
			lockText.TextScaled = true
			lockText.Font = Enum.Font.GothamBold
			lockText.TextStrokeTransparency = 0
			lockText.TextStrokeColor3 = Color3.new(0, 0, 0)
			lockText.ZIndex = 11
			lockText.Parent = lockedFrame
		end

		-- USE MODULE TO GET REBIRTH REQUIREMENT
		local requiredRebirth = ItemsData:GetToolRebirthRequirement(toolName)

		-- FIX: Look for both "Txt" AND "LockText" to handle any existing inconsistency
		local lockText = lockedFrame:FindFirstChild("Txt") or lockedFrame:FindFirstChild("LockText")
		if lockText then
			lockText.Text = "LOCKED - REBIRTH " .. requiredRebirth
		end
		lockedFrame.Visible = true
	else
		if lockedFrame then
			lockedFrame.Visible = false
		end
	end
end

-- Optimized layout order calculation (USES MODULE)
local function getLayoutOrder(item)
	local rebirthRequirement = tonumber(ItemsData:GetToolRebirthRequirement(item.toolName)) or 0
	local itemPrice = tonumber(item.price) or 0
	return (rebirthRequirement * 10000) + (itemPrice / 1000000)
end

-- Optimized sorting function (USES MODULE)
local function getSortedItemsByRebirth()
	return ItemsData:GetItemsSortedByRebirth()
end

-- COMPLETELY FIXED button setup
local function setupBuyButton(buyButton, item)
	local uiScale = buyButton:FindFirstChild("UIScale")
	local priceLabel = buyButton:FindFirstChild("Price")

	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Scale = 1
		uiScale.Parent = buyButton
	end

	-- Button state management
	local buttonState = {
		isHovered = false,
		isPressed = false,
		baseColor = BUTTON_COLORS.DEFAULT,
		isActive = true
	}

	-- FIXED button appearance update
	local function updateButtonAppearance()
		-- ENSURE NUMBERS FOR COMPARISON
		local playerCoins = tonumber(playerData.coins) or 0
		local itemPrice = tonumber(item.price) or 0
		local canAfford = playerCoins >= itemPrice

		local isOwned = table.find(playerData.ownedTools, item.toolName) ~= nil
		local toolUnlocked = isToolUnlocked(item.toolName)

		-- Always make buttons active unless owned or locked
		buttonState.isActive = true
		buyButton.Active = true

		if isOwned then
			buttonState.baseColor = BUTTON_COLORS.OWNED
			buttonState.isActive = false
			buyButton.Active = false
			if priceLabel then priceLabel.Text = "OWNED" end
		elseif not toolUnlocked then
			buttonState.baseColor = BUTTON_COLORS.LOCKED
			buttonState.isActive = false
			buyButton.Active = false
			if priceLabel then priceLabel.Text = "LOCKED" end
		elseif not canAfford then
			-- CAN'T AFFORD - RED BUT STILL CLICKABLE FOR ERROR FEEDBACK
			buttonState.baseColor = BUTTON_COLORS.CANNOT_AFFORD
			if priceLabel then 
				local success, formattedPrice = pcall(function()
					return ItemsData:FormatCurrency(item.price)
				end)
				if success then
					priceLabel.Text = formattedPrice
				else
					priceLabel.Text = "$" .. tostring(item.price)
				end
			end
		else
			-- CAN AFFORD - GREEN AND CLICKABLE
			buttonState.baseColor = BUTTON_COLORS.DEFAULT
			if priceLabel then 
				local success, formattedPrice = pcall(function()
					return ItemsData:FormatCurrency(item.price)
				end)
				if success then
					priceLabel.Text = formattedPrice
				else
					priceLabel.Text = "$" .. tostring(item.price)
				end
			end
		end

		-- Apply visual state
		if buttonState.isPressed and buttonState.isActive then
			-- RED BUTTONS STAY RED EVEN WHEN PRESSED
			if not canAfford and toolUnlocked and not isOwned then
				buyButton.BackgroundColor3 = BUTTON_COLORS.CANNOT_AFFORD
			else
				buyButton.BackgroundColor3 = BUTTON_COLORS.PRESS
			end
		elseif buttonState.isHovered and buttonState.isActive then
			-- RED BUTTONS STAY RED EVEN WHEN HOVERED
			if not canAfford and toolUnlocked and not isOwned then
				buyButton.BackgroundColor3 = BUTTON_COLORS.CANNOT_AFFORD
			else
				buyButton.BackgroundColor3 = BUTTON_COLORS.HOVER
			end
		else
			buyButton.BackgroundColor3 = buttonState.baseColor
		end
	end

	-- Store update function
	buttonUpdateFunctions[item.name] = updateButtonAppearance

	-- FIXED purchase handler
	local function handlePurchase()
		local currentTime = tick()
		local cooldownKey = item.name

		if purchaseCooldowns[cooldownKey] and currentTime - purchaseCooldowns[cooldownKey] < 1 then
			return
		end
		purchaseCooldowns[cooldownKey] = currentTime

		-- ENSURE NUMBERS FOR COMPARISON
		local playerCoins = tonumber(playerData.coins) or 0
		local itemPrice = tonumber(item.price) or 0
		local canAfford = playerCoins >= itemPrice

		local isOwned = table.find(playerData.ownedTools, item.toolName) ~= nil
		local toolUnlocked = isToolUnlocked(item.toolName)

		-- Don't do anything if owned or locked
		if isOwned or not toolUnlocked then return end

		if not canAfford then
			-- PLAY ERROR SOUND AND SHAKE - EXACTLY WHAT YOU WANTED
			task.spawn(function()
				local originalPos = buyButton.Position
				safeTween(buyButton, TweenInfo.new(0.05), {Position = originalPos + UDim2.fromOffset(5, 0)})
				task.wait(0.05)
				safeTween(buyButton, TweenInfo.new(0.05), {Position = originalPos - UDim2.fromOffset(5, 0)})
				task.wait(0.05)
				safeTween(buyButton, TweenInfo.new(0.05), {Position = originalPos})
			end)
			playSound("Error")
			return
		end

		-- Can afford - do the purchase
		local success, result = pcall(function()
			purchaseItemRemote:FireServer(item.name)
		end)

		if not success then
			warn("Error sending purchase request: " .. tostring(result))
		end
	end

	-- FIXED event connections
	buyButton.MouseEnter:Connect(function()
		buttonState.isHovered = true
		if buttonState.isActive then
			playSound("ButtonHover")
			safeTween(uiScale, TweenInfo.new(0.15), {Scale = 1.05})
		end
		updateButtonAppearance()
	end)

	buyButton.MouseLeave:Connect(function()
		buttonState.isHovered = false
		buttonState.isPressed = false

		safeTween(uiScale, TweenInfo.new(0.15), {Scale = 1})
		updateButtonAppearance()
	end)

	buyButton.MouseButton1Down:Connect(function()
		if buttonState.isActive then
			buttonState.isPressed = true
			playSound("ButtonPress")
			safeTween(uiScale, TweenInfo.new(0.1), {Scale = 0.95})
			updateButtonAppearance()
		end
	end)

	buyButton.MouseButton1Up:Connect(function()
		if buttonState.isPressed then
			buttonState.isPressed = false
			local targetScale = buttonState.isHovered and 1.05 or 1
			safeTween(uiScale, TweenInfo.new(0.1), {Scale = targetScale})
			updateButtonAppearance()
		end
	end)

	-- ALWAYS ALLOW CLICKING FOR ERROR FEEDBACK
	buyButton.Activated:Connect(function()
		handlePurchase()
	end)

	-- Touch support
	if UserInputService.TouchEnabled then
		buyButton.TouchTap:Connect(function()
			handlePurchase()
		end)
	end

	-- Initial update
	updateButtonAppearance()
end

-- Optimized item template creation
local function createItemTemplate(item, parent)
	if not template then return end

	local newTemplate = template:Clone()
	newTemplate.Name = item.name
	newTemplate.Visible = true
	newTemplate.LayoutOrder = getLayoutOrder(item)
	newTemplate.Parent = parent

	-- Update item information efficiently
	local itemInformation = newTemplate:FindFirstChild("ItemInformation")
	if itemInformation then
		local itemName = itemInformation:FindFirstChild("ItemName")
		local itemDescription = itemInformation:FindFirstChild("ItemDescription")

		if itemName then itemName.Text = item.name end
		if itemDescription then itemDescription.Text = item.description end
	end

	createViewportFrame(newTemplate, item.toolName)

	local buyButton = newTemplate:FindFirstChild("Buy")
	if buyButton then
		setupBuyButton(buyButton, item)
		uiCache[item.name] = {frame = newTemplate, button = buyButton}
	end

	createLockedOverlay(newTemplate, item.toolName)

	return newTemplate
end

-- Optimized shop population
local function populateShop()
	if isUpdating then return end
	isUpdating = true

	-- Clear existing items efficiently
	for _, child in ipairs(itemsFrame:GetChildren()) do
		if child ~= template and child.ClassName == "Frame" then
			child:Destroy()
		end
	end

	uiCache = {}
	buttonUpdateFunctions = {}
	local sortedItems = getSortedItemsByRebirth()

	for _, item in ipairs(sortedItems) do
		createItemTemplate(item, itemsFrame)
	end

	if template then template.Visible = false end

	-- Setup or get existing UIListLayout
	local listLayout = itemsFrame:FindFirstChild("UIListLayout")
	if not listLayout then
		listLayout = Instance.new("UIListLayout")
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout.Padding = UDim.new(0, 10)
		listLayout.FillDirection = Enum.FillDirection.Vertical
		listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		listLayout.Parent = itemsFrame
	end

	-- Auto-resize canvas
	if contentFrame.ClassName == "ScrollingFrame" then
		local function updateCanvasSize()
			contentFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
		end

		listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize)
		updateCanvasSize()
	end

	isUpdating = false
end

-- Optimized button updates
local function updateAllBuyButtons()
	for itemName, updateFunc in pairs(buttonUpdateFunctions) do
		if type(updateFunc) == "function" then
			updateFunc()
		end

		local cached = uiCache[itemName]
		if cached and cached.frame then
			local itemData = ItemsData:GetItemByName(itemName)
			if itemData then
				createLockedOverlay(cached.frame, itemData.toolName)
			end
		end
	end
end

-- Purchase response handler
purchaseItemRemote.OnClientEvent:Connect(function(result)
	if result.success then
		playSound("Collecting_Coins")
		task.spawn(function()
			task.wait(0.1)
			if updatePlayerData() then
				updateAllBuyButtons()
			end
		end)
	end
end)

-- Optimized stats change handler
local function onStatsChanged()
	if updatePlayerData() then
		updateAllBuyButtons()
	end
end

-- Connect to leaderstats changes efficiently
local function connectToStats(leaderstats)
	for _, stat in ipairs(leaderstats:GetChildren()) do
		if stat.Name == "Coins" or stat.Name == "Rebirth" then
			stat.Changed:Connect(onStatsChanged)
		end
	end

	leaderstats.ChildAdded:Connect(function(stat)
		if stat.Name == "Coins" or stat.Name == "Rebirth" then
			stat.Changed:Connect(onStatsChanged)
		end
	end)
end

-- Player connection handler
player.ChildAdded:Connect(function(child)
	if child.Name == "leaderstats" then
		connectToStats(child)
	end
end)

if player:FindFirstChild("leaderstats") then
	connectToStats(player.leaderstats)
end

-- Initialize shop with error handling
task.spawn(function()
	task.wait(2)

	local success = updatePlayerData()
	if success then
		populateShop()

		-- Reduced frequency updates for performance
		task.spawn(function()
			while true do
				task.wait(15)
				if updatePlayerData() then
					updateAllBuyButtons()
				end
			end
		end)
	end
end)