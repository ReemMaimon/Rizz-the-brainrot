local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local BaseService = {}
local StandService = require(script.Parent:WaitForChild("StandService"))

local bases = {} -- array of Base instances
local playerBases = {} -- [player] = baseInstance
local baseOwners = {} -- [baseInstance] = player

function BaseService:DiscoverBases()
	bases = {}
	local basesFolder = Workspace:FindFirstChild("Bases") or Workspace:FindFirstChild("BaseFolder")
	if basesFolder then
		for _, child in ipairs(basesFolder:GetChildren()) do
			if child:IsA("Folder") or child:IsA("Model") then
				table.insert(bases, child)
				StandService:ScanBaseStands(child)
			end
		end
	else
		for _, child in ipairs(Workspace:GetChildren()) do
			if string.match(child.Name, "Base%d+") then
				table.insert(bases, child)
				StandService:ScanBaseStands(child)
			end
		end
	end

	table.sort(bases, function(a, b)
		local numA = tonumber(string.match(a.Name, "%d+")) or 0
		local numB = tonumber(string.match(b.Name, "%d+")) or 0
		if numA ~= numB then return numA < numB end
		return a.Name < b.Name
	end)

	print(string.format("[BaseService] Discovered %d bases dynamically.", #bases))
	return bases
end

function BaseService:GetBases()
	if #bases == 0 then
		return self:DiscoverBases()
	end
	return bases
end

function BaseService:GetPlayerBase(player)
	if not player then return nil end
	return playerBases[player]
end

function BaseService:GetBaseOwner(baseInstance)
	if not baseInstance then return nil end
	return baseOwners[baseInstance]
end

function BaseService:AssignBase(player, baseNumber)
	if not player or not player.Parent then return nil end
	if playerBases[player] then
		return playerBases[player]
	end

	self:GetBases()

	local function claimBase(base)
		baseOwners[base] = player
		playerBases[player] = base

		local ownerVal = base:FindFirstChild("Owner")
		if not ownerVal then
			ownerVal = Instance.new("ObjectValue")
			ownerVal.Name = "Owner"
			ownerVal.Parent = base
		end
		ownerVal.Value = player

		local ownedBaseVal = player:FindFirstChild("OwnedBase")
		if not ownedBaseVal then
			ownedBaseVal = Instance.new("IntValue")
			ownedBaseVal.Name = "OwnedBase"
			ownedBaseVal.Parent = player
		end
		local num = tonumber(string.match(base.Name, "%d+")) or 1
		ownedBaseVal.Value = num

		print(string.format("[BaseService] Assigned %s to player %s", base.Name, player.Name))
		return base
	end

	-- A specific base was claimed at a collect-zone pad: it must be free
	if baseNumber then
		local targetName = "Base" .. baseNumber
		for _, base in ipairs(bases) do
			if base.Name == targetName and not baseOwners[base] then
				return claimBase(base)
			end
		end
		return nil
	end

	for _, base in ipairs(bases) do
		if not baseOwners[base] then
			return claimBase(base)
		end
	end

	warn(string.format("[BaseService] No available bases for player %s", player.Name))
	return nil
end

function BaseService:ReleaseBase(player)
	if not player then return end
	local base = playerBases[player]
	if base then
		print(string.format("[BaseService] Releasing %s from player %s", base.Name, player.Name))
		baseOwners[base] = nil
		playerBases[player] = nil

		local ownerVal = base:FindFirstChild("Owner")
		if ownerVal then
			ownerVal.Value = nil
		end

		StandService:ClearAllStands(base)
	end
end

Players.PlayerRemoving:Connect(function(player)
	BaseService:ReleaseBase(player)
end)

return BaseService