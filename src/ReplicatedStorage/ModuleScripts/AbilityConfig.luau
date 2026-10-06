local config = {
	LevelScaling = {
		[1] = 10,
		[2] = 5,
		[3] = 1,
		[4] = 0.3,
		[5] = 0.1,
	},
	MaxEquippedAbilities = 4,
	GiveTestAbilities = true,
	TestAbilities = {
		"SigmaFace",
		"SigmaMewing",
		"RizzPunch",
		"RizzBlast",
	},
	DefaultOwnedAbilities = {},
	DefaultEquippedAbilities = {nil, nil, nil, nil},
	CardPacks = {
		StarterPack = {
			PackId = "StarterPack",
			DisplayName = "Starter Pack",
			Description = "Three cards with a chance to unlock new moves.",
			Price = 250,
			CardCount = 3,
			RarityWeights = {Common = 60, Uncommon = 25, Rare = 10, Epic = 4, Legendary = 1},
			EligibleAbilities = {"SigmaFace", "SigmaMewing", "RizzPunch", "RizzBlast", "MogAttack", "GyattSlam", "OhioEnergy", "FanumTax", "GrimaceBeam", "UltimateRizz"},
		},
		PowerPack = {
			PackId = "PowerPack",
			DisplayName = "Power Pack",
			Description = "Five cards weighted toward stronger moves.",
			Price = 750,
			CardCount = 5,
			RarityWeights = {Common = 35, Uncommon = 30, Rare = 20, Epic = 10, Legendary = 4, Mythic = 1},
			EligibleAbilities = {"SigmaMewing", "RizzBlast", "MogAttack", "GyattSlam", "OhioEnergy", "FanumTax", "GrimaceBeam", "UltimateRizz"},
		},
	},
	Abilities = {
		UltimateRizz = {
			AbilityId = "UltimateRizz", DisplayName = "Ultimate Rizz", Description = "Unleash the ultimate expression of Rizz.", Rarity = "OG", Damage = 75, PowerMultiplier = 4.0, ManaCost = 40, Cooldown = 7, TargetType = "Enemy", AbilityType = "Damage", Icon = "", AnimationId = "", SoundId = "", VFX = "",
			BaseStats = {Damage = 250, Cooldown = 30, Radius = 25, Duration = 5},
			RizzScaling = {
				Damage = {Enabled = true, Interval = 5, Mode = "Multiplicative", IncreasePerStep = 0.15, MaxValue = 750},
				Cooldown = {Enabled = true, Interval = 5, Mode = "Multiplicative", IncreasePerStep = -0.05, MinValue = 10},
				Radius = {Enabled = true, Interval = 5, Mode = "Additive", IncreasePerStep = 5, MaxValue = 60},
				Duration = {Enabled = true, Interval = 5, Mode = "Additive", IncreasePerStep = 0.5, MaxValue = 10},
			},
		},
		GrimaceBeam = {
			AbilityId = "GrimaceBeam", DisplayName = "Grimace Beam", Description = "Fire a powerful purple beam.", Rarity = "Mythic", Damage = 50, PowerMultiplier = 3.0, ManaCost = 28, Cooldown = 5, TargetType = "Enemy", AbilityType = "Damage", Icon = "", AnimationId = "", SoundId = "", VFX = "",
			BaseStats = {Damage = 180, Cooldown = 20, BeamDuration = 3},
			RizzScaling = {
				Damage = {Enabled = true, Interval = 5, Mode = "Multiplicative", IncreasePerStep = 0.12, MaxValue = 500},
				Cooldown = {Enabled = true, Interval = 5, Mode = "Multiplicative", IncreasePerStep = -0.05, MinValue = 7},
				BeamDuration = {Enabled = true, Interval = 5, Mode = "Additive", IncreasePerStep = 0.5, MaxValue = 7},
			},
		},
		GyattSlam = {
			AbilityId = "GyattSlam", DisplayName = "Gyatt Slam", Description = "A heavy slam that shakes the battle.", Rarity = "Epic", Damage = 38, PowerMultiplier = 2.5, ManaCost = 22, Cooldown = 4, TargetType = "Enemy", AbilityType = "Damage", Icon = "", AnimationId = "", SoundId = "", VFX = "",
			BaseStats = {Damage = 160, Cooldown = 18, Radius = 15},
			RizzScaling = {
				Damage = {Enabled = true, Interval = 5, Mode = "Multiplicative", IncreasePerStep = 0.12, MaxValue = 450},
				Cooldown = {Enabled = true, Interval = 5, Mode = "Multiplicative", IncreasePerStep = -0.05, MinValue = 6},
				Radius = {Enabled = true, Interval = 5, Mode = "Additive", IncreasePerStep = 3, MaxValue = 35},
			},
		},
		OhioEnergy = {
			AbilityId = "OhioEnergy", DisplayName = "Ohio Energy", Description = "An unpredictable special ability hook.", Rarity = "Epic", Damage = 0, PowerMultiplier = 1.0, ManaCost = 12, Cooldown = 3, TargetType = "Self", AbilityType = "Special", Icon = "", AnimationId = "", SoundId = "", VFX = "",
			BaseStats = {Damage = 120, Cooldown = 16, ProjectileCount = 3},
			RizzScaling = {
				Damage = {Enabled = true, Interval = 5, Mode = "Multiplicative", IncreasePerStep = 0.10, MaxValue = 350},
				Cooldown = {Enabled = true, Interval = 5, Mode = "Multiplicative", IncreasePerStep = -0.05, MinValue = 6},
				ProjectileCount = {Enabled = true, Interval = 5, Mode = "Additive", IncreasePerStep = 1, MaxValue = 10},
			},
		},
		RizzBlast = {
			AbilityId = "RizzBlast", DisplayName = "Rizz Blast", Description = "Launch a concentrated blast of Rizz.", Rarity = "Rare", Damage = 25, PowerMultiplier = 1.75, ManaCost = 14, Cooldown = 2, TargetType = "Enemy", AbilityType = "Damage", Icon = "", AnimationId = "", SoundId = "", VFX = "",
			BaseStats = {Damage = 120, Cooldown = 14, Range = 50},
			RizzScaling = {
				Damage = {Enabled = true, Interval = 5, Mode = "Multiplicative", IncreasePerStep = 0.10, MaxValue = 350},
				Cooldown = {Enabled = true, Interval = 5, Mode = "Multiplicative", IncreasePerStep = -0.05, MinValue = 5},
				Range = {Enabled = true, Interval = 5, Mode = "Additive", IncreasePerStep = 5, MaxValue = 100},
			},
		},
		MogAttack = {
			AbilityId = "MogAttack", DisplayName = "Mog Attack", Description = "Overpower the enemy with unmatched aura.", Rarity = "Rare", Damage = 30, PowerMultiplier = 2.0, ManaCost = 16, Cooldown = 3, TargetType = "Enemy", AbilityType = "Damage", Icon = "", AnimationId = "", SoundId = "", VFX = "",
			BaseStats = {Damage = 130, Cooldown = 13},
			RizzScaling = {
				Damage = {Enabled = true, Interval = 5, Mode = "Multiplicative", IncreasePerStep = 0.10, MaxValue = 350},
				Cooldown = {Enabled = true, Interval = 5, Mode = "Multiplicative", IncreasePerStep = -0.05, MinValue = 5},
			},
		},
		RizzPunch = {
			AbilityId = "RizzPunch", DisplayName = "Rizz Punch", Description = "A reliable punch powered by Rizz.", Rarity = "Common", Damage = 12, PowerMultiplier = 1.0, ManaCost = 5, Cooldown = 0, TargetType = "Enemy", AbilityType = "Damage", Icon = "", AnimationId = "", SoundId = "", VFX = "",
			BaseStats = {Damage = 110, Cooldown = 11, Knockback = 50},
			RizzScaling = {
				Damage = {Enabled = true, Interval = 5, Mode = "Multiplicative", IncreasePerStep = 0.10, MaxValue = 300},
				Cooldown = {Enabled = true, Interval = 5, Mode = "Multiplicative", IncreasePerStep = -0.05, MinValue = 4},
				Knockback = {Enabled = true, Interval = 5, Mode = "Additive", IncreasePerStep = 10, MaxValue = 150},
			},
		},
		SigmaFace = {
			AbilityId = "SigmaFace", DisplayName = "Sigma Face", Description = "Form a sigma energy guard, strike a commanding pose, then fire a focused jawline beam.", Rarity = "Common", Damage = 10, PowerMultiplier = 1.0, ManaCost = 5, Cooldown = 1, TargetType = "Enemy", AbilityType = "Damage", Icon = "", AnimationId = "", SoundId = "", VFX = "SigmaFace",
			BaseStats = {Damage = 100, Cooldown = 10},
			RizzScaling = {
				Damage = {Enabled = true, Interval = 5, Mode = "Multiplicative", IncreasePerStep = 0.10, MaxValue = 300},
				Cooldown = {Enabled = true, Interval = 5, Mode = "Multiplicative", IncreasePerStep = -0.05, MinValue = 3},
			},
			Presentation = {
				Animation = "Sigma Face Animation",
				Markers = {Cast = 0.06, Attack = 0.48, Hit = 0.64, RizzRelease = 0.73, End = 1.12},
				AttackTime = 0.48,
				HitTime = 0.73,
				RecoveryTime = 1.12,
				VFX = {
					ChargeColor = {0.28, 0.82, 1},
					ChargeSize = 0.7,
					AttackSize = 1.0,
					ImpactSize = 2.25,
					Duration = 0.24,
					Buildup = {AuraRadius = 2.5, GlowBrightness = 1.8, ParticleRate = 18},
					Shield = {Radius = 4.2, FormationTime = 0.18, PulseTime = 0.32, FadeTime = 0.16, ParticleCount = 28, OrbitCount = 6},
					Laser = {CoreWidth = 0.22, GlowWidth = 0.72, Duration = 0.16, ParticleCount = 18},
				},
				Sounds = {Cast = "", Attack = "", Hit = ""},
			},
		},
		FanumTax = {
			AbilityId = "FanumTax", DisplayName = "Fanum Tax", Description = "Take a bite out of the enemy's momentum.", Rarity = "Legendary", Damage = 28, PowerMultiplier = 2.0, ManaCost = 18, Cooldown = 3, TargetType = "Enemy", AbilityType = "Special", Icon = "", AnimationId = "", SoundId = "", VFX = "",
			BaseStats = {Damage = 75, Cooldown = 8},
			RizzScaling = {
				Damage = {Enabled = true, Interval = 5, Mode = "Multiplicative", IncreasePerStep = 0.08, MaxValue = 200},
				Cooldown = {Enabled = true, Interval = 5, Mode = "Multiplicative", IncreasePerStep = -0.10, MinValue = 2},
			},
		},
		SigmaMewing = {
			AbilityId = "SigmaMewing", DisplayName = "Sigma Mewing", Description = "Overwhelm the enemy with focused Sigma energy.", Rarity = "Uncommon", Damage = 18, PowerMultiplier = 1.5, ManaCost = 9, Cooldown = 2, TargetType = "Enemy", AbilityType = "Damage", Icon = "", AnimationId = "", SoundId = "", VFX = "",
			BaseStats = {Damage = 60, Cooldown = 7, Duration = 3},
			RizzScaling = {
				Damage = {Enabled = true, Interval = 5, Mode = "Multiplicative", IncreasePerStep = 0.08, MaxValue = 150},
				Cooldown = {Enabled = true, Interval = 5, Mode = "Multiplicative", IncreasePerStep = -0.05, MinValue = 2},
				Duration = {Enabled = true, Interval = 5, Mode = "Additive", IncreasePerStep = 0.5, MaxValue = 7},
			},
		},
	},
}

-- BaseStats contains arbitrary numeric gameplay stats. RizzScaling is optional per stat.
-- Interval is the number of Rizz Levels per step; Mode is Additive or Multiplicative.
-- IncreasePerStep may be negative for reductions such as cooldowns. MinValue/MaxValue cap the result.
-- Add a new stat by adding it to BaseStats and optionally adding the same key to RizzScaling.
-- Example 1: Damage every 5 levels: RizzScaling = {Damage = {Enabled = true, Interval = 5, Mode = "Additive", IncreasePerStep = 5, MaxValue = 200}}
-- Example 2: Different intervals: RizzScaling = {Range = {Enabled = true, Interval = 10, Mode = "Additive", IncreasePerStep = 2}, Duration = {Enabled = true, Interval = 5, Mode = "Multiplicative", IncreasePerStep = 0.1, MaxValue = 6}}
-- Example 3: Cooldown reduction and capped damage: RizzScaling = {Cooldown = {Enabled = true, Interval = 5, Mode = "Multiplicative", IncreasePerStep = -0.05, MinValue = 3}, Damage = {Enabled = true, Interval = 5, Mode = "Additive", IncreasePerStep = 5, MaxValue = 200}}

for _, definition in pairs(config.Abilities) do
	definition.BaseStats = definition.BaseStats or {
		Damage = definition.Damage,
		Cooldown = definition.Cooldown,
		ManaCost = definition.ManaCost,
		HealAmount = definition.HealAmount,
		MinDamage = definition.MinDamage,
		MaxDamage = definition.MaxDamage,
	}
	definition.RizzScaling = definition.RizzScaling or {}
end

return config