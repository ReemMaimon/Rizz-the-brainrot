local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local BrainrotMovement = {}

local function getMovingOnPart()
	return Workspace:FindFirstChild("MovingOn")
end

function BrainrotMovement:GetPathEndpoints()
	local movingOn = getMovingOnPart()
	if not movingOn then return Vector3.new(0, 3, 0), Vector3.new(100, 3, 0) end

	local cf = movingOn.CFrame
	local size = movingOn.Size
	local startPos = cf:PointToWorldSpace(Vector3.new(size.X / 2, size.Y / 2 + 1.5, 0))
	local endPos = cf:PointToWorldSpace(Vector3.new(-size.X / 2, size.Y / 2 + 1.5, 0))

	return startPos, endPos
end

function BrainrotMovement:MoveAlongPath(brainrotModel, onReachedEnd, isCancelledCallback)
	local movingOn = getMovingOnPart()
	if not movingOn or not brainrotModel or not brainrotModel.PrimaryPart then
		if onReachedEnd then onReachedEnd() end
		return
	end

	local startPos, endPos = self:GetPathEndpoints()
	brainrotModel:PivotTo(CFrame.lookAt(startPos, endPos))

	local speed = 8 -- studs per second
	local totalDistance = (endPos - startPos).Magnitude
	local duration = math.max(1, totalDistance / speed)

	local startTime = os.clock()
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not brainrotModel.Parent or (isCancelledCallback and isCancelledCallback()) then
			connection:Disconnect()
			return
		end

		local elapsed = os.clock() - startTime
		local alpha = math.clamp(elapsed / duration, 0, 1)
		local currentPos = startPos:Lerp(endPos, alpha)

		local lookTarget = currentPos + (endPos - startPos).Unit
		brainrotModel:PivotTo(CFrame.lookAt(currentPos, lookTarget))

		if alpha >= 1 then
			connection:Disconnect()
			if onReachedEnd then
				onReachedEnd()
			end
		end
	end)

	return connection
end

function BrainrotMovement:MoveToBaseStand(brainrotModel, targetStandData, onCompleted)
	if not brainrotModel or not brainrotModel.PrimaryPart or not targetStandData then
		if onCompleted then onCompleted(false) end
		return
	end

	local targetPart = targetStandData.PlaceholderPart or targetStandData.CollectPart or targetStandData.Instance
	local targetPos = targetPart:IsA("BasePart") and (targetPart.Position + Vector3.new(0, 1.5, 0)) or targetPart:GetPivot().Position

	local startPos = brainrotModel:GetPivot().Position

	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 4,
		AgentCanJump = false,
	})

	local success, errorMessage = pcall(function()
		path:ComputeAsync(startPos, targetPos)
	end)

	local waypoints = {}
	if success and path.Status == Enum.PathStatus.Success then
		waypoints = path:GetWaypoints()
	else
		-- Direct lerp fallback if pathfinding cannot find a route
		table.insert(waypoints, { Position = startPos })
		table.insert(waypoints, { Position = targetPos })
	end

	task.spawn(function()
		local speed = 14
		for i, waypoint in ipairs(waypoints) do
			if not brainrotModel.Parent then return end

			local nextPos = waypoint.Position + Vector3.new(0, 1.5, 0)
			local currentPos = brainrotModel:GetPivot().Position
			local dist = (nextPos - currentPos).Magnitude
			local duration = math.max(0.05, dist / speed)

			local startTime = os.clock()
			while os.clock() - startTime < duration do
				if not brainrotModel.Parent then return end
				local alpha = math.clamp((os.clock() - startTime) / duration, 0, 1)
				local lerped = currentPos:Lerp(nextPos, alpha)
				local lookAtTarget = (nextPos - currentPos).Magnitude > 0.1 and nextPos or (currentPos + brainrotModel:GetPivot().LookVector)
				brainrotModel:PivotTo(CFrame.lookAt(lerped, lookAtTarget))
				RunService.Heartbeat:Wait()
			end
			brainrotModel:PivotTo(CFrame.lookAt(nextPos, nextPos + brainrotModel:GetPivot().LookVector))
		end

		if onCompleted then
			onCompleted(true)
		end
	end)
end

return BrainrotMovement