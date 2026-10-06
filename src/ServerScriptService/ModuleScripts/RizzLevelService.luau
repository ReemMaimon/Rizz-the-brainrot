local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))

local RizzLevelService = {}

local function finiteNumber(value, fallback)
	if typeof(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then return fallback end
	return value
end

function RizzLevelService:GetRizzLevel(player)
	if not player then return 0 end
	local leaderstats = player:FindFirstChild("leaderstats")
	local levelValue = leaderstats and leaderstats:FindFirstChild("RizzLevel")
	local level = finiteNumber(levelValue and levelValue.Value, nil)
	if level == nil then
		local data = PlayerDataService:Get(player)
		level = finiteNumber(data and data.RizzLevel, nil)
	end
	return math.max(0, math.floor(level or 0))
end

return RizzLevelService