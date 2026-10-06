-- Tool Script: Anti-Steal AoE Version (5 meter radius + 0.4s cooldown)
local tool = script.Parent
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

-- Asset IDs
local hitAnimId  = "rbxassetid://110995150636949"
local missSoundId = "rbxassetid://9113305311"
local hitSoundId  = "rbxassetid://10730819"

local canUse = true
local humanoid, animator, character = nil, nil, nil

-- Setup sounds
local hitSound = Instance.new("Sound", tool)
hitSound.Name = "HitSound"
hitSound.SoundId = hitSoundId
hitSound.Volume = 1

local missSound = Instance.new("Sound", tool)
missSound.Name = "MissSound"
missSound.SoundId = missSoundId
missSound.Volume = 1

-- Paralyze logic
local function paralyzeNow(character, humanoid)
	humanoid.PlatformStand = true
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	task.delay(2.5, function()
		if humanoid.Health > 0 then
			humanoid.PlatformStand = false
			humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end)
end

-- AoE hit logic - affects all players within 5 meters
local function performAoEAttack()
	local myRoot = character:FindFirstChild("HumanoidRootPart")
	if not myRoot then return 0 end

	local hitCount = 0

	-- Check all players in the game
	for _, player in pairs(Players:GetPlayers()) do
		if player.Character and player.Character ~= character then
			local hitChar = player.Character
			local hitHumanoid = hitChar:FindFirstChildOfClass("Humanoid")
			local hitRoot = hitChar:FindFirstChild("HumanoidRootPart")

			if hitHumanoid and hitRoot and hitHumanoid.Health > 0 then
				-- Check if within 5 meter range
				local distance = (hitRoot.Position - myRoot.Position).Magnitude
				if distance <= 5 then
					hitCount = hitCount + 1

					-- Apply paralyze effect
					paralyzeNow(hitChar, hitHumanoid)

					-- Apply knockback
					local dir = (hitRoot.Position - myRoot.Position).Unit
					local bv = Instance.new("BodyVelocity", hitRoot)
					bv.Velocity = dir * 200 + Vector3.new(0, 80, 0)
					bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
					bv.P = 125000
					Debris:AddItem(bv, 0.3)

					-- Baby return logic
					if _G.ForceReturnStolenBaby then
						local success = _G.ForceReturnStolenBaby(player)
						if success then
							local toolUser = Players:GetPlayerFromCharacter(character)
							if toolUser then
								local gui = toolUser:FindFirstChild("PlayerGui"):FindFirstChild("MainGui"):FindFirstChild("ErrorGui")
								local txt = gui and gui:FindFirstChild("ErrorText")
								if txt then
									local count = _G.DebugBabyCount and _G.DebugBabyCount(player).total or "Unknown"
									local oldT, oldC, oldV = txt.Text, txt.TextColor3, gui.Visible
									txt.Text = "✅ Baby Returned! Thief now has " .. count .. "/10 babies"
									txt.TextColor3 = Color3.new(0, 1, 0)
									gui.Visible = true

									task.delay(3, function()
										if txt.Text:find("✅ Baby Returned!") then
											txt.Text, txt.TextColor3, gui.Visible = oldT, oldC, oldV
										end
									end)
								end
							end
						end
					end
				end
			end
		end
	end

	return hitCount
end

-- Slash logic with 0.4s cooldown and AoE attack
local function slash()
	if not canUse then return end
	canUse = false

	character = tool.Parent
	humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then 
		canUse = true
		return 
	end
	animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)

	-- Play hit animation
	local hitAnim = Instance.new("Animation")
	hitAnim.AnimationId = hitAnimId
	local hitTrack = animator:LoadAnimation(hitAnim)
	hitTrack.Priority = Enum.AnimationPriority.Action
	hitTrack:Play()

	-- Perform AoE attack and get hit count
	local hitCount = performAoEAttack()

	-- Play appropriate sound based on whether anyone was hit
	if hitCount > 0 then
		hitSound:Play() -- Play hit sound if anyone was affected
	else
		missSound:Play() -- Play miss sound if no one was hit
	end

	-- 0.4 second cooldown
	task.delay(0.4, function()
		canUse = true
	end)
end

-- Connect everything
tool.Activated:Connect(slash)