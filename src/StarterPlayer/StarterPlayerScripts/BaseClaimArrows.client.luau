-- BaseClaimArrows: green arrows point from a baseless player to every available base
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local basesFolder = workspace:WaitForChild("Bases")

local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "BaseClaimArrows"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local ARROW_IMAGE = "rbxassetid://124300905660565"
local MAX_BASES = 8
local ARROW_SIZE = 56
local OFFSET_PX = 95
local MARGIN_PX = 40
local TOP_KEEPOUT_PX = 74

local arrows = {}
for baseNumber = 1, MAX_BASES do
	local plate = Instance.new("Frame")
	plate.Name = "Arrow" .. baseNumber
	plate.Size = UDim2.fromOffset(ARROW_SIZE, ARROW_SIZE)
	plate.BackgroundColor3 = Color3.fromRGB(16, 84, 32)
	plate.BackgroundTransparency = 0.25
	plate.BorderSizePixel = 0
	plate.Visible = false
	plate.ZIndex = 10
	plate.Parent = gui

	local plateStroke = Instance.new("UIStroke")
	plateStroke.Color = Color3.new(0, 0, 0)
	plateStroke.Thickness = 4
	plateStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	plateStroke.Parent = plate

	local arrow = Instance.new("ImageLabel")
	arrow.Name = "ArrowImage"
	arrow.BackgroundTransparency = 1
	arrow.Size = UDim2.new(1, -10, 1, -10)
	arrow.Position = UDim2.fromOffset(5, 5)
	arrow.Image = ARROW_IMAGE
	arrow.ImageColor3 = Color3.new(1, 1, 1)
	arrow.ZIndex = 11
	arrow.Parent = plate

	local pulse = Instance.new("UIScale")
	pulse.Parent = arrow

	arrows[baseNumber] = {plate = plate, arrow = arrow, pulse = pulse}
end

local elapsed = 0

RunService.RenderStepped:Connect(function(dt)
	elapsed += dt

	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local ownedBase = player:FindFirstChild("OwnedBase")

	-- Arrows only guide a player who hasn't chosen a base yet
	local hideAll = not hrp or (ownedBase and ownedBase.Value > 0)

	for baseNumber = 1, MAX_BASES do
		local widget = arrows[baseNumber]
		if hideAll then
			widget.plate.Visible = false
		else
			local base = basesFolder:FindFirstChild("Base" .. baseNumber)
			local owner = base and base:FindFirstChild("Owner")
			local isAvailable = base ~= nil and not (owner and owner.Value)
			if not isAvailable then
				widget.plate.Visible = false
			else
				local target = base:FindFirstChild("UnlockBase") or base:FindFirstChild("BaseNameParent")
				local targetPos = target and target.Position
				if not targetPos then
					widget.plate.Visible = false
				else
					local headPos = hrp.Position + Vector3.new(0, 4, 0)
					local headScreen = camera:WorldToViewportPoint(headPos)
					local baseScreen = camera:WorldToViewportPoint(targetPos)

					local dx = baseScreen.X - headScreen.X
					local dy = baseScreen.Y - headScreen.Y
					if baseScreen.Z < 0 then
						dx, dy = -dx, -dy
					end

					local len = math.sqrt(dx * dx + dy * dy)
					if len < 1 then
						dx, dy = 0, -1
					else
						dx, dy = dx / len, dy / len
					end

					local viewport = camera.ViewportSize
					local ax = headScreen.X + dx * OFFSET_PX
					local ay = headScreen.Y + dy * OFFSET_PX
					ax = math.clamp(ax, MARGIN_PX, viewport.X - MARGIN_PX)
					ay = math.clamp(ay, TOP_KEEPOUT_PX, viewport.Y - MARGIN_PX)

					widget.plate.Position = UDim2.fromOffset(ax - ARROW_SIZE / 2, ay - ARROW_SIZE / 2)
					widget.plate.Visible = true

					-- Icon points up by default; rotate it toward the base on screen
					widget.arrow.Rotation = math.deg(math.atan2(dx, -dy))
					widget.pulse.Scale = 1 + 0.09 * math.sin(elapsed * 4 + baseNumber)
				end
			end
		end
	end
end)
