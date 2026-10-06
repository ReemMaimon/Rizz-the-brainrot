-- ServerScript placed under a character model or rig
local root = script.Parent:FindFirstChild("HumanoidRootPart")
if not root then
	warn("HumanoidRootPart not found in: " .. tostring(script.Parent))
	return
end

-- Recursive function to weld all BaseParts
local function weldAllPartsToRoot(parent)
	for _, descendant in ipairs(parent:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant ~= root then
			-- Check if it already has a WeldConstraint to avoid duplication
			local alreadyWelded = false
			for _, child in ipairs(descendant:GetChildren()) do
				if child:IsA("WeldConstraint") and (child.Part0 == root or child.Part1 == root) then
					alreadyWelded = true
					break
				end
			end

			if not alreadyWelded then
				local weld = Instance.new("WeldConstraint")
				weld.Name = "AutoWeldToRoot"
				weld.Part0 = root
				weld.Part1 = descendant
				weld.Parent = descendant
			end
		end
	end
end

weldAllPartsToRoot(script.Parent)
