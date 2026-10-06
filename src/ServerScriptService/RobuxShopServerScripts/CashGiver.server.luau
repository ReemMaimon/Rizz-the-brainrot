local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Developer Product rewards
local CoinProducts = {
	[3305375330] = 2000,       -- $2K
	[3305375589] = 20000,      -- $20K
	[3305375873] = 50000,      -- $50K
	[3305376210] = 200000,     -- $200K
	[3305376873] = 2000000     -- $2M
}

-- Track already handled purchases
local purchaseHistory = {}

-- Handle product purchase
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if purchaseHistory[receiptInfo.PurchaseId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local reward = CoinProducts[receiptInfo.ProductId]
	if reward then
		local stats = player:FindFirstChild("leaderstats")
		local coins = stats and stats:FindFirstChild("Coins")
		if coins then
			coins.Value += reward
			purchaseHistory[receiptInfo.PurchaseId] = true
			print("✅ Gave "..reward.." Coins to "..player.Name)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	warn("❌ Failed to grant Developer Product Coins: "..tostring(receiptInfo.ProductId))
	return Enum.ProductPurchaseDecision.NotProcessedYet
end
