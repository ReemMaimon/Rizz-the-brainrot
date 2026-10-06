-- Fixed CameraController Module
local TweenService = game:GetService("TweenService")

local module = {
	GetDefaultFov = function(self)
		return 70
	end,

	Get = function(self)
		local camera
		while not camera do
			task.wait()
			camera = workspace.CurrentCamera
		end
		return camera
	end
}

function module:Fov(targetFov, duration, useDefault)
	local fov = targetFov
	if useDefault == true then
		fov = self:GetDefaultFov()
	end

	if not duration or duration == 0 then
		self:Get().FieldOfView = fov
	else
		TweenService:Create(self:Get(), TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			FieldOfView = fov
		}):Play()
	end
end

function module:Blur(size, duration)
	local camera = self:Get()
	local blurEffect = camera:FindFirstChild("Blur")

	if not blurEffect then
		blurEffect = Instance.new("BlurEffect")
		blurEffect.Name = "Blur"
		blurEffect.Size = 0
		blurEffect.Parent = camera
	end

	if not duration or duration == 0 then
		blurEffect.Size = size
	else
		TweenService:Create(blurEffect, TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Size = size
		}):Play()
	end
end

return module