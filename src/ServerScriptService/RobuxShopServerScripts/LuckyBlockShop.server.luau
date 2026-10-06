local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local ServerScriptService = game:GetService("ServerScriptService")

local LuckyBlockConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("LuckyBlockConfig"))
local LuckyBlockService = require(ServerScriptService:WaitForChild("ModuleScripts"):WaitForChild("LuckyBlockService"))
local ReceiptDispatcher = require(ServerScriptService:WaitForChild("ModuleScripts"):WaitForChild("ReceiptDispatcher"))

local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents") or Instance.new("Folder")
remotes.Name = "RemoteEvents"
remotes.Parent = ReplicatedStorage

local function getOrCreate(className, name)
	local existing = remotes:FindFirstChild(name)
	if existing then return existing end
	local instance = Instance.new(className)
	instance.Name = name
	instance.Parent = remotes
	return instance
end

local getShopListing = getOrCreate("RemoteFunction", "GetLuckyBlockShop")
local getOwnedBlocks = getOrCreate("RemoteFunction", "GetOwnedLuckyBlocks")
local openBlock = getOrCreate("RemoteFunction", "OpenLuckyBlock")
local promptPurchase = getOrCreate("RemoteEvent", "PromptLuckyBlockPurchase")

getShopListing.OnServerInvoke = function(player)
	return LuckyBlockService:GetShopListing()
end

getOwnedBlocks.OnServerInvoke = function(player)
	return LuckyBlockService:GetOwned(player)
end

openBlock.OnServerInvoke = function(player, blockId)
	return LuckyBlockService:OpenBlock(player, blockId)
end

promptPurchase.OnServerEvent:Connect(function(player, blockId)
	local block = LuckyBlockConfig.Get(blockId)
	if not block or typeof(block.ProductId) ~= "number" or block.ProductId <= 0 then return end
	MarketplaceService:PromptProductPurchase(player, block.ProductId)
end)

-- Register a ProcessReceipt handler for every configured Lucky Block product.
local productIds = {}
for _, block in pairs(LuckyBlockConfig.Blocks) do
	if typeof(block.ProductId) == "number" and block.ProductId > 0 then
		table.insert(productIds, block.ProductId)
	end
end

if #productIds > 0 then
	ReceiptDispatcher:RegisterHandler("LuckyBlockShop", productIds, function(receiptInfo, player)
		local blockId = LuckyBlockService:FindProductId(receiptInfo.ProductId)
		if not blockId then return Enum.ProductPurchaseDecision.NotProcessedYet end
		if LuckyBlockService:GrantBlock(player, blockId, 1) then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end)
end

print("[LuckyBlockShop] Ready with " .. #productIds .. " purchasable Lucky Block product(s)")
