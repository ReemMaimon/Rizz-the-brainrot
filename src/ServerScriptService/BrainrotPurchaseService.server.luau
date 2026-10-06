local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BrainrotConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("BrainrotConfig"))
local CurrencyService = require(script.Parent:WaitForChild("ModuleScripts"):WaitForChild("CurrencyService"))
local defeatedFolder = Workspace:WaitForChild("DefeatedBrainrots")
local promptName = "PurchaseBrainrotPrompt"
local bound = {}
local cooldowns = {}

local function getRoot(model)
	return model and (model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart", true))
end

local function getCost(model)
	local configured = tonumber(model:GetAttribute("BrainrotPurchaseCost"))
	if configured then return math.max(1, math.floor(configured)) end
	local definition = BrainrotConfig.Get(model:GetAttribute("BrainrotId"))
	return math.max(1, math.floor(tonumber(definition and definition.PurchaseCost) or 100))
end

local function findAvailableStand(base)
	local stands = base and base:FindFirstChild("Stands")
	if not stands then return nil end
	local standNames = {}
	for _, child in stands:GetChildren() do
		local number = tonumber(string.match(child.Name, "^Stand(%d+)$"))
		if child:IsA("Model") and number then
			table.insert(standNames, {number = number, stand = child})
		end
	end
	table.sort(standNames, function(a, b) return a.number < b.number end)
	for _, entry in ipairs(standNames) do
		local stand = entry.stand
		local placeholder = stand:FindFirstChild("PlaceHolder")
		if placeholder then
			local occupied = false
			for _, child in stand:GetChildren() do
				if child:IsA("Model") and child ~= stand then
					occupied = true
					break
				end
			end
			if not occupied then return stand, placeholder, entry.number end
		end
	end
	return nil
end

local function moveIntoBase(player, model)
	local ownedBase = player:FindFirstChild("OwnedBase")
	local bases = Workspace:FindFirstChild("Bases")
	local base = ownedBase and bases and bases:FindFirstChild("Base" .. tostring(ownedBase.Value))
	local touchingPart = base and base:FindFirstChild("TouchingPart")
	local stand, placeholder, standNumber = findAvailableStand(base)
	if not base or not touchingPart or not stand or not placeholder then return false end

	local currentPivot, bounds = model:GetBoundingBox()
	local bottomOffset = currentPivot.Position.Y - bounds.Y / 2
	local target = placeholder.Position + Vector3.new(0, placeholder.Size.Y / 2 + (currentPivot.Position.Y - bottomOffset) + 0.1, 0)
	local start = model:GetPivot()
	local distance = (touchingPart.Position - start.Position).Magnitude
	local duration = math.max(1, distance / 8)
	local startedAt = os.clock()
	while model:IsDescendantOf(defeatedFolder) and os.clock() - startedAt < duration do
		local alpha = math.clamp((os.clock() - startedAt) / duration, 0, 1)
		model:PivotTo(start:Lerp(CFrame.new(target), alpha))
		task.wait(0.05)
	end
	if not model:IsDescendantOf(defeatedFolder) then return false end
	model:PivotTo(CFrame.new(target))
	model.Parent = stand
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
		end
	end

	local owner = Instance.new("ObjectValue")
	owner.Name = "Owner"
	owner.Value = player
	owner.Parent = model
	local standValue = Instance.new("IntValue")
	standValue.Name = "StandNumber"
	standValue.Value = standNumber
	standValue.Parent = model
	local inBase = Instance.new("BoolValue")
	inBase.Name = "InBase"
	inBase.Value = true
	inBase.Parent = model
	return true
end

local function getBrainrotModel(instance)
	local model = instance and instance:FindFirstAncestorOfClass("Model")
	while model and model.Parent ~= defeatedFolder do
		model = model.Parent and model.Parent:FindFirstAncestorOfClass("Model")
	end
	return model
end

local function isPurchasePrompt(prompt)
	return prompt:IsA("ProximityPrompt") and (prompt.Name == promptName or prompt.Name == "PurchasePrompt" or prompt:GetAttribute("BrainrotPurchasePrompt") == true)
end

local function attemptPurchase(player, model, prompt)
	if not player or not player.Parent or not model or not model:IsDescendantOf(defeatedFolder) then return end
	local now = os.clock()
	local key = player.UserId .. ":" .. model:GetDebugId()
	if now - (cooldowns[key] or 0) < 1 then return end
	cooldowns[key] = now
	if model:GetAttribute("DeliveredBrainrot") ~= true or model:GetAttribute("PurchaseInProgress") == true then return end

	local root = getRoot(model)
	local playerRoot = getRoot(player.Character)
	if not playerRoot or not root or (playerRoot.Position - root.Position).Magnitude > prompt.MaxActivationDistance + 3 then return end

	local cost = getCost(model)
	if not CurrencyService:HasCoins(player, cost) then
		warn(string.format("[BrainrotPurchaseService] %s needs %d Coins for %s", player.Name, cost, tostring(model:GetAttribute("BrainrotName"))))
		return
	end
	if not CurrencyService:RemoveCoins(player, cost) then return end

	prompt.Enabled = false
	model:SetAttribute("PurchaseInProgress", true)
	if not moveIntoBase(player, model) then
		model:SetAttribute("PurchaseInProgress", false)
		prompt.Enabled = true
		CurrencyService:AddCoins(player, cost)
		return
	end
	local name = tostring(model:GetAttribute("BrainrotName") or model.Name)
	if _G.DataManager and _G.DataManager.addToAllTimeBabies then
		_G.DataManager.addToAllTimeBabies(player, name)
	end
	model:SetAttribute("PurchasedByUserId", player.UserId)
	print(string.format("[BrainrotPurchaseService] %s purchased %s for %d Coins", player.Name, name, cost))
end

local function bind(model)
	if not model or not model:IsA("Model") or not model:IsDescendantOf(defeatedFolder) or bound[model] then return end
	local prompt
	for _, descendant in model:GetDescendants() do
		if isPurchasePrompt(descendant) then
			prompt = descendant
			break
		end
	end
	if not prompt then return end
	bound[model] = prompt
	prompt.Triggered:Connect(function(player)
		attemptPurchase(player, model, prompt)
	end)
end

defeatedFolder.ChildAdded:Connect(function(model)
	task.defer(bind, model)
end)
defeatedFolder.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("ProximityPrompt") and isPurchasePrompt(descendant) then
		task.defer(function()
			local model = getBrainrotModel(descendant)
			if model then bind(model) end
		end)
	end
end)
ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
	if not isPurchasePrompt(prompt) or not prompt:IsDescendantOf(defeatedFolder) then return end
	local model = getBrainrotModel(prompt)
	if model then
		if bound[model] ~= prompt then bind(model) end
		attemptPurchase(player, model, prompt)
	end
end)
for _, descendant in defeatedFolder:GetDescendants() do
	if descendant:IsA("Model") then bind(descendant) end
end
Players.PlayerRemoving:Connect(function(player)
	local prefix = player.UserId .. ":"
	for key in pairs(cooldowns) do
		if string.sub(key, 1, #prefix) == prefix then cooldowns[key] = nil end
	end
end)
print("[BrainrotPurchaseService] BUY button ready; purchased Brainrots walk into the first available base stand")