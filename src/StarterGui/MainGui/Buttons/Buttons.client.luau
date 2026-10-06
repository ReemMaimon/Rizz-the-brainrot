-- Enhanced Button Controller Script (Mobile Fixed)
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Get references with error handling
local buttons = script.Parent -- Contains the 3 buttons
local frames = script.Parent.Parent -- Contains the frames to open

-- Safely get sounds folder
local sounds = ReplicatedStorage:FindFirstChild("Sounds")
if not sounds then
	warn("Sounds folder not found in ReplicatedStorage")
	sounds = nil
end

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
		-- If not found or error loading, create a simple fallback
		warn("CameraController error: " .. tostring(result) .. ", using fallback")
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

-- Button names and their corresponding frames
local buttonData = {
	"Index",
	"Rebirth", 
	"Shop"
}

local extraFrameNames = {
	"CoinsShop",
	"AbilityCardShop",
}

-- Tween settings
local hoverTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local clickTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local releaseTweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

-- Frame transition settings
local frameSlideDownInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
local frameSlideUpInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

-- Colors
local defaultColor = Color3.fromRGB(255, 255, 255) -- White
local clickColor = Color3.fromRGB(179, 179, 179) -- Gray when clicking

-- Track current open frame and button states
local currentFrame = nil
local buttonStates = {} -- Track each button's state
local isTransitioning = false -- Prevent multiple transitions at once
local lastActivationTime = {} -- Debounce activation

-- Store original positions for frames
local originalPositions = {}

-- Detect if we're on mobile
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

-- Function to store original frame positions
local function storeOriginalPositions()
	for _, frameName in ipairs(buttonData) do
		local frame = frames:FindFirstChild(frameName)
		if frame then
			originalPositions[frame] = frame.Position
		end
	end
	for _, frameName in ipairs(extraFrameNames) do
		local frame = frames:FindFirstChild(frameName)
		if frame then
			originalPositions[frame] = frame.Position
		end
	end
end

-- Function to animate frame sliding down (closing)
local function slideFrameDown(frame, callback)
	if not frame or not frame.Visible then
		if callback then callback() end
		return
	end

	local originalPos = originalPositions[frame] or frame.Position
	local slideDownPos = UDim2.new(originalPos.X.Scale, originalPos.X.Offset, 1.2, originalPos.Y.Offset)

	-- Create slide down tween (only animate position)
	local slideTween = TweenService:Create(frame, frameSlideDownInfo, {
		Position = slideDownPos
	})

	slideTween.Completed:Connect(function()
		frame.Visible = false
		-- Reset position for next time
		frame.Position = originalPos
		if callback then callback() end
	end)

	slideTween:Play()
end

-- Function to animate frame sliding up (opening)
local function slideFrameUp(frame, callback)
	if not frame then
		if callback then callback() end
		return
	end

	local originalPos = originalPositions[frame] or UDim2.new(0.5, 0, 0.5, 0)
	local slideUpStartPos = UDim2.new(originalPos.X.Scale, originalPos.X.Offset, -0.2, originalPos.Y.Offset)

	-- Set initial position and make visible
	frame.Position = slideUpStartPos
	frame.Visible = true

	-- Create slide up tween (only animate position)
	local slideTween = TweenService:Create(frame, frameSlideUpInfo, {
		Position = originalPos
	})

	slideTween.Completed:Connect(function()
		if callback then callback() end
	end)

	slideTween:Play()
end

-- Setup Blur effect in Lighting
local function setupBlur()
	local blur = Lighting:FindFirstChild("Blur")
	if not blur then
		blur = Instance.new("BlurEffect")
		blur.Name = "Blur"
		blur.Size = 14 -- Set blur size to 14
		blur.Enabled = false
		blur.Parent = Lighting
	end
	return blur
end

local blurEffect = setupBlur()

-- Function to close all frames
local function closeAllFrames(animated, callback)
	if not animated then
		-- Instant close
		for _, frameName in ipairs(buttonData) do
			local frame = frames:FindFirstChild(frameName)
			if frame then
				frame.Visible = false
				if originalPositions[frame] then
					frame.Position = originalPositions[frame]
				end
			end
		end
		for _, frameName in ipairs(extraFrameNames) do
			local frame = frames:FindFirstChild(frameName)
			if frame then
				frame.Visible = false
				if originalPositions[frame] then
					frame.Position = originalPositions[frame]
				end
			end
		end
		currentFrame = nil

		-- Reset camera effects and disable blur
		blurEffect.Enabled = false
		CameraController:Fov(CameraController:GetDefaultFov(), 0.5)

		if callback then callback() end
	else
		-- Animated close
		if currentFrame then
			slideFrameDown(currentFrame, function()
				currentFrame = nil
				blurEffect.Enabled = false
				CameraController:Fov(CameraController:GetDefaultFov(), 0.5)
				if callback then callback() end
			end)
		else
			if callback then callback() end
		end
	end
end

-- Function to open a specific frame
local function openFrame(frameName, animated)
	if isTransitioning then return end

	local targetFrame = frames:FindFirstChild(frameName)
	if not targetFrame then
		warn("Frame not found: " .. frameName)
		return
	end

	-- If same frame is already open, close it
	if currentFrame and currentFrame == targetFrame then
		isTransitioning = true
		closeAllFrames(true, function()
			isTransitioning = false
		end)
		return
	end

	-- If another frame is open, transition between them
	if currentFrame and animated then
		isTransitioning = true
		slideFrameDown(currentFrame, function()
			currentFrame = targetFrame
			blurEffect.Enabled = true
			CameraController:Fov(CameraController:GetDefaultFov() - 25, 0.5)

			slideFrameUp(targetFrame, function()
				isTransitioning = false
			end)
		end)
	else
		-- Direct open (no animation or no current frame)
		if currentFrame then
			currentFrame.Visible = false
		end

		currentFrame = targetFrame

		if animated then
			-- Apply camera effects
			blurEffect.Enabled = true
			CameraController:Fov(CameraController:GetDefaultFov() - 25, 0.5)

			slideFrameUp(targetFrame, function()
				-- Animation complete
			end)
		else
			targetFrame.Visible = true
			blurEffect.Enabled = true
			CameraController:Fov(CameraController:GetDefaultFov() - 25, 0.5)
		end
	end
end

-- Function to close current frame
local function closeCurrentFrame(animated)
	if isTransitioning then return end

	if currentFrame then
		isTransitioning = true
		closeAllFrames(animated or true, function()
			isTransitioning = false
		end)
	end
end

-- Function to play sound
local function playSound(soundName)
	if sounds then
		local sound = sounds:FindFirstChild(soundName)
		if sound then
			sound:Play()
		else
			-- Uncomment the line below if you want to see missing sound warnings
			-- warn("Sound not found: " .. soundName)
		end
	end
end

-- Function to reset button visual state
local function resetButtonVisuals(button, uiScale, icon, animated)
	local targetScale = 1
	local tweenInfo = animated and releaseTweenInfo or TweenInfo.new(0)

	-- Scale animation
	local scaleTween = TweenService:Create(uiScale, tweenInfo, {
		Scale = targetScale
	})
	scaleTween:Play()

	-- Color back to default for button
	local buttonColorTween = TweenService:Create(button, tweenInfo, {
		ImageColor3 = defaultColor
	})
	buttonColorTween:Play()

	-- Color back to default for icon if it exists
	if icon then
		local iconColorTween = TweenService:Create(icon, tweenInfo, {
			ImageColor3 = defaultColor
		})
		iconColorTween:Play()
	end
end

-- Function to apply pressed visuals
local function applyPressedVisuals(button, uiScale, icon)
	-- Scale down animation
	local clickTween = TweenService:Create(uiScale, clickTweenInfo, {
		Scale = 0.95
	})
	clickTween:Play()

	-- Color change for button
	local buttonColorTween = TweenService:Create(button, clickTweenInfo, {
		ImageColor3 = clickColor
	})
	buttonColorTween:Play()

	-- Color change for icon if it exists
	if icon then
		local iconColorTween = TweenService:Create(icon, clickTweenInfo, {
			ImageColor3 = clickColor
		})
		iconColorTween:Play()
	end
end

-- Function to apply hover visuals
local function applyHoverVisuals(button, uiScale)
	local hoverTween = TweenService:Create(uiScale, hoverTweenInfo, {
		Scale = 1.05
	})
	hoverTween:Play()
end

-- Debounce function to prevent rapid activations
local function canActivateButton(button)
	local currentTime = tick()
	local lastTime = lastActivationTime[button] or 0

	if currentTime - lastTime < 0.3 then -- 300ms debounce
		return false
	end

	lastActivationTime[button] = currentTime
	return true
end

-- Separate function to handle button activation logic
function handleButtonActivation(button)
	if isTransitioning then return end -- Prevent clicks during transitions

	-- Add debounce to prevent rapid activations
	if not canActivateButton(button) then return end

	local frameName = button.Name
	local targetFrame = frames:FindFirstChild(frameName)

	if not targetFrame then
		warn("Frame not found: " .. frameName)
		return
	end

	-- If clicking the same button as current open frame, close it
	if currentFrame and currentFrame == targetFrame then
		closeCurrentFrame(true) -- Animated close
	else
		-- Open the new frame with animation
		openFrame(frameName, true) -- Animated open
	end
end

-- Function to setup button animations
local function setupButton(button)
	local uiScale = button:FindFirstChild("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Scale = 1
		uiScale.Parent = button
	end

	local icon = button:FindFirstChild("Icon")

	-- Initialize button state
	buttonStates[button] = {
		isPressed = false,
		isHovering = false,
		touchActive = false,
		hasBeenActivated = false
	}

	local state = buttonStates[button]

	-- For mobile devices, only use touch events
	if isMobile then
		button.TouchTap:Connect(function()
			if state.touchActive then return end -- Prevent double activation

			state.touchActive = true
			state.hasBeenActivated = true

			-- Quick press animation for touch
			playSound("ButtonPress")
			applyPressedVisuals(button, uiScale, icon)

			-- Use spawn to prevent yielding in the event
			spawn(function()
				wait(0.1) -- Brief visual feedback

				playSound("ButtonRelease")
				resetButtonVisuals(button, uiScale, icon, true)

				wait(0.1) -- Ensure animation completes

				-- Trigger the frame toggle
				handleButtonActivation(button)

				-- Reset state after a delay
				wait(0.2)
				state.touchActive = false
				state.hasBeenActivated = false
			end)
		end)
	else
		-- For desktop, use mouse events
		-- Mouse Enter (Hover)
		button.MouseEnter:Connect(function()
			if not state.isPressed and not state.touchActive then
				state.isHovering = true
				playSound("ButtonHover")
				applyHoverVisuals(button, uiScale)
			end
		end)

		-- Mouse Leave
		button.MouseLeave:Connect(function()
			if state.isHovering and not state.isPressed and not state.touchActive then
				state.isHovering = false
				resetButtonVisuals(button, uiScale, icon, true)
			elseif state.isPressed then
				-- If mouse leaves while pressed, reset the pressed state
				state.isPressed = false
				state.isHovering = false
				resetButtonVisuals(button, uiScale, icon, true)
			end
		end)

		-- Mouse Button 1 Down (Click and Hold)
		button.MouseButton1Down:Connect(function()
			if not state.touchActive then
				state.isPressed = true
				playSound("ButtonPress")
				applyPressedVisuals(button, uiScale, icon)
			end
		end)

		-- Mouse Button 1 Up (Release)
		button.MouseButton1Up:Connect(function()
			if state.isPressed then
				state.isPressed = false
				playSound("ButtonRelease")

				-- Determine target scale based on hover state
				local targetScale = state.isHovering and 1.05 or 1

				-- Scale back animation
				local releaseTween = TweenService:Create(uiScale, releaseTweenInfo, {
					Scale = targetScale
				})
				releaseTween:Play()

				-- Color back to default for button
				local buttonColorTween = TweenService:Create(button, releaseTweenInfo, {
					ImageColor3 = defaultColor
				})
				buttonColorTween:Play()

				-- Color back to default for icon if it exists
				if icon then
					local iconColorTween = TweenService:Create(icon, releaseTweenInfo, {
						ImageColor3 = defaultColor
					})
					iconColorTween:Play()
				end
			end
		end)

		-- Activated (Click functionality) - Only for desktop
		button.Activated:Connect(function()
			if not state.touchActive and not state.hasBeenActivated then
				handleButtonActivation(button)
			end
		end)
	end
end

-- Global input handling to reset pressed states when mouse is released outside buttons
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		for button, state in pairs(buttonStates) do
			if state.isPressed then
				state.isPressed = false
				state.isHovering = false

				local uiScale = button:FindFirstChild("UIScale")
				local icon = button:FindFirstChild("Icon")
				if uiScale then
					resetButtonVisuals(button, uiScale, icon, true)
				end
			end
		end
	end
end)

-- Setup all buttons
for _, buttonName in ipairs(buttonData) do
	local button = buttons:FindFirstChild(buttonName)
	if button and button:IsA("GuiButton") then
		setupButton(button)
	else
		warn("Button not found or not a GuiButton: " .. buttonName)
	end
end

_G.OpenMainGuiFrame = function(frameName)
	if isTransitioning then return end

	if frameName == "__CLOSE__" then
		closeAllFrames(true)
		return
	end

	local targetFrame = frames:FindFirstChild(frameName)
	if not targetFrame then
		warn("Frame not found: " .. frameName)
		return
	end

	if currentFrame and currentFrame == targetFrame then
		closeAllFrames(true)
	else
		if currentFrame then
			isTransitioning = true
			slideFrameDown(currentFrame, function()
				currentFrame = targetFrame
				blurEffect.Enabled = true
				CameraController:Fov(CameraController:GetDefaultFov() - 25, 0.5)

				slideFrameUp(targetFrame, function()
					isTransitioning = false
				end)
			end)
		else
			currentFrame = targetFrame
			blurEffect.Enabled = true
			CameraController:Fov(CameraController:GetDefaultFov() - 25, 0.5)
			slideFrameUp(targetFrame)
		end
	end
end

-- Store original positions for animation reference
storeOriginalPositions()

-- Initialize with all frames closed
closeAllFrames(false) -- No animation on startup

local function bindCloseButton(frameName)
	local frame = frames:FindFirstChild(frameName)
	if not frame then return end
	local closeButton = frame:FindFirstChild("Close")
	if closeButton and closeButton:IsA("GuiButton") then
		closeButton.Activated:Connect(function()
			_G.OpenMainGuiFrame("__CLOSE__")
		end)
	end
end

for _, frameName in ipairs(extraFrameNames) do
	bindCloseButton(frameName)
end
bindCloseButton("Shop")