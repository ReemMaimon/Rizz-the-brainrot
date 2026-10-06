local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CurrencyConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("CurrencyConfig"))
local RizzConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("RizzConfig"))
local GameConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("GameConfig"))
local AbilityConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("AbilityConfig"))
local PlayerDataService = require(script.Parent:WaitForChild("ModuleScripts"):WaitForChild("PlayerDataService"))
local CurrencyService = require(script.Parent:WaitForChild("ModuleScripts"):WaitForChild("CurrencyService"))

local dataStoreConfig = GameConfig.DataStore or {}
local dataStore = DataStoreService:GetDataStore(dataStoreConfig.Name or "PlayerStats_v10")
local loadedPlayers = {}

local defaults = {
	DataVersion = GameConfig.DataVersion,
	Rebirth = 0,
	Steals = 0,
	Coins = CurrencyConfig.StartingCoins,
	Rizz = RizzConfig.StartingRizz,
	RizzLevel = RizzConfig.StartingRizzLevel,
	RawPower = 0,
	Tutorial = false,
	Babies = {},
	OfflineEarnings = {},
	LastLogout = 0,
	AllTimeBabies = {},
	OwnedAbilities = {},
	EquippedAbilities = {nil, nil, nil, nil},
	LuckyBlocks = {},
}

_G.DataManager = {}
_G.DataManager.getCoins = function(player)
	return CurrencyService:GetCoins(player)
end
_G.DataManager.addCoins = function(player, amount)
	local success = CurrencyService:AddCoins(player, amount)
	return success
end
_G.DataManager.removeCoins = function(player, amount)
	local success = CurrencyService:RemoveCoins(player, amount)
	return success
end
_G.DataManager.hasCoins = function(player, amount)
	return CurrencyService:HasCoins(player, amount)
end
_G.DataManager.getAbilityInventory = function(player)
	local data = PlayerDataService:Get(player)
	return data and data.OwnedAbilities or nil
end
_G.DataManager.addOwnedAbility = function(player, abilityId, metadata)
	local data = PlayerDataService:EnsureAbilityData(player, AbilityConfig.MaxEquippedAbilities)
	if not data or typeof(abilityId) ~= "string" or not AbilityConfig.Abilities[abilityId] then return false end
	data.OwnedAbilities[abilityId] = data.OwnedAbilities[abilityId] or (typeof(metadata) == "table" and table.clone(metadata) or {})
	return true
end

local function keyFor(player)
	return "Player_" .. tostring(player.UserId)
end

local function copyDefaults()
	local result = {}
	for key, value in pairs(defaults) do
		if typeof(value) == "table" then
			result[key] = table.clone(value)
		else
			result[key] = value
		end
	end
	return result
end

local function loadPlayer(player)
	if not player.Parent or loadedPlayers[player] then return end
	local raw
	local success, errorMessage = pcall(function()
		raw = dataStore:GetAsync(keyFor(player))
	end)
	if not success then
		warn("[DataManager] Failed to load " .. player.Name .. ": " .. tostring(errorMessage))
	end
	local data = PlayerDataService:Validate(success and raw or nil, defaults, GameConfig.DataVersion)
	if not PlayerDataService:Register(player, data) then return end
	PlayerDataService:CreateValues(player, data)
	loadedPlayers[player] = true
	print("[DataManager] Player data loaded for " .. player.Name)
end

local function snapshot(player)
	local data = PlayerDataService:Get(player)
	if not data then return nil end
	PlayerDataService:SyncFromValues(player)
	return table.clone(data)
end

local function savePlayer(player)
	if not loadedPlayers[player] then return end
	local data = snapshot(player)
	if not data then return end
	local success, errorMessage = pcall(function()
		dataStore:UpdateAsync(keyFor(player), function()
			return data
		end)
	end)
	if not success then
		warn("[DataManager] Failed to save " .. player.Name .. ": " .. tostring(errorMessage))
	end
end

local function onPlayerRemoving(player)
	savePlayer(player)
	loadedPlayers[player] = nil
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(loadPlayer, player)
end)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(loadPlayer, player)
end

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(savePlayer, player)
	end
	task.wait(2)
end)

task.spawn(function()
	while task.wait(60) do
		for player in pairs(loadedPlayers) do
			task.spawn(savePlayer, player)
		end
	end
end)