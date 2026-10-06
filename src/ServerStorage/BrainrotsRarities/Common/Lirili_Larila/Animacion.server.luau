local controller = script.Parent:WaitForChild("AnimationController")
local animator = controller:WaitForChild("Animator")

local anim = Instance.new("Animation")
anim.AnimationId = "rbxassetid://139702462244046"

local track = animator:LoadAnimation(anim)
track.Looped = true
track:Play()