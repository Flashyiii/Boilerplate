--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.trove)
local Signal = require(ReplicatedStorage.Packages.Signal)
local KeyframesResearcher = require(script.Parent.Parent.KeyframesResearcher)

local Types = require(script.Parent.Types)

type MarkerCallback = Types.MarkerCallback
type FrameCallback = Types.FrameCallback
type EndCallback = Types.EndCallback
type AnimationInfo = Types.AnimationInfo

local DEFAULT_FADE_TIME = 0.1
local NEAR_END_THRESHOLD = 0.1

local AnimationHandle = {}
AnimationHandle.__index = AnimationHandle

export type AnimationHandleImpl = {
	_player: any,
	_animName: string,
	_track: AnimationTrack,
	_info: AnimationInfo?,
	_trove: typeof(Trove.new()),
	_researcher: any,
	_speed: number,
	_priority: Enum.AnimationPriority?,
	_fadeTime: number,
	_pauseOnLastFrame: boolean,
	_autoStopDelay: number?,
	_autoStopDelayCallbacks: { EndCallback },
	_waiting: boolean,
	_waitingStartTime: number?,
	_startTime: number?,
	_endTime: number?,
	_playing: boolean,
	_paused: boolean,
	_destroyed: boolean,
	_markerCallbacks: { [string]: { MarkerCallback } },
	_frameCallbacks: { { frame: number, callback: FrameCallback } },
	_frameRangeCallbacks: { { startFrame: number, endFrame: number, callback: FrameCallback } },
	_endCallbacks: { EndCallback },
	_nearEndCallbacks: { EndCallback },
	_endedConnection: RBXScriptConnection?,
	_stoppedConnection: RBXScriptConnection?,
	Ended: typeof(Signal.new()),
}

function AnimationHandle.new(
	player: any,
	animName: string,
	track: AnimationTrack,
	info: AnimationInfo?
): Types.AnimationHandle
	local self = setmetatable({}, AnimationHandle) :: AnimationHandleImpl

	self._player = player
	self._animName = animName
	self._track = track
	self._info = info
	self._trove = Trove.new()
	self._researcher = nil
	self._speed = 1
	self._priority = nil
	self._fadeTime = DEFAULT_FADE_TIME
	self._pauseOnLastFrame = false
	self._autoStopDelay = nil
	self._autoStopDelayCallbacks = {}
	self._waiting = false
	self._waitingStartTime = nil
	self._startTime = nil
	self._endTime = nil
	self._playing = false
	self._paused = false
	self._destroyed = false
	self._markerCallbacks = {}
	self._frameCallbacks = {}
	self._frameRangeCallbacks = {}
	self._endCallbacks = {}
	self._nearEndCallbacks = {}

	self.Ended = self._trove:Construct(Signal)

	return self :: any
end

function AnimationHandle.Play(self: AnimationHandleImpl): Types.AnimationHandle
	if self._destroyed then
		return self :: any
	end

	self._playing = true
	self._paused = false

	local track = self._track
	local startTime = self._startTime or 0
	local endTime = self._endTime or track.Length

	if self._priority then
		track.Priority = self._priority
	end

	track:Play(self._fadeTime, self._speed)
	track.TimePosition = startTime

	self:_SetupMarkerListeners()
	self:_SetupFrameCallbacks()
	
	if self._pauseOnLastFrame then
		self:_SetupNearEndDetection(endTime)
	else
		self:_SetupEndDetection(endTime)
		if #self._nearEndCallbacks > 0 then
			self:_SetupNearEndDetection(endTime)
		end
	end

	return self :: any
end

function AnimationHandle.Stop(self: AnimationHandleImpl, fadeTime: number?): Types.AnimationHandle
	if self._destroyed then
		return self :: any
	end

	self._playing = false
	self._waiting = false
	self._waitingStartTime = nil
	self._track:Stop(fadeTime or self._fadeTime)

	if self._researcher then
		self._researcher:Stop()
	end

	return self :: any
end

function AnimationHandle.Pause(self: AnimationHandleImpl): Types.AnimationHandle
	if self._destroyed then
		return self :: any
	end

	self._paused = true
	self._track:AdjustSpeed(0)

	if self._researcher then
		self._researcher:Pause()
	end

	return self :: any
end

function AnimationHandle.Resume(self: AnimationHandleImpl): Types.AnimationHandle
	if self._destroyed then
		return self :: any
	end

	self._paused = false
	self._waiting = false
	self._waitingStartTime = nil
	self._track:AdjustSpeed(self._speed)

	if self._researcher then
		self._researcher:Resume()
	end

	return self :: any
end

function AnimationHandle.Continue(self: AnimationHandleImpl): Types.AnimationHandle
	if self._destroyed or not self._waiting then
		return self :: any
	end

	self._waiting = false
	self._waitingStartTime = nil
	self:Resume()

	return self :: any
end

function AnimationHandle.IsWaiting(self: AnimationHandleImpl): boolean
	return self._waiting
end

function AnimationHandle.SetSpeed(self: AnimationHandleImpl, speed: number): Types.AnimationHandle
	self._speed = speed

	if self._playing and not self._paused then
		self._track:AdjustSpeed(speed)
	end

	if self._researcher then
		self._researcher:SetSpeed(speed)
	end

	return self :: any
end

function AnimationHandle.SetPriority(self: AnimationHandleImpl, priority: Enum.AnimationPriority): Types.AnimationHandle
	self._priority = priority
	self._track.Priority = priority
	return self :: any
end

function AnimationHandle.SetFadeTime(self: AnimationHandleImpl, fadeTime: number): Types.AnimationHandle
	self._fadeTime = fadeTime
	return self :: any
end

function AnimationHandle.PauseOnLastFrame(self: AnimationHandleImpl, enabled: boolean?): Types.AnimationHandle
	self._pauseOnLastFrame = if enabled == false then false else true
	return self :: any
end

function AnimationHandle.SetAutoStopDelay(self: AnimationHandleImpl, delay: number?): Types.AnimationHandle
	self._autoStopDelay = delay
	return self :: any
end

function AnimationHandle.OnAutoStopDelay(self: AnimationHandleImpl, callback: EndCallback): Types.AnimationHandle
	table.insert(self._autoStopDelayCallbacks, callback)
	return self :: any
end

function AnimationHandle.SetRange(
	self: AnimationHandleImpl,
	startTime: number?,
	endTime: number?
): Types.AnimationHandle
	self._startTime = startTime
	self._endTime = endTime
	return self :: any
end

function AnimationHandle.SetLooped(self: AnimationHandleImpl, looped: boolean): Types.AnimationHandle
	self._track.Looped = looped
	return self :: any
end

function AnimationHandle.IsLooped(self: AnimationHandleImpl): boolean
	return self._track.Looped
end

function AnimationHandle.FromMarker(self: AnimationHandleImpl, markerName: string): Types.AnimationHandle
	if self._info and self._info.Markers[markerName] then
		self._startTime = self._info.Markers[markerName]
	end
	return self :: any
end

function AnimationHandle.ToMarker(self: AnimationHandleImpl, markerName: string): Types.AnimationHandle
	if self._info and self._info.Markers[markerName] then
		self._endTime = self._info.Markers[markerName]
	end
	return self :: any
end

function AnimationHandle.OnMarker(
	self: AnimationHandleImpl,
	markerName: string,
	callback: MarkerCallback
): Types.AnimationHandle
	if not self._markerCallbacks[markerName] then
		self._markerCallbacks[markerName] = {}
	end
	table.insert(self._markerCallbacks[markerName], callback)
	return self :: any
end

function AnimationHandle.OnFrame(
	self: AnimationHandleImpl,
	frame: number,
	callback: FrameCallback
): Types.AnimationHandle
	table.insert(self._frameCallbacks, { frame = frame, callback = callback })
	return self :: any
end

function AnimationHandle.OnFrameRange(
	self: AnimationHandleImpl,
	startFrame: number,
	endFrame: number,
	callback: FrameCallback
): Types.AnimationHandle
	table.insert(self._frameRangeCallbacks, { startFrame = startFrame, endFrame = endFrame, callback = callback })
	return self :: any
end

function AnimationHandle.OnEnd(self: AnimationHandleImpl, callback: EndCallback): Types.AnimationHandle
	table.insert(self._endCallbacks, callback)
	return self :: any
end

function AnimationHandle.OnNearEnd(self: AnimationHandleImpl, callback: EndCallback): Types.AnimationHandle
	table.insert(self._nearEndCallbacks, callback)
	return self :: any
end

function AnimationHandle.IsPlaying(self: AnimationHandleImpl): boolean
	return self._playing and not self._destroyed
end

function AnimationHandle.GetTimePosition(self: AnimationHandleImpl): number
	return self._track.TimePosition
end

function AnimationHandle.GetAnimationName(self: AnimationHandleImpl): string
	return self._animName
end

function AnimationHandle.AwaitEnd(self: AnimationHandleImpl): ()
	if self._destroyed or not self._playing then
		return
	end

	local thread = coroutine.running()
	local conn

	conn = self.Ended:Connect(function()
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

function AnimationHandle.Destroy(self: AnimationHandleImpl): ()
	if self._destroyed then
		return
	end

	self._destroyed = true
	self._playing = false
	self._waiting = false
	self._waitingStartTime = nil

	if self._track and self._track.IsPlaying then
		self._track:Stop(self._fadeTime)
	end

	if self._researcher then
		self._researcher:Destroy()
		self._researcher = nil
	end

	self._trove:Destroy()
end

function AnimationHandle._SetupMarkerListeners(self: AnimationHandleImpl): ()
	for markerName, callbacks in self._markerCallbacks do
		local connection = self._track:GetMarkerReachedSignal(markerName):Connect(function(value: string?)
			local time = self._track.TimePosition
			for _, callback in callbacks do
				task.spawn(callback, time, value)
			end
		end)
		self._trove:Add(connection)
	end
end

function AnimationHandle._SetupFrameCallbacks(self: AnimationHandleImpl): ()
	if #self._frameCallbacks == 0 and #self._frameRangeCallbacks == 0 then
		return
	end

	local info = self._info
	if not info then
		return
	end

	local frameRate = info.FrameRate
	local researcher = KeyframesResearcher.new({
		Speed = self._speed,
		Looped = self._track.Looped,
	})

	self._researcher = researcher
	self._trove:Add(researcher)

	for _, frameData in self._frameCallbacks do
		researcher:AddFrame(frameData.frame, function()
			task.spawn(frameData.callback, frameData.frame)
		end)
	end

	for _, rangeData in self._frameRangeCallbacks do
		researcher:AddFrames(rangeData.startFrame, rangeData.endFrame, function(_, frame: number)
			task.spawn(rangeData.callback, frame)
		end)
	end

	local startFrame = math.floor((self._startTime or 0) * frameRate)
	researcher:PlayAt(startFrame)
end

function AnimationHandle._SetupEndDetection(self: AnimationHandleImpl, targetEndTime: number): ()
	local track = self._track

	local function onEnd()
		if self._destroyed then
			return
		end

		self._playing = false

		for _, callback in self._endCallbacks do
			task.spawn(callback)
		end

		self.Ended:Fire()
	end

	if self._endTime then
		local checkThread = task.spawn(function()
			while self._playing and not self._destroyed do
				if track.TimePosition >= targetEndTime then
					track:Stop(self._fadeTime)
					onEnd()
					break
				end
				task.wait()
			end
		end)
		self._trove:Add(checkThread)
	else
		local stoppedConn = track.Stopped:Connect(function()
			onEnd()
		end)
		self._trove:Add(stoppedConn)

		if not track.Looped then
			local endedConn = track.Ended:Connect(function()
				onEnd()
			end)
			self._trove:Add(endedConn)
		end
	end
end

function AnimationHandle._SetupNearEndDetection(self: AnimationHandleImpl, targetEndTime: number): ()
	local track = self._track
	local nearEndTime = targetEndTime - NEAR_END_THRESHOLD
	local nearEndFired = false

	local checkThread = task.spawn(function()
		while self._playing and not self._destroyed and not nearEndFired do
			if track.TimePosition >= nearEndTime then
				nearEndFired = true
				
				if self._pauseOnLastFrame then
					self:Pause()
					self._waiting = true
					self._waitingStartTime = tick()

					for _, callback in self._endCallbacks do
						task.spawn(callback)
					end

					self.Ended:Fire()

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
				end

				for _, callback in self._nearEndCallbacks do
					task.spawn(callback)
				end
				break
			end
			task.wait()
		end
	end)
	self._trove:Add(checkThread)
end

return AnimationHandle
