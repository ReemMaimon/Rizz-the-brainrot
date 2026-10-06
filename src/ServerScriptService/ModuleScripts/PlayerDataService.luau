local Players = game:GetService("Players")

local PlayerDataService = {}
local states = {}
local levelUpEvent = Instance.new("BindableEvent")
PlayerDataService.OnRizzLevelUp = levelUpEvent.Event

local function isFiniteNumber(value)
	return typeof(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function clampNumber(value, minimum)
	if not isFiniteNumber(value) then return minimum end
	return math.max(minimum, value)
end

function PlayerDataService:Register(player, data)
	if not player or states[player] then return false end
	data = typeof(data) == "table" and data or {}
	data.OwnedAbilities = typeof(data.OwnedAbilities) == "table" and data.OwnedAbilities or {}
	data.EquippedAbilities = typeof(data.EquippedAbilities) == "table" and data.EquippedAbilities or {}
	data.LuckyBlocks = typeof(data.LuckyBlocks) == "table" and data.LuckyBlocks or {}
	data.RawPower = clampNumber(data.RawPower, 0)
	states[player] = {Data = data, Loaded = true}
	return true
end

function PlayerDataService:IsLoaded(player)
	return states[player] ~= nil and states[player].Loaded == true
end

function PlayerDataService:Get(player)
	local state = states[player]
	return state and state.Data or nil
end

function PlayerDataService:Update(player, key, value)
	local data = self:Get(player)
	if not data then return false end
	if key == "Coins" or key == "Rizz" or key == "RizzLevel" then
		if not isFiniteNumber(value) then return false end
		value = math.max(0, math.floor(value))
	elseif key == "RawPower" then
		if not isFiniteNumber(value) then return false end
		value = math.max(0, value)
	end
	data[key] = value
	return true
end

function PlayerDataService:EnsureAbilityData(player, maxSlots)
	local data = self:Get(player)
	if not data then return nil end
	data.OwnedAbilities = typeof(data.OwnedAbilities) == "table" and data.OwnedAbilities or {}
	data.EquippedAbilities = typeof(data.EquippedAbilities) == "table" and data.EquippedAbilities or {}
	maxSlots = math.max(1, math.floor(tonumber(maxSlots) or 4))
	for slot = 1, maxSlots do
		if data.EquippedAbilities[slot] ~= nil and typeof(data.EquippedAbilities[slot]) ~= "string" then
			data.EquippedAbilities[slot] = nil
		end
	end
	return data
end

-- Returns the player's {blockId = count} table of unopened Lucky Blocks, live (mutate in place).
function PlayerDataService:EnsureLuckyBlockData(player)
	local data = self:Get(player)
	if not data then return nil end
	data.LuckyBlocks = typeof(data.LuckyBlocks) == "table" and data.LuckyBlocks or {}
	return data.LuckyBlocks
end

function PlayerDataService:Unregister(player)
	states[player] = nil
end

function PlayerDataService:Validate(raw, defaults, dataVersion)
	local source = typeof(raw) == "table" and raw or {}
	local result = {}
	for key, defaultValue in pairs(defaults) do
		local value = source[key]
		if typeof(defaultValue) == "number" then
			result[key] = clampNumber(value, defaultValue)
		else
			result[key] = typeof(value) == typeof(defaultValue) and value or defaultValue
		end
	end
	result.DataVersion = dataVersion
	return result
end

function PlayerDataService:CreateValues(player, data)
	local leaderstats = player:FindFirstChild("leaderstats") or Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	local function ensureInt(name, value)
		local object = leaderstats:FindFirstChild(name) or Instance.new("IntValue")
		object.Name = name
		object.Value = math.max(0, math.floor(value))
		object.Parent = leaderstats
		return object
	end
	ensureInt("Coins", data.Coins)
	ensureInt("Rizz", data.Rizz)
	ensureInt("RizzLevel", data.RizzLevel)
	player:SetAttribute("DataLoaded", true)
	player:SetAttribute("RawPower", math.max(0, data.RawPower or 0))
	return leaderstats
end

function PlayerDataService:SyncFromValues(player)
	local data = self:Get(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not data or not leaderstats then return false end
	for _, key in ipairs({"Coins", "Rizz", "RizzLevel"}) do
		local value = leaderstats:FindFirstChild(key)
		if value and isFiniteNumber(value.Value) then data[key] = math.max(0, math.floor(value.Value)) end
	end
	return true
end

Players.PlayerRemoving:Connect(function(player)
	PlayerDataService:Unregister(player)
end)

return PlayerDataService