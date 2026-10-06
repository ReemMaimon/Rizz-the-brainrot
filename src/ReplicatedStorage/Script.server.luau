local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RemoteEvent oluştur (bir kereye mahsus)
local event = Instance.new("RemoteEvent")
event.Name = "UpdateLikes"
event.Parent = ReplicatedStorage

-- Örnek like sayısı
local likeCount = 0
local likeGoal = 10

-- Her 5 saniyede bir rastgele beğeni artışı simüle (test amaçlı)
while true do
	task.wait(5)
	likeCount += math.random(0, 2)
	if likeCount > likeGoal then likeCount = likeGoal end

	event:FireAllClients(likeCount, likeGoal)
end
