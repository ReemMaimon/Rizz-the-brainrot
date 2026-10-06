local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotesFolder = ReplicatedStorage:FindFirstChild("RemoteEvents") or Instance.new("Folder")
remotesFolder.Name = "RemoteEvents"
remotesFolder.Parent = ReplicatedStorage

local purchaseItemRemote = remotesFolder:FindFirstChild("PurchaseItem") or Instance.new("RemoteEvent")
purchaseItemRemote.Name = "PurchaseItem"
purchaseItemRemote.Parent = remotesFolder

local getPlayerDataRemote = remotesFolder:FindFirstChild("GetPlayerData") or Instance.new("RemoteFunction")
getPlayerDataRemote.Name = "GetPlayerData"
getPlayerDataRemote.Parent = remotesFolder

local function getStats(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local function value(name)
		local object = leaderstats and leaderstats:FindFirstChild(name)
		return object and object.Value or 0
	end
	return {
		money = value("Coins"),
		coins = value("Coins"),
		rizz = value("Rizz"),
		rizzLevel = value("RizzLevel"),
		ownedTools = {},
	}
end

purchaseItemRemote.OnServerEvent:Connect(function(player)
	purchaseItemRemote:FireClient(player, {success = false, message = "The old item purchase system is disabled."})
end)

getPlayerDataRemote.OnServerInvoke = function(player)
	return getStats(player)
end