local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TouchInputService = game:GetService("TouchInputService")
local TweenService = game:GetService("TweenService")

local maid = require(ReplicatedStorage.Packages.maid)
local refx = require(ReplicatedStorage.Packages.refx)
local ClientUtil = require(ReplicatedStorage.Shared.Modules.Game.ClientUtil)
local EndLag = require(ReplicatedStorage.Shared.Wcs.Conditions.States.EndLag)

local Indicator = refx.CreateEffect("Indicator")

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
function Indicator:OnConstruct()
	self.DestroyOnEnd = true
	self.DestroyOnLifecycleEnd = true
	self._maid = maid.new()
end

type IndicatorParams = {
	Value: number | string,
	Color: Color3?,
	Size: number?,
}

-- Lifecycle: OnStart
function Indicator:OnStart(Target, Params: IndicatorParams)
	self.Target = Target
	local Color = Params.Color or Color3.fromRGB(249, 60, 73)
	local Size = Params.Size or 0.25
	self.Value = Params.Value or 0

	if self.Value == 0 then
		return
	end

	if not self.Target then
		return
	end

	local Assets = ReplicatedStorage.Assets.Effects
	self.Holder = Assets.Holder:Clone()
	local Indicator = self.Holder.Indicator
	local Label = Indicator.TextLabel
	local Label2 = Label.TextLabel

	Label.Text = "-" .. tonumber(self.Value)
	Label2.Text = "-" .. tonumber(self.Value)
	Label2.TextColor3 = Color
	Label.Size = UDim2.new(0.8, 0, Size, 0)

	local CF = (Target and Target.PrimaryPart and Target:GetPivot())
	CF *= CFrame.new(ClientUtil.RNG(-2, 2), ClientUtil.RNG(-2, 2), ClientUtil.RNG(-2, 2))

	self.Holder.CFrame = CF - Vector3.new(0, 2, 0)
	self.Holder.Parent = workspace.Effects
	self._maid:GiveTask(self.Holder)

	local tween1 =
		TweenService:Create(self.Holder, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			CFrame = CF,
		})
	tween1:Play()
	self._maid:GiveTask(tween1)

	task.wait(0.5)

	local tween2 =
		TweenService:Create(self.Holder, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			CFrame = self.Holder.CFrame + Vector3.yAxis * 1.35,
		})
	tween2:Play()
	self._maid:GiveTask(tween2)

	for _, inst in Indicator:GetDescendants() do
		if inst:IsA("TextLabel") then
			local tween =
				TweenService:Create(inst, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
					TextTransparency = 1,
					TextColor3 = Color3.new(1, 1, 1),
				})
			tween:Play()
			self._maid:GiveTask(tween)
		elseif inst:IsA("UIStroke") then
			local tween =
				TweenService:Create(inst, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
					Transparency = 1,
					Color = Color3.new(1, 1, 1),
				})
			tween:Play()
			self._maid:GiveTask(tween)
		elseif inst:IsA("ImageLabel") then
			local tween =
				TweenService:Create(inst, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
					ImageTransparency = 1,
					ImageColor3 = Color3.new(0, 0, 0),
				})
			tween:Play()
			self._maid:GiveTask(tween)
		end
	end

	self._destroyed = false
	local destroyTask = task.delay(2, function()
		if not self._destroyed then
			self:Destroy()
		end
	end)
	self._maid:GiveTask(function()
		if destroyTask then
			task.cancel(destroyTask)
		end
	end)
end

-- Lifecycle: OnDestroy
function Indicator:OnDestroy()
	self._destroyed = true
	if self._maid then
		self._maid:Cleanup()
	end
	if self.Holder and self.Holder.Parent then
		self.Holder:Destroy()
	end
	self.Holder = nil
end

return Indicator
