local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local BrainrotConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("BrainrotConfig"))
local StandService = require(script.Parent:WaitForChild("StandService"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))
local CurrencyService = require(script.Parent:WaitForChild("CurrencyService"))

local IncomeService = {}
local isRunning = false

local function formatCollectText(coins, rizz)
	if coins > 0 and rizz > 0 then
		return string.format("Collect: +%d Coins +%d Rizz", coins, rizz)
	elseif coins > 0 then
		return string.format("Collect: +%d Coins", coins)
	elseif rizz > 0 then
		return string.format("Collect: +%d Rizz", rizz)
	else
		return "Empty"
	end
end

function IncomeService:UpdateStandUI(standData)
	if not standData or not standData.CollectPart then return end
	local collectPart = standData.CollectPart

	local prompt = collectPart:FindFirstChild("CollectPrompt")
	local totalCoins = standData.UncollectedCoins or 0
	local totalRizz = standData.UncollectedRizz or 0
	local hasIncome = (totalCoins > 0) or (totalRizz > 0)

	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "CollectPrompt"
		prompt.ActionText = "Collect"
		prompt.ObjectText = "Stand Income"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 12
		prompt.RequiresLineOfSight = false
		prompt.Parent = collectPart

		prompt.Triggered:Connect(function(player)
			self:CollectIncome(player, standData)
		end)
	end

	prompt.Enabled = hasIncome
	if hasIncome then
		prompt.ActionText = formatCollectText(totalCoins, totalRizz)
	end

	-- Also update any BillboardGui inside Collect or Collect/Text
	local billboard = collectPart:FindFirstChildWhichIsA("BillboardGui", true)
	if billboard then
		local amountLabel = billboard:FindFirstChild("AmountToTake") or billboard:FindFirstChild("AmountText")
		local collectLabel = billboard:FindFirstChild("CollectText")

		if amountLabel and amountLabel:IsA("TextLabel") then
			if totalCoins > 0 and totalRizz > 0 then
				amountLabel.Text = string.format("$%d / %d Rizz", totalCoins, totalRizz)
			elseif totalCoins > 0 then
				amountLabel.Text = string.format("$%d", totalCoins)
			elseif totalRizz > 0 then
				amountLabel.Text = string.format("%d Rizz", totalRizz)
			else
				amountLabel.Text = "$0"
			end
			amountLabel.Visible = hasIncome
		end

		if collectLabel and collectLabel:IsA("TextLabel") then
			collectLabel.Text = hasIncome and "Collect" or "Empty"
		end
	end
end

function IncomeService:CollectIncome(player, standData)
	if not player or not player.Parent or not standData then return false end

	local baseOwner = BaseService:GetBaseOwner(standData.Base)
	if baseOwner ~= player then
		warn(string.format("[IncomeService] Player %s tried to collect from %s's base!", player.Name, baseOwner and baseOwner.Name or "unowned"))
		return false
	end

	local coins = standData.UncollectedCoins or 0
	local rizz = standData.UncollectedRizz or 0

	if coins <= 0 and rizz <= 0 then
		return false
	end

	standData.UncollectedCoins = 0
	standData.UncollectedRizz = 0

	if coins > 0 then
		CurrencyService:AddCoins(player, coins)
	end
	if rizz > 0 then
		CurrencyService:AddRizz(player, rizz)
	end

	self:UpdateStandUI(standData)
	print(string.format("[IncomeService] %s collected %d Coins and %d Rizz from %s", player.Name, coins, rizz, standData.StandId))
	return true
end

function IncomeService:Start()
	if isRunning then return end
	isRunning = true

	task.spawn(function()
		while isRunning do
			task.wait(BrainrotConfig.GlobalIncomeInterval or 3)

			local bases = BaseService:GetBases()
			for _, base in ipairs(bases) do
				local stands = StandService:GetStands(base)
				for _, stand in pairs(stands) do
					if stand.Occupied and stand.BrainrotData then
						local incomeCfg = stand.BrainrotData.Income or {}
						local coinsPerInterval = tonumber(incomeCfg.CoinsPerInterval) or (incomeCfg.Coins and tonumber(incomeCfg.Coins)) or 0
						local rizzPerInterval = tonumber(incomeCfg.RizzPerInterval) or (incomeCfg.Rizz and tonumber(incomeCfg.Rizz)) or 0

						if coinsPerInterval > 0 then
							stand.UncollectedCoins = (stand.UncollectedCoins or 0) + coinsPerInterval
						end
						if rizzPerInterval > 0 then
							stand.UncollectedRizz = (stand.UncollectedRizz or 0) + rizzPerInterval
						end

						self:UpdateStandUI(stand)
					else
						if (stand.UncollectedCoins or 0) == 0 and (stand.UncollectedRizz or 0) == 0 then
							self:UpdateStandUI(stand)
						end
					end
				end
			end
		end
	end)
end

function IncomeService:Stop()
	isRunning = false
end

return IncomeService