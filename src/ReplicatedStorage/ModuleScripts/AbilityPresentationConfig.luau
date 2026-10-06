local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AbilityConfig = require(script.Parent:WaitForChild("AbilityConfig"))

local AbilityPresentationConfig = {
	Defaults = {
		Animation = {},
		VFX = {},
		Sounds = {},
		Timing = {},
		Sequence = {},
	},
	Abilities = {
		SigmaMewing = {
			Animation = {
				Cast = {
					Name = "Sigma mewing",
					Speed = 1,
					FadeTime = 0.05,
					Priority = Enum.AnimationPriority.Action,
				},
				Attack = "",
				Recovery = "",
			},
			VFX = {
				Cast = {
					Effect = "Sigma mewing VFX1",
					AttachTo = "RootPart",
					Lifetime = 1.5,
				},
				Impact = {
					Effect = "Sigma mewing VFX2",
					AttachTo = "UnderPlayer",
					Lifetime = 1.5,
				},
				Attack = "",
				Hit = "",
				End = "",
			},
			Sounds = {
				Cast = "Sigma Mewing Cast",
				Attack = "",
				Hit = "Sigma Mewing Hit",
				End = "",
			},
			Timing = {
				Cast = 3,
				Attack = 2,
				Hit = 1,
				End = 1,
			},
			Face = {
				Model = "Sigma Face Model",
				AttachTo = "Head",
				Lifetime = 6,
			},
			Sequence = {
				Cast = {
					{
						Delay = 0.5,
						Action = "Jump",
					},
				},
				Impact = {},
			},
		},
		
		
		SigmaFace = {
			Animation = {
				Cast = {
				},
				Attack = "",
				Recovery = "",
			},
			VFX = {
				Cast = {
					Effect = "Sigma face wind VFX",
					AttachTo = "UnderPlayer",
					Lifetime = 1.5,
				},
				Impact = {
					Effect = "Sigma face shiny VFX",
					AttachTo = "RootPart",
					Lifetime = 1.5,
				},
				Attack = "",
				Hit = "",
				End = "",
			},
			Sounds = {
				Cast = "Sigma face wind",
				Attack = "",
				Hit = "Sigma face shiny sparkle",
				End = "",
			},
			Timing = {
				Cast = 3,
				Attack = 1,
				Hit = 1,
				End = 1,
			},
			Face = {
				Model = "Sigma Face Model",
				AttachTo = "Head",
				Lifetime = 6,
			},
			Sequence = {
				Cast = {
				},
				Impact = {},
			},
		},
		

	},
}

for abilityId, definition in pairs(AbilityConfig.Abilities or {}) do
	if AbilityPresentationConfig.Abilities[abilityId] then
		continue
	end
	local legacy = definition.Presentation
	AbilityPresentationConfig.Abilities[abilityId] = {
		Animation = legacy and legacy.Animation and {Cast = legacy.Animation} or {},
		VFX = {},
		Sounds = legacy and legacy.Sounds or {},
		Timing = legacy and {Cast = legacy.AttackTime or 0, Hit = legacy.HitTime or 0, End = legacy.RecoveryTime or 0} or {},
		Sequence = {},
	}
end

local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, item in pairs(value) do result[key] = copy(item) end
	return result
end

local function merge(base, override)
	local result = copy(base or {})
	for key, value in pairs(override or {}) do
		if type(value) == "table" and type(result[key]) == "table" then result[key] = merge(result[key], value) else result[key] = copy(value) end
	end
	return result
end

function AbilityPresentationConfig.Get(abilityId, override)
	return merge(merge(AbilityPresentationConfig.Defaults, AbilityPresentationConfig.Abilities[abilityId]), override)
end

return AbilityPresentationConfig