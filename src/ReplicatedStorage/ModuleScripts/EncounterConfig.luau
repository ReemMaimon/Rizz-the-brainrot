return {
	InteractionDistance = 12,
	PromptName = "BrainrotInfoPrompt",
	PromptActionText = "Inspect",
	PromptObjectText = "Brainrot",
	PromptHoldDuration = 0,
	PromptRequiresLineOfSight = false,
	UI = {
		PanelVisibleDistance = 20,
		ApproachText = "Walk closer to interact",
		ActivateText = "RIZZ BATTLE",
		UnavailableText = "Already in an encounter",
		PreparedText = "Encounter prepared",
		FeedbackDuration = 3,
	},
	Encounter = {
		StateAvailable = "Available",
		StateInEncounter = "InEncounter",
		StateInBattle = "InBattle", -- Phase 6: brainrot locked inside a battle
		StateDespawned = "Despawned",
		StartCooldown = 0.5,
		-- Attribute name the encounter system uses to track which player
		-- prepared the encounter (used by BattleService to validate ownership).
		PlayerAttribute = "EncounterPlayer",
	},
}