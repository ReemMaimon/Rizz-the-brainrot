-- BadgeGiverScript.lua
local Players = game:GetService("Players")
local BadgeService = game:GetService("BadgeService")

local BADGE_ID = 3978877986821180

-- Function to check and award badge
local function awardBadge(player)
	local success, hasBadge = pcall(function()
		return BadgeService:UserHasBadgeAsync(player.UserId, BADGE_ID)
	end)

	if success and not hasBadge then
		pcall(function()
			BadgeService:AwardBadge(player.UserId, BADGE_ID)
		end)
	end
end

-- Connect to PlayerAdded
Players.PlayerAdded:Connect(function(player)
	task.defer(function() -- small delay to ensure Player is fully loaded
		awardBadge(player)
	end)
end)
