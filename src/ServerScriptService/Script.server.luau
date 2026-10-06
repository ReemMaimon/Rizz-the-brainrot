local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RemoteEvent oluştur
local event = Instance.new("RemoteEvent")
event.Name = "UpdateLikes"
event.Parent = ReplicatedStorage

local GAME_ID = game.GameId
local LIKE_GOAL = 10
local UPDATE_INTERVAL = 60 -- saniyede bir güncelle

local function getLikeCount()
	local success, response = pcall(function()
		local url = "https://games.roproxy.com/v1/games/votes?universeIds=" 87591910559112 GAME_ID
		return HttpService:GetAsync(url)
	end)

	if success then
		local data = HttpService:JSONDecode(response)
		if data and data.data and data.data[1] then
			return data.data[1].upVotes or 0
		end
	end
	return 0
end

while true do
	local likes = getLikeCount()
	event:FireAllClients(likes, LIKE_GOAL)

	print("Likes:", likes)
	task.wait(UPDATE_INTERVAL)
end
