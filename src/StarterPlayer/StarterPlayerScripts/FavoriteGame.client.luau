-- LocalScript — place in StarterPlayerScripts

local Players = game:GetService("Players")
local AvatarEditorService = game:GetService("AvatarEditorService")

local player = Players.LocalPlayer
local WAIT_TIME = 10 * 15 -- 10 minutes
local GAME_ID = 87591910559112

-- Wait 10 minutes, then prompt favorite
task.delay(WAIT_TIME, function()
	if player and player.Parent then
		pcall(function()
			AvatarEditorService:PromptSetFavorite(GAME_ID, Enum.AvatarItemType.Asset, true)
		end)
	end
end)
