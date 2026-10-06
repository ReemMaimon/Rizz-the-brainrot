local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mainGui = playerGui:WaitForChild("MainGui")
local shopFrame = mainGui:WaitForChild("AbilityCardShop")
local content = shopFrame:WaitForChild("Content")
local items = content:WaitForChild("Items")
local template = items:WaitForChild("Template")
local results = content:WaitForChild("Results")
local coinsBalance = shopFrame:WaitForChild("CoinsBalance")
local closeButton = shopFrame:WaitForChild("Close")

local remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local purchasePack = remotes:WaitForChild("PurchaseAbilityPack")
local getPacks = remotes:WaitForChild("GetAbilityPacks")
local openShop = ReplicatedStorage:WaitForChild("Open_ToolsShop")

local packCards = {}

local function updateBalance(value)
	coinsBalance.Text = "Coins: " .. tostring(tonumber(value) or 0)
end

local function showResult(response)
	if not response or not response.Success then
		results.TextColor3 = Color3.fromRGB(255, 130, 130)
		results.Text = response and response.Message or "Purchase failed."
		return
	end
	updateBalance(response.Coins)
	local names = {}
	for _, card in ipairs(response.Cards or {}) do
		table.insert(names, card.New and ("NEW " .. card.DisplayName) or card.DisplayName)
	end
	results.TextColor3 = Color3.fromRGB(160, 255, 180)
	results.Text = "Cards received: " .. table.concat(names, "  •  ")
end

local function clearPackCards()
	for _, card in ipairs(packCards) do
		if card and card.Parent then card:Destroy() end
	end
	packCards = {}
end

local function makePackCard(pack)
	local card = template:Clone()
	card.Name = pack.PackId
	card.Visible = true
	card.Parent = items

	local packName = card:FindFirstChild("PackName")
	local description = card:FindFirstChild("Description")
	local cardCount = card:FindFirstChild("CardCount")
	local price = card:FindFirstChild("Price")
	local buy = card:FindFirstChild("Buy")

	if packName then packName.Text = pack.DisplayName end
	if description then description.Text = pack.Description end
	if cardCount then cardCount.Text = tostring(pack.CardCount) .. " Cards" end
	if price then price.Text = tostring(pack.Price) end
	if buy then buy.Text = "BUY" end

	if buy then
		buy.Activated:Connect(function()
			buy.Active = false
			local success, response = pcall(function()
				return purchasePack:InvokeServer(pack.PackId)
			end)
			showResult(success and response or {Success = false, Message = "Shop request failed."})
			buy.Active = true
		end)
	end

	table.insert(packCards, card)
end

local function loadShop()
	clearPackCards()
	results.Text = ""

	local success, packs = pcall(function()
		return getPacks:InvokeServer()
	end)
	if not success then
		results.TextColor3 = Color3.fromRGB(255, 130, 130)
		results.Text = "Unable to load packs."
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	updateBalance(coins and coins.Value or 0)

	for _, pack in ipairs(packs or {}) do
		makePackCard(pack)
	end
end

local function openAbilityShop()
	if _G.OpenMainGuiFrame then
		_G.OpenMainGuiFrame("AbilityCardShop")
	else
		shopFrame.Visible = true
	end
	loadShop()
end

closeButton.Activated:Connect(function()
	if _G.OpenMainGuiFrame then
		_G.OpenMainGuiFrame("__CLOSE__")
	else
		shopFrame.Visible = false
	end
end)

openShop.OnClientEvent:Connect(function(frameName)
	if frameName == "AbilityCardShop" then
		openAbilityShop()
	elseif frameName == "CoinsShop" and _G.OpenMainGuiFrame then
		_G.OpenMainGuiFrame("CoinsShop")
	end
end)

local leaderstats = player:WaitForChild("leaderstats", 15)
if leaderstats and leaderstats:FindFirstChild("Coins") then
	leaderstats.Coins.Changed:Connect(updateBalance)
end

print("[AbilityCardShopClient] Ready (Studio UI)")