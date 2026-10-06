return {
	Defaults = {
		Loop = false,
		Priority = Enum.AnimationPriority.Action,
		Speed = 1,
		FadeTime = 0.1,
		CounterRotateLegs = true,
	},

	Animations = {
		["Punching Animation"] = {
			Module = "Punching Animation",
			Loop = false,
			Priority = Enum.AnimationPriority.Action,
			Speed = 1,
			FadeTime = 0.08,
			CounterRotateLegs = true,
		},
		["Zombie Walk Animation"] = {
			Module = "Zombie Walk Animation",
			Loop = true,
			Priority = Enum.AnimationPriority.Movement,
			Speed = 1,
			FadeTime = 0.15,
			CounterRotateLegs = false,
		},
		["Spell Cast Fireball Animation"] = {
			Module = "Spell Cast Fireball Animation",
			Loop = false,
			Priority = Enum.AnimationPriority.Action,
			Speed = 1,
			FadeTime = 0.1,
			CounterRotateLegs = false,
		},
		["Sigma Face Animation"] = {
			Module = "Sigma Face Animation",
			Loop = false,
			Priority = Enum.AnimationPriority.Action,
			Speed = 1,
			FadeTime = 0.1,
			CounterRotateLegs = true,
		},
	},

	Actions = {
		Attack = "Punching Animation",
		Walk = "Zombie Walk Animation",
		Cast = "Spell Cast Fireball Animation",
		Emote = "Sigma Face Animation",
	},
}
