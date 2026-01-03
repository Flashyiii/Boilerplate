local RunService = game:GetService("RunService")
return function(target, position: CFrame, time: number?)
	local CameraMotor = target.Head:FindFirstChild("CameraMotor")
	assert(CameraMotor, "Camera Motor needs to exist")

	local transitionTime = time or 0.1 -- seconds
	local elapsed = 0
	local startC0 = CameraMotor.C0
	local targetC0 = position -- new offset

	-- Run in a render loop
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		local alpha = math.clamp(elapsed / transitionTime, 0, 1)

		-- Smoothstep easing
		alpha = alpha * alpha * (3 - 2 * alpha)

		CameraMotor.C0 = startC0:Lerp(targetC0, alpha)

		if alpha >= 1 then
			conn:Disconnect()
		end
	end)
end
