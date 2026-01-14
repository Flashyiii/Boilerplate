--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.trove)
local Signal = require(ReplicatedStorage.Packages.Signal)

local Types = require(script.Parent.Types)

type ChainMarkerCallback = Types.ChainMarkerCallback
type IndexCallback = Types.IndexCallback
type AnimationEndCallback = Types.AnimationEndCallback
type EndCallback = Types.EndCallback

local ChainHandle = {}
ChainHandle.__index = ChainHandle

export type ChainHandleImpl = {
	_player: any,
	_animations: { string },
	_moveset: string?,
	_trove: typeof(Trove.new()),
	_currentIndex: number,
	_currentHandle: Types.AnimationHandle?,
	_speed: number,
	_priority: Enum.AnimationPriority?,
	_indexPriorities: { [number]: Enum.AnimationPriority },
	_fadeTime: number,
	_playing: boolean,
	_paused: boolean,
	_waiting: boolean,
	_waitingStartTime: number?,
	_autoStopDelay: number?,
	_destroyed: boolean,
	_mode: Types.ChainMode,
	_markerCallbacks: { [string]: { ChainMarkerCallback } },
	_indexCallbacks: { [number]: { IndexCallback } },
	_animationEndCallbacks: { AnimationEndCallback },
	_chainEndCallbacks: { EndCallback },
	_autoStopDelayCallbacks: { EndCallback },
	AnimationStarted: typeof(Signal.new()),
	AnimationEnded: typeof(Signal.new()),
	ChainCompleted: typeof(Signal.new()),
}

function ChainHandle.new(player: any, animations: { string }, moveset: string?): Types.ChainHandle
	local self = setmetatable({}, ChainHandle) :: ChainHandleImpl

	self._player = player
	self._animations = animations
	self._moveset = moveset
	self._trove = Trove.new()
	self._currentIndex = 0
	self._currentHandle = nil
	self._speed = 1
	self._priority = nil
	self._indexPriorities = {}
	self._fadeTime = 0.15
	self._playing = false
	self._paused = false
	self._waiting = false
	self._waitingStartTime = nil
	self._autoStopDelay = nil
	self._destroyed = false
	self._mode = "AutoContinue"
	self._markerCallbacks = {}
	self._indexCallbacks = {}
	self._animationEndCallbacks = {}
	self._chainEndCallbacks = {}
	self._autoStopDelayCallbacks = {}

	self.AnimationStarted = self._trove:Construct(Signal)
	self.AnimationEnded = self._trove:Construct(Signal)
	self.ChainCompleted = self._trove:Construct(Signal)

	return self :: any
end

function ChainHandle.Play(self: ChainHandleImpl): Types.ChainHandle
	if self._destroyed or self._playing then
		return self :: any
	end

	self._playing = true
	self._currentIndex = 0
	self:_PlayNextAnimation()

	return self :: any
end

function ChainHandle.Continue(self: ChainHandleImpl): Types.ChainHandle
	if self._destroyed or not self._waiting then
		return self :: any
	end

	self._waiting = false
	self._waitingStartTime = nil

	if self._currentHandle then
		self._currentHandle:Stop(self._fadeTime)
		self._currentHandle:Destroy()
		self._currentHandle = nil
	end

	self:_PlayNextAnimation()

	return self :: any
end

function ChainHandle.Skip(self: ChainHandleImpl): Types.ChainHandle
	if self._destroyed or not self._playing then
		return self :: any
	end

	if self._currentHandle then
		self._currentHandle:Stop(0)
	end

	if self._currentIndex < #self._animations then
		self:_PlayNextAnimation()
	else
		self:_OnChainComplete()
	end

	return self :: any
end

function ChainHandle.Stop(self: ChainHandleImpl, fadeTime: number?): Types.ChainHandle
	if self._destroyed then
		return self :: any
	end

	self._playing = false
	self._waiting = false
	self._waitingStartTime = nil

	if self._currentHandle then
		self._currentHandle:Stop(fadeTime)
		self._currentHandle:Destroy()
		self._currentHandle = nil
	end

	return self :: any
end

function ChainHandle.Pause(self: ChainHandleImpl): Types.ChainHandle
	if self._destroyed then
		return self :: any
	end

	self._paused = true

	if self._currentHandle then
		self._currentHandle:Pause()
	end

	return self :: any
end

function ChainHandle.Resume(self: ChainHandleImpl): Types.ChainHandle
	if self._destroyed then
		return self :: any
	end

	self._paused = false

	if self._currentHandle then
		self._currentHandle:Resume()
	end

	return self :: any
end

function ChainHandle.SetSpeed(self: ChainHandleImpl, speed: number): Types.ChainHandle
	self._speed = speed

	if self._currentHandle then
		self._currentHandle:SetSpeed(speed)
	end

	return self :: any
end

function ChainHandle.SetFadeTime(self: ChainHandleImpl, fadeTime: number): Types.ChainHandle
	self._fadeTime = fadeTime
	return self :: any
end

function ChainHandle.SetPriority(self: ChainHandleImpl, priority: Enum.AnimationPriority): Types.ChainHandle
	self._priority = priority

	if self._currentHandle then
		self._currentHandle:SetPriority(priority)
	end

	return self :: any
end

function ChainHandle.SetIndexPriority(
	self: ChainHandleImpl,
	index: number,
	priority: Enum.AnimationPriority
): Types.ChainHandle
	if index >= 1 and index <= #self._animations then
		self._indexPriorities[index] = priority

		if self._playing and self._currentIndex == index and self._currentHandle then
			self._currentHandle:SetPriority(priority)
		end
	end

	return self :: any
end

function ChainHandle.SetIndex(self: ChainHandleImpl, index: number): Types.ChainHandle
	if self._destroyed then
		return self :: any
	end

	if index >= 1 and index <= #self._animations then
		self._currentIndex = index - 1
		if self._playing then
			if self._currentHandle then
				self._currentHandle:Stop(self._fadeTime)
				self._currentHandle:Destroy()
				self._currentHandle = nil
			end
			self:_PlayNextAnimation()
		end
	end

	return self :: any
end

function ChainHandle.SetAutoStopDelay(self: ChainHandleImpl, delay: number?): Types.ChainHandle
	self._autoStopDelay = delay
	return self :: any
end

function ChainHandle.ContinueOnRequest(self: ChainHandleImpl, enabled: boolean?): Types.ChainHandle
	self._mode = if enabled == false then "AutoContinue" else "ContinueOnRequest"
	return self :: any
end

function ChainHandle.AutoContinue(self: ChainHandleImpl, enabled: boolean?): Types.ChainHandle
	self._mode = if enabled == false then "ContinueOnRequest" else "AutoContinue"
	return self :: any
end

function ChainHandle.PauseOnLastFrame(self: ChainHandleImpl, enabled: boolean?): Types.ChainHandle
	self._mode = if enabled == false then "AutoContinue" else "PauseOnLastFrame"
	return self :: any
end

function ChainHandle.OnMarker(
	self: ChainHandleImpl,
	markerName: string,
	callback: ChainMarkerCallback
): Types.ChainHandle
	if not self._markerCallbacks[markerName] then
		self._markerCallbacks[markerName] = {}
	end
	table.insert(self._markerCallbacks[markerName], callback)
	return self :: any
end

function ChainHandle.OnIndex(self: ChainHandleImpl, index: number, callback: IndexCallback): Types.ChainHandle
	if not self._indexCallbacks[index] then
		self._indexCallbacks[index] = {}
	end
	table.insert(self._indexCallbacks[index], callback)
	return self :: any
end

function ChainHandle.OnAnimationEnd(self: ChainHandleImpl, callback: AnimationEndCallback): Types.ChainHandle
	table.insert(self._animationEndCallbacks, callback)
	return self :: any
end

function ChainHandle.OnChainEnd(self: ChainHandleImpl, callback: EndCallback): Types.ChainHandle
	table.insert(self._chainEndCallbacks, callback)
	return self :: any
end

function ChainHandle.OnAutoStopDelay(self: ChainHandleImpl, callback: EndCallback): Types.ChainHandle
	table.insert(self._autoStopDelayCallbacks, callback)
	return self :: any
end

function ChainHandle.IsPlaying(self: ChainHandleImpl): boolean
	return self._playing and not self._destroyed
end

function ChainHandle.IsWaiting(self: ChainHandleImpl): boolean
	return self._waiting
end

function ChainHandle.GetCurrentIndex(self: ChainHandleImpl): number
	return self._currentIndex
end

function ChainHandle.GetCurrentAnimation(self: ChainHandleImpl): string?
	if self._currentIndex > 0 and self._currentIndex <= #self._animations then
		return self._animations[self._currentIndex]
	end
	return nil
end

function ChainHandle.IsLastAnimation(self: ChainHandleImpl): boolean
	return self._currentIndex == #self._animations
end

function ChainHandle.AwaitEnd(self: ChainHandleImpl): ()
	if self._destroyed or not self._playing then
		return
	end

	local thread = coroutine.running()
	local conn

	conn = self.ChainCompleted:Connect(function()
		if conn then
			conn:Disconnect()
		end
		task.spawn(thread)
	end)

	self._trove:Add(conn)

	if not self._destroyed and self._playing then
		coroutine.yield()
	end
end

function ChainHandle.AwaitAnimation(self: ChainHandleImpl): ()
	if self._destroyed or not self._playing then
		return
	end

	local thread = coroutine.running()
	local conn
	local resumed = false

	local function resume()
		if not resumed then
			resumed = true
			if conn then
				conn:Disconnect()
			end
			task.spawn(thread)
		end
	end

	conn = self.AnimationEnded:Connect(resume)
	self._trove:Add(conn :: any)

	if not self._destroyed and self._playing then
		coroutine.yield()
	else
		resume()
	end
end

function ChainHandle.Destroy(self: ChainHandleImpl): ()
	if self._destroyed then
		return
	end

	self._destroyed = true
	self._playing = false
	self._waiting = false

	if self._currentHandle then
		self._currentHandle:Destroy()
		self._currentHandle = nil
	end

	self._trove:Destroy()
end

function ChainHandle._PlayNextAnimation(self: ChainHandleImpl): ()
	if self._destroyed or not self._playing then
		return
	end

	self._currentIndex += 1

	if self._currentIndex > #self._animations then
		self:_OnChainComplete()
		return
	end

	local animName = self._animations[self._currentIndex]
	local isLast = self._currentIndex == #self._animations

	if self._currentHandle then
		self._currentHandle:Destroy()
	end

	local handle = self._player:Play(animName, self._moveset)
	self._currentHandle = handle

	handle:SetSpeed(self._speed)

	local priority = self._indexPriorities[self._currentIndex] or self._priority
	if priority then
		handle:SetPriority(priority)
	end

	self:_SetupChainMarkerListeners(handle, animName, self._currentIndex)
	self:_FireIndexCallbacks(self._currentIndex, animName)

	self.AnimationStarted:Fire(animName, self._currentIndex)

	if self._mode == "PauseOnLastFrame" then
		handle:OnNearEnd(function()
			if self._destroyed then
				return
			end
			handle:Pause()

			self.AnimationEnded:Fire(animName, self._currentIndex)

			for _, callback in self._animationEndCallbacks do
				task.spawn(callback, animName, self._currentIndex)
			end

			if isLast then
				self:_OnChainComplete()
			end

			self._waiting = true
			self._waitingStartTime = tick()

			-- Auto-stop if paused for more than 0.5 seconds
			if self._autoStopDelay then
				local delay = self._autoStopDelay
				task.delay(delay, function()
					if self._waiting and self._waitingStartTime and tick() - self._waitingStartTime >= delay then
						for _, callback in self._autoStopDelayCallbacks do
							task.spawn(callback)
						end
						self:Stop()
					end
				end)
			end
		end)
	else
		handle:OnEnd(function()
			if self._destroyed then
				return
			end

			self.AnimationEnded:Fire(animName, self._currentIndex)

			for _, callback in self._animationEndCallbacks do
				task.spawn(callback, animName, self._currentIndex)
			end

			if isLast then
				self:_OnChainComplete()
			end

			if self._mode == "ContinueOnRequest" then
				self._waiting = true
			else
				self:_PlayNextAnimation()
			end
		end)
	end

	handle:Play()
end

function ChainHandle._SetupChainMarkerListeners(
	self: ChainHandleImpl,
	handle: Types.AnimationHandle,
	animName: string,
	index: number
): ()
	for markerName, callbacks in self._markerCallbacks do
		handle:OnMarker(markerName, function(time: number, value: string?)
			for _, callback in callbacks do
				task.spawn(callback, animName, index, time, value)
			end
		end)
	end
end

function ChainHandle._FireIndexCallbacks(self: ChainHandleImpl, index: number, animName: string): ()
	local callbacks = self._indexCallbacks[index]
	if callbacks then
		for _, callback in callbacks do
			task.spawn(callback, index, animName)
		end
	end
end

function ChainHandle._OnChainComplete(self: ChainHandleImpl): ()
	self._playing = false

	for _, callback in self._chainEndCallbacks do
		task.spawn(callback)
	end

	self.ChainCompleted:Fire()
end

return ChainHandle
