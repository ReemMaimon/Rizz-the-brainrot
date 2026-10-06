local Workspace = game:GetService("Workspace")

local StandService = {}
local baseStands = {} -- [baseInstance] = { standId = standData, ... }

local function findCollectPart(standModel)
	local collect = standModel:FindFirstChild("Collect")
	if collect and collect:IsA("BasePart") then
		return collect
	end
	for _, desc in ipairs(standModel:GetDescendants()) do
		if desc:IsA("BasePart") and desc.Name == "Collect" then
			return desc
		end
	end
	return nil
end

local function findPlaceholderPart(standModel)
	local ph = standModel:FindFirstChild("PlaceHolder")
	if ph and ph:IsA("BasePart") then
		return ph
	end
	for _, desc in ipairs(standModel:GetDescendants()) do
		if desc:IsA("BasePart") and desc.Name == "PlaceHolder" then
			return desc
		end
	end
	if standModel.PrimaryPart then
		return standModel.PrimaryPart
	end
	local part = standModel:FindFirstChildOfClass("BasePart")
	return part
end

function StandService:ScanBaseStands(baseInstance)
	if not baseInstance then return {} end
	if baseStands[baseInstance] then
		return baseStands[baseInstance]
	end

	local standsFolder = baseInstance:FindFirstChild("Stands") or baseInstance:FindFirstChild("Slots")
	local standModels = {}

	if standsFolder then
		for _, child in ipairs(standsFolder:GetChildren()) do
			if child:IsA("Model") or child:IsA("Folder") or child:IsA("BasePart") then
				table.insert(standModels, child)
			end
		end
	else
		for _, child in ipairs(baseInstance:GetChildren()) do
			if string.match(child.Name, "Stand") or string.match(child.Name, "Slot") then
				table.insert(standModels, child)
			end
		end
	end

	table.sort(standModels, function(a, b)
		local numA = tonumber(string.match(a.Name, "%d+")) or 0
		local numB = tonumber(string.match(b.Name, "%d+")) or 0
		if numA ~= numB then return numA < numB end
		return a.Name < b.Name
	end)

	local list = {}
	for index, standInst in ipairs(standModels) do
		local standId = standInst.Name
		local collectPart = findCollectPart(standInst)
		local placeholderPart = findPlaceholderPart(standInst)

		local standData = {
			StandId = standId,
			Index = index,
			Instance = standInst,
			Base = baseInstance,
			CollectPart = collectPart,
			PlaceholderPart = placeholderPart,
			Occupied = false,
			BrainrotModel = nil,
			BrainrotId = nil,
			BrainrotData = nil,
			UncollectedCoins = 0,
			UncollectedRizz = 0,
			LastIncomeTick = os.time(),
		}
		list[standId] = standData
	end

	baseStands[baseInstance] = list
	return list
end

function StandService:GetStands(baseInstance)
	if not baseInstance then return {} end
	return baseStands[baseInstance] or self:ScanBaseStands(baseInstance)
end

function StandService:GetAvailableStand(baseInstance)
	local stands = self:GetStands(baseInstance)
	local sortedList = {}
	for _, standData in pairs(stands) do
		table.insert(sortedList, standData)
	end
	table.sort(sortedList, function(a, b)
		local numA = tonumber(string.match(a.StandId, "%d+")) or 0
		local numB = tonumber(string.match(b.StandId, "%d+")) or 0
		if numA ~= numB then return numA < numB end
		return a.StandId < b.StandId
	end)

	for _, standData in ipairs(sortedList) do
		if not standData.Occupied then
			return standData
		end
	end
	return nil
end

function StandService:GetStandCount(baseInstance)
	local stands = self:GetStands(baseInstance)
	local count = 0
	for _ in pairs(stands) do
		count += 1
	end
	return count
end

function StandService:GetOccupiedCount(baseInstance)
	local stands = self:GetStands(baseInstance)
	local count = 0
	for _, stand in pairs(stands) do
		if stand.Occupied then
			count += 1
		end
	end
	return count
end

function StandService:AssignBrainrot(baseInstance, standId, brainrotModel, brainrotId, brainrotData)
	local stands = self:GetStands(baseInstance)
	local stand = stands[standId]
	if not stand then
		warn("[StandService] Stand not found:", standId)
		return false
	end

	stand.Occupied = true
	stand.BrainrotModel = brainrotModel
	stand.BrainrotId = brainrotId
	stand.BrainrotData = brainrotData
	stand.LastIncomeTick = os.time()
	return true
end

function StandService:ClearStand(baseInstance, standId)
	local stands = self:GetStands(baseInstance)
	local stand = stands[standId]
	if not stand then return false end

	if stand.BrainrotModel and stand.BrainrotModel.Parent then
		stand.BrainrotModel:Destroy()
	end
	stand.Occupied = false
	stand.BrainrotModel = nil
	stand.BrainrotId = nil
	stand.BrainrotData = nil
	stand.UncollectedCoins = 0
	stand.UncollectedRizz = 0
	return true
end

function StandService:ClearAllStands(baseInstance)
	local stands = self:GetStands(baseInstance)
	for standId, _ in pairs(stands) do
		self:ClearStand(baseInstance, standId)
	end
end

return StandService