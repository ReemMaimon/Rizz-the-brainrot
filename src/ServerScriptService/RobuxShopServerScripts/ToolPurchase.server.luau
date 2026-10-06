-- Server Script - Tool Purchase Handler (Developer Products)
-- Place this in ServerScriptService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

-- ======== CONFIGURATION ========
local TOOL_PRODUCTS = {
	["Blackhole Slap"] = {id = 3309234502, price = "199"},
	["Flying Carpet"] = {id = 3306052966, price = "9"},
	["Lazer Gun"] = {id = 3309235011, price = "49"},
	["Ban Hammer"] = {id = 3309235456, price = "99"}
}

-- Create or get the RemoteEvent
local toolPurchaseEvent = ReplicatedStorage:FindFirstChild("ToolPurchaseEvent")
if not toolPurchaseEvent then
	toolPurchaseEvent = Instance.new("RemoteEvent")
	toolPurchaseEvent.Name = "ToolPurchaseEvent"
	toolPurchaseEvent.Parent = ReplicatedStorage
end

-- Function to give actual tool to player
local function giveActualTool(player, toolName)
	local tool = nil

	-- Look for the tool in ReplicatedStorage first
	tool = ReplicatedStorage:FindFirstChild(toolName)
	if not tool then
		-- Look in ServerStorage root
		local ServerStorage = game:GetService("ServerStorage")
		tool = ServerStorage:FindFirstChild(toolName)
	end
	if not tool then
		-- Look in ServerStorage > Tools folder
		local ServerStorage = game:GetService("ServerStorage")
		local toolsFolder = ServerStorage:FindFirstChild("Tools")
		if toolsFolder then
			tool = toolsFolder:FindFirstChild(toolName)
		end
	end
	if not tool then
		-- Look in ServerStorage > Babies folder
		local ServerStorage = game:GetService("ServerStorage")
		local babiesFolder = ServerStorage:FindFirstChild("Babies")
		if babiesFolder then
			tool = babiesFolder:FindFirstChild(toolName)
		end
	end

	if tool and tool:IsA("Tool") then
		-- Clone the tool to player's backpack
		local toolClone = tool:Clone()
		toolClone.Parent = player.Backpack
		return true
	else
		warn("Tool not found: " .. toolName)
		return false
	end
end

-- Function to get tool name from product ID
local function getToolNameFromProductId(productId)
	for toolName, toolData in pairs(TOOL_PRODUCTS) do
		if toolData.id == productId then
			return toolName
		end
	end
	return nil
end

-- Handle developer product purchases
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		-- Player left, grant purchase later
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local productId = receiptInfo.ProductId
	local toolName = getToolNameFromProductId(productId)

	if toolName then
		-- Give the tool
		local success = giveActualTool(player, toolName)
		if success then
			-- Notify client for animation
			toolPurchaseEvent:FireClient(player, true, toolName)
			-- Purchase processed successfully
			return Enum.ProductPurchaseDecision.PurchaseGranted
		else
			-- Failed to give tool, try again later
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
	end

	-- Unknown product
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- Handle client requests (simplified)
toolPurchaseEvent.OnServerEvent:Connect(function(player, action, toolName)
	if action == "testGiveTool" and toolName then
		-- Debug function to test tool giving
		local success = giveActualTool(player, toolName)
		if success then
			toolPurchaseEvent:FireClient(player, true, toolName)
		end
	end
end)