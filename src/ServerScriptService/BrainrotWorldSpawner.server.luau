local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local BrainrotConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("BrainrotConfig"))
local AreaConfig = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("AreaConfig"))
local BrainrotWorldService = require(script.Parent:WaitForChild("ModuleScripts"):WaitForChild("BrainrotWorldService"))

local activeFolderName = BrainrotConfig.Spawn.FolderName or "ActiveBrainrots"
local activeFolder = Workspace:FindFirstChild(activeFolderName)
if not activeFolder then
	activeFolder = Instance.new("Folder")
	activeFolder.Name = activeFolderName
	activeFolder.Parent = Workspace
end

local function findSpawnPlatform(area)
	local configuredName = area.SpawnPartName
	if configuredName then
		local configured = Workspace:FindFirstChild(configuredName, true)
		if configured and configured:IsA("BasePart") then
			return configured
		end
	end
	local fallback = Workspace:FindFirstChild(area.DisplayName, true)
	if fallback and fallback:IsA("BasePart") then
		return fallback
	end
end

local areaPlatforms = {}
for _, area in ipairs(AreaConfig.Areas or {}) do
	local platform = findSpawnPlatform(area)
	if platform then
		platform:SetAttribute("AreaId", area.AreaId or area.Id)
		table.insert(areaPlatforms, {Area = area, Platform = platform})
	else
		warn(string.format("[BrainrotWorldSpawner] Missing spawn platform for %s (%s)", tostring(area.AreaId or area.Id), tostring(area.SpawnPartName)))
	end
end

local function spawnInArea(entry)
	local model, reason = BrainrotWorldService:Spawn(entry.Platform, activeFolder, entry.Area.AreaId or entry.Area.Id)
	if not model and reason ~= "Maximum brainrots reached" then
		warn(string.format("[BrainrotWorldSpawner] Could not spawn in %s: %s", tostring(entry.Area.AreaId or entry.Area.Id), tostring(reason)))
	end
	return model
end

if BrainrotConfig.Spawn.Enabled ~= false and #areaPlatforms > 0 then
	local initialCount = math.max(0, math.floor(tonumber(BrainrotConfig.Spawn.InitialSpawnCount) or 0))
	for index = 1, initialCount do
		local entry = areaPlatforms[((index - 1) % #areaPlatforms) + 1]
		spawnInArea(entry)
	end

	task.spawn(function()
		local interval = math.max(1, tonumber(BrainrotConfig.Spawn.SpawnInterval) or 10)
		while task.wait(interval) do
			if BrainrotWorldService:GetActiveCount() >= BrainrotConfig.Spawn.MaxWorldBrainrots then
				continue
			end
			for _, entry in ipairs(areaPlatforms) do
				if BrainrotWorldService:GetActiveCount() >= BrainrotConfig.Spawn.MaxWorldBrainrots then
					break
				end
				spawnInArea(entry)
			end
		end
	end)
end

print(string.format("[BrainrotWorldSpawner] World spawning enabled across %d area(s); carpet spawning remains victory-only", #areaPlatforms))