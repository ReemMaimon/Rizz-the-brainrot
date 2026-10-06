local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local modules = ReplicatedStorage:WaitForChild("ModuleScripts")
local AbilityConfig = require(modules:WaitForChild("AbilityConfig"))
local PlayerDataService = require(game:GetService("ServerScriptService"):WaitForChild("ModuleScripts"):WaitForChild("PlayerDataService"))

local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents") or Instance.new("Folder")
remotes.Name = "RemoteEvents"
remotes.Parent = ReplicatedStorage

local purchasePack = remotes:FindFirstChild("PurchaseAbilityPack") or Instance.new("RemoteFunction")
purchasePack.Name = "PurchaseAbilityPack"
purchasePack.Parent = remotes

local getPacks = remotes:FindFirstChild("GetAbilityPacks") or Instance.new("RemoteFunction")
getPacks.Name = "GetAbilityPacks"
getPacks.Parent = remotes

local function finitePositive(value)
	return typeof(value) == "number" and value == value and value > 0 and value < math.huge and math.floor(value) == value
end

local function getCoins(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	return coins and coins.Value or 0, coins
end

local function chooseRarity(weights)
	local total = 0
	for rarity, weight in pairs(weights or {}) do
		if typeof(rarity) == "string" and finitePositive(weight) and AbilityConfig.Abilities then
			total += weight
		end
	end
	if total <= 0 then return nil end
	local roll = math.random() * total
	local running = 0
	for rarity, weight in pairs(weights) do
		if typeof(rarity) == "string" and finitePositive(weight) and AbilityConfig.Abilities then
			running += weight
			if roll <= running then return rarity end
		end
	end
	return nil
end

local function buildPool(pack, rarity)
	local pool = {}
	for _, abilityId in ipairs(pack.EligibleAbilities or {}) do
		local ability = AbilityConfig.Abilities[abilityId]
		if ability and ability.Rarity == rarity then table.insert(pool, abilityId) end
	end
	return pool
end

local function rollAbility(pack)
	local rarity = chooseRarity(pack.RarityWeights)
	local pool = rarity and buildPool(pack, rarity) or {}
	if #pool == 0 then
		for _, abilityId in ipairs(pack.EligibleAbilities or {}) do
			if AbilityConfig.Abilities[abilityId] then table.insert(pool, abilityId) end
		end
	end
	if #pool == 0 then return nil end
	return pool[math.random(1, #pool)]
end

getPacks.OnServerInvoke = function(player)
	local result = {}
	for packId, pack in pairs(AbilityConfig.CardPacks or {}) do
		if typeof(packId) == "string" and typeof(pack) == "table" and finitePositive(pack.Price) and math.floor(tonumber(pack.CardCount) or 0) > 0 then
			table.insert(result, {PackId = packId, DisplayName = tostring(pack.DisplayName or packId), Description = tostring(pack.Description or ""), Price = pack.Price, CardCount = math.floor(pack.CardCount)})
		end
	end
	return result
end

purchasePack.OnServerInvoke = function(player, packId)
	if typeof(packId) ~= "string" then return {Success = false, Message = "Invalid pack."} end
	local pack = AbilityConfig.CardPacks and AbilityConfig.CardPacks[packId]
	if typeof(pack) ~= "table" or not finitePositive(pack.Price) then return {Success = false, Message = "This pack is unavailable."} end
	local cardCount = math.floor(tonumber(pack.CardCount) or 0)
	if cardCount < 1 or cardCount > 20 then return {Success = false, Message = "This pack is misconfigured."} end
	local coins, coinsValue = getCoins(player)
	if not coinsValue or coins < pack.Price then return {Success = false, Message = "Not enough Coins.", Coins = coins} end
	local data = PlayerDataService:EnsureAbilityData(player, AbilityConfig.MaxEquippedAbilities)
	if not data then return {Success = false, Message = "Your data is still loading."} end
	local awarded = {}
	for _ = 1, cardCount do
		local abilityId = rollAbility(pack)
		if not abilityId then return {Success = false, Message = "This pack has no valid cards."} end
		table.insert(awarded, {AbilityId = abilityId, DisplayName = AbilityConfig.Abilities[abilityId].DisplayName, Rarity = AbilityConfig.Abilities[abilityId].Rarity, New = data.OwnedAbilities[abilityId] == nil})
		data.OwnedAbilities[abilityId] = data.OwnedAbilities[abilityId] or {Cards = 0}
		data.OwnedAbilities[abilityId].Cards = (tonumber(data.OwnedAbilities[abilityId].Cards) or 0) + 1
	end
	coinsValue.Value -= pack.Price
	PlayerDataService:Update(player, "Coins", coinsValue.Value)
	return {Success = true, Coins = coinsValue.Value, PackId = packId, Cards = awarded}
end

Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("AbilityCardShopReady", true)
end)

print("[AbilityCardShop] Ready")