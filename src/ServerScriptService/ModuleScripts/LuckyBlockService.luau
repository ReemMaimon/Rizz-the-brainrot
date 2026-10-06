local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local LuckyBlockConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("LuckyBlockConfig"))
local RarityConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("RarityConfig"))
local BrainrotConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("BrainrotConfig"))
local WeightedRoll = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("WeightedRoll"))

local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))
local StandService = require(script.Parent:WaitForChild("StandService"))
local BrainrotWorldService = require(script.Parent:WaitForChild("BrainrotWorldService"))
local ErrorHandler = nil
pcall(function()
	ErrorHandler = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("ErrorHandler"))
end)

local LuckyBlockService = {}

local function sendNotification(player, message)
	if ErrorHandler and ErrorHandler.ShowError then
		pcall(function() ErrorHandler.ShowError(player, message) end)
	else
		print(string.format("[Notification to %s]: %s", player.Name, message))
	end
end

local function isRealProduct(productId)
	return typeof(productId) == "number" and productId > 0 and productId == math.floor(productId)
end

local productInfoCache = {}
local function getDisplayPrice(block)
	if not isRealProduct(block.ProductId) then
		return block.RobuxPrice, false
	end
	if productInfoCache[block.ProductId] then
		return productInfoCache[block.ProductId], true
	end
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfo(block.ProductId, Enum.InfoType.Product)
	end)
	if ok and info and typeof(info.PriceInRobux) == "number" then
		productInfoCache[block.ProductId] = info.PriceInRobux
		return info.PriceInRobux, true
	end
	return block.RobuxPrice, false
end

--------------------------------------------------------------------------------
-- Shop listing (with odds baked in for display)
--------------------------------------------------------------------------------

function LuckyBlockService:GetShopListing()
	local result = {}
	for _, block in ipairs(LuckyBlockConfig.GetOrdered()) do
		local price, isLivePrice = getDisplayPrice(block)
		local odds = {}
		for _, entry in ipairs(WeightedRoll.ToPercentages(block.RarityWeights)) do
			local rarityInfo = RarityConfig.Get(entry.Key)
			table.insert(odds, {
				Rarity = entry.Key,
				Percent = entry.Percent,
				Color = rarityInfo and rarityInfo.Color or {255, 255, 255},
			})
		end
		table.insert(result, {
			BlockId = block.BlockId,
			DisplayName = block.DisplayName,
			Description = block.Description,
			Style = block.Style,
			IconColor = block.IconColor,
			Price = price,
			IsLivePrice = isLivePrice,
			ProductId = block.ProductId,
			Purchasable = isRealProduct(block.ProductId),
			Odds = odds,
		})
	end
	return result
end

function LuckyBlockService:GetOwned(player)
	local owned = PlayerDataService:EnsureLuckyBlockData(player)
	if not owned then return {} end
	local result = {}
	for blockId, count in pairs(owned) do
		local block = LuckyBlockConfig.Get(blockId)
		if block and (tonumber(count) or 0) > 0 then
			table.insert(result, {
				BlockId = blockId,
				DisplayName = block.DisplayName,
				Style = block.Style,
				IconColor = block.IconColor,
				Count = math.floor(tonumber(count) or 0),
			})
		end
	end
	table.sort(result, function(a, b) return a.BlockId < b.BlockId end)
	return result
end

--------------------------------------------------------------------------------
-- Granting (called from the ReceiptDispatcher handler on a successful Robux purchase)
--------------------------------------------------------------------------------

function LuckyBlockService:GrantBlock(player, blockId, amount)
	amount = math.max(1, math.floor(tonumber(amount) or 1))
	local block = LuckyBlockConfig.Get(blockId)
	if not block then return false end
	local owned = PlayerDataService:EnsureLuckyBlockData(player)
	if not owned then return false end
	local nextCount = math.min((tonumber(owned[blockId]) or 0) + amount, LuckyBlockConfig.MaxUnopenedPerBlock)
	owned[blockId] = nextCount
	sendNotification(player, string.format("You received a %s! Open it from the Robux Shop.", block.DisplayName))
	return true
end

function LuckyBlockService:FindProductId(productId)
	for _, block in pairs(LuckyBlockConfig.Blocks) do
		if isRealProduct(block.ProductId) and block.ProductId == productId then
			return block.BlockId
		end
	end
	return nil
end

--------------------------------------------------------------------------------
-- Opening (instant grant into an open base stand)
--------------------------------------------------------------------------------

local function rollBrainrot(block)
	local rarity = WeightedRoll.Choose(block.RarityWeights)
	if not rarity then return nil end

	local pool = {}
	for _, brainrotId in ipairs(block.EligibleBrainrots or {}) do
		local definition = BrainrotConfig.Definitions[brainrotId]
		if definition and definition.Rarity == rarity and definition.Obtainable then
			table.insert(pool, brainrotId)
		end
	end
	if #pool == 0 then
		-- Rarity rolled but the tier's explicit list has nothing at that rarity; fall back to
		-- anything eligible at all rather than failing the whole open.
		for _, brainrotId in ipairs(block.EligibleBrainrots or {}) do
			local definition = BrainrotConfig.Definitions[brainrotId]
			if definition and definition.Obtainable then table.insert(pool, brainrotId) end
		end
	end
	if #pool == 0 then return nil end
	return pool[math.random(1, #pool)]
end

function LuckyBlockService:OpenBlock(player, blockId)
	if not player or not player.Parent then return {Success = false, Message = "Invalid player."} end

	local block = LuckyBlockConfig.Get(blockId)
	if not block then return {Success = false, Message = "Unknown Lucky Block."} end

	local owned = PlayerDataService:EnsureLuckyBlockData(player)
	if not owned or (tonumber(owned[blockId]) or 0) < 1 then
		return {Success = false, Message = "You don't own one of these."}
	end

	local base = BaseService:GetPlayerBase(player) or BaseService:AssignBase(player)
	if not base then return {Success = false, Message = "You don't have a base yet."} end

	local stand = StandService:GetAvailableStand(base)
	if not stand then return {Success = false, Message = "No free stand at your base — clear some space first."} end

	local brainrotId = rollBrainrot(block)
	if not brainrotId then return {Success = false, Message = "This Lucky Block has no valid Brainrots configured."} end

	local definition = BrainrotConfig.Get(brainrotId)
	local source = BrainrotWorldService:FindModelSource(definition.Rarity, definition.ModelName, "Normal")
	if not source then return {Success = false, Message = "That Brainrot's model is missing from ServerStorage."} end

	-- Lock the stand immediately so a second Open call can't double-place into it.
	stand.Occupied = true

	local model = source:Clone()
	model.Name = definition.DisplayName
	local targetPart = stand.PlaceholderPart or stand.CollectPart or stand.Instance
	local targetPosition = targetPart:IsA("BasePart") and targetPart.Position or targetPart:GetPivot().Position
	local sourcePivot = model:GetPivot()
	local boundsCFrame, boundsSize = model:GetBoundingBox()
	local boundsInPivot = sourcePivot:ToObjectSpace(boundsCFrame)
	local bottomOffset = boundsInPivot.Position.Y - boundsSize.Y * 0.5
	model:PivotTo(CFrame.new(targetPosition) * sourcePivot.Rotation * CFrame.new(0, -bottomOffset, 0))
	model.Parent = stand.Instance
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
		end
	end

	model:SetAttribute("BrainrotId", definition.BrainrotId)
	model:SetAttribute("BrainrotName", definition.DisplayName)
	model:SetAttribute("BrainrotRarity", definition.Rarity)
	model:SetAttribute("BrainrotMutation", "Normal")
	model:SetAttribute("BrainrotHP", definition.HP)
	model:SetAttribute("Purchased", true)
	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("StandId", stand.StandId)
	model:SetAttribute("FromLuckyBlock", blockId)

	StandService:AssignBrainrot(base, stand.StandId, model, definition.BrainrotId, definition)

	owned[blockId] = math.max(0, (tonumber(owned[blockId]) or 1) - 1)

	return {
		Success = true,
		BlockId = blockId,
		BrainrotId = definition.BrainrotId,
		DisplayName = definition.DisplayName,
		Rarity = definition.Rarity,
		RemainingOwned = owned[blockId],
	}
end

return LuckyBlockService
