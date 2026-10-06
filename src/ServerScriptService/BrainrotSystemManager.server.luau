local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModuleScripts = script.Parent:WaitForChild("ModuleScripts")
local StandService = require(ModuleScripts:WaitForChild("StandService"))
local BaseService = require(ModuleScripts:WaitForChild("BaseService"))
local IncomeService = require(ModuleScripts:WaitForChild("IncomeService"))
local BrainrotDataService = require(ModuleScripts:WaitForChild("BrainrotDataService"))

local movingBrainrotsFolder = Workspace:FindFirstChild("MovingBrainrots")
if not movingBrainrotsFolder then
	movingBrainrotsFolder = Instance.new("Folder")
	movingBrainrotsFolder.Name = "MovingBrainrots"
	movingBrainrotsFolder.Parent = Workspace
end

BaseService:DiscoverBases()
IncomeService:Start()

-- Brainrots load into a player's base when they claim one at a collect-zone pad
local baseClaimed = ReplicatedStorage:WaitForChild("BaseClaimed")
baseClaimed.Event:Connect(function(player, baseNumber)
	if not player or not player.Parent then return end
	local base = BaseService:AssignBase(player, baseNumber)
	if base then
		BrainrotDataService:LoadPlayerBrainrots(player, base)
	end
end)

print("[BrainrotSystemManager] Base, Stand, Income, and saved Brainrot systems initialized; players claim a base at a collect-zone pad")
