-- LocalScript: Place this in StarterPlayerScripts or StarterGui
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Device detection
local function getDeviceType()
	if GuiService:IsTenFootInterface() then
		return "Console" -- Xbox, PlayStation, etc.
	elseif UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
		return "Mobile" -- Phone/Tablet
	elseif UserInputService.KeyboardEnabled and UserInputService.MouseEnabled then
		return "Desktop" -- PC
	else
		return "Unknown"
	end
end

-- UIStroke settings for each device type
local strokeSettings = {
	Mobile = {
		Thickness = 2,     -- Thin for mobile
		Transparency = 0,     -- Fully opaque
	},
	Desktop = {
		Thickness = 3,      -- Thicker for PC
		Transparency = 0,     -- Fully opaque
	},
	Console = {
		Thickness = 2.3,      -- Same as desktop
		Transparency = 0,     -- Fully opaque
	},
	Unknown = {
		Thickness = 3,      -- Default to desktop settings
		Transparency = 0,     -- Fully opaque
	}
}

-- Special thickness settings for specific UI elements (all devices)
local specialThickness = {
	Mobile = 3.0,
	Desktop = 4.4,
	Console = 4.4,
	Unknown = 3.5
}

-- Table to keep track of UIStrokes we've already updated with special thickness
local updatedUIStrokes = {}

-- Function to update specific UIStrokes with higher thickness
local function updateSpecialUIStrokes(deviceType)
	local specialCount = 0
	local deviceSpecialThickness = specialThickness[deviceType] or specialThickness.Unknown

	-- Wait for SpecialGui to exist
	local specialGui = playerGui:WaitForChild("SpecialGui", 5)
	if not specialGui then
		return 0
	end

	-- Check TopSide and LeftSide
	local topSide = specialGui:FindFirstChild("TopSide")
	local leftSide = specialGui:FindFirstChild("LeftSide")

	-- Now let's try to find and update all UIStrokes in the specific frames
	local framesToCheck = {
		{topSide, "BarFrame", "TopSide.BarFrame"},
		{topSide, "CreamCurrencyFrame", "TopSide.CreamCurrencyFrame"},
		{leftSide, "EnergyFrame", "LeftSide.EnergyFrame"}
	}

	for _, frameInfo in pairs(framesToCheck) do
		local parent = frameInfo[1]
		local frameName = frameInfo[2]
		local pathName = frameInfo[3]

		if parent then
			local frame = parent:FindFirstChild(frameName)
			if frame then
				-- Check for UIStroke directly in the frame
				local directStroke = frame:FindFirstChildOfClass("UIStroke")
				if directStroke then
					directStroke.Thickness = deviceSpecialThickness
					updatedUIStrokes[directStroke] = true  -- Mark as updated
					specialCount = specialCount + 1
				end

				-- Check for UIStroke in Corner child
				local corner = frame:FindFirstChild("Corner")
				if corner then
					local cornerStroke = corner:FindFirstChildOfClass("UIStroke")
					if cornerStroke then
						cornerStroke.Thickness = deviceSpecialThickness
						updatedUIStrokes[cornerStroke] = true  -- Mark as updated
						specialCount = specialCount + 1
					end
				end

				-- Check for UIStroke in Bar child (for CreamCurrencyFrame and EnergyFrame)
				local bar = frame:FindFirstChild("Bar")
				if bar then
					local barStroke = bar:FindFirstChildOfClass("UIStroke")
					if barStroke then
						barStroke.Thickness = deviceSpecialThickness
						updatedUIStrokes[barStroke] = true  -- Mark as updated
						specialCount = specialCount + 1
					end
				end
			end
		end
	end

	return specialCount
end

-- Function to update all existing UIStrokes
local function updateAllUIStrokes()
	local deviceType = getDeviceType()
	local settings = strokeSettings[deviceType]

	local count = 0

	-- First, update special UIStrokes
	local specialCount = updateSpecialUIStrokes(deviceType)

	-- Then update all other UIStroke objects in PlayerGui
	for _, descendant in pairs(playerGui:GetDescendants()) do
		if descendant:IsA("UIStroke") then
			-- Skip the special ones we already updated
			if not updatedUIStrokes[descendant] then
				descendant.Thickness = settings.Thickness
				descendant.Transparency = settings.Transparency
			end
			count = count + 1
		end
	end
end

-- Wait for GUIs to load then update all existing UIStrokes
wait(2)
updateAllUIStrokes()