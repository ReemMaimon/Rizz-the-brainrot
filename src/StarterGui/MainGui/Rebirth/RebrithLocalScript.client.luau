-- OPTIMIZED REBIRTH LOCALSCRIPT - CLEAN VERSION
-- Place in StarterGui or StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Cache all UI elements at startup
local screenGui = playerGui:WaitForChild("MainGui")
local rebirthFrame = screenGui:WaitForChild("Rebirth")
local content = rebirthFrame:WaitForChild("Content")
local holder = content:WaitForChild("Holder")
local holderImage = holder:WaitForChild("HolderImage")
local barContainer = holderImage:WaitForChild("BarContainer")
local frame = barContainer:WaitForChild("Frame")
local bar = frame:WaitForChild("Bar")
local textLabel = barContainer:WaitForChild("TextLabel")
local rebirthButton = content:WaitForChild("Rebirth")
local rebirthButtonText = rebirthButton:WaitForChild("Txt")

local unlockable = content:WaitForChild("Unlockable")
local items = unlockable:WaitForChild("Items")
local template = items:WaitForChild("Template")

-- Shop elements (optional)
local coinsShop = screenGui:FindFirstChild("CoinsShop")
local shopContent = coinsShop and coinsShop:FindFirstChild("Content")
local shopItems = shopContent and shopContent:FindFirstChild("Items")

-- Cache remote events and modules with error handling
local rebirthRemote = ReplicatedStorage:WaitForChild("RebirthRemote")
local sounds = ReplicatedStorage:WaitForChild("Sounds")

-- Load modules with error handling
local RebirthData = nil
local ItemsData = nil
local Module3D = nil

pcall(function()
	RebirthData = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("RebirthData"))
end)

pcall(function()
	ItemsData = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("ItemsData"))
end)

pcall(function()
	Module3D = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("Module3D"))
end)

-- Wait for modules to load
task.wait(0.5)

-- Cache sounds
local buttonHover = sounds:WaitForChild("ButtonHover")
local buttonPress = sounds:WaitForChild("ButtonPress")
local buttonRelease = sounds:WaitForChild("ButtonRelease")
local codeRedeemed = sounds:WaitForChild("Code_Reedemed")
local errorSound = sounds:WaitForChild("Error")

-- Optimized rebirth requirements
local REBIRTH_REQUIREMENTS = {
	[0] = 100000, [1] = 3000000, [2] = 10000000, [3] = 25000000, [4] = 50000000,
	[5] = 100000000, [6] = 250000000, [7] = 500000000, [8] = 1000000000, [9] = 2500000000,
}

-- Optimized UI constants
local tweenInfo = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local defaultColor = Color3.fromRGB(255, 200, 0)
local hoverColor = Color3.fromRGB(255, 230, 37)
local pressColor = Color3.fromRGB(216, 169, 0)

-- State management
local itemFrames = {}
local model3DObjects = {}
local lastCoins = 0
local lastRebirth = 0
local isUpdating = false
local lastUpdateTime = 0
local UPDATE_COOLDOWN = 0.2

-- Optimized debounced update
local updateDebounce = false
local function debouncedUpdate()
	if updateDebounce then return end
	updateDebounce = true

	task.spawn(function()
		task.wait(0.1)
		updateRebirthProgress()
		updateShopItemLocks()
		updateDebounce = false
	end)
end

-- Optimized currency formatter with enhanced caching
local currencyCache = {}
local function formatCurrency(amount)
	amount = tonumber(amount) or 0

	if currencyCache[amount] then
		return currencyCache[amount]
	end

	local formatted
	if amount >= 1000000000000 then
		local val = amount / 1000000000000
		formatted = string.format(val >= 10 and "$%.0fT" or "$%.1fT", val)
	elseif amount >= 1000000000 then
		local val = amount / 1000000000
		formatted = string.format(val >= 10 and "$%.0fB" or "$%.1fB", val)
	elseif amount >= 1000000 then
		local val = amount / 1000000
		formatted = string.format(val >= 10 and "$%.0fM" or "$%.1fM", val)
	elseif amount >= 1000 then
		local val = amount / 1000
		formatted = string.format(val >= 10 and "$%.0fK" or "$%.1fK", val)
	else
		formatted = "$" .. tostring(math.floor(amount))
	end

	if #currencyCache > 100 then
		currencyCache = {}
	end
	currencyCache[amount] = formatted
	return formatted
end

-- Optimized shop item sorting with layout order calculation
local function sortShopItemsByRebirthOrder()
	if not shopItems or not ItemsData then return end

	local sortedTools = ItemsData:GetItemsSortedByRebirth()
	local layoutOrderMap = {}
	for index, toolData in ipairs(sortedTools) do
		layoutOrderMap[toolData.name] = (toolData.rebirth * 1000) + index
	end

	for _, child in ipairs(shopItems:GetChildren()) do
		if child.ClassName == "Frame" and child.Name ~= "Template" then
			local itemName = nil
			local itemInfo = child:FindFirstChild("ItemInformation")
			if itemInfo then
				local nameLabel = itemInfo:FindFirstChild("ItemName")
				if nameLabel then
					itemName = nameLabel.Text
				end
			end

			if not itemName then
				itemName = child.Name
			end

			local layoutOrder = layoutOrderMap[itemName] or 9999
			child.LayoutOrder = layoutOrder
		end
	end

	local listLayout = shopItems:FindFirstChild("UIListLayout")
	if not listLayout then
		listLayout = Instance.new("UIListLayout")
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout.Padding = UDim.new(0, 10)
		listLayout.FillDirection = Enum.FillDirection.Vertical
		listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		listLayout.Parent = shopItems
	end
end

-- Optimized clear function with memory management
local function clearItemDisplays()
	for i = #itemFrames, 1, -1 do
		local frame = itemFrames[i]
		if frame and frame.Parent then
			frame:Destroy()
		end
		itemFrames[i] = nil
	end

	for i = #model3DObjects, 1, -1 do
		local modelData = model3DObjects[i]
		if modelData and modelData.model then
			modelData.model:Destroy()
		end
		model3DObjects[i] = nil
	end
end

-- Optimized item display creation with better error handling
local function createItemDisplay(reward, index)
	local itemFrame = template:Clone()
	itemFrame.Name = "Item" .. index
	itemFrame.Visible = true
	itemFrame.Parent = items

	local itemName = itemFrame:FindFirstChild("ItemName")
	local itemValue = itemFrame:FindFirstChild("ItemValue")
	local viewportFrame = itemFrame:FindFirstChild("ViewportFrame")

	if itemName then itemName.Text = reward.name end
	if itemValue then itemValue.Text = reward.value end

	-- Handle 3D models
	if reward.type == "tool" and reward.showModel and viewportFrame then
		viewportFrame.Visible = true
		itemFrame.Image = ""

		task.spawn(function()
			local toolsModels = ReplicatedStorage:FindFirstChild("ToolsModels")
			if toolsModels then
				local toolModel = toolsModels:FindFirstChild(reward.toolName)
				if toolModel then
					local success, model3D = pcall(function()
						local clonedModel = toolModel:Clone()
						if Module3D then
							local model3D = Module3D:Attach3D(viewportFrame, clonedModel)
							model3D.Visible = true
							model3D:SetCFrame(CFrame.Angles(math.rad(-10), math.rad(30), 0))
							return model3D
						end
						return nil
					end)

					if success and model3D then
						table.insert(model3DObjects, {model = model3D})
					else
						viewportFrame.Visible = false
						if reward.image then itemFrame.Image = reward.image end
					end
				else
					viewportFrame.Visible = false
					if reward.image then itemFrame.Image = reward.image end
				end
			else
				viewportFrame.Visible = false
				if reward.image then itemFrame.Image = reward.image end
			end
		end)
	else
		if viewportFrame then viewportFrame.Visible = false end
		if reward.image then itemFrame.Image = reward.image end
	end

	table.insert(itemFrames, itemFrame)
end

-- Enhanced shop lock updates with optimized performance
function updateShopItemLocks()
	if not shopItems or not ItemsData then return end

	local leaderstats = player:FindFirstChild("leaderstats")
	local rebirthValue = leaderstats and leaderstats:FindFirstChild("Rebirth")
	if not rebirthValue then return end

	local playerRebirth = tonumber(rebirthValue.Value) or 0

	sortShopItemsByRebirthOrder()

	local sortedTools = ItemsData:GetItemsSortedByRebirth()

	for _, toolData in ipairs(sortedTools) do
		local toolName = toolData.name
		local requiredRebirth = toolData.rebirth

		local itemFrame = nil
		for _, child in ipairs(shopItems:GetChildren()) do
			if child.ClassName == "Frame" and child.Name ~= "Template" then
				local itemInfo = child:FindFirstChild("ItemInformation")
				if itemInfo then
					local nameLabel = itemInfo:FindFirstChild("ItemName")
					if nameLabel and nameLabel.Text == toolName then
						itemFrame = child
						break
					end
				end
				if child.Name == toolName then
					itemFrame = child
					break
				end
			end
		end

		if itemFrame then
			local lockedFrame = itemFrame:FindFirstChild("Locked")
			local isUnlocked = tonumber(playerRebirth) >= tonumber(requiredRebirth)

			if isUnlocked then
				if lockedFrame then 
					lockedFrame.Visible = false 
				end
			else
				if not lockedFrame then
					lockedFrame = Instance.new("Frame")
					lockedFrame.Name = "Locked"
					lockedFrame.Size = UDim2.new(1, 0, 1, 0)
					lockedFrame.BackgroundColor3 = Color3.new(0, 0, 0)
					lockedFrame.BackgroundTransparency = 0.6
					lockedFrame.BorderSizePixel = 0
					lockedFrame.ZIndex = 10
					lockedFrame.Parent = itemFrame

					local txt = Instance.new("TextLabel")
					txt.Name = "Txt"
					txt.Size = UDim2.new(0.9, 0, 0.3, 0)
					txt.Position = UDim2.new(0.05, 0, 0.35, 0)
					txt.BackgroundTransparency = 1
					txt.TextColor3 = Color3.new(1, 1, 1)
					txt.TextScaled = true
					txt.Font = Enum.Font.GothamBold
					txt.TextStrokeTransparency = 0
					txt.TextStrokeColor3 = Color3.new(0, 0, 0)
					txt.ZIndex = 11
					txt.Parent = lockedFrame
				end

				local txt = lockedFrame:FindFirstChild("Txt") or lockedFrame:FindFirstChild("LockText")
				if txt then
					txt.Text = "LOCKED - REBIRTH " .. requiredRebirth
				end
				lockedFrame.Visible = true
			end
		end
	end
end

-- Optimized rebirth rewards display
function updateRebirthRewards()
	local leaderstats = player:FindFirstChild("leaderstats")
	local rebirthValue = leaderstats and leaderstats:FindFirstChild("Rebirth")
	if not rebirthValue or not RebirthData then return end

	local currentRebirth = tonumber(rebirthValue.Value) or 0

	clearItemDisplays()

	local nextRebirth = currentRebirth + 1
	local rewards = RebirthData:GetRewardsForRebirth(nextRebirth)

	if #rewards > 0 then
		for i, reward in ipairs(rewards) do
			pcall(function()
				createItemDisplay(reward, i)
			end)
		end
	else
		-- Max rebirth display
		local completionFrame = template:Clone()
		completionFrame.Name = "Completion"
		completionFrame.Visible = true
		completionFrame.Parent = items

		local itemName = completionFrame:FindFirstChild("ItemName")
		local itemValue = completionFrame:FindFirstChild("ItemValue")
		local viewportFrame = completionFrame:FindFirstChild("ViewportFrame")

		if itemName then itemName.Text = "MAX REBIRTH!" end
		if itemValue then itemValue.Text = "Completed" end
		if viewportFrame then viewportFrame.Visible = false end

		completionFrame.Image = "rbxassetid://82462348100010"
		table.insert(itemFrames, completionFrame)
	end
end

-- Highly optimized progress update with throttling
function updateRebirthProgress()
	local currentTime = tick()
	if isUpdating or currentTime - lastUpdateTime < UPDATE_COOLDOWN then 
		return 
	end

	lastUpdateTime = currentTime
	isUpdating = true

	local leaderstats = player:FindFirstChild("leaderstats")
	local coinsValue = leaderstats and leaderstats:FindFirstChild("Coins")
	local rebirthValue = leaderstats and leaderstats:FindFirstChild("Rebirth")

	if not coinsValue or not rebirthValue then
		isUpdating = false
		return
	end

	local currentCoins = tonumber(coinsValue.Value) or 0
	local currentRebirth = tonumber(rebirthValue.Value) or 0

	local coinsChanged = currentCoins ~= lastCoins
	local rebirthChanged = currentRebirth ~= lastRebirth

	if not coinsChanged and not rebirthChanged then
		isUpdating = false
		return
	end

	if rebirthChanged then
		updateRebirthRewards()
	end

	-- Handle max rebirth efficiently
	if currentRebirth >= 10 then
		if rebirthChanged then
			bar.Size = UDim2.new(1, 0, bar.Size.Y.Scale, bar.Size.Y.Offset)
			textLabel.Text = "MAX REBIRTH!"
			rebirthButtonText.Text = "MAX LEVEL"
		end
		lastCoins = currentCoins
		lastRebirth = currentRebirth
		isUpdating = false
		return
	end

	local requiredCoins = REBIRTH_REQUIREMENTS[currentRebirth]
	if not requiredCoins then
		isUpdating = false
		return
	end

	-- Update progress bar only if coins changed
	if coinsChanged then
		local progress = math.min(currentCoins / tonumber(requiredCoins), 1)
		local barScale = math.max(progress, 0.01)

		TweenService:Create(bar, tweenInfo, {
			Size = UDim2.new(barScale, 0, bar.Size.Y.Scale, bar.Size.Y.Offset)
		}):Play()

		if progress >= 1 then
			textLabel.Text = "Ready!"
			rebirthButtonText.Text = "REBIRTH!"
		else
			textLabel.Text = formatCurrency(currentCoins) .. " / " .. formatCurrency(tonumber(requiredCoins))
			rebirthButtonText.Text = "REBIRTH (" .. (currentRebirth + 1) .. ")"
		end
	end

	lastCoins = currentCoins
	lastRebirth = currentRebirth
	isUpdating = false
end

-- Optimized rebirth check
local function canRebirth()
	local leaderstats = player:FindFirstChild("leaderstats")
	local coinsValue = leaderstats and leaderstats:FindFirstChild("Coins")
	local rebirthValue = leaderstats and leaderstats:FindFirstChild("Rebirth")

	if not coinsValue or not rebirthValue then return false end

	local currentRebirth = tonumber(rebirthValue.Value) or 0
	local currentCoins = tonumber(coinsValue.Value) or 0

	if currentRebirth >= 10 then return false end

	local requiredCoins = REBIRTH_REQUIREMENTS[currentRebirth]
	return requiredCoins and currentCoins >= requiredCoins
end

-- Optimized button setup
rebirthButton.BackgroundColor3 = defaultColor
if not rebirthButton:FindFirstChild("UIScale") then
	local uiScale = Instance.new("UIScale")
	uiScale.Scale = 1.0
	uiScale.Parent = rebirthButton
end

-- Optimized button effects
rebirthButton.MouseEnter:Connect(function()
	buttonHover:Play()
	TweenService:Create(rebirthButton, tweenInfo, {BackgroundColor3 = hoverColor}):Play()
	local uiScale = rebirthButton:FindFirstChild("UIScale")
	if uiScale then
		TweenService:Create(uiScale, tweenInfo, {Scale = 1.05}):Play()
	end
end)

rebirthButton.MouseLeave:Connect(function()
	TweenService:Create(rebirthButton, tweenInfo, {BackgroundColor3 = defaultColor}):Play()
	local uiScale = rebirthButton:FindFirstChild("UIScale")
	if uiScale then
		TweenService:Create(uiScale, tweenInfo, {Scale = 1.0}):Play()
	end
end)

rebirthButton.MouseButton1Down:Connect(function()
	buttonPress:Play()
	TweenService:Create(rebirthButton, tweenInfo, {BackgroundColor3 = pressColor}):Play()
	local uiScale = rebirthButton:FindFirstChild("UIScale")
	if uiScale then
		TweenService:Create(uiScale, tweenInfo, {Scale = 0.95}):Play()
	end
end)

rebirthButton.MouseButton1Up:Connect(function()
	buttonRelease:Play()
	TweenService:Create(rebirthButton, tweenInfo, {BackgroundColor3 = hoverColor}):Play()
	local uiScale = rebirthButton:FindFirstChild("UIScale")
	if uiScale then
		TweenService:Create(uiScale, tweenInfo, {Scale = 1.05}):Play()
	end
end)

-- Rebirth button click with cooldown
local lastClickTime = 0
rebirthButton.MouseButton1Click:Connect(function()
	local currentTime = tick()
	if currentTime - lastClickTime < 1 then return end
	lastClickTime = currentTime

	if canRebirth() then
		rebirthRemote:FireServer()
	else
		errorSound:Play()
	end
end)

-- Handle rebirth response
rebirthRemote.OnClientEvent:Connect(function(success)
	if success then
		codeRedeemed:Play()
		task.spawn(debouncedUpdate)
	else
		errorSound:Play()
	end
end)

-- Optimized stat change handling
local function connectToStats(leaderstats)
	local coins = leaderstats:WaitForChild("Coins")
	local rebirth = leaderstats:WaitForChild("Rebirth")

	coins.Changed:Connect(debouncedUpdate)
	rebirth.Changed:Connect(debouncedUpdate)

	-- Initial update with proper timing
	task.spawn(function()
		task.wait(1)
		updateRebirthProgress()
		updateRebirthRewards()
	end)
end

-- Connect to leaderstats efficiently
if player:FindFirstChild("leaderstats") then
	connectToStats(player.leaderstats)
else
	player.ChildAdded:Connect(function(child)
		if child.Name == "leaderstats" then
			connectToStats(child)
		end
	end)
end

-- Hide template and initialize
template.Visible = false

-- Initial setup with proper timing
task.spawn(function()
	task.wait(2)
	sortShopItemsByRebirthOrder()
	updateShopItemLocks()
	updateRebirthRewards()
end)