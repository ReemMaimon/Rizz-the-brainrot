-- BaseManagerBootstrap - bases are CLAIMED by players at the green collect-zone pad (hold E)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModuleScripts = script.Parent:WaitForChild("ModuleScripts")
local BaseManager = require(ModuleScripts:WaitForChild("BaseManager"))
local PlayerManager = require(ModuleScripts:WaitForChild("PlayerManager"))
local GameUtilities = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("GameUtilities"))
local UIManager = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("UIManager"))
local CollectionManager = require(ModuleScripts:WaitForChild("CollectionManager"))

local basesFolder = Workspace:WaitForChild("Bases")

BaseManager.basesFolder = basesFolder
BaseManager.soundRemote = ReplicatedStorage:FindFirstChild("BaseLockRemote")

-- Shared workspace references (signage, touch detection, collection systems all read these)
GameUtilities.basesFolder = basesFolder
UIManager.basesFolder = basesFolder
CollectionManager.basesFolder = basesFolder

local STUDS_TILE = "rbxassetid://92521981645530"

local function applyPlateStyle(gui, titleText, faceColor)
	-- 4-layer bevel stack: dark base + outline, gradient face, stud tile, FredokaOne text
	local baseFrame = Instance.new("Frame")
	baseFrame.Name = "Plate"
	baseFrame.Size = UDim2.fromScale(1, 1)
	baseFrame.BackgroundColor3 = Color3.fromRGB(16, 84, 32)
	baseFrame.BorderSizePixel = 0
	baseFrame.Parent = gui
	local baseStroke = Instance.new("UIStroke")
	baseStroke.Color = Color3.new(0, 0, 0)
	baseStroke.Thickness = 4
	baseStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	baseStroke.Parent = baseFrame

	local face = Instance.new("Frame")
	face.Name = "Face"
	face.Size = UDim2.new(1, 0, 0.94, 0)
	face.BackgroundColor3 = Color3.new(1, 1, 1)
	face.BorderSizePixel = 0
	face.ZIndex = baseFrame.ZIndex + 1
	face.Parent = baseFrame
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), faceColor)
	gradient.Parent = face

	local studs = Instance.new("ImageLabel")
	studs.Name = "Studs"
	studs.Size = UDim2.fromScale(1, 1)
	studs.BackgroundTransparency = 1
	studs.Image = STUDS_TILE
	studs.ImageTransparency = 0.55
	studs.ZIndex = face.ZIndex + 1
	studs.Parent = face

	local text = Instance.new("TextLabel")
	text.Name = "PlateText"
	text.BackgroundTransparency = 1
	text.Size = UDim2.fromScale(1, 1)
	text.Font = Enum.Font.FredokaOne
	text.Text = titleText
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextScaled = true
	text.ZIndex = studs.ZIndex + 1
	text.Parent = face
	local textStroke = Instance.new("UIStroke")
	textStroke.Color = Color3.new(0, 0, 0)
	textStroke.Thickness = 3
	textStroke.Parent = text
end

-- The green pad in front of a base: stand on it and hold E to claim
local function setupCollectZone(base, baseNumber)
	local pad = base:FindFirstChild("UnlockBase")
	if not pad or not pad:IsA("BasePart") then
		warn("[BaseManagerBootstrap] Missing green collect-zone pad (UnlockBase) for " .. base.Name)
		return
	end

	pad.Color = Color3.fromRGB(63, 190, 70)
	pad.Size = Vector3.new(4.5, 1.5, 4.5)
	pad.Anchored = true
	pad.CanCollide = true

	local existingLabel = pad:FindFirstChild("CollectZoneLabel")
	if existingLabel then existingLabel:Destroy() end

	local label = Instance.new("BillboardGui")
	label.Name = "CollectZoneLabel"
	label.Size = UDim2.new(0, 340, 0, 84)
	label.StudsOffsetWorldSpace = Vector3.new(0, 3.4, 0)
	label.AlwaysOnTop = true
	label.MaxDistance = 90
	label.Parent = pad
	applyPlateStyle(label, "Collect Zone", Color3.fromRGB(63, 190, 70))

	local prompt = pad:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "ClaimBasePrompt"
		prompt.Parent = pad
	end
	prompt.ActionText = "Claim Base"
	prompt.ObjectText = base.Name
	prompt.HoldDuration = BaseManager.CLAIM_HOLD_DURATION
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Enabled = true
	prompt.Triggered:Connect(function(player)
		BaseManager.handleBaseClaim(player, baseNumber)
	end)
end

-- Per-player banner: only the owner sees "Your Base" above the base they selected
local function setupYourBaseBanner(base)
	local nameParent = base:FindFirstChild("BaseNameParent")
	if not nameParent or not nameParent:IsA("BasePart") then
		warn("[BaseManagerBootstrap] Missing BaseNameParent for " .. base.Name)
		return
	end

	local existing = nameParent:FindFirstChild("YourBase")
	if existing then existing:Destroy() end

	local anchor = Instance.new("Part")
	anchor.Name = "YourBase"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.CFrame = nameParent.CFrame * CFrame.new(0, 7, 0)
	anchor.Parent = nameParent

	local banner = Instance.new("BillboardGui")
	banner.Name = "BillboardGui"
	banner.Size = UDim2.new(0, 420, 0, 100)
	banner.AlwaysOnTop = true
	banner.MaxDistance = 130
	banner.Parent = anchor
	applyPlateStyle(banner, "Your Base", Color3.fromRGB(63, 190, 70))
end

for _, base in ipairs(basesFolder:GetChildren()) do
	local baseNumber = tonumber(string.match(base.Name, "%d+"))
	if base:IsA("Folder") and baseNumber then
		setupCollectZone(base, baseNumber)
		setupYourBaseBanner(base)
	end
end

BaseManager.initializeEmptyBases()

Players.PlayerRemoving:Connect(function(player) BaseManager.releasePlayerBase(player) end)
print("[BaseManagerBootstrap] Initialized " .. tostring(#basesFolder:GetChildren()) .. " bases; players claim one at a collect-zone pad")
