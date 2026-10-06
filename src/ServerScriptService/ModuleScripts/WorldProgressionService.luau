local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AreaConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("AreaConfig"))
local RarityService = require(script.Parent:WaitForChild("RarityService"))

local WorldProgressionService = {}
local areaUnlockedEvent = Instance.new("BindableEvent")
WorldProgressionService.AreaUnlocked = areaUnlockedEvent.Event
WorldProgressionService._areaUnlockedBindable = areaUnlockedEvent

local definitions = {}
local orderedAreas = {}

local function copyArray(array)
	local result = {}
	for index, value in ipairs(array or {}) do result[index] = value end
	return result
end

local function copyArea(area)
	if not area then return nil end
	local result = table.clone(area)
	result.AllowedRarities = copyArray(area.AllowedRarities)
	result.SpawnRates = table.clone(area.SpawnRates or {})
	result.Multipliers = table.clone(area.Multipliers or {})
	result.Metadata = table.clone(area.Metadata or {})
	result.Gate = table.clone(area.Gate or {})
	result.UI = table.clone(area.UI or {})
	return result
end

for _, area in ipairs(AreaConfig.Areas or {}) do
	local areaId = area.AreaId or area.Id
	if typeof(areaId) == "string" and areaId ~= "" and not definitions[areaId] then
		local stored = copyArea(area)
		stored.Id = areaId
		stored.AreaId = areaId
		stored.Order = math.max(1, math.floor(tonumber(stored.Order) or (#orderedAreas + 1)))
		stored.RequiredRizz = 0
		stored.RizzRequirement = 0
		stored.UnlockCost = 0
		stored.CoinCost = 0
		stored.RequirePreviousArea = false
		stored.IsStartingArea = stored.IsStartingArea == true or stored.Order == 1
		stored.IsDangerousArea = stored.IsDangerousArea == true
		stored.IsBossArea = stored.IsBossArea == true
		stored.MinimumRizzToSurvive = math.max(0, math.floor(tonumber(stored.MinimumRizzToSurvive) or 0))
		stored.AllowedRarities = stored.AllowedRarities or {}
		definitions[areaId] = stored
		table.insert(orderedAreas, stored)
	end
end

table.sort(orderedAreas, function(left, right)
	if left.Order == right.Order then return left.Id < right.Id end
	return left.Order < right.Order
end)

function WorldProgressionService:GetArea(areaId) return copyArea(definitions[areaId]) end
function WorldProgressionService:GetAllAreas()
	local result = {}
	for _, area in ipairs(orderedAreas) do table.insert(result, copyArea(area)) end
	return result
end
function WorldProgressionService:GetAreaByOrder(order)
	order = tonumber(order)
	if not order then return nil end
	for _, area in ipairs(orderedAreas) do
		if area.Order == math.floor(order) then return copyArea(area) end
	end
	return nil
end

function WorldProgressionService:IsAreaPurchased(player, areaId)
	return definitions[areaId] ~= nil
end

function WorldProgressionService:GetAreaStatus(player, areaId)
	local area = definitions[areaId]
	if not area then return false, "AreaNotFound", nil end
	return true, "Unlocked", {
		Id = area.Id,
		DisplayName = area.DisplayName,
		RequiredRizz = 0,
		UnlockCost = 0,
		CurrencyType = area.CurrencyType or "Coins",
		PlayerRizz = 0,
		PlayerCurrency = 0,
		PreviousArea = nil,
		PreviousAreaMet = true,
		IsDangerousArea = area.IsDangerousArea,
		MinimumRizzToSurvive = area.MinimumRizzToSurvive,
		Unlocked = true,
	}
end

function WorldProgressionService:CanAccessArea(player, areaId)
	local status, reason, details = self:GetAreaStatus(player, areaId)
	return status, reason, details
end

function WorldProgressionService:PurchaseArea(player, areaId)
	local unlocked, reason, status = self:GetAreaStatus(player, areaId)
	if not unlocked then return false, reason, status end
	return true, "AlreadyUnlocked", status
end

function WorldProgressionService:LoadPurchasedAreas(player, areaIds)
end

function WorldProgressionService:GetPurchasedAreaIds(player)
	local result = {}
	for _, area in ipairs(orderedAreas) do table.insert(result, area.Id) end
	return result
end

function WorldProgressionService:GetAllowedRarities(player, areaId)
	local area = definitions[areaId]
	if not area then return {}, "AreaNotFound", nil end
	local result = {}
	for _, rarityId in ipairs(area.AllowedRarities) do
		if RarityService:IsObtainable(rarityId) then table.insert(result, rarityId) end
	end
	return result, "Unlocked", copyArea(area)
end

function WorldProgressionService:CanAccessRarity(player, areaId, rarityId)
	local area = definitions[areaId]
	if not area then return false, "AreaNotFound", nil, rarityId end
	if not RarityService:IsObtainable(rarityId) then return false, "RarityNotObtainable", copyArea(area), rarityId end
	for _, allowedRarity in ipairs(area.AllowedRarities) do
		if allowedRarity == rarityId then return true, "Allowed", copyArea(area), rarityId end
	end
	return false, "RarityNotAllowed", copyArea(area), rarityId
end

function WorldProgressionService:GetNextArea(player)
	return nil
end

function WorldProgressionService:GetUnlockedAreas(player)
	local result = {}
	for _, area in ipairs(orderedAreas) do table.insert(result, copyArea(area)) end
	return result
end

function WorldProgressionService:RefreshPlayer(player)
	return self:GetUnlockedAreas(player)
end

function WorldProgressionService:ClearPlayer(player)
end

return WorldProgressionService