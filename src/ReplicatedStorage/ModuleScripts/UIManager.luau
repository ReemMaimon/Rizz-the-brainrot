-- UIManager.lua - SIMPLE FIX (just visibility and text updates)
local UIManager = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Dependencies
local BrainrotConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("BrainrotConfig"))
local GameUtilities = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("GameUtilities"))

-- Initialize workspace references
UIManager.basesFolder = nil

-- ===========================
-- CLIENT COMMUNICATION SETUP
-- ===========================

local function getOrCreateCollectionUIRemote()
	local remote = ReplicatedStorage:FindFirstChild("CollectionUIRemote")
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = "CollectionUIRemote"
		remote.Parent = ReplicatedStorage
	end
	return remote
end

local collectionUIRemote = getOrCreateCollectionUIRemote()

function UIManager.disableCollectionUIOnClient(player, standNumber)
	if player and player.Parent and collectionUIRemote then
		collectionUIRemote:FireClient(player, "disable", standNumber)
	end
end

function UIManager.enableCollectionUIOnClient(player, standNumber)
	if player and player.Parent and collectionUIRemote then
		collectionUIRemote:FireClient(player, "enable", standNumber)
	end
end

function UIManager.clearAllDisabledUIsOnClient(player)
	if player and player.Parent and collectionUIRemote then
		collectionUIRemote:FireClient(player, "clear_all")
	end
end

-- ===========================
-- COLLECTION UI FUNCTIONS - SIMPLE
-- ===========================

function UIManager.updateCollectionUIWithOffline(player, standNumber, totalAmount, offlineAmount)
	if not player or not player.Parent or not standNumber then return end

	local ownedBase = player:FindFirstChild("OwnedBase")
	if not ownedBase then return end

	local baseNumber = ownedBase.Value
	local baseName = "Base" .. baseNumber
	local base = UIManager.basesFolder and UIManager.basesFolder:FindFirstChild(baseName)
	if not base then return end

	local standsFolder = base:FindFirstChild("Stands")
	if not standsFolder then return end

	local stand = standsFolder:FindFirstChild("Stand" .. standNumber)
	if not stand then return end

	local collect = stand:FindFirstChild("Collect")
	if not collect then return end

	-- Use existing structure: Collect > Text > BillboardGui
	local text = collect:FindFirstChild("Text")
	if not text then return end

	local billboardGui = text:FindFirstChild("BillboardGui")
	if not billboardGui then return end

	-- Update existing labels
	local amountToTake = billboardGui:FindFirstChild("AmountToTake")
	local collectText = billboardGui:FindFirstChild("CollectText")

	if amountToTake then
		local formatCurrency = BrainrotConfig.formatCurrency or GameUtilities.formatNumber or tostring

		if offlineAmount and offlineAmount > 0 then
			amountToTake.Text = formatCurrency(totalAmount) .. "\n(+" .. formatCurrency(offlineAmount) .. " Offline)"
			amountToTake.TextColor3 = Color3.fromRGB(255, 255, 0) -- Yellow for offline
		else
			amountToTake.Text = formatCurrency(totalAmount)
			amountToTake.TextColor3 = Color3.fromRGB(100, 255, 100) -- Green for regular
		end
	end

	if collectText then
		collectText.Text = "Collect"
	end

	-- Make visible
	billboardGui.Enabled = true
	billboardGui.AlwaysOnTop = true
end

function UIManager.updateCollectionUI(player, standNumber, amount)
	UIManager.updateCollectionUIWithOffline(player, standNumber, amount, nil)
end

function UIManager.disableCollectionUI(player, standNumber)
	if not player or not standNumber then return end

	local ownedBase = player:FindFirstChild("OwnedBase")
	if not ownedBase then return end

	local baseNumber = ownedBase.Value
	local baseName = "Base" .. baseNumber
	local base = UIManager.basesFolder and UIManager.basesFolder:FindFirstChild(baseName)
	if not base then return end

	local standsFolder = base:FindFirstChild("Stands")
	if not standsFolder then return end

	local stand = standsFolder:FindFirstChild("Stand" .. standNumber)
	if not stand then return end

	local collect = stand:FindFirstChild("Collect")
	if not collect then return end

	-- Use existing structure: Collect > Text > BillboardGui
	local text = collect:FindFirstChild("Text")
	if not text then return end

	local billboardGui = text:FindFirstChild("BillboardGui")
	if not billboardGui then return end

	-- Just make it invisible
	billboardGui.Enabled = false

	-- Tell client too
	UIManager.disableCollectionUIOnClient(player, standNumber)
end

function UIManager.enableCollectionUI(player, standNumber)
	if not player or not standNumber then return end

	local ownedBase = player:FindFirstChild("OwnedBase")
	if not ownedBase then return end

	local baseNumber = ownedBase.Value
	local baseName = "Base" .. baseNumber
	local base = UIManager.basesFolder and UIManager.basesFolder:FindFirstChild(baseName)
	if not base then return end

	local standsFolder = base:FindFirstChild("Stands")
	if not standsFolder then return end

	local stand = standsFolder:FindFirstChild("Stand" .. standNumber)
	if not stand then return end

	local collect = stand:FindFirstChild("Collect")
	if not collect then return end

	-- Use existing structure: Collect > Text > BillboardGui
	local text = collect:FindFirstChild("Text")
	if not text then return end

	local billboardGui = text:FindFirstChild("BillboardGui")
	if not billboardGui then return end

	-- Just make it visible
	billboardGui.Enabled = true

	-- Tell client too
	UIManager.enableCollectionUIOnClient(player, standNumber)
end

-- ===========================
-- OTHER EXISTING FUNCTIONS (unchanged)
-- ===========================

function UIManager.updateBaseName(baseNumber, playerName)
	if not baseNumber or not UIManager.basesFolder then return end

	local baseName = "Base" .. baseNumber
	local base = UIManager.basesFolder:FindFirstChild(baseName)
	if base then
		local baseNameParent = base:FindFirstChild("BaseNameParent")
		if baseNameParent then
			local baseNameContainer = baseNameParent:FindFirstChild("BaseNameContainer")
			if baseNameContainer then
				local surfaceGui = baseNameContainer:FindFirstChild("SurfaceGui")
				if surfaceGui then
					local textLabel = surfaceGui:FindFirstChild("TextLabel")
					if textLabel then
						textLabel.Text = playerName or "Empty Base"
					end
				end
			end
		end
	end
end

function UIManager.updateBabyUI(babyModel)
	if not babyModel or not babyModel.Parent then return end

	local babyName = babyModel.Name:gsub("_Carried", ""):gsub("_Stolen", "")
	local babyData = BrainrotConfig.getBabyData(babyName)
	if not babyData then return end

	local textPart = babyModel:FindFirstChild("Text")
	if textPart then
		local billboardGui = textPart:FindFirstChild("BillboardGui")
		if billboardGui then
			local nameLabel = billboardGui:FindFirstChild("Name")
			local priceLabel = billboardGui:FindFirstChild("Price")
			local perSecLabel = billboardGui:FindFirstChild("PerSec")
			local rarityLabel = billboardGui:FindFirstChild("Rarity")

			if not rarityLabel then
				rarityLabel = Instance.new("TextLabel")
				rarityLabel.Name = "Rarity"
				rarityLabel.Size = UDim2.new(1, 0, 0.2, 0)
				rarityLabel.Position = UDim2.new(0, 0, 0.8, 0)
				rarityLabel.BackgroundTransparency = 1
				rarityLabel.TextScaled = true
				rarityLabel.Font = Enum.Font.GothamBold
				rarityLabel.Parent = billboardGui
			end

			if nameLabel then 
				nameLabel.Text = babyData.displayName or babyData.name or babyName
			end
			if priceLabel and BrainrotConfig.formatCurrency then 
				priceLabel.Text = BrainrotConfig.formatCurrency(babyData.price or 0)
			end
			if perSecLabel and BrainrotConfig.formatPerSec then 
				perSecLabel.Text = BrainrotConfig.formatPerSec(babyData.perSec or 0)
			end

			local rarity = BrainrotConfig.getBabyRarity and BrainrotConfig.getBabyRarity(babyName) or babyData.rarity
			local rarityInfo = BrainrotConfig.getRarityInfo and BrainrotConfig.getRarityInfo(rarity)
			if rarityInfo then
				rarityLabel.Text = rarityInfo.displayName or rarity

				if BrainrotConfig.applyRarityEffects then
					BrainrotConfig.applyRarityEffects(rarityLabel, rarity)
					if nameLabel then
						BrainrotConfig.applyRarityEffects(nameLabel, rarity)
					end
				end
			end
		end
	end
end

function UIManager.setBabyAsStolen(babyModel, isCarriedBaby)
	if not babyModel or not babyModel.Parent then return end

	local textPart = babyModel:FindFirstChild("Text")
	if not textPart then return end

	local billboardGui = textPart:FindFirstChild("BillboardGui")
	if not billboardGui then return end

	for _, label in pairs(billboardGui:GetChildren()) do
		if label:IsA("TextLabel") then
			label.Visible = false
		end
	end

	local nameLabel = billboardGui:FindFirstChild("Name")
	if nameLabel then
		nameLabel.Visible = true
		if isCarriedBaby then
			nameLabel.Text = "STEALING!"
			nameLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
		else
			nameLabel.Text = "STOLEN!"
			nameLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
		end

		local uiStroke = nameLabel:FindFirstChild("UIStroke")
		if uiStroke then
			uiStroke:Destroy()
		end
	end
end

function UIManager.restoreBabyFromStolen(babyModel, babyName)
	if not babyModel or not babyModel.Parent then return end

	UIManager.updateBabyUI(babyModel)

	local textPart = babyModel:FindFirstChild("Text")
	if not textPart then return end

	local billboardGui = textPart:FindFirstChild("BillboardGui")
	if not billboardGui then return end

	for _, child in ipairs(billboardGui:GetChildren()) do
		if child:IsA("TextLabel") then
			child.Visible = true
		end
	end

	if BrainrotConfig.getBabyRarity and BrainrotConfig.applyRarityEffects then
		local rarity = BrainrotConfig.getBabyRarity(babyName)
		local nameLabel = billboardGui:FindFirstChild("Name")
		local rarityLabel = billboardGui:FindFirstChild("Rarity")

		if nameLabel then
			BrainrotConfig.applyRarityEffects(nameLabel, rarity)
		end

		if rarityLabel then
			BrainrotConfig.applyRarityEffects(rarityLabel, rarity)
		end
	end
end

function UIManager.updateLockUI(baseNumber, baseLocks)
	if not baseNumber or not baseLocks or not UIManager.basesFolder then return end

	local baseName = "Base" .. baseNumber
	local base = UIManager.basesFolder:FindFirstChild(baseName)
	if not base then return end

	local lock = base:FindFirstChild("Lock")
	if not lock then return end

	local text = lock:FindFirstChild("Text")
	if not text then return end

	local billboardGui = text:FindFirstChild("BillboardGui")
	if not billboardGui then return end

	local lockText = billboardGui:FindFirstChild("LockText")
	local timer = billboardGui:FindFirstChild("Timer")

	if not lockText or not timer then return end

	local lockData = baseLocks[baseNumber]
	local isLocked = lockData and lockData.locked

	if isLocked then
		local timeLeft = math.max(0, lockData.endTime - tick())
		lockText.Text = "Locked:"
		lockText.TextColor3 = Color3.fromRGB(255, 0, 0)
		timer.Text = math.ceil(timeLeft) .. "s"
		timer.TextColor3 = Color3.fromRGB(255, 255, 255)
		timer.Visible = true
	else
		lockText.Text = "Lock Base"
		lockText.TextColor3 = Color3.fromRGB(200, 200, 0)
		timer.Visible = false
	end
end

function UIManager.setBaseEmpty(baseNumber)
	if not baseNumber then return end

	-- Free bases are claimable by any player
	UIManager.updateBaseName(baseNumber, "Empty Base")
	local baseName = "Base" .. baseNumber
	local base = UIManager.basesFolder and UIManager.basesFolder:FindFirstChild(baseName)
	if not base then return end

	local lazer = base:FindFirstChild("Lazer")
	if lazer then
		for _, part in pairs(lazer:GetChildren()) do
			if part:IsA("BasePart") then
				if part.Name ~= "Blocker" then
					part.Transparency = 1
				end
				part.CanCollide = false
			end
		end
	end

	local lock = base:FindFirstChild("Lock")
	if lock then
		local text = lock:FindFirstChild("Text")
		if text then
			local billboardGui = text:FindFirstChild("BillboardGui")
			if billboardGui then
				billboardGui.Enabled = false
			end
		end
	end
end

function UIManager.setBaseOccupied(baseNumber, player)
	if not baseNumber or not player then return end

	-- Owned bases are unavailable: flag the owner so players can tell claimable bases apart
	UIManager.updateBaseName(baseNumber, "🔒 " .. player.Name)
	local baseName = "Base" .. baseNumber
	local base = UIManager.basesFolder and UIManager.basesFolder:FindFirstChild(baseName)
	if not base then return end

	local lock = base:FindFirstChild("Lock")
	if lock then
		local text = lock:FindFirstChild("Text")
		if text then
			local billboardGui = text:FindFirstChild("BillboardGui")
			if billboardGui then
				billboardGui.Enabled = true
			end
		end
	end
end

-- Backward compatibility
function UIManager.updateBabyUIForStolen(babyModel)
	UIManager.setBabyAsStolen(babyModel, false)
end

return UIManager