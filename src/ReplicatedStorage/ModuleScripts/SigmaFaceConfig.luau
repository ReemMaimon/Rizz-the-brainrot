--[[
	SigmaFaceConfig - the ONLY place that maps Rizz Level -> Sigma Face.

	* Level <= DefaultLevel (1) never has a face and needs no entry.
	* A level without an entry keeps the face of the closest lower configured level
	  (L5 = SigmaFace_5, L6 unconfigured -> still SigmaFace_5). No code change needed to add levels.
	* "Model" is the name of a Model/BasePart inside ReplicatedStorage/Assets/SigmaFaces.
	  Replace the placeholder model (same name) in Studio, or point "Model" at another name.
	* An entry may be a string ("SigmaFace_7") or a table. A table can override Attachment / Scene
	  for that single face, e.g. [9] = {Model = "SigmaFace_9", Scene = {Duration = 2.5, Bounce = false}}.

	The Scene table feeds the existing Ability Scene system (AbilityPresentation remote -> BattleClient,
	VFXService, AnimationService). VFX / sound names are the ones in ReplicatedStorage/AbilityVFX and AbilitySounds.
]]
return {
	DefaultLevel = 1, -- levels at or below this have NO Sigma Face

	AssetFolder = "Assets/SigmaFaces", -- path under ReplicatedStorage

	SigmaFaces = {
		[2] = {Model = "SigmaFace_2"},
		[3] = {Model = "SigmaFace_3"},
		[4] = {Model = "SigmaFace_4"},
		[5] = {Model = "SigmaFace_5"},
		[6] = {Model = "SigmaFace_6"},
		[7] = {Model = "SigmaFace_7"},
		[8] = {Model = "SigmaFace_8"},
		[9] = {Model = "SigmaFace_9"},
		[10] = {Model = "SigmaFace_10"},
	},

	Attachment = {
		ParentPart = "Head", -- character part the face is welded to
		Offset = CFrame.new(0, 0, 0), -- extra offset from the anchor point
		HideHead = true, -- hide the real head while a face is worn (restored when removed)
		FaceAttachment = "SigmaFaceAttachment", -- optional Attachment inside the face model that marks its pivot
		TargetAttachment = "FaceFrontAttachment", -- optional Attachment on ParentPart to snap that pivot to
	},

	Scene = {
		Enabled = true,
		SceneId = "SigmaFaceChange", -- id used with the existing AbilityPresentation scene system
		Duration = 1.5, -- total scene length (seconds)
		SwapDelay = 0.45, -- seconds into the scene when old face -> new face
		RemoveOldFace = true, -- true: old face vanishes when the scene starts; false: it stays until the swap
		CameraEffect = true, -- reuses BattleClient's camera hit-stop + shake
		FaceAnimation = true, -- entrance scale tween of the new face
		EntranceScale = 0.5,
		FinalScale = 1,
		Bounce = true, -- Back easing (overshoot) for the entrance
		VFX = true,
		Sound = true,
		-- Scene content (same format as AbilityPresentationConfig)
		StartVFX = {Effect = "Sigma face wind VFX", AttachTo = "UnderPlayer"},
		RevealVFX = {Effect = "Sigma face shiny VFX", AttachTo = "Head"},
		StartSound = "Sigma face wind",
		RevealSound = "Sigma face shiny sparkle",
	},
}
