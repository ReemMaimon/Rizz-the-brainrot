-- PromptManager.lua - FIXED VERSION (THEFT WORKING + BABY PURCHASE SOUNDS)
-- Place in ServerScriptService > ModuleScripts
-- Handles proximity prompts for buying, selling, and stealing babies

local PromptManager = {}

local function setPlayerSpeed(player, speed)
	if player and player.Character and player.Character:FindFirstChild("Humanoid") then
		player.Character.Humanoid.WalkSpeed = speed
	end
end

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-- Dependencies
local GameUtilities = require(game:GetService("ReplicatedStorage"):WaitForChild("ModuleScripts"):WaitForChild("GameUtilities"))
local BrainrotConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("ModuleScripts"):WaitForChild("BrainrotConfig"))

local function getBrainrotData(name)
	return BrainrotConfig.GetByModelName(name) or BrainrotConfig.Get(name)
end
local BabyManager = require(game:GetService("ServerScriptService"):WaitForChild("ModuleScripts"):WaitForChild("BabyManager"))
local TheftManager = require(game:GetService("ServerScriptService"):WaitForChild("ModuleScripts"):WaitForChild("TheftManager"))
local BaseManager = require(game:GetService("ServerScriptService"):WaitForChild("ModuleScripts"):WaitForChild("BaseManager"))
local CollectionManager = require(game:GetService("ServerScriptService"):WaitForChild("ModuleScripts"):WaitForChild("CollectionManager"))
local ErrorHandler = require(game:GetService("ReplicatedStorage"):WaitForChild("ModuleScripts"):WaitForChild("ErrorHandler"))

-- Server-side: play the baby's sound inside its Proxy, so everyone hears it
local function playBabyPurchaseSound(player, babyName)
	local brainrotSounds = ReplicatedStorage:WaitForChild("BrainotSounds")
	local babySound = brainrotSounds:FindFirstChild(babyName)

	if not babySound then
		warn("❌ No sound found in BrainotSounds for:", babyName)
		return
	end

	-- Find the baby model in workspace that matches
	local babyModel = nil
	for _, model in pairs(workspace:GetDescendants()) do
		if model:IsA("Model") and model.Name == babyName and model:FindFirstChild("Proxy") then
			babyModel = model
			break
		end
	end

	if not babyModel then
		warn("❌ Baby model not found in workspace with name:", babyName)
		return
	end

	local proxy = babyModel:FindFirstChild("Proxy")
	if not proxy then
		warn("❌ Proxy not found in baby model:", babyName)
		return
	end

	-- Clone and play the sound in the proxy
	local soundClone = babySound:Clone()
	soundClone.Parent = proxy
	soundClone.RollOffMode = Enum.RollOffMode.Linear -- Less aggressive volume drop-off
	soundClone.EmitterSize = 15 -- Sweet spot for range
	soundClone.MaxDistance = 80 -- Good hearing distance without being too quiet
	soundClone.Volume = 1 -- Full volume
	soundClone.Looped = false
	soundClone:Play()

	Debris:AddItem(soundClone, soundClone.TimeLength + 1)
end

function PromptManager.setupOwnedBabyPrompt(babyModel, owner, babyName, standNumber)
	local proxy = babyModel:FindFirstChild("Proxy")
	if not proxy then 
		-- Create proxy if it doesn't exist
		proxy = Instance.new("Part")
		proxy.Name = "Proxy"
		proxy.Size = Vector3.new(4, 4, 4)
		proxy.Anchored = true
		proxy.CanCollide = false
		proxy.Transparency = 1
		proxy.Parent = babyModel
	end

	local existingPrompt = proxy:FindFirstChild("ProximityPrompt")
	if existingPrompt then existingPrompt:Destroy() end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Parent = proxy
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false

	local babyData = getBrainrotData(babyName)
	if not babyData then return end

	local sellPrice = math.floor(babyData.price * 0.5)

	prompt.ActionText = "Sell for " .. BrainrotConfig.formatCurrency(sellPrice)
	prompt.ObjectText = babyData.displayName
	prompt.HoldDuration = GameUtilities.SELL_HOLD_DURATION

	local function updatePromptForPlayer(nearbyPlayer)
		if nearbyPlayer == owner then
			prompt.ActionText = "Sell for " .. BrainrotConfig.formatCurrency(sellPrice)
			prompt.ObjectText = babyData.displayName
			prompt.HoldDuration = GameUtilities.SELL_HOLD_DURATION
		else
			prompt.ActionText = "Steal"
			prompt.ObjectText = babyData.displayName
			prompt.HoldDuration = GameUtilities.STEAL_HOLD_DURATION
		end
	end

	task.spawn(function()
		while babyModel.Parent and proxy.Parent do
			task.wait(0.5)
			local nearestPlayer = nil
			local nearestDistance = math.huge

			for _, player in pairs(Players:GetPlayers()) do
				if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					local distance = (player.Character.HumanoidRootPart.Position - proxy.Position).Magnitude
					if distance < 15 and distance < nearestDistance then
						nearestDistance = distance
						nearestPlayer = player
					end
				end
			end

			if nearestPlayer then
				updatePromptForPlayer(nearestPlayer)
			end
		end
	end)

	prompt.Triggered:Connect(function(player)
		local isBeingStolen = babyModel:GetAttribute("IsBeingStolen")

		if player == owner then
			-- Selling
			if isBeingStolen then 
				ErrorHandler.ShowError(player, "BABY_BEING_STOLEN")
				return 
			end

			local moneyAdded = false
			if _G.DataManager and _G.DataManager.addCoins then
				moneyAdded = _G.DataManager.addCoins(player, sellPrice)
			else
				local coins = player.leaderstats:FindFirstChild("Coins")
				if coins then
					coins.Value = coins.Value + sellPrice
					moneyAdded = true
				end
			end

			if moneyAdded then
				CollectionManager.clearStandCollection(player, standNumber)

				local babiesFolder = owner:FindFirstChild("Babies")
				if babiesFolder then
					local folderName = babyName .. "_Stand" .. standNumber
					local babyFolder = babiesFolder:FindFirstChild(folderName)
					if babyFolder then babyFolder:Destroy() end
				end

				-- ONLY PLAY BABY'S UNIQUE SOUND (NO GENERIC BRAINROT SOUND)
				playBabyPurchaseSound(player, babyName)

				babyModel:Destroy()
			end

		else
			-- Stealing attempt - FIXED LOGIC

			-- Check if already carrying a baby
			if TheftManager.carriedBabies[player] then
				ErrorHandler.ShowError(player, "ALREADY_CARRYING")
				return
			end

			-- Check baby count limit for stealing
			if not GameUtilities.canPlayerBuyBaby(player, BabyManager.pendingBabies) then
				ErrorHandler.ShowError(player, "TOO_MANY_BABIES_STEAL")
				task.wait(1)
				ErrorHandler.ShowError(player, "HINT_SELL_BABIES")
				return
			end

			-- Use TheftManager's proper ownership check instead of faulty base comparison
			local canSteal, reason = TheftManager.canStealBaby(babyModel, player)
			if not canSteal then
				ErrorHandler.ShowError(player, reason)
				return
			end

			-- Check base lock status if BaseManager is available
			if BaseManager and BaseManager.getBaseLockStatus then
				local ownerOwnedBase = owner:FindFirstChild("OwnedBase")
				if ownerOwnedBase then
					local isLocked, timeLeft, lockOwner = BaseManager.getBaseLockStatus(ownerOwnedBase.Value)
					if isLocked and lockOwner ~= player then
						local timeText = GameUtilities.formatTime(math.ceil(timeLeft))
						ErrorHandler.ShowError(player, "BASE_ALREADY_LOCKED", timeText)
						return
					end
				end
			end

			-- Attempt theft
			if TheftManager.startTheft(babyModel, player, owner, babyName, standNumber) then
				prompt.Enabled = false

				CollectionManager.clearStandCollection(owner, standNumber)

				local babiesFolder = owner:FindFirstChild("Babies")
				if babiesFolder then
					local folderName = babyName .. "_Stand" .. standNumber
					local babyFolder = babiesFolder:FindFirstChild(folderName)
					if babyFolder then babyFolder:Destroy() end
				end

				-- Notify tutorial system of theft
				if _G.TutorialSystem and _G.TutorialSystem.onBabyStolen then
					_G.TutorialSystem.onBabyStolen(player)
				end
			else
				ErrorHandler.ShowError(player, "BABY_BEING_STOLEN")
			end
		end
	end)
end

function PromptManager.setupMovingBabyPrompt(babyModel)
	-- Only setup prompts for valid moving babies from ServerStorage
	if not GameUtilities.isValidBabyModel(babyModel) then 
		return 
	end

	-- Must be in our moving babies list to get a purchase prompt
	if not GameUtilities.isValidMovingBaby(babyModel, BabyManager.movingBabiesList) then
		return
	end

	local proxy = babyModel:FindFirstChild("Proxy")
	if not proxy then 
		-- Create proxy if missing
		proxy = Instance.new("Part")
		proxy.Name = "Proxy"
		proxy.Size = Vector3.new(4, 4, 4)
		proxy.Anchored = true
		proxy.CanCollide = false
		proxy.Transparency = 1
		proxy.Parent = babyModel

		-- Position proxy at baby's center
		if babyModel.PrimaryPart then
			proxy.CFrame = babyModel.PrimaryPart.CFrame
		end
	end

	-- Remove existing prompt if any
	local existingPrompt = proxy:FindFirstChild("ProximityPrompt")
	if existingPrompt then
		existingPrompt:Destroy()
	end

	-- Create new proximity prompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.Parent = proxy
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false

	local babyName = babyModel.Name
	local babyData = getBrainrotData(babyName)
	if not babyData then 
		prompt:Destroy()
		return 
	end

	prompt.ActionText = "Purchase for " .. BrainrotConfig.formatCurrency(babyData.price)
	prompt.ObjectText = babyData.displayName
	prompt.HoldDuration = GameUtilities.PURCHASE_HOLD_DURATION

	prompt.Triggered:Connect(function(player)
		if not player or not player:FindFirstChild("leaderstats") then return end

		-- Check if already carrying a baby
		if TheftManager.carriedBabies[player] then
			ErrorHandler.ShowError(player, "ALREADY_CARRYING")
			return
		end

		-- Check baby count limit FIRST (including pending babies)
		if not GameUtilities.canPlayerBuyBaby(player, BabyManager.pendingBabies) then
			ErrorHandler.ShowError(player, "TOO_MANY_BABIES_PURCHASE")
			task.wait(1)
			ErrorHandler.ShowError(player, "HINT_SELL_BABIES")
			return
		end

		local coins = player.leaderstats:FindFirstChild("Coins")
		if not coins then return end

		local stand, standNumber = GameUtilities.findAvailableStand(player)
		if not stand then
			ErrorHandler.ShowError(player, "NO_STANDS_AVAILABLE")
			return
		end

		-- Check if player has enough money
		if coins.Value < babyData.price then
			local needed = babyData.price - coins.Value
			ErrorHandler.ShowError(player, "NO_MONEY", BrainrotConfig.formatCurrency(needed))
			return
		end

		-- All validations passed - proceed with purchase
		local coinsRemoved = false
		if _G.DataManager and _G.DataManager.removeCoins then
			coinsRemoved = _G.DataManager.removeCoins(player, babyData.price)
		else
			if coins.Value >= babyData.price then
				coins.Value = coins.Value - babyData.price
				coinsRemoved = true
			end
		end

		if coinsRemoved then
			-- Instantly notify tutorial system of purchase
			if _G.TutorialSystem and _G.TutorialSystem.onBabyPurchased then
				_G.TutorialSystem.onBabyPurchased(player)
			end

			-- Track baby purchase in AllTimeBabies
			if _G.DataManager and _G.DataManager.addToAllTimeBabies then
				_G.DataManager.addToAllTimeBabies(player, babyName)
			end

			-- Add pending baby immediately when purchase succeeds
			BabyManager.addPendingBaby(player)

			if not GameUtilities.setupBabyAnchoring(babyModel, false) then
				-- Remove pending baby if setup fails
				BabyManager.removePendingBaby(player)
				ErrorHandler.ShowError(player, "BABY_BEING_STOLEN")
				return
			end

			prompt.Enabled = false

			-- Remove baby from moving list when purchased
			for i = #BabyManager.movingBabiesList, 1, -1 do
				if BabyManager.movingBabiesList[i] == babyModel then
					table.remove(BabyManager.movingBabiesList, i)
					break
				end
			end

			-- PLAY BABY'S UNIQUE PURCHASE SOUND
			playBabyPurchaseSound(player, babyName)

			BabyManager.moveBabyToPlayerLaser(babyModel, player, babyName)
			ErrorHandler.ShowError(player, "SUCCESS_PURCHASE")

			-- Add PurchasedBy tag for tutorial system
			local tag = Instance.new("StringValue")
			tag.Name = "PurchasedBy"
			tag.Value = player.Name
			tag.Parent = babyModel

			local InBase = Instance.new("BoolValue", babyModel)
			InBase.Name = "InBase"
			InBase.Value = false

		else
			-- Coins removal failed
			ErrorHandler.ShowError(player, "NO_MONEY", BrainrotConfig.formatCurrency(babyData.price))
		end
	end)
end

return PromptManager