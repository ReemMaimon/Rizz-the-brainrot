local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")
local AbilityPresentationConfig = require(script.Parent:WaitForChild("AbilityPresentationConfig"))

local VFXService = {}
local active = {}

local function rootOf(value)
	if typeof(value) ~= "Instance" then return nil end
	if value:IsA("BasePart") then return value end
	return value:FindFirstChild("HumanoidRootPart", true) or value.PrimaryPart or value:FindFirstChildWhichIsA("BasePart", true)
end

local function normalizedName(value)
	return tostring(value):lower():gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
end

local function findNamed(folder, requested)
	if not folder or type(requested) ~= "string" or requested == "" then return nil end
	local exact = folder:FindFirstChild(requested, true)
	if exact then return exact end
	local wanted = normalizedName(requested)
	for _, item in ipairs(folder:GetDescendants()) do
		if normalizedName(item.Name) == wanted then return item end
	end
	for _, item in ipairs(folder:GetDescendants()) do
		local candidate = normalizedName(item.Name)
		if candidate:sub(1, #wanted) == wanted then return item end
	end
	return nil
end

local function attachmentFor(context, attachTo, attachmentName)
	local target = attachTo == "Target" and context.Target or context.Character
	if attachTo == "Player" or attachTo == "UnderPlayer" then target = context.Player and context.Player.Character or context.Character end
	if attachTo == "Projectile" then target = context.Projectile end
	if attachTo == "Ground" then target = context.Ground or context.WorldPosition end
	if attachTo == "WorldPosition" then return context.WorldPosition end
	if typeof(target) == "Vector3" then return target end
	local root = rootOf(target)
	if not root then return nil end
	if attachmentName and attachmentName ~= "" then
		local named = root:FindFirstChild(attachmentName, true)
		if named and (named:IsA("Attachment") or named:IsA("BasePart")) then return named end
	end
	if attachTo == "UnderPlayer" and target:IsA("Model") then
		local boundsCFrame, boundsSize = target:GetBoundingBox()
		return Vector3.new(root.Position.X, boundsCFrame.Position.Y - boundsSize.Y * 0.5, root.Position.Z)
	end
	local partName = attachTo == "RootPart" and "HumanoidRootPart" or attachTo
	local part = target and target:FindFirstChild(partName, true)
	return part and (part:IsA("BasePart") and part or part.Parent) or root
end

local function setWorldPosition(instance, position)
	if typeof(position) ~= "Vector3" then return end
	if instance:IsA("Model") then instance:PivotTo(CFrame.new(position))
	elseif instance:IsA("BasePart") then instance.CFrame = CFrame.new(position)
	elseif instance:IsA("Attachment") then instance.WorldPosition = position end
end

local function forEachBasePart(container, callback)
	if container:IsA("BasePart") then callback(container) end
	for _, item in ipairs(container:GetDescendants()) do
		if item:IsA("BasePart") then callback(item) end
	end
end

local function enableEmitters(container)
	local function enable(item)
		if item:IsA("ParticleEmitter") then
			item.Enabled = true
			local count = item:GetAttribute("EmitCount")
			if count then item:Emit(math.max(0, tonumber(count) or 0)) end
		elseif item:IsA("Beam") or item:IsA("Trail") or item:IsA("PointLight") or item:IsA("Highlight") then
			item.Enabled = true
		end
	end
	enable(container)
	for _, item in ipairs(container:GetDescendants()) do enable(item) end
end

local function prepareClone(container)
	forEachBasePart(container, function(part)
		part.Anchored = false
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Massless = true
	end)
	for _, item in ipairs(container:GetDescendants()) do
		if item:IsA("Attachment") and item.Parent:IsA("BasePart") then
			item.Parent.Anchored = false
		end
	end
end

local function disableEmitters(container)
	local function disable(item)
		if item:IsA("ParticleEmitter") or item:IsA("Beam") or item:IsA("Trail") or item:IsA("PointLight") or item:IsA("Highlight") then item.Enabled = false end
	end
	disable(container)
	for _, item in ipairs(container:GetDescendants()) do disable(item) end
end

function VFXService:Play(abilityId, effectName, context, override)
	context = context or {}
	local configured = AbilityPresentationConfig.Get(abilityId, context.Presentation)
	local entry = override or configured.VFX and configured.VFX[effectName]
	if type(entry) == "string" then entry = {Effect = entry} end
	if type(entry) == "table" and (entry.Effect == nil or entry.Effect == "") and type(entry.Name) == "string" then entry = table.clone(entry); entry.Effect = entry.Name end
	if type(entry) ~= "table" or entry.Effect == nil or entry.Effect == "" then return nil end
	local folder = ReplicatedStorage:FindFirstChild("AbilityVFX")
	local template = findNamed(folder, entry.Effect)
	if not template then warn("[VFXService] Missing effect: " .. tostring(entry.Effect)); return nil end
	local clone = template:Clone()
	clone.Name = string.format("AbilityVFX_%s_%s", abilityId, effectName)
	prepareClone(clone)
	local target = attachmentFor(context, entry.AttachTo or "RootPart", entry.AttachmentName)
	local followPart
	if typeof(target) == "Instance" then
		followPart = target:IsA("Attachment") and target.Parent or target:IsA("BasePart") and target
		clone.Parent = Workspace
		local targetPosition = target:IsA("Attachment") and target.WorldPosition or target:IsA("BasePart") and target.Position
		if targetPosition then setWorldPosition(clone, targetPosition) end
		if followPart then
			forEachBasePart(clone, function(part)
				part.Anchored = false
				part.CanCollide = false
				part.CanTouch = false
				part.CanQuery = false
				part.Massless = true
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = followPart
				weld.Part1 = part
				weld.Parent = part
			end)
		end
	elseif typeof(target) == "Vector3" then
		clone.Parent = Workspace
		setWorldPosition(clone, target)
	else
		clone.Parent = Workspace
	end
	enableEmitters(clone)
	local key = tostring(context.Token or clone)
	active[key] = active[key] or {}
	table.insert(active[key], clone)
	local timingKey = effectName == "Cast" and "VFXCastLifetime" or "VFXImpactLifetime"
	local lifetime = math.max(0, tonumber(entry.Lifetime) or tonumber(configured.Timing and configured.Timing[timingKey]) or tonumber(configured.Timing and configured.Timing[effectName]) or 0)
	if lifetime > 0 then task.delay(lifetime, function() self:Stop(abilityId, effectName, context, clone) end) end
	return clone
end

function VFXService:Stop(_, _, context, specific)
	local key = tostring(context and context.Token or specific)
	local list = active[key]
	if specific then
		if specific.Parent then disableEmitters(specific); Debris:AddItem(specific, 0.05) end
		if list then for index, item in ipairs(list) do if item == specific then table.remove(list, index); break end end end
		return
	end
	if list then for _, item in ipairs(list) do if item.Parent then disableEmitters(item); Debris:AddItem(item, 0.05) end end end
	active[key] = nil
end

return VFXService