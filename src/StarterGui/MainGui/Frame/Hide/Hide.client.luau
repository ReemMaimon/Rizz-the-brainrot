local UserInputService = game:GetService("UserInputService")

local button = script.Parent
local frameToHide = button.Parent

-- Input begin function
local function onInputBegan(input, isProcessed)
	if isProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or
		input.UserInputType == Enum.UserInputType.Touch or
		input.UserInputType == Enum.UserInputType.Gamepad1 then
		frameToHide.Visible = false
	end
end

-- Connect to InputBegan for all input types
button.InputBegan:Connect(onInputBegan)
