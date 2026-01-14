--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local wcs = require(ReplicatedStorage.Packages.wcs)
local MoveRegistry = require(ReplicatedStorage.Shared.Modules.Data.Moves.MoveRegistry)
local AnimationPlayer = require(ReplicatedStorage.Shared.Modules.Game.AnimationPlayer)

local Stun = require(ReplicatedStorage.Shared.Wcs.Conditions.States.Stun)
local EndLagStatus = require(ReplicatedStorage.Shared.Wcs.Conditions.States.EndLag)
local Summoned = require(ReplicatedStorage.Shared.Wcs.Conditions.States.Summoned)

local Barrage = wcs.RegisterHoldableSkill("Barrage")

-- Phase enum
type Phase = "Startup" | "Main" | "End" | "None"

function Barrage:OnConstruct()
	self.MutualExclusives = { Stun, EndLagStatus }
	self.Requirements = { Summoned }
	self.CheckedByOthers = true

	-- State
	self._phase = "None" :: Phase
	self._animator = nil
	self._currentHandle = nil
	self._data = nil
	self._hitboxThread = nil
	self._releaseRequested = false
	self._mainPhaseStartTime = 0
	self._pendingTransitionThread = nil
end

function Barrage:CanCancel(): boolean
	return self._phase == "End" or self._phase == "Startup"
end

function Barrage:OnStartServer()
	local character = self.Character.Instance
	local moveset = character:GetAttribute("Moveset") :: string?

	if not moveset then
		self:End()
		return
	end

	self._data = MoveRegistry.get(moveset).Barrage
	if not self._data then
		self:End()
		return
	end

	-- Reset state
	self._phase = "None"
	self._releaseRequested = false
	self._mainPhaseStartTime = 0

	-- Get animation target
	local animTarget: Model = character :: Model
	if CollectionService:HasTag(character, "Summoned") then
		local standModel = character:FindFirstChild(moveset)
		if standModel and standModel:IsA("Model") then
			animTarget = standModel
		end
	end

	self._animator = AnimationPlayer.new(animTarget)

	local maxHoldTime = self._data.MaxDuration or 5
	self:SetMaxHoldTime(maxHoldTime)
	self:_enterPhase("Startup")
end

function Barrage:_enterPhase(phase: Phase)
	self._phase = phase

	if phase == "Startup" then
		self:_runStartupPhase()
	elseif phase == "Main" then
		self:_runMainPhase()
	elseif phase == "End" then
		self:_runEndPhase()
	end
end

function Barrage:_runStartupPhase()
	local character = self.Character.Instance
	local moveset = character:GetAttribute("Moveset")
	local animName = self._data.Animations and self._data.Animations.Startup or "BarrageStart"

	if self._animator then
		local handle = self._animator:Play(animName, moveset)
		handle:SetPriority(Enum.AnimationPriority.Movement)
		handle:Play()
		self._currentHandle = handle
		handle:AwaitEnd()
		if self._phase == "Startup" then
			self:_enterPhase("Main")
		end
	else
		-- No animator, skip to Main
		task.defer(function()
			if self._phase == "Startup" then
				self:_enterPhase("Main")
			end
		end)
	end
end

function Barrage:_runMainPhase()
	local character = self.Character.Instance
	local moveset = character:GetAttribute("Moveset")
	local animName = self._data.Animations and self._data.Animations.Loop or "BarrageLoop"

	self._mainPhaseStartTime = tick()

	-- Play looping animation
	if self._animator then
		local handle = self._animator:Play(animName, moveset)
		handle:SetLooped(true)
		handle:Play()
		self._currentHandle = handle
	end

	self:_startHitboxLoop()

	if self._releaseRequested then
		self:_handleReleaseInMain()
	end
end

function Barrage:_runEndPhase()
	local character = self.Character.Instance
	local moveset = character:GetAttribute("Moveset")
	local animName = self._data.Animations and self._data.Animations.End or "BarrageEnd"

	self:_stopHitboxLoop()

	if self._currentHandle then
		self._currentHandle:Stop()
		self._currentHandle = nil
	end

	if self._animator then
		local handle = self._animator:Play(animName, moveset)

		handle:OnEnd(function() end)

		handle:Play()
		self._currentHandle = handle

		handle:AwaitEnd()
		if self._phase == "End" then
			self:End()
		end
	else
		-- No animator, end immediately
		task.defer(function()
			if self._phase == "End" then
				self:End()
			end
		end)
	end
end

function Barrage:_getMinHoldTime(): number
	return self._data.MinHoldTime or 1.0
end

function Barrage:_getMainPhaseElapsed(): number
	if self._mainPhaseStartTime == 0 then
		return 0
	end
	return tick() - self._mainPhaseStartTime
end

function Barrage:_isMinHoldTimeSatisfied(): boolean
	return self:_getMainPhaseElapsed() >= self:_getMinHoldTime()
end

function Barrage:_handleReleaseInMain()
	if self._phase ~= "Main" then
		return
	end

	if self:_isMinHoldTimeSatisfied() then
		--self:_enterPhase("End")
		self:ApplyCooldown(self._data.Cooldown or 3)
	else
		local remaining = self:_getMinHoldTime() - self:_getMainPhaseElapsed()

		if self._pendingTransitionThread then
			task.cancel(self._pendingTransitionThread)
		end

		self._pendingTransitionThread = task.delay(remaining, function()
			self._pendingTransitionThread = nil
			if self._phase == "Main" then
				self:_enterPhase("End")
			end
		end)
	end
end

function Barrage:_startHitboxLoop()
	self:_stopHitboxLoop()

	self._hitboxThread = task.spawn(function()
		while self._phase == "Main" do
			self:_doBarrageHit()
			local interval = self._data.HitInterval or 0.1
			task.wait(interval)
		end
	end)
end

function Barrage:_stopHitboxLoop()
	if self._hitboxThread then
		task.cancel(self._hitboxThread)
		self._hitboxThread = nil
	end
end

function Barrage:_doBarrageHit()
	local hrp = self.Character.Instance:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	print("[Barrage] Hit!")
end

function Barrage:OnEndServer()
	if self._phase == "Startup" then
		self._releaseRequested = true
		return
	elseif self._phase == "Main" then
		self._releaseRequested = true
		self:_handleReleaseInMain()
		return
	elseif self._phase == "End" then
		self:ApplyCooldown(self._data.Cooldown or 3)
		return
	end
	-- Fallback
	self:_cleanup()
end

function Barrage:_cleanup()
	self._phase = "None"
	self._releaseRequested = false
	self._mainPhaseStartTime = 0

	if self._pendingTransitionThread then
		task.cancel(self._pendingTransitionThread)
		self._pendingTransitionThread = nil
	end

	self:_stopHitboxLoop()

	if self._animator then
		self._animator:StopAll()
	end

	if self._currentHandle then
		self._currentHandle:Destroy()
		self._currentHandle = nil
	end
end

-- Client-side
function Barrage:OnStartClient() end
function Barrage:OnEndClient() end

return Barrage
