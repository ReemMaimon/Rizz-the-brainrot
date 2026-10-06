-- CLOSE BUTTON LOCALSCRIPT
-- Put this LocalScript inside the Close button (script.parent = Close button)

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")

-- Get the close button (script.parent)
local closeButton = script.Parent
local uiScale = closeButton:FindFirstChild("UIScale")

-- Create UIScale if it doesn't exist
if not uiScale then
	uiScale = Instance.new("UIScale")
	uiScale.Scale = 1
	uiScale.Parent = closeButton
end

-- Get sounds with error handling
local sounds = ReplicatedStorage:FindFirstChild("Sounds")

-- Get CameraController module with error handling
local CameraController
local function findCameraController()
	local success, result = pcall(function()
		local possiblePaths = {
			ReplicatedStorage:FindFirstChild("ModuleScripts"),
			ReplicatedStorage:FindFirstChild("Controllers"),
			ReplicatedStorage:FindFirstChild("Modules")
		}

		for _, path in ipairs(possiblePaths) do
			if path then
				local controller = path:FindFirstChild("CameraController")
				if controller then
					return require(controller)
				end
			end
		end

		error("CameraController not found in any expected location")
	end)

	if success then
		return result
	else
		-- Fallback camera controller
		return {
			GetDefaultFov = function() return 70 end,
			Fov = function(self, fov, duration) 
				if workspace.CurrentCamera then
					workspace.CurrentCamera.FieldOfView = fov
				end
			end
		}
	end
end

CameraController = findCameraController()

-- Setup blur effect
local function setupBlur()
	local blur = Lighting:FindFirstChild("Blur")
	if not blur then
		blur = Instance.new("BlurEffect")
		blur.Name = "Blur"
		blur.Size = 14
		blur.Enabled = false
		blur.Parent = Lighting
	end
	return blur
end

local blurEffect = setupBlur()

-- Tween settings
local hoverTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local clickTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local releaseTweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local frameSlideDownInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

-- Colors
local defaultColor = Color3.fromRGB(255, 255, 255)
local clickColor = Color3.fromRGB(179, 179, 179)

-- Button states
local isPressed = false
local isHovering = false
local touchActive = false

-- Function to play sound
local function playSound(soundName)
	pcall(function()
		if sounds then
			local sound = sounds:FindFirstChild(soundName)
			if sound and sound.Play then
				sound:Play()
			end
		end
	end)
end

-- Safe tween function
local function safeTween(object, tweenInfo, properties)
	if not object or not object.Parent then
		return nil
	end

	local success, result = pcall(function()
		local tween = TweenService:Create(object, tweenInfo, properties)
		tween:Play()
		return tween
	end)

	return success and result or nil
end

-- Function to close the main frame
local function closeMainFrame()
	-- Get the target frame (script.Parent.Parent.Parent.Parent)
	local mainGuiFrame = script.Parent.Parent.Parent.Parent

	if not mainGuiFrame then
		return
	end

	if not mainGuiFrame.Visible then
		return
	end

	-- Store original position
	local originalPos = mainGuiFrame.Position
	local slideDownPos = UDim2.new(originalPos.X.Scale, originalPos.X.Offset, 1.2, originalPos.Y.Offset)

	-- Play close sound
	playSound("ButtonPress")

	-- Create slide down animation
	local slideTween = safeTween(mainGuiFrame, frameSlideDownInfo, {
		Position = slideDownPos
	})

	if slideTween then
		slideTween.Completed:Connect(function()
			-- Hide frame and reset position
			pcall(function()
				if mainGuiFrame and mainGuiFrame.Parent then
					mainGuiFrame.Visible = false
					mainGuiFrame.Position = originalPos
				end
			end)

			-- Disable blur and reset camera
			pcall(function()
				if blurEffect and blurEffect.Parent then
					blurEffect.Enabled = false
				end
				if CameraController then
					CameraController:Fov(CameraController:GetDefaultFov(), 0.5)
				end
			end)

			-- Play release sound
			playSound("ButtonRelease")
		end)
	else
		-- Fallback: instant close
		pcall(function()
			mainGuiFrame.Visible = false
			if blurEffect then
				blurEffect.Enabled = false
			end
			if CameraController then
				CameraController:Fov(CameraController:GetDefaultFov(), 0.5)
			end
		end)
		playSound("ButtonRelease")
	end
end

-- Function to apply pressed visuals
local function applyPressedVisuals()
	playSound("ButtonPress")
	safeTween(uiScale, clickTweenInfo, {Scale = 0.95})
	safeTween(closeButton, clickTweenInfo, {ImageColor3 = clickColor})
end

-- Function to reset button visuals
local function resetButtonVisuals()
	local targetScale = isHovering and 1.05 or 1
	safeTween(uiScale, releaseTweenInfo, {Scale = targetScale})
	safeTween(closeButton, releaseTweenInfo, {ImageColor3 = defaultColor})
end

-- ================================
-- BUTTON ANIMATIONS
-- ================================

-- Hover effects (only for non-touch devices)
closeButton.MouseEnter:Connect(function()
	if not UserInputService.TouchEnabled or UserInputService.MouseEnabled then
		if not isPressed and not touchActive then
			isHovering = true
			playSound("ButtonHover")
			safeTween(uiScale, hoverTweenInfo, {Scale = 1.05})
		end
	end
end)

closeButton.MouseLeave:Connect(function()
	if isHovering and not isPressed and not touchActive then
		isHovering = false
		safeTween(uiScale, releaseTweenInfo, {Scale = 1})
		safeTween(closeButton, releaseTweenInfo, {ImageColor3 = defaultColor})
	elseif isPressed then
		isPressed = false
		isHovering = false
		resetButtonVisuals()
	end
end)

-- Press effects
closeButton.MouseButton1Down:Connect(function()
	if not touchActive then
		isPressed = true
		applyPressedVisuals()
	end
end)

closeButton.MouseButton1Up:Connect(function()
	if isPressed then
		isPressed = false
		playSound("ButtonRelease")
		resetButtonVisuals()
	end
end)

-- Touch/Tap support for mobile devices
if UserInputService.TouchEnabled then
	closeButton.TouchTap:Connect(function()
		touchActive = true

		-- Quick press animation for touch
		applyPressedVisuals()

		wait(0.1) -- Brief visual feedback

		playSound("ButtonRelease")
		safeTween(uiScale, releaseTweenInfo, {Scale = 1})
		safeTween(closeButton, releaseTweenInfo, {ImageColor3 = defaultColor})

		wait(0.1) -- Ensure animation completes
		touchActive = false

		-- Trigger the close function
		closeMainFrame()
	end)
end

-- Click functionality - close the frame (for mouse)
closeButton.Activated:Connect(function()
	if not touchActive then
		closeMainFrame()
	end
end)