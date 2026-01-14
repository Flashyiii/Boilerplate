local KeyframesResearcher = {}
KeyframesResearcher.__index = KeyframesResearcher

local RepStorage = game:GetService("ReplicatedStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)

KeyframesResearcher.new = function(config)
	local self = setmetatable({}, KeyframesResearcher)

	self._Time = 0
	self._Position = 0
	self._Length = 0
	self._Speed = 1
	self._Playing = false
	self._Paused = false
	self._Looped = false
	self._Frames = {}
	self._FrameCache = {}
	self._Destroyed = false

	self.Played = Signal.new()
	self.Ended = Signal.new()
	self.Paused = Signal.new()
	self.Stopped = Signal.new()
	self.Completed = Signal.new()
	self.DidLoop = Signal.new()
	self.MovedTo = Signal.new()
	self.Updated = Signal.new()
	self.Failed = Signal.new()
	self.Destroying = Signal.new()

	if config then
		self:Load(config)
	end

	return self
end

function KeyframesResearcher:Load(config)
	if config.Speed ~= nil then
		self:SetSpeed(config.Speed)
	end

	if config.Looped ~= nil then
		self:Loop(config.Looped)
	end

	if config.Validate ~= nil then
		self:SetValidate(config.Validate)
	end

	if config.FrameHandler ~= nil then
		self:SetFrameHandler(config.FrameHandler)
	end

	if config.ErrorHandler ~= nil then
		self:SetErrorHandler(config.ErrorHandler)
	end

	for _, v10 in ipairs(config.Frames) do
		if typeof(v10[2]) == "number" then
			self:AddFrames(unpack(v10))
		else
			self:AddFrame(unpack(v10))
		end
	end

	return self
end

function KeyframesResearcher:AddFrame(frameNumber, callback)
	local frameList = self._Frames[frameNumber]

	if not frameList then
		frameList = {}
		self._Frames[frameNumber] = frameList
	end

	table.insert(frameList, callback)

	if self._Length < frameNumber then
		self._Length = frameNumber
	end
end

function KeyframesResearcher:AddFrames(startFrame, endFrame, callback)
	for frameNumber = startFrame, endFrame do
		self:AddFrame(frameNumber, callback)
	end
end

function KeyframesResearcher:RunFrame(frameNumber, ...)
	if self._FrameCache[frameNumber] then
		return false
	else
		local frameList = self._Frames[frameNumber]
		if not frameList then
			return false
		else
			self._FrameCache[frameNumber] = true
			for _, callback in ipairs(frameList) do
				if typeof(callback) == "function" then
					local result =
						table.pack(xpcall(self.RunCallback, debug.traceback, callback, self, frameNumber, ...))
					local success = result[1]

					if not success and typeof(result[2]) == "string" then
						local errorMessage = result[2]
						warn((("An error occurred attempting to run frame %*\n%*"):format(frameNumber, result[2])))

						self.Failed:Fire(frameNumber, errorMessage)
						KeyframesResearcher.Errored(self, frameNumber, errorMessage)
					elseif success then
						local command = typeof(result[2]) == "string" and result[2]:lower() or nil
						if command then
							if not (command ~= "goto") or command == "moveto" then
								self:_PlayAt(result[3] or nil)
							elseif not (command ~= "stop") or result[2] == false then
								self:Stop()
								return
							elseif command == "pause" then
								self:Pause()
								return
							elseif command == "repeat" then
								self:MoveTo(frameNumber)
								return
							elseif command == "playsequence" then
								local keyframes = result[3]
								local time = result[4]

								if typeof(keyframes) == "table" and keyframes.ClassName == "Sequence" then
									keyframes:_PlayAt(time, unpack(result[5] or {}))
								end
							elseif not (command ~= "switchsequence") or command == "switch" then
								local keyframes = result[3]
								local time = result[4]

								if typeof(keyframes) == "table" and keyframes.ClassName == "Sequence" then
									self:Stop()
									keyframes:_PlayAt(time, unpack(result[5] or {}))
								end

								return
							end
						end
					end
				end
			end
			return true
		end
	end
end

function KeyframesResearcher.RunCallback(callback, self, ...)
	return callback(self, ...)
end

function KeyframesResearcher.Validate()
	return true
end

function KeyframesResearcher.Errored(self)
	self:Stop()
end

function KeyframesResearcher:_PlayAt(startTime, ...)
	self._Time = startTime or 0

	if self:IsPlaying() then
		self:MoveTo(self._Time)
		return
	else
		self._Playing = true
		self:MoveTo(self._Time)
		self:RunFrame(0, ...)
		self.Played:Fire(...)

		while (not (self._Time > self:GetLength()) or self:IsLooped()) and self:IsPlaying() do
			local delta = task.wait()

			if not self:IsPlaying() then
				return
			elseif not self:IsPaused() then
				if not self:Validate(...) then
					self.Failed:Fire(self._Position, "ValidateFailed")
					break
				else
					self._Time = self._Time + delta * self:GetSpeed() * 60
					self._Position = math.floor(self._Time)
					self.Updated:Fire(self._Position)

					for frameNumber, _ in pairs(self._Frames) do
						if
							not (
								not (self._Time >= frameNumber)
								or self:RunFrame(frameNumber, ...) ~= nil and self:IsPlaying()
							)
						then
							break
						end
					end

					if self:IsLooped() and self._Time > self:GetLength() then
						table.clear(self._FrameCache)
						self._Time = self._Time - self:GetLength()
						self:RunFrame(0, ...)
						self.DidLoop:Fire()
					end
				end
			end
		end

		self:End()
		self.Completed:Fire()
		return
	end
end

function KeyframesResearcher:End()
	self._Playing = false
	self._Position = 0
	self.Ended:Fire()

	table.clear(self._FrameCache)
end

function KeyframesResearcher:Play(...)
	return task.spawn(self._PlayAt, self, 0, ...)
end

function KeyframesResearcher:PlayAt(time, ...)
	return task.spawn(self._PlayAt, self, time or 0, ...)
end

function KeyframesResearcher:Pause()
	if self._Playing then
		self._Paused = true
		self.Paused:Fire()
	end
end

function KeyframesResearcher:Resume()
	if self._Paused then
		self._Paused = false
	end
end

function KeyframesResearcher:Stop()
	if self._Playing then
		self:End()
		self.Stopped:Fire()

		if self.Trove then
			self.Trove:Destroy()
		end
	end
end

function KeyframesResearcher:MoveTo(position, preservePrevious)
	self._Position = math.clamp(position, 0, self._Length)
	self._Time = position

	for cachedFrame, _ in pairs(self._FrameCache) do
		if self:GetPosition() <= cachedFrame then
			self._FrameCache[cachedFrame] = nil
		end
	end

	if preservePrevious == true then
		for frameNumber, _ in pairs(self._Frames) do
			if frameNumber < self:GetPosition() then
				self._FrameCache[frameNumber] = true
			end
		end
	end

	self.MovedTo:Fire(self._Position)
end

function KeyframesResearcher:IsPlaying()
	return self._Playing
end

function KeyframesResearcher:IsPaused()
	return self._Paused
end

function KeyframesResearcher:IsLooped()
	return self._Looped
end

function KeyframesResearcher:Loop(isLooped)
	self._Looped = isLooped
end

function KeyframesResearcher:GetSpeed()
	return self._Speed
end

function KeyframesResearcher:GetPosition()
	return self._Position
end

function KeyframesResearcher:GetLength()
	return self._Length
end

function KeyframesResearcher:SetSpeed(speed)
	self._Speed = speed
end

function KeyframesResearcher:GetValidate()
	return self.Validate
end

function KeyframesResearcher:SetValidate(callback)
	self.Validate = callback
end

function KeyframesResearcher:GetFrameHandler()
	return self.RunCallback
end

function KeyframesResearcher:SetFrameHandler(callback)
	self.RunCallback = callback
end

function KeyframesResearcher:GetErrorHandler()
	return self.Errored
end

function KeyframesResearcher:SetErrorHandler(callback)
	self.Errored = callback
end

function KeyframesResearcher:Destroy()
	if self._Destroyed then
		return
	else
		self._Destroyed = true

		if self:IsPlaying() then
			self:Stop()
		end

		if self.Trove then
			self.Trove:Destroy()
		end

		self.Destroying:Fire()
		return
	end
end

return KeyframesResearcher
