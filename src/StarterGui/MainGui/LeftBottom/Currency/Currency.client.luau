local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local leaderstats = player:WaitForChild("leaderstats")
local coinsStat = leaderstats:WaitForChild("Coins")
local currencyLabel = script.Parent
local coinsoutFolder = currencyLabel.Parent:WaitForChild("Coinsout")
local template = coinsoutFolder:WaitForChild("Template")

-- Colors
local GREEN = Color3.fromRGB(115, 255, 0)
local RED = Color3.fromRGB(173, 0, 3)

-- Vars
local currentDisplayedCoins = coinsStat.Value
local tweenObject = nil

-- FIXED Number formatting function
local function formatNumber(num)
	num = math.floor(num + 0.5)
	local isNegative = num < 0
	num = math.abs(num)

	local suffixes = {
		{1e93, "Tg"}, {1e90, "Nvg"}, {1e87, "Ovg"}, {1e84, "Svg"},
		{1e81, "Sxv"}, {1e78, "Qnv"}, {1e75, "Qtv"}, {1e72, "Trv"},
		{1e69, "Duv"}, {1e66, "Unv"}, {1e63, "Vg"}, {1e60, "Nd"},
		{1e57, "Od"}, {1e54, "Sd"}, {1e51, "Sxd"}, {1e48, "Qnd"},
		{1e45, "Qtd"}, {1e42, "Trd"}, {1e39, "Dd"}, {1e36, "Ud"},
		{1e33, "Dc"}, {1e30, "No"}, {1e27, "Oc"}, {1e24, "Sp"},
		{1e21, "Sx"}, {1e18, "Qi"}, {1e15, "Qa"}, {1e12, "T"},
		{1e9, "B"}, {1e6, "M"}, {1e3, "K"}
	}

	for _, suffix in ipairs(suffixes) do
		local threshold, label = suffix[1], suffix[2]
		if num >= threshold then
			local value = num / threshold
			local formatted = string.format("%.2f", value)
			formatted = formatted:gsub("0+$", ""):gsub("%.$", "")
			return (isNegative and "-" or "") .. formatted .. label
		end
	end

	local formatted = tostring(num)
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then break end
	end

	return (isNegative and "-" or "") .. formatted
end

currencyLabel.Text = "Coins: " .. formatNumber(currentDisplayedCoins)

-- Popup effect
local function showCoinsChangeEffect(amountChanged)
	local isIncrease = amountChanged > 0
	local clone = template:Clone()
	clone.Visible = true
	clone.Parent = coinsoutFolder
	clone.Name = "Flash"
	clone.Text = (isIncrease and "+" or "-") .. formatNumber(math.abs(amountChanged)) .. " Coins"
	clone.TextColor3 = isIncrease and GREEN or RED
	clone.TextTransparency = 0
	clone.BackgroundTransparency = 1

	local stroke = clone:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Transparency = 0
	end

	task.delay(2, function()
		local fadeTween = TweenService:Create(clone, TweenInfo.new(1), {
			TextTransparency = 1
		})
		fadeTween:Play()

		if stroke then
			TweenService:Create(stroke, TweenInfo.new(1), {
				Transparency = 1
			}):Play()
		end

		fadeTween.Completed:Connect(function()
			clone:Destroy()
		end)
	end)
end

-- Animate coins change (no queue, just always tween to new value)
local function animateCoinsChange(newValue)
	local oldValue = currentDisplayedCoins
	local amountChanged = newValue - oldValue
	if amountChanged == 0 then return end

	showCoinsChangeEffect(amountChanged)

	if tweenObject then
		tweenObject:Cancel()
	end

	local numberValue = Instance.new("NumberValue")
	numberValue.Value = oldValue

	local connection
	connection = numberValue:GetPropertyChangedSignal("Value"):Connect(function()
		currencyLabel.Text = "Coins: " .. formatNumber(numberValue.Value)
	end)

	tweenObject = TweenService:Create(numberValue, TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Value = newValue
	})

	tweenObject.Completed:Connect(function()
		if connection then connection:Disconnect() end
		numberValue:Destroy()
		currentDisplayedCoins = newValue
		currencyLabel.Text = "Coins: " .. formatNumber(currentDisplayedCoins)
		tweenObject = nil
	end)

	tweenObject:Play()
end

-- Listen for changes
coinsStat:GetPropertyChangedSignal("Value"):Connect(function()
	animateCoinsChange(coinsStat.Value)
end)
