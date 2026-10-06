local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local MAX_PLAYERS = 100
local UPDATE_INTERVAL = 30
local SAVE_INTERVAL = 15
local MIN_CHANGE_THRESHOLD = 1
local POSITION_COLORS = {
	[1] = Color3.fromRGB(255, 215, 0),
	[2] = Color3.fromRGB(192, 192, 192),
	[3] = Color3.fromRGB(205, 127, 50),
}
local DEFAULT_COLOR = Color3.fromRGB(255, 255, 255)

local coinsOrderedStore = DataStoreService:GetOrderedDataStore("GlobalCoinsLeaderboard")
local legacyCoinsOrderedStore = DataStoreService:GetOrderedDataStore("GlobalCashLeaderboard")
local playerDataStore = DataStoreService:GetDataStore("PlayerCoinsData")
local legacyCoinsDataStore = DataStoreService:GetDataStore("PlayerCashData")

local scrollingFrame = script.Parent
local template = scrollingFrame:WaitForChild("Template")
local playerTemplates = {}
local isUpdating = false
local lastUpdateTime = 0
local lastSaveTime = 0
local playerCoinsCache = {}
local saveQueue = {}
local isSaving = false
local formatCache = {}

local function formatNumber(num)
	num = tonumber(num) or 0
	if formatCache[num] then return formatCache[num] end
	local result
	if num >= 1000000000000000000 then result = string.format("%.1fQ", num / 1000000000000000000)
	elseif num >= 1000000000000000 then result = string.format("%.1fQa", num / 1000000000000000)
	elseif num >= 1000000000000 then result = string.format("%.1fT", num / 1000000000000)
	elseif num >= 1000000000 then result = string.format("%.1fB", num / 1000000000)
	elseif num >= 1000000 then result = string.format("%.1fM", num / 1000000)
	elseif num >= 1000 then result = string.format("%.1fK", num / 1000)
	else result = string.format("%.0f", num) end
	formatCache[num] = result
	return result
end

local function getPlayerCoins(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	return coins and tonumber(coins.Value) or 0
end

local function savePlayerCoins(player, coins)
	if coins <= 0 then return end
	saveQueue[player.UserId] = {player = player, coins = coins, timestamp = tick()}
end

local function processSaveQueue()
	local queueSize = 0
	for _ in pairs(saveQueue) do queueSize += 1 end
	if isSaving or queueSize == 0 then return end
	isSaving = true
	local processedCount = 0
	for userId, data in pairs(saveQueue) do
		if processedCount >= 3 then break end
		local player = data.player
		local coins = data.coins
		if not player or not player.Parent then
			saveQueue[userId] = nil
			continue
		end
		task.spawn(function()
			local success, err = pcall(function()
				playerDataStore:SetAsync("Player_" .. userId, {
					UserId = tonumber(userId),
					Username = player.Name,
					DisplayName = player.DisplayName or player.Name,
					LastUpdate = tick(),
				})
				coinsOrderedStore:SetAsync(userId, coins)
			end)
			if not success then warn("Failed to save Coins for " .. player.Name .. ": " .. tostring(err)) end
			saveQueue[userId] = nil
		end)
		processedCount += 1
		task.wait(0.2)
	end
	isSaving = false
end

local function getGlobalTopPlayers()
	local success, result = pcall(function()
		return coinsOrderedStore:GetSortedAsync(false, MAX_PLAYERS)
	end)
	if not success or not result then
		local legacySuccess, legacyResult = pcall(function()
			return legacyCoinsOrderedStore:GetSortedAsync(false, MAX_PLAYERS)
		end)
		if legacySuccess then result = legacyResult end
	end
	if not result then return {} end
	local topPlayers = {}
	for _, entry in ipairs(result:GetCurrentPage()) do
		local userId = tonumber(entry.key)
		local coins = tonumber(entry.value) or 0
		if userId and coins > 0 then
			local username = "Loading..."
			local displayName = ""
			local dataSuccess, savedData = pcall(function()
				return playerDataStore:GetAsync("Player_" .. userId)
			end)
			if not dataSuccess or not savedData then
				dataSuccess, savedData = pcall(function()
					return legacyCoinsDataStore:GetAsync("Player_" .. userId)
				end)
			end
			if dataSuccess and savedData then
				username = savedData.Username or username
				displayName = savedData.DisplayName or ""
			end
			local livePlayer = Players:GetPlayerByUserId(userId)
			if livePlayer then
				username = livePlayer.Name
				displayName = livePlayer.DisplayName or ""
			end
			if username == "Loading..." then
				local nameSuccess, nameResult = pcall(function() return Players:GetNameFromUserIdAsync(userId) end)
				if nameSuccess and nameResult then username, displayName = nameResult, nameResult end
			end
			table.insert(topPlayers, {userId = userId, username = username, displayName = displayName, coins = coins})
		end
	end
	return topPlayers
end

local function getPlayerAvatarUrl(userId)
	return "rbxthumb://type=AvatarHeadShot&id=" .. userId .. "&w=150&h=150"
end

local function applyPositionColors(templateClone, position)
	local color = POSITION_COLORS[position] or DEFAULT_COLOR
	for _, elementName in ipairs({"Value", "NameLabel", "PositionLabel"}) do
		local element = templateClone:FindFirstChild(elementName)
		if element then element.TextColor3 = color end
	end
	if position == 1 then
		local avatarImage = templateClone:FindFirstChild("AvatarImage")
		if avatarImage and not avatarImage:FindFirstChild("UIStroke") then
			local uiStroke = Instance.new("UIStroke")
			uiStroke.Color = POSITION_COLORS[1]
			uiStroke.Thickness = 3
			uiStroke.Parent = avatarImage
		end
	end
end

local function createOrUpdateGlobalTemplate(playerData, position)
	local userId = playerData.userId
	local templateClone = playerTemplates[userId]
	if not templateClone then
		templateClone = template:Clone()
		templateClone.Name = "GlobalPlayer_" .. userId
		templateClone.Visible = true
		templateClone.Parent = scrollingFrame
		playerTemplates[userId] = templateClone
	end
	templateClone.LayoutOrder = position - 1
	local valueLabel = templateClone:FindFirstChild("Value")
	local avatarImage = templateClone:FindFirstChild("AvatarImage")
	local nameLabel = templateClone:FindFirstChild("NameLabel")
	local positionLabel = templateClone:FindFirstChild("PositionLabel")
	if valueLabel then valueLabel.Text = formatNumber(playerData.coins) .. " Coins" end
	if avatarImage then avatarImage.Image = getPlayerAvatarUrl(userId) end
	if nameLabel then nameLabel.Text = playerData.displayName ~= "" and playerData.displayName or playerData.username end
	if positionLabel then positionLabel.Text = "#" .. position end
	applyPositionColors(templateClone, position)
end

local function cleanupTemplates(activePlayerIds)
	for userId, templateClone in pairs(playerTemplates) do
		if not activePlayerIds[userId] then
			if templateClone.Parent then templateClone:Destroy() end
			playerTemplates[userId] = nil
		end
	end
end

local function updateGlobalLeaderboard()
	local currentTime = tick()
	if isUpdating or currentTime - lastUpdateTime < UPDATE_INTERVAL then return end
	isUpdating = true
	lastUpdateTime = currentTime
	local activePlayerIds = {}
	for position, playerData in ipairs(getGlobalTopPlayers()) do
		activePlayerIds[playerData.userId] = true
		local success, err = pcall(createOrUpdateGlobalTemplate, playerData, position)
		if not success then warn("Template update error:", err) end
	end
	cleanupTemplates(activePlayerIds)
	local listLayout = scrollingFrame:FindFirstChild("UIListLayout")
	if listLayout then scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10) end
	isUpdating = false
end

local function saveCurrentServerPlayers()
	local currentTime = tick()
	if currentTime - lastSaveTime < SAVE_INTERVAL then return end
	lastSaveTime = currentTime
	for _, player in ipairs(Players:GetPlayers()) do
		local coins = getPlayerCoins(player)
		local lastCoins = playerCoinsCache[player.UserId] or 0
		if math.abs(coins - lastCoins) >= MIN_CHANGE_THRESHOLD then
			playerCoinsCache[player.UserId] = coins
			savePlayerCoins(player, coins)
		end
	end
	task.spawn(processSaveQueue)
end

local function savePlayerName(player)
	local success, err = pcall(function()
		playerDataStore:SetAsync("Player_" .. player.UserId, {
			UserId = player.UserId,
			Username = player.Name,
			DisplayName = player.DisplayName or player.Name,
			LastUpdate = tick(),
		})
	end)
	if not success then warn("Failed to save name data for " .. player.Name .. ": " .. tostring(err)) end
end

local function onPlayerAdded(player)
	task.spawn(savePlayerName, player)
	task.spawn(function()
		task.wait(3)
		local coins = getPlayerCoins(player)
		if coins > 0 then savePlayerCoins(player, coins) end
	end)
	local leaderstats = player:WaitForChild("leaderstats", 10)
	local coinsValue = leaderstats and leaderstats:WaitForChild("Coins", 5)
	if coinsValue then
		coinsValue.Changed:Connect(function(value)
			playerCoinsCache[player.UserId] = tonumber(value) or 0
		end)
	end
end

local function onPlayerRemoving(player)
	local coins = getPlayerCoins(player)
	if coins > 0 then savePlayerCoins(player, coins) end
	playerCoinsCache[player.UserId] = nil
	if playerTemplates[player.UserId] then
		if playerTemplates[player.UserId].Parent then playerTemplates[player.UserId]:Destroy() end
		playerTemplates[player.UserId] = nil
	end
end

local function setupLeaderboardUI()
	template.Visible = false
	local listLayout = scrollingFrame:FindFirstChild("UIListLayout") or Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 8)
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	listLayout.Parent = scrollingFrame
	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do onPlayerAdded(player) end
setupLeaderboardUI()
task.spawn(function()
	task.wait(5)
	while true do
		updateGlobalLeaderboard()
		task.wait(UPDATE_INTERVAL)
	end
end)
task.spawn(function()
	task.wait(8)
	while true do
		saveCurrentServerPlayers()
		task.wait(SAVE_INTERVAL)
	end
end)