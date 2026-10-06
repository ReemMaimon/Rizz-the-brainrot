local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- PRODUCT IDs
local killAllProductId = 3306045903
local giveToolProductId = 3306052966

-- Ensure RemoteEvent exists
local KillAllEvent = ReplicatedStorage:FindFirstChild("KillAll") or Instance.new("RemoteEvent", ReplicatedStorage)
KillAllEvent.Name = "KillAll"

local GiveToolEvent = ReplicatedStorage:FindFirstChild("GiveTool") or Instance.new("RemoteEvent", ReplicatedStorage)
GiveToolEvent.Name = "GiveTool"

-- Studio test for KillAll
KillAllEvent.OnServerEvent:Connect(function(player)
	if RunService:IsStudio() then
		for _, target in ipairs(Players:GetPlayers()) do
			if target.Character and target.Character:FindFirstChild("Humanoid") then
				target.Character.Humanoid.Health = 0
			end
		end
	end
end)

-- Studio test for GiveTool
GiveToolEvent.OnServerEvent:Connect(function(player)
	if RunService:IsStudio() then
		local tool = ServerStorage:WaitForChild("Tools"):FindFirstChild("Flying Carpet")
		if tool then
			local clone = tool:Clone()
			clone.Parent = player:FindFirstChild("Backpack") or player
		end
	end
end)

-- Handle Developer Product receipts securely
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if receiptInfo.ProductId == killAllProductId then
		for _, target in ipairs(Players:GetPlayers()) do
			if target.Character and target.Character:FindFirstChild("Humanoid") then
				target.Character.Humanoid.Health = 0
			end
		end
		return Enum.ProductPurchaseDecision.PurchaseGranted

	elseif receiptInfo.ProductId == giveToolProductId then
		local tool = ServerStorage:WaitForChild("Tools"):FindFirstChild("Flying Carpet")
		if tool then
			local clone = tool:Clone()
			clone.Parent = player:FindFirstChild("Backpack") or player
		end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end
