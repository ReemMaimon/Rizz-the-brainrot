local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BrainrotConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("BrainrotConfig"))
local BrainrotPurchaseService = require(script.Parent:WaitForChild("ModuleScripts"):WaitForChild("BrainrotPurchaseService"))
local defeatedFolder = Workspace:FindFirstChild("DefeatedBrainrots") or Instance.new("Folder")
defeatedFolder.Name = "DefeatedBrainrots"
defeatedFolder.Parent = Workspace

local gate = Workspace:FindFirstChild("BrainrotGate")
local carpet = Workspace:FindFirstChild("MovingOn")
local deliverySpeed = 3

if not carpet then
	warn("[BrainrotVictoryDelivery] MovingOn was not found at startup; waiting for it to appear")
	Workspace.ChildAdded:Connect(function(child)
		if child.Name == "MovingOn" and child:IsA("BasePart") then
			carpet = child
			print("[BrainrotVictoryDelivery] MovingOn detected")
		end
	end)
end
local movingOnOffset = 0

local function getPart(instance)
	if not instance then return nil end
	if instance:IsA("BasePart") then return instance end
	return instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart", true)
end

local function removePrompts(model)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("ProximityPrompt") then
			descendant:Destroy()
		end
	end
end

local function disablePrompts(model)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("ProximityPrompt") then
			descendant.Enabled = false
		end
	end
end

local function addPurchasePrompt(model, definition)
	if not getPart(model) then
		warn("[BrainrotVictoryDelivery] Cannot add BUY prompt; Brainrot has no BasePart: " .. model.Name)
		return
	end
	removePrompts(model)
	local prompt = BrainrotPurchaseService:SetupPurchasePrompt(model, definition)
	if prompt then
		prompt.Enabled = true
		prompt.MaxActivationDistance = 24
		prompt.RequiresLineOfSight = false
		print("[BrainrotVictoryDelivery] BUY prompt enabled for " .. model.Name)
	else
		warn("[BrainrotVictoryDelivery] BUY prompt was not created for " .. model.Name)
	end
end

local function getPathPoint(pathPart, model, localX)
	local pivot = model:GetPivot()
	local _, bounds = model:GetBoundingBox()
	local pathTop = pathPart.Position.Y + pathPart.Size.Y * 0.5
	local modelCenterY = pathTop + bounds.Y * 0.5 + movingOnOffset
	local localPoint = Vector3.new(localX, 0, 0)
	local worldPoint = pathPart.CFrame:PointToWorldSpace(localPoint)
	worldPoint = Vector3.new(worldPoint.X, modelCenterY, worldPoint.Z)
	return CFrame.new(worldPoint) * pivot.Rotation
end

local function sendToCarpet(model)
	if not model or not model.Parent then return end
	local gatePart = getPart(gate)
	local carpetPart = getPart(carpet)
	if not gatePart or not carpetPart then
		warn("[BrainrotVictoryDelivery] BrainrotGate or MovingOn is missing")
		model:Destroy()
		return
	end

	local definition = BrainrotConfig.Get(model:GetAttribute("BrainrotId")) or BrainrotConfig.GetByModelName(model.Name)
	if not definition then
		warn("[BrainrotVictoryDelivery] Missing BrainrotConfig definition for " .. model.Name)
		model:Destroy()
		return
	end
	removePrompts(model)
	model.Parent = defeatedFolder
	model:SetAttribute("DeliveryPathActive", true)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
		end
	end

	local halfLength = math.max(0, carpetPart.Size.X * 0.5 - 1)
	local positiveEnd = carpetPart.CFrame:PointToWorldSpace(Vector3.new(halfLength, 0, 0))
	local negativeEnd = carpetPart.CFrame:PointToWorldSpace(Vector3.new(-halfLength, 0, 0))
	local startX, destinationX
	if (positiveEnd - gatePart.Position).Magnitude <= (negativeEnd - gatePart.Position).Magnitude then
		startX, destinationX = halfLength, -halfLength
	else
		startX, destinationX = -halfLength, halfLength
	end

	local start = getPathPoint(carpetPart, model, startX)
	local destination = getPathPoint(carpetPart, model, destinationX)
	model:PivotTo(start)
	model:SetAttribute("BrainrotMovingToMovingOn", true)

	local distance = (destination.Position - start.Position).Magnitude
	local travelTime = math.max(4, distance / math.max(0.5, deliverySpeed))
	local startedAt = os.clock()
	while model.Parent and os.clock() - startedAt < travelTime do
		local alpha = math.clamp((os.clock() - startedAt) / travelTime, 0, 1)
		model:PivotTo(start:Lerp(destination, alpha))
		task.wait(0.05)
	end
	if model.Parent then
		model:PivotTo(destination)
		model.Parent = defeatedFolder
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.Anchored = true
				descendant.CanCollide = false
			end
		end
		model:SetAttribute("BrainrotMovingToMovingOn", false)
		model:SetAttribute("DeliveryPathActive", false)
		model:SetAttribute("DeliveredBrainrot", true)
		model:SetAttribute("BrainrotPurchaseCost", math.max(1, math.floor(tonumber(definition.PurchaseCost) or 100)))
		addPurchasePrompt(model, definition)
	end
end

local function handleVictory(player, battle, status)
	if status ~= "Victory" or not battle or battle.ResultHandled then return end
	battle.ResultHandled = true
	local model = battle.Brainrot
	if model and model.Parent then
		disablePrompts(model)
		task.spawn(sendToCarpet, model)
	end
end

local BattleService = require(script.Parent:WaitForChild("ModuleScripts"):WaitForChild("BattleService"))
BattleService.Finished.Event:Connect(handleVictory)
print("[BrainrotVictoryDelivery] Brainrots walk along MovingOn and show a BUY prompt after victory")