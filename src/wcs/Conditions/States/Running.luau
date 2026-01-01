local ReplicatedStorage = game:GetService("ReplicatedStorage")

local wcs = require(ReplicatedStorage.Packages.wcs)

local Running = wcs.RegisterStatusEffect("Running")

function Running:OnStartServer()
	local char = self.Character.Instance
	char:GetAttributeChangedSignal("RunSpeed"):Connect(function()
		self:SetHumanoidData({
			WalkSpeed = { char:GetAttribute("RunSpeed"), "Set", 0 },
			JumpHeight = { char:GetAttribute("JumpHeight"), "Set", 0 },
		})
	end)

	self:SetHumanoidData({
		WalkSpeed = { self.Character.Instance:GetAttribute("RunSpeed"), "Set", 0 },
		JumpHeight = { self.Character.Instance:GetAttribute("JumpHeight"), "Set", 0 },
	})
end

function Running:OnStartClient()
	local Camera = workspace.CurrentCamera
	local TweenService = game:GetService("TweenService")
	local TargetFieldOfView = 70 + 5
	local TweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local FOVTween = TweenService:Create(Camera, TweenInfo, { FieldOfView = TargetFieldOfView })
	FOVTween:Play()
end

function Running:OnEndClient()
	local Camera = workspace.CurrentCamera
	local TweenService = game:GetService("TweenService")
	local OriginalFieldOfView = 70
	local TweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local FOVTween = TweenService:Create(Camera, TweenInfo, { FieldOfView = OriginalFieldOfView })
	FOVTween:Play()
end

function Running:OnEndServer()
	self:ClearHumanoidData()
end

return Running
