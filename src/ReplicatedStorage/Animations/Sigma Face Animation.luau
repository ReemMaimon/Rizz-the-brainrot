-- R15 Sigma Face: a restrained, intimidating stare rather than a punch.
-- Marker timestamps stay aligned with AbilityConfig's existing presentation timing.
return {
	Settings = {
		Loop = false,
		Priority = Enum.AnimationPriority.Action,
	},
	Markers = {
		Cast = 0.06,
		Attack = 0.48,
		Hit = 0.64,
		RizzRelease = 0.73,
		End = 1.12,
	},
	Timestamps = {
		[0] = {
			LowerTorso = CFrame.new(), UpperTorso = CFrame.new(), Head = CFrame.new(),
			LeftUpperArm = CFrame.new(), LeftLowerArm = CFrame.new(), LeftHand = CFrame.new(),
			RightUpperArm = CFrame.new(), RightLowerArm = CFrame.new(), RightHand = CFrame.new(),
		},
		-- Preparation: straighten subtly, settle the shoulders, and lower the chin.
		[0.12] = {
			LowerTorso = CFrame.new(0, 0.025, 0.018) * CFrame.Angles(math.rad(-1), math.rad(-2), math.rad(-1)),
			UpperTorso = CFrame.Angles(math.rad(2), math.rad(2), math.rad(1)),
			Head = CFrame.Angles(math.rad(5), math.rad(-2), math.rad(-1)),
			LeftUpperArm = CFrame.Angles(math.rad(2), math.rad(-2), math.rad(-4)),
			LeftLowerArm = CFrame.Angles(math.rad(-3), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(2), math.rad(2), math.rad(4)),
			RightLowerArm = CFrame.Angles(math.rad(-3), 0, 0),
		},
		-- Anticipation: chest opens while the head remains deliberately withheld.
		[0.28] = {
			LowerTorso = CFrame.new(-0.018, 0.04, 0.012) * CFrame.Angles(math.rad(-2), math.rad(-5), math.rad(-2)),
			UpperTorso = CFrame.Angles(math.rad(4), math.rad(6), math.rad(2)),
			Head = CFrame.Angles(math.rad(7), math.rad(-8), math.rad(-2)),
			LeftUpperArm = CFrame.Angles(math.rad(4), math.rad(-3), math.rad(-7)),
			LeftLowerArm = CFrame.Angles(math.rad(-5), 0, math.rad(-1)),
			RightUpperArm = CFrame.Angles(math.rad(4), math.rad(3), math.rad(7)),
			RightLowerArm = CFrame.Angles(math.rad(-5), 0, math.rad(1)),
		},
		-- Sigma face reveal: chin rises into direct eye contact with a slight judging tilt.
		[0.48] = {
			LowerTorso = CFrame.new(-0.025, 0.045, -0.008) * CFrame.Angles(math.rad(-3), math.rad(-7), math.rad(-2)),
			UpperTorso = CFrame.Angles(math.rad(6), math.rad(8), math.rad(2)),
			Head = CFrame.Angles(math.rad(-8), math.rad(-9), math.rad(-4)),
			LeftUpperArm = CFrame.Angles(math.rad(6), math.rad(-4), math.rad(-9)),
			LeftLowerArm = CFrame.Angles(math.rad(-7), 0, math.rad(-1)),
			LeftHand = CFrame.Angles(0, 0, math.rad(-2)),
			RightUpperArm = CFrame.Angles(math.rad(6), math.rad(4), math.rad(9)),
			RightLowerArm = CFrame.Angles(math.rad(-7), 0, math.rad(1)),
			RightHand = CFrame.Angles(0, 0, math.rad(2)),
		},
		-- Power moment: near-still stare; squared shoulders make the pause feel dominant.
		[0.64] = {
			LowerTorso = CFrame.new(-0.028, 0.048, -0.012) * CFrame.Angles(math.rad(-3), math.rad(-8), math.rad(-2)),
			UpperTorso = CFrame.Angles(math.rad(7), math.rad(9), math.rad(2)),
			Head = CFrame.Angles(math.rad(-10), math.rad(-10), math.rad(-4)),
			LeftUpperArm = CFrame.Angles(math.rad(7), math.rad(-4), math.rad(-10)),
			LeftLowerArm = CFrame.Angles(math.rad(-8), 0, math.rad(-1)),
			LeftHand = CFrame.Angles(0, 0, math.rad(-2)),
			RightUpperArm = CFrame.Angles(math.rad(7), math.rad(4), math.rad(10)),
			RightLowerArm = CFrame.Angles(math.rad(-8), 0, math.rad(1)),
			RightHand = CFrame.Angles(0, 0, math.rad(2)),
		},
		-- Rizz release: one compact upper-body pulse, driven by the sternum and chin.
		[0.73] = {
			LowerTorso = CFrame.new(0.01, 0.035, -0.045) * CFrame.Angles(math.rad(-5), math.rad(4), math.rad(1)),
			UpperTorso = CFrame.Angles(math.rad(-3), math.rad(-5), math.rad(-1)),
			Head = CFrame.Angles(math.rad(-13), math.rad(4), math.rad(1)),
			LeftUpperArm = CFrame.Angles(math.rad(2), math.rad(-2), math.rad(-7)),
			LeftLowerArm = CFrame.Angles(math.rad(-5), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(2), math.rad(2), math.rad(7)),
			RightLowerArm = CFrame.Angles(math.rad(-5), 0, 0),
		},
		-- Controlled after-hold: the eyes stay forward after the release.
		[0.88] = {
			LowerTorso = CFrame.new(0, 0.025, -0.018) * CFrame.Angles(math.rad(-2), math.rad(1), 0),
			UpperTorso = CFrame.Angles(math.rad(2), math.rad(-1), 0),
			Head = CFrame.Angles(math.rad(-7), math.rad(1), 0),
			LeftUpperArm = CFrame.Angles(math.rad(2), 0, math.rad(-5)),
			LeftLowerArm = CFrame.Angles(math.rad(-4), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(2), 0, math.rad(5)),
			RightLowerArm = CFrame.Angles(math.rad(-4), 0, 0),
		},
		-- Natural recovery without breaking the emotionless composure.
		[1.02] = {
			LowerTorso = CFrame.new(0, 0.01, -0.005) * CFrame.Angles(math.rad(-1), 0, 0),
			UpperTorso = CFrame.Angles(math.rad(1), 0, 0),
			Head = CFrame.Angles(math.rad(-3), 0, 0),
			LeftUpperArm = CFrame.Angles(math.rad(1), 0, math.rad(-2)),
			LeftLowerArm = CFrame.Angles(math.rad(-2), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(1), 0, math.rad(2)),
			RightLowerArm = CFrame.Angles(math.rad(-2), 0, 0),
		},
		[1.12] = {
			LowerTorso = CFrame.new(), UpperTorso = CFrame.new(), Head = CFrame.new(),
			LeftUpperArm = CFrame.new(), LeftLowerArm = CFrame.new(), LeftHand = CFrame.new(),
			RightUpperArm = CFrame.new(), RightLowerArm = CFrame.new(), RightHand = CFrame.new(),
		},
	},
}
