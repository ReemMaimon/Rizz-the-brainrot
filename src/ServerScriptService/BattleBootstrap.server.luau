local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BattleService = require(script.Parent:WaitForChild("ModuleScripts"):WaitForChild("BattleService"))
local remotes = ReplicatedStorage:WaitForChild("BattleRemotes")
local startBattle = remotes:WaitForChild("StartBattle")
local chooseAction = remotes:WaitForChild("ChooseAction")
local battleState = remotes:WaitForChild("BattleState")
local battleCamera = remotes:WaitForChild("BattleCamera")
local abilityRequest = remotes:WaitForChild("AbilityRequest")
local abilityResponse = remotes:WaitForChild("AbilityResponse")
local abilityEquipRequest = remotes:WaitForChild("AbilityEquipRequest")

local function send(player, snapshot)
	battleState:FireClient(player, snapshot)
end

BattleService.Changed.Event:Connect(function(player, snapshot)
	if snapshot then
		send(player, snapshot)
		if snapshot.BattleStatus == "PlayerTurn" or snapshot.BattleStatus == "BrainrotTurn" then
			battleCamera:FireClient(player, "Start", snapshot)
		else
			battleCamera:FireClient(player, "Stop")
		end
	end
end)

BattleService.Finished.Event:Connect(function(player, battle, status)
	battleCamera:FireClient(player, "Stop")
	battleState:FireClient(player, BattleService:GetSnapshotForFinished(battle, status))
end)

startBattle.OnServerEvent:Connect(function(player, model)
	local success, message = BattleService:Start(player, model)
	if not success then
		battleState:FireClient(player, {BattleStatus = "Rejected", Message = message})
	end
end)

chooseAction.OnServerEvent:Connect(function(player, action)
	local success, message = BattleService:ChooseAction(player, action)
	if not success then
		local snapshot = BattleService:GetSnapshot(player)
		if snapshot then
			snapshot.Message = message
			battleState:FireClient(player, snapshot)
		end
	end
end)

abilityRequest.OnServerEvent:Connect(function(player, abilityId)
	local success, result = BattleService:UseAbility(player, abilityId)
	abilityResponse:FireClient(player, success, success and result.AbilityId or result, success and "" or result)
	if not success then
		local snapshot = BattleService:GetSnapshot(player)
		if snapshot then
			snapshot.Message = result
			battleState:FireClient(player, snapshot)
		end
	end
end)

abilityEquipRequest.OnServerEvent:Connect(function(player, action, first, second)
	local AbilityService = require(script.Parent:WaitForChild("ModuleScripts"):WaitForChild("AbilityService"))
	local success, result
	if action == "Equip" then success, result = AbilityService:Equip(player, first, second)
	elseif action == "Unequip" then success, result = AbilityService:Unequip(player, first)
	elseif action == "Replace" then success, result = AbilityService:Replace(player, first, second)
	elseif action == "Reorder" then success, result = AbilityService:Reorder(player, first, second)
	else success, result = false, "Invalid ability inventory action." end
	abilityResponse:FireClient(player, success, action, success and result or result)
	local snapshot = BattleService:GetSnapshot(player)
	if snapshot then battleState:FireClient(player, snapshot) end
end)

print("[BattleBootstrap] Battle remotes ready with ability support")
