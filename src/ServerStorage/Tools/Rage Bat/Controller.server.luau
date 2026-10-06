local tool = script.Parent
local Debris = game:GetService("Debris")

local hitAnimId = "rbxassetid://121478842828549"
local missSoundId = "rbxassetid://9113305311"
local hitSoundId = "rbxassetid://146163534"

local canUse = true
local humanoid, animator, character = nil, nil, nil
local pendingHit = false

local hitSound = Instance.new("Sound", tool)
hitSound.Name = "HitSound"
hitSound.SoundId = hitSoundId
hitSound.Volume = 1

local missSound = Instance.new("Sound", tool)
missSound.Name = "MissSound"
missSound.SoundId = missSoundId
missSound.Volume = 1

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

local function onTouch(otherPart)
	if not pendingHit then return end

	local hitChar = otherPart:FindFirstAncestorOfClass("Model")
	if not hitChar or hitChar == character then return end

	local hitHumanoid = hitChar:FindFirstChildOfClass("Humanoid")
	local hitRoot = hitChar:FindFirstChild("HumanoidRootPart")
	local myRoot = character:FindFirstChild("HumanoidRootPart")

	if hitHumanoid and hitRoot and myRoot and hitHumanoid.Health > 0 then
		pendingHit = false

		paralyzeNow(hitChar, hitHumanoid)

		local dir = (hitRoot.Position - myRoot.Position).Unit
		local bv = Instance.new("BodyVelocity", hitRoot)
		bv.Velocity = dir * 120 + Vector3.new(0, 50, 0)
		bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
		bv.P = 125000
		Debris:AddItem(bv, 0.3)

		local targetPlayer = game.Players:GetPlayerFromCharacter(hitChar)
		if targetPlayer and _G.ForceReturnStolenBaby then
			local success = _G.ForceReturnStolenBaby(targetPlayer)
			if success then
				local toolUser = game.Players:GetPlayerFromCharacter(character)
				if toolUser then
					local gui = toolUser:FindFirstChild("PlayerGui"):FindFirstChild("MainGui"):FindFirstChild("ErrorGui")
					local txt = gui and gui:FindFirstChild("ErrorText")
					if txt then
						local count = _G.DebugBabyCount and _G.DebugBabyCount(targetPlayer).total or "Unknown"
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

		hitSound:Play()
	end
end

local function slash()
	if not canUse then return end
	canUse = false
	pendingHit = false

	character = tool.Parent
	humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)

	local hitAnim = Instance.new("Animation")
	hitAnim.AnimationId = hitAnimId
	local hitTrack = animator:LoadAnimation(hitAnim)
	hitTrack.Priority = Enum.AnimationPriority.Action
	hitTrack:Play()

	missSound:Play()

	task.delay(0.2, function()
		pendingHit = true
		task.delay(0.15, function()
			pendingHit = false
		end)
		canUse = true
	end)
end

tool.Activated:Connect(slash)
tool.Handle.Touched:Connect(onTouch)