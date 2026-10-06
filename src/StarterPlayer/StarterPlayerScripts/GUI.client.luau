local StarterGui = game:GetService("StarterGui")

local MessageConfig = {
	{ 5, "👍 Like The Game For Free Babies!", Color3.fromRGB(255, 0, 4) },
	{ 8, "👥 Join The Group For Free Babies!", Color3.fromRGB(0, 255, 0) }
}

local function sendChat(text, color)
	local success, error = pcall(function()
		StarterGui:SetCore("ChatMakeSystemMessage", {
			Text = text,
			Color = color,
			Font = Enum.Font.SourceSansBold,
			TextSize = 18,
		})
	end)

	if success then
	else
	end
end

-- Test with immediate message first
sendChat("🔧 Script loaded successfully!", Color3.fromRGB(0, 255, 255))

-- Then start the timers
for _, config in ipairs(MessageConfig) do
	local minutes, text, color = unpack(config)
	task.spawn(function()
		while true do
			sendChat(text, color)
			task.wait(minutes * 60)
		end
	end)
end