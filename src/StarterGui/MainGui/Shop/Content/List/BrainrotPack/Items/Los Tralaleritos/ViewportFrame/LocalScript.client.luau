-- Baby God ViewportFrame Setup Script
-- Put this script as a child of your ViewportFrame

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get the ViewportFrame (this script should be a child of it)
local ViewportFrame = script.Parent

-- Set ViewportFrame size and position
ViewportFrame.Size = UDim2.new(1.6, 0, 1.6, 0)
ViewportFrame.Position = UDim2.new(0.5, 0, 0.2, 0)

-- Configuration
local Config = {
	RotationEnabled = true,
	RotationSpeed = 30, -- degrees per second
	FAR_POSITION = Vector3.new(0, 10000, 0) -- Position to avoid physics interactions
}

-- Function to scale model
local function scaleModel(model, scaleFactor)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Size = part.Size * scaleFactor
			part.Position = part.Position * scaleFactor
		elseif part:IsA("Attachment") then
			part.Position = part.Position * scaleFactor
		end
	end
end

-- Function to setup the Baby God model
local function setupBabyGod()
	-- Get the Baby God model
	local Baby3DFolder = ReplicatedStorage:WaitForChild("Baby3D")
	local BabyGodModel = Baby3DFolder:FindFirstChild("Los_Tralaleritos")

	if not BabyGodModel then
		warn("BABY_GOD model not found in ReplicatedStorage.Baby3D")
		return nil
	end

	-- Clear any existing content in the ViewportFrame
	for _, child in pairs(ViewportFrame:GetChildren()) do
		if child.Name ~= "UICorner" and child.Name ~= "UIStroke" and not child:IsA("UIBase") then
			child:Destroy()
		end
	end

	-- Clone the model
	local modelClone = BabyGodModel:Clone()

	-- Scale down by 0.5x (make it 2x smaller)
	scaleModel(modelClone, 0.5)

	-- Create and setup camera
	local camera = Instance.new("Camera")
	camera.Parent = ViewportFrame
	ViewportFrame.CurrentCamera = camera

	-- Setup model primary part
	local basePrimaryPart = modelClone.PrimaryPart
	if not basePrimaryPart then
		modelClone.PrimaryPart = modelClone:FindFirstChildWhichIsA("BasePart", true)
	end

	-- Move model to far position to avoid physics interactions
	if modelClone.PrimaryPart then
		modelClone:SetPrimaryPartCFrame(
			CFrame.new(Config.FAR_POSITION - modelClone.PrimaryPart.Position) * modelClone.PrimaryPart.CFrame
		)
		modelClone.PrimaryPart = basePrimaryPart
	end

	-- Parent the model to the ViewportFrame
	modelClone.Parent = ViewportFrame

	-- Function to update camera position
	local function updateCamera(rotationAngle)
		rotationAngle = rotationAngle or 0

		local boundingCFrame, boundingSize = modelClone:GetBoundingBox()
		local modelCenter = boundingCFrame.Position
		local maxSize = math.max(boundingSize.X, boundingSize.Y, boundingSize.Z)

		local depthMultiplier = 1.2
		local distanceBack = (maxSize / math.tan(math.rad(camera.FieldOfView))) * depthMultiplier

		local center = CFrame.new(modelCenter)
		local cframeOffset = CFrame.Angles(0, math.rad(-180) + rotationAngle, 0)

		camera.CFrame = center * cframeOffset * CFrame.new(0, 0, (maxSize / 2) + distanceBack)
		camera.Focus = center
	end

	-- Initial camera setup
	updateCamera()

	-- Setup rotation if enabled
	local rotationConnection = nil
	if Config.RotationEnabled then
		local startTime = tick()

		rotationConnection = RunService.Heartbeat:Connect(function()
			if not modelClone or not modelClone.Parent or not camera then
				if rotationConnection then
					rotationConnection:Disconnect()
				end
				return
			end

			local elapsed = tick() - startTime
			local rotationAngle = elapsed * math.rad(Config.RotationSpeed)

			local success = pcall(function()
				updateCamera(rotationAngle)
			end)

			if not success and rotationConnection then
				rotationConnection:Disconnect()
			end
		end)
	end

	return {
		model = modelClone,
		camera = camera,
		updateCamera = updateCamera,
		rotationConnection = rotationConnection
	}
end

-- Setup the Baby God model
local babyGodData = setupBabyGod()

-- Cleanup when script is removed
script.AncestryChanged:Connect(function()
	if not script.Parent then
		if babyGodData and babyGodData.rotationConnection then
			babyGodData.rotationConnection:Disconnect()
		end
		if babyGodData and babyGodData.model then
			babyGodData.model:Destroy()
		end
	end
end)
