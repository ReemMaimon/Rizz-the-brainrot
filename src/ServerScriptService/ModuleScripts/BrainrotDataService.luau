local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("BrainrotConfig"))
local StandService = require(script.Parent:WaitForChild("StandService"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))

local BrainrotDataStore = nil
pcall(function()
	BrainrotDataStore = DataStoreService:GetDataStore("PlayerBrainrots_v1")
end)

local BrainrotDataService = {}

local function findBrainrotTemplate(modelName, brainrotId)
	local raritiesFolder = ServerStorage:FindFirstChild("BrainrotsRarities")
	if raritiesFolder then
		for _, folder in ipairs(raritiesFolder:GetChildren()) do
			local template = folder:FindFirstChild(modelName) or folder:FindFirstChild(brainrotId)
			if template then return template end
		end
	end
	return nil
end

local function spawnStandBrainrotModel(brainrotId, standData)
	local def = BrainrotConfig.Get(brainrotId)
	if not def then return nil end

	local template = findBrainrotTemplate(def.ModelName or def.BrainrotId, def.BrainrotId)
	local model = nil

	if template then
		model = template:Clone()
	else
		model = Instance.new("Model")
		model.Name = def.DisplayName or brainrotId
		local part = Instance.new("Part")
		part.Name = "HumanoidRootPart"
		part.Size = Vector3.new(2, 4, 2)
		part.Anchored = true
		part.CanCollide = false
		part.Parent = model
		model.PrimaryPart = part
	end

	local targetPart = standData.PlaceholderPart or standData.CollectPart or standData.Instance
	local targetPos = targetPart:IsA("BasePart") and (targetPart.Position + Vector3.new(0, 1.5, 0)) or targetPart:GetPivot().Position

	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = true
		end
	end

	model:PivotTo(CFrame.new(targetPos))
	model.Parent = standData.Instance
	return model
end

function BrainrotDataService:LoadPlayerBrainrots(player, base)
	if not BrainrotDataStore or not player then return end

	local key = "Brainrots_" .. tostring(player.UserId)
	local success, savedData = pcall(function()
		return BrainrotDataStore:GetAsync(key)
	end)

	if success and typeof(savedData) == "table" then
		print(string.format("[BrainrotDataService] Loaded %d brainrots for %s", #savedData, player.Name))
		local stands = StandService:GetStands(base)

		for _, item in ipairs(savedData) do
			local stand = stands[item.StandId]
			if stand and not stand.Occupied then
				local def = BrainrotConfig.Get(item.BrainrotId)
				if def then
					local model = spawnStandBrainrotModel(item.BrainrotId, stand)
					StandService:AssignBrainrot(base, item.StandId, model, item.BrainrotId, def)
					stand.UncollectedCoins = tonumber(item.UncollectedCoins) or 0
					stand.UncollectedRizz = tonumber(item.UncollectedRizz) or 0
				end
			end
		end
	end
end

function BrainrotDataService:SavePlayerBrainrots(player)
	if not BrainrotDataStore or not player then return end

	local base = BaseService:GetPlayerBase(player)
	if not base then return end

	local stands = StandService:GetStands(base)
	local dataToSave = {}

	for standId, standData in pairs(stands) do
		if standData.Occupied and standData.BrainrotId then
			table.insert(dataToSave, {
				StandId = standId,
				BrainrotId = standData.BrainrotId,
				UncollectedCoins = standData.UncollectedCoins or 0,
				UncollectedRizz = standData.UncollectedRizz or 0,
			})
		end
	end

	local key = "Brainrots_" .. tostring(player.UserId)
	pcall(function()
		BrainrotDataStore:SetAsync(key, dataToSave)
	end)
	print(string.format("[BrainrotDataService] Saved %d brainrots for %s", #dataToSave, player.Name))
end

Players.PlayerRemoving:Connect(function(player)
	BrainrotDataService:SavePlayerBrainrots(player)
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		BrainrotDataService:SavePlayerBrainrots(player)
	end
end)

return BrainrotDataService