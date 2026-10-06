local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RizzConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("RizzConfig"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local CurrencyService = require(script.Parent:WaitForChild("CurrencyService"))
local AbilityPowerService = {
	AddRizzPower = function() end,
}

local ProgressionService = {}
local levelUpEvent = Instance.new("BindableEvent")
ProgressionService.OnRizzLevelUp = levelUpEvent.Event

local function getRequirement(level)
	local requirements = RizzConfig.LevelRequirements or {}
	local requirement = requirements[level]
	return typeof(requirement) == "number" and math.max(0, requirement) or math.huge
end

local function getMaxLevel()
	local progression = RizzConfig.Progression or {}
	return math.max(1, math.floor(progression.MaxLevel or 1000))
end

function ProgressionService:GetRizz(player)
	local data = PlayerDataService:Get(player)
	return data and data.Rizz or 0
end

function ProgressionService:GetRizzLevel(player)
	local data = PlayerDataService:Get(player)
	return data and data.RizzLevel or RizzConfig.StartingRizzLevel
end

function ProgressionService:CheckRizzLevel(player)
	local data = PlayerDataService:Get(player)
	if not data then return RizzConfig.StartingRizzLevel end
	local previousLevel = math.max(1, math.floor(data.RizzLevel or RizzConfig.StartingRizzLevel))
	local level = previousLevel
	local maxLevel = getMaxLevel()
	while level < maxLevel and getRequirement(level + 1) <= data.Rizz do level += 1 end
	if level ~= data.RizzLevel then
		data.RizzLevel = level
		PlayerDataService:Update(player, "RizzLevel", level)
		local value = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("RizzLevel")
		if value then value.Value = level end
		if level > previousLevel then
			player:SetAttribute("LastRizzLevelUp", level)
			levelUpEvent:Fire(player, level, previousLevel)
		end
	end
	return level
end

function ProgressionService:AddRizz(player, amount)
	local numericAmount = typeof(amount) == "number" and amount == amount and amount > 0 and amount < math.huge and math.floor(amount) or 0
	if numericAmount <= 0 or not PlayerDataService:IsLoaded(player) then return false, self:GetRizz(player), self:GetRizzLevel(player) end
	local success = CurrencyService:AddRizz(player, numericAmount)
	if success then
		AbilityPowerService:AddRizzPower(player, numericAmount)
		self:CheckRizzLevel(player)
	end
	return success, self:GetRizz(player), self:GetRizzLevel(player)
end

function ProgressionService:RemoveRizz(player, amount)
	local success = CurrencyService:RemoveRizz(player, amount)
	if success then self:CheckRizzLevel(player) end
	return success, self:GetRizz(player), self:GetRizzLevel(player)
end

function ProgressionService:HandleRizzGain(player, amount)
	return self:AddRizz(player, amount)
end

function ProgressionService:HasRizz(player, amount)
	return CurrencyService:HasRizz(player, amount)
end

function ProgressionService:HasRequiredRizz(player, requiredRizz)
	return typeof(requiredRizz) == "number" and requiredRizz >= 0 and self:GetRizz(player) >= math.floor(requiredRizz)
end

function ProgressionService:HasRequiredRizzLevel(player, requiredLevel)
	return typeof(requiredLevel) == "number" and requiredLevel >= 1 and self:GetRizzLevel(player) >= math.floor(requiredLevel)
end

return ProgressionService