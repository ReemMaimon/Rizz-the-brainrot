local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(script.Parent:WaitForChild("ModuleScripts"):WaitForChild("PlayerDataService"))
local ProgressionService = require(script.Parent:WaitForChild("ModuleScripts"):WaitForChild("ProgressionService"))
local WorldProgressionService = require(script.Parent:WaitForChild("ModuleScripts"):WaitForChild("WorldProgressionService"))
local AreaConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("AreaConfig"))

local characterConnections = {}
local playerGroups = {}

local function ensureCollisionGroup(name)
	if not PhysicsService:IsCollisionGroupRegistered(name) then PhysicsService:RegisterCollisionGroup(name) end
end

local function configureCollisionGroups()
	for order = 1, #AreaConfig.Areas do ensureCollisionGroup("WorldProgressionPlayer" .. order) end
	for _, area in ipairs(AreaConfig.Areas or {}) do
		if area.BlockerPartName then ensureCollisionGroup("WorldProgressionBlocker" .. area.Order) end
	end
	for playerOrder = 1, #AreaConfig.Areas do
		local playerGroup = "WorldProgressionPlayer" .. playerOrder
		for _, area in ipairs(AreaConfig.Areas or {}) do
			if area.BlockerPartName then
				local blockerGroup = "WorldProgressionBlocker" .. area.Order
				PhysicsService:CollisionGroupSetCollidable(playerGroup, blockerGroup, false)
			end
		end
	end
end

local function getConfiguredPart(name)
	if typeof(name) ~= "string" or name == "" then return nil end
	local part = Workspace:FindFirstChild(name, true)
	return part and part:IsA("BasePart") and part or nil
end

local function setCharacterCollisionGroup(character, groupName)
	if character:IsA("BasePart") then character.CollisionGroup = groupName end
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") then descendant.CollisionGroup = groupName end
	end
end

local function updatePlayerCollisionGroup(player)
	local character = player.Character
	if not character or not PlayerDataService:IsLoaded(player) then return end
	local groupName = "WorldProgressionPlayer" .. math.max(1, #AreaConfig.Areas)
	playerGroups[player] = groupName
	setCharacterCollisionGroup(character, groupName)
end

local function setReplicatedProgression(player)
	local areaIds = {}
	for _, area in ipairs(AreaConfig.Areas or {}) do table.insert(areaIds, area.Id or area.AreaId) end
	local ids = table.concat(areaIds, ",")
	player:SetAttribute("WorldProgressionUnlockedAreas", ids)
	player:SetAttribute("WorldProgressionNextArea", "")
	player:SetAttribute("WorldProgressionRizz", ProgressionService:GetRizz(player))
	player:SetAttribute("WorldProgressionPurchasedAreas", ids)
	for _, area in ipairs(AreaConfig.Areas or {}) do
		local currencyType = area.CurrencyType or "Coins"
		local value = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild(currencyType)
		player:SetAttribute("WorldProgressionCurrency_" .. currencyType, value and value.Value or 0)
	end
	updatePlayerCollisionGroup(player)
end

local function initializeBlockers()
	for _, area in ipairs(AreaConfig.Areas or {}) do
		if area.BlockerPartName then
			local blocker = getConfiguredPart(area.BlockerPartName)
			if blocker then
				blocker.CollisionGroup = "WorldProgressionBlocker" .. area.Order
				blocker.CanCollide = false
				blocker.CanTouch = false
				blocker.CanQuery = false
				blocker.Transparency = AreaConfig.GateDefaults.UnlockedTransparency or 1
			else
				warn(string.format("[WorldProgression] Blocker part %q for %s was not found", area.BlockerPartName, area.Id))
			end
		end
	end
end

configureCollisionGroups()
initializeBlockers()

local function initializePlayer(player)
	repeat task.wait() until PlayerDataService:IsLoaded(player) or not player.Parent
	if not player.Parent then return end
	WorldProgressionService:RefreshPlayer(player)
	setReplicatedProgression(player)
	local function onCharacterAdded(character)
		character:WaitForChild("HumanoidRootPart", 10)
		updatePlayerCollisionGroup(player)
		if characterConnections[player] then characterConnections[player]:Disconnect() end
		characterConnections[player] = character.DescendantAdded:Connect(function(descendant)
			if descendant:IsA("BasePart") then descendant.CollisionGroup = playerGroups[player] or "WorldProgressionPlayer1" end
		end)
	end
	if player.Character then onCharacterAdded(player.Character) end
	player.CharacterAdded:Connect(onCharacterAdded)
end

Players.PlayerAdded:Connect(function(player) task.spawn(initializePlayer, player) end)
Players.PlayerRemoving:Connect(function(player)
	WorldProgressionService:ClearPlayer(player)
	playerGroups[player] = nil
	if characterConnections[player] then characterConnections[player]:Disconnect() characterConnections[player] = nil end
end)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(initializePlayer, player) end

task.spawn(function()
	while task.wait(1) do
		for _, player in ipairs(Players:GetPlayers()) do
			if PlayerDataService:IsLoaded(player) then
				WorldProgressionService:RefreshPlayer(player)
				setReplicatedProgression(player)
			end
		end
	end
end)