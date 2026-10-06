local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RizzConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("RizzConfig"))
local PlayerDataService = require(script.Parent:WaitForChild("ModuleScripts"):WaitForChild("PlayerDataService"))
local ProgressionService = require(script.Parent:WaitForChild("ModuleScripts"):WaitForChild("ProgressionService"))
local PlayerStatsService = require(script.Parent:WaitForChild("ModuleScripts"):WaitForChild("PlayerStatsService"))

local function initializeCharacter(player, character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then return end
	PlayerStatsService:Initialize(player)
	PlayerStatsService:Recalculate(player)
	local startingHP = RizzConfig.Stats.StartingHPAtSpawn == "MaxHP" and PlayerStatsService:GetMaxHP(player) or PlayerStatsService:GetHP(player)
	if startingHP <= 0 then
		startingHP = PlayerStatsService:GetMaxHP(player)
	end
	local startingMana = RizzConfig.Stats.StartingManaAtSpawn == "MaxMana" and PlayerStatsService:GetMaxMana(player) or PlayerStatsService:GetMana(player)
	PlayerStatsService:SetMaxHP(player, PlayerStatsService:GetMaxHP(player))
	PlayerStatsService:SetMaxMana(player, PlayerStatsService:GetMaxMana(player))
	local stats = player:FindFirstChild("PlayerStats")
	local hp = stats and stats:FindFirstChild("HP")
	local mana = stats and stats:FindFirstChild("Mana")
	if hp then hp.Value = math.max(1, math.clamp(startingHP, 0, PlayerStatsService:GetMaxHP(player))) end
	if mana then mana.Value = math.clamp(startingMana, 0, PlayerStatsService:GetMaxMana(player)) end
	humanoid.MaxHealth = PlayerStatsService:GetMaxHP(player)
	humanoid.Health = math.max(1, PlayerStatsService:GetHP(player))
end

local function initializePlayer(player)
	repeat task.wait() until PlayerDataService:IsLoaded(player) or not player.Parent
	if not player.Parent then return end
	PlayerStatsService:Initialize(player)
	ProgressionService:CheckRizzLevel(player)
	player.CharacterAdded:Connect(function(character)
		initializeCharacter(player, character)
	end)
	if player.Character then task.spawn(initializeCharacter, player, player.Character) end
end

Players.PlayerAdded:Connect(initializePlayer)
Players.PlayerRemoving:Connect(function(player)
	PlayerStatsService:Clear(player)
end)
for _, player in Players:GetPlayers() do task.spawn(initializePlayer, player) end

task.spawn(function()
	local interval = math.max(0.1, RizzConfig.Mana.RegenerationInterval or 1)
	while true do
		task.wait(interval)
		local amount = math.max(0, RizzConfig.Mana.RegenerationPerInterval or 0)
		for _, player in Players:GetPlayers() do
			if PlayerDataService:IsLoaded(player) and PlayerStatsService:IsPlayerAlive(player) then
				PlayerStatsService:AddMana(player, amount)
			end
		end
	end
end)