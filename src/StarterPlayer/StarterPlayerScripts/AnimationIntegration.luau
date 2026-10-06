local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationController = require(ReplicatedStorage:WaitForChild("AnimationController"))
local AnimationConfig = require(ReplicatedStorage:WaitForChild("AnimationConfig"))

local AnimationIntegration = {}

function AnimationIntegration.Play(actionOrAnimation, overrides)
	return AnimationController.Play(actionOrAnimation, overrides)
end

function AnimationIntegration.Stop()
	AnimationController.Stop()
end

function AnimationIntegration.IsPlaying()
	return AnimationController.IsPlaying()
end

function AnimationIntegration.GetConfig()
	return AnimationConfig
end

function AnimationIntegration.GetAnimation(name)
	return AnimationController.GetAnimation(name)
end

return AnimationIntegration
