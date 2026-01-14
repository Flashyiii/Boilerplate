local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TouchInputService = game:GetService("TouchInputService")
local TweenService = game:GetService("TweenService")

local maid = require(ReplicatedStorage.Packages.maid)
local refx = require(ReplicatedStorage.Packages.refx)
local trove = require(ReplicatedStorage.Packages.trove)

local Highlight = refx.CreateEffect("Highlight")

local function SubtractColor3(color3: Color3, amount: number)
	amount /= 255
	return Color3.new(
		math.clamp(color3.R - amount, 0, 1),
		math.clamp(color3.G - amount, 0, 1),
		math.clamp(color3.B - amount, 0, 1)
	)
end

local function Tween(object, time, style, direction, goalProps)
	local tweenInfo = TweenInfo.new(time, style, direction)
	local tween = TweenService:Create(object, tweenInfo, goalProps)
	tween:Play()
	return tween
end

-- Lifecycle: OnConstruct
function Highlight:OnConstruct()
	self.DestroyOnEnd = false
	self.DestroyOnLifecycleEnd = true
	self.MaxLifetime = 5
end

type HighlightParams = {
	Stand: Model,
	Color: Color3?,
	Transparency: number?,
	StayTime: number?,
	FadeInTime: number?,
	FadeOutTime: number?,
	OutlineTransparency: number?,
	Step: number?,
}

-- Lifecycle: OnStart
function Highlight:OnStart(Target, Params: HighlightParams)
	self.Target = Target
	local Color = Params.Color
		or (Params.Stand and Params.Stand:FindFirstChild("HumanoidRootPart") and Params.Stand:FindFirstChild("Torso").Color)
		or Color3.new(1, 1, 1)
	local Transparency = Params.Transparency or 0.5
	local StayTime = Params.StayTime or 0.5
	local FadeInTime = Params.FadeInTime or 0.25
	local FadeOutTime = Params.FadeOutTime or 0.25
	local OutlineTransparency = Params.OutlineTransparency or 0.5

	local id = math.random()
	self.Highlight = Target:FindFirstChild("HighlightEffect")
	local Highlight = self.Highlight

	if not self.Highlight then
		local new = Instance.new("Highlight")
		new.Name = "HighlightEffect"
		new.DepthMode = Enum.HighlightDepthMode.Occluded
		new.FillColor = Color
		new.OutlineColor = SubtractColor3(Color, 50)
		new.OutlineTransparency = OutlineTransparency
		new.FillTransparency = Transparency
		new.Parent = Target
		Highlight = new
	else
		Highlight.FillColor = Color
		Highlight.OutlineColor = SubtractColor3(Color, 50)
		Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	end

	Highlight.Enabled = true

	if not Highlight then
		return
	end

	Highlight:SetAttribute("id", id)

	self.Highlight = Highlight

	Highlight.FillTransparency = 1
	Highlight.OutlineTransparency = 1


	Tween(Highlight, FadeInTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, {
		FillTransparency = Transparency,
		OutlineTransparency = Transparency,
		FillColor = Color,
		OutlineColor = SubtractColor3(Color, 50),
	}).Completed:Once(function()
		task.wait(StayTime)

		if Highlight and Highlight:GetAttribute("id") == id then
			Tween(Highlight, FadeOutTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, {
				FillTransparency = 1,
				OutlineTransparency = 1,
			}).Completed:Once(function()
				if Highlight and Highlight:GetAttribute("id") == id then
					self:Destroy()
				end
			end)
		end
	end)
end

-- Lifecycle: OnDestroy
function Highlight:OnDestroy()
	if self.Highlight then
		self.Highlight:Destroy()
		self.Highlight = nil
	end
end

return Highlight
