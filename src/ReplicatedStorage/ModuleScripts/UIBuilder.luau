-- Tiny shared helpers for fully code-built shop/panel UIs (corner, stroke, label), so this
-- boilerplate isn't hand-copied into every new shop client script.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("UIConfig"))

local UIBuilder = {}
UIBuilder.Theme = UIConfig.Theme

function UIBuilder.Corner(inst, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = inst
	return c
end

function UIBuilder.Stroke(inst, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or UIBuilder.Theme.Stroke
	s.Thickness = thickness or 1.5
	s.Parent = inst
	return s
end

function UIBuilder.Label(parent, props)
	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamBold
	text.TextColor3 = UIBuilder.Theme.Text
	text.TextScaled = true
	for key, value in pairs(props) do text[key] = value end
	text.Parent = parent
	return text
end

function UIBuilder.RarityColor3(rgb)
	if typeof(rgb) == "table" then
		return Color3.fromRGB(rgb[1] or 255, rgb[2] or 255, rgb[3] or 255)
	end
	return UIBuilder.Theme.Accent
end

return UIBuilder
