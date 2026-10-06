local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CurrencyConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("CurrencyConfig"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))

local CurrencyService = {}

local function getValue(player, name)
	local leaderstats = player and player:FindFirstChild("leaderstats")
	return leaderstats and leaderstats:FindFirstChild(name)
end

local function validAmount(amount)
	return typeof(amount) == "number" and amount == amount and amount > 0 and amount < math.huge
end

local function getCurrency(player, name)
	local value = getValue(player, name)
	return value and value.Value or 0
end

local function getLimit(name)
	local limits = CurrencyConfig.Limits or {}
	local limit = limits[name]
	return typeof(limit) == "number" and limit >= 0 and limit or math.huge
end

local function changeCurrency(player, name, amount, direction)
	if not PlayerDataService:IsLoaded(player) or not validAmount(amount) then
		return false, getCurrency(player, name)
	end
	local value = getValue(player, name)
	if not value then
		return false, 0
	end
	amount = math.floor(amount)
	if direction < 0 and value.Value < amount then
		return false, value.Value
	end
	local nextValue = math.clamp(value.Value + amount * direction, 0, getLimit(name))
	value.Value = nextValue
	PlayerDataService:Update(player, name, nextValue)
	return true, nextValue
end

function CurrencyService:GetCoins(player) return getCurrency(player, "Coins") end
function CurrencyService:AddCoins(player, amount) return changeCurrency(player, "Coins", amount, 1) end
function CurrencyService:RemoveCoins(player, amount) return changeCurrency(player, "Coins", amount, -1) end
function CurrencyService:HasCoins(player, amount) return validAmount(amount) and self:GetCoins(player) >= math.floor(amount) end
function CurrencyService:GetRizz(player) return getCurrency(player, "Rizz") end
function CurrencyService:AddRizz(player, amount) return changeCurrency(player, "Rizz", amount, 1) end
function CurrencyService:RemoveRizz(player, amount) return changeCurrency(player, "Rizz", amount, -1) end
function CurrencyService:HasRizz(player, amount) return validAmount(amount) and self:GetRizz(player) >= math.floor(amount) end

return CurrencyService