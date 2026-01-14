--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Wcs = require(ReplicatedStorage.Packages.wcs)
local MoveRegistry = require(ReplicatedStorage.Shared.Modules.Data.Moves.MoveRegistry)
local InputManager = require(ReplicatedStorage.Shared.Modules.Utility.InputManager)

local CharacterClass = Wcs.Character
type InputAction = InputManager.InputAction

export type InputServiceClient = {
	init: (self: InputServiceClient) -> (),
	_bindCharacter: (self: InputServiceClient) -> (),
	_onCharacter: (self: InputServiceClient, character: Model) -> (),
	_buildMoveset: (self: InputServiceClient, movesetName: string) -> (),
	_clearInputs: (self: InputServiceClient) -> (),
	_setupHoldRepeat: (self: InputServiceClient, skill: any, keys: any) -> () -> (),
	_setupAutoRestart: (self: InputServiceClient, action: any, skill: any) -> () -> (),

	_activeMoveset: string?,
	_disconnects: { () -> () },
	_characterConnection: RBXScriptConnection?,
}

local InputServiceClient = {}

local function getWcsCharacter()
	local model = Players.LocalPlayer.Character
	if not model then
		return nil :: any
	end
	return CharacterClass.GetCharacterFromInstance(model)
end

local function isSkillInCurrentMoveset(character: Model, skillConstructor: any): boolean
	local globalRegistry = MoveRegistry.get("Global")
	if globalRegistry then
		for _, moveData in pairs(globalRegistry) do
			if moveData.Skill == skillConstructor then
				return true
			end
		end
	end

	local currentMoveset = character:GetAttribute("Moveset")
	if not currentMoveset or currentMoveset == "None" or currentMoveset == "" then
		return false
	end

	local registry = MoveRegistry.get(currentMoveset)
	if not registry then
		return false
	end

	for _, moveData in pairs(registry) do
		if moveData.Skill == skillConstructor then
			return true
		end
	end

	return false
end

function InputServiceClient:_setupHoldRepeat(skillConstructor: any, keys: any): () -> ()
	local running = true

	task.spawn(function()
		while running do
			task.wait(0.05)
			if not running then
				break
			end

			if not InputManager.IsKeySetHeld(keys) then
				break
			end

			local characterModel = Players.LocalPlayer.Character
			if not characterModel then
				continue
			end

			if not isSkillInCurrentMoveset(characterModel, skillConstructor) then
				break
			end

			local character = getWcsCharacter()
			if not character then
				continue
			end

			local skill = character:GetSkillFromConstructor(skillConstructor)
			if not skill then
				continue
			end

			local state = skill:GetState()
			if not state.IsActive and not state.Debounce then
				skill:Start()
			end
		end
	end)

	return function()
		running = false
	end
end

function InputServiceClient:_setupAutoRestart(action: any, skillConstructor: any): () -> ()
	local running = true

	task.spawn(function()
		while running do
			task.wait(0.1)
			if not running then
				break
			end

			if not InputManager.ShouldAutoRestart(action) then
				continue
			end

			local characterModel = Players.LocalPlayer.Character
			if not characterModel then
				continue
			end

			if not isSkillInCurrentMoveset(characterModel, skillConstructor) then
				break
			end

			local character = getWcsCharacter()
			if not character then
				continue
			end

			local skill = character:GetSkillFromConstructor(skillConstructor)
			if not skill then
				continue
			end

			local state = skill:GetState()
			if not state.IsActive and not state.Debounce then
				skill:Start()
				-- Reset desired state after starting
				local actionAny = action :: any
				actionAny.DesiredState = nil
			end
		end
	end)

	return function()
		running = false
	end
end

function InputServiceClient:init()
	self._disconnects = {}
	self._activeMoveset = nil
	self._characterConnection = nil
	self:_bindCharacter()
end

function InputServiceClient:_bindCharacter()
	local player = Players.LocalPlayer

	player.CharacterAdded:Connect(function(char)
		self:_onCharacter(char)
	end)

	if player.Character then
		self:_onCharacter(player.Character)
	end
end

function InputServiceClient:_onCharacter(character: Model)
	-- Disconnect previous moveset listener if any
	local oldConnection = self._characterConnection
	if oldConnection then
		oldConnection:Disconnect()
	end
	self._characterConnection = nil :: any

	local function onMovesetChanged()
		local newMoveset = character:GetAttribute("Moveset")
		self:_clearInputs()

		self:_buildMoveset("Global")

		if newMoveset then
			self:_buildMoveset(newMoveset)
		end

		self._activeMoveset = newMoveset
	end

	onMovesetChanged()
	self._characterConnection = character:GetAttributeChangedSignal("Moveset"):Connect(onMovesetChanged)
end

function InputServiceClient:_buildMoveset(movesetName: string)
	local registry = MoveRegistry.get(movesetName)
	if not registry then
		return
	end

	for moveName, data in registry do
		if not data.Input then
			continue
		end

		if not data.Skill then
			continue
		end

		-- Determine input mode
		local inputMode = data.InputMode or "Press"

		local action = InputManager.CreateAction(moveName, {
			Category = movesetName,
			Keys = data.Input,
			Mode = inputMode,
			Cooldown = data.Cooldown or 0,
			Priority = data.Priority or 1000,
		})

		if inputMode == "Holdable" then
			-- Holdable skill (like Barrage, or Run with toggle option)
			local autoRestartDisconnect: (() -> ())?

			local disconnect = action:OnPress(function()
				local characterModel = Players.LocalPlayer.Character
				if not characterModel then
					return
				end

				if not isSkillInCurrentMoveset(characterModel, data.Skill) then
					return
				end

				local character = getWcsCharacter()
				if not character then
					warn("[InputService] No WCS character found")
					return
				end

				local skill = character:GetSkillFromConstructor(data.Skill)
				if not skill then
					warn(string.format("[InputService] Skill not found on character: %s", moveName))
					return
				end

				-- Check if skill has Toggle property set to true
				local isToggle = (skill :: any).Toggle == true

				if isToggle then
					-- Toggle behavior: press to start, press again to stop
					local state = skill:GetState()
					if state.IsActive then
						-- Toggle off
						skill:End()
						if autoRestartDisconnect then
							autoRestartDisconnect()
							autoRestartDisconnect = nil
						end
					else
						-- Toggle on
						skill:Start()
						-- Setup auto-restart if not already running
						if autoRestartDisconnect then
							autoRestartDisconnect()
						end
						autoRestartDisconnect = self:_setupAutoRestart(action, data.Skill)
					end
				else
					-- Normal holdable behavior: hold to start
					skill:Start()
					-- Setup auto-restart if not already running
					if autoRestartDisconnect then
						autoRestartDisconnect()
					end
					autoRestartDisconnect = self:_setupAutoRestart(action, data.Skill)
				end
			end)
			table.insert(self._disconnects, disconnect)

			local releaseDisconnect = action:OnRelease(function(_, _heldDuration)
				local characterModel = Players.LocalPlayer.Character
				if not characterModel then
					return
				end

				if not isSkillInCurrentMoveset(characterModel, data.Skill) then
					return
				end

				local character = getWcsCharacter()
				if not character then
					return
				end

				local skill = character:GetSkillFromConstructor(data.Skill)
				if not skill then
					return
				end

				-- Check if skill has Toggle property set to true
				local isToggle = (skill :: any).Toggle == true

				if isToggle then
					-- For toggle mode, release doesn't end the skill, only next press does
					return
				end

				-- Normal holdable: release ends the skill
				if skill:GetState().IsActive then
					skill:End()
				end
				if autoRestartDisconnect then
					autoRestartDisconnect()
					autoRestartDisconnect = nil
				end
			end)
			table.insert(self._disconnects, releaseDisconnect)

			-- Cancel handler (for stun interrupts from server) - setup auto-restart
			local cancelDisconnect = action:OnCancel(function(_, _source)
				-- Setup auto-restart if key is still held
				if InputManager.ShouldAutoRestart(action) then
					if autoRestartDisconnect then
						autoRestartDisconnect()
					end
					autoRestartDisconnect = self:_setupAutoRestart(action, data.Skill)
				else
					if autoRestartDisconnect then
						autoRestartDisconnect()
						autoRestartDisconnect = nil
					end
				end
			end)
			table.insert(self._disconnects, cancelDisconnect)

			table.insert(self._disconnects, function()
				if autoRestartDisconnect then
					autoRestartDisconnect()
				end
			end)
		elseif inputMode == "Toggle" then
			-- Toggle skill (like Run)
			local autoRestartDisconnect: (() -> ())?

			local disconnect = action:OnPress(function()
				local characterModel = Players.LocalPlayer.Character
				if not characterModel then
					return
				end

				if not isSkillInCurrentMoveset(characterModel, data.Skill) then
					return
				end

				local character = getWcsCharacter()
				if not character then
					warn("[InputService] No WCS character found")
					return
				end

				local skill = character:GetSkillFromConstructor(data.Skill)
				if skill then
					local state = skill:GetState()
					if state.IsActive then
						-- Toggle off
						skill:End()
						if autoRestartDisconnect then
							autoRestartDisconnect()
							autoRestartDisconnect = nil
						end
					else
						-- Toggle on
						skill:Start()
						-- Setup auto-restart if not already running
						if autoRestartDisconnect then
							autoRestartDisconnect()
						end
						autoRestartDisconnect = self:_setupAutoRestart(action, data.Skill)
					end
				else
					warn(string.format("[InputService] Skill not found on character: %s", moveName))
				end
			end)
			table.insert(self._disconnects, disconnect)

			local releaseDisconnect = action:OnRelease(function(_, _heldDuration)
				-- For toggle, release doesn't end the skill, only next press does
			end)
			table.insert(self._disconnects, releaseDisconnect)

			-- Cancel handler (for stun interrupts from server) - setup auto-restart
			local cancelDisconnect = action:OnCancel(function(_, _source)
				-- Setup auto-restart if key is still held
				if InputManager.ShouldAutoRestart(action) then
					if autoRestartDisconnect then
						autoRestartDisconnect()
					end
					autoRestartDisconnect = self:_setupAutoRestart(action, data.Skill)
				else
					if autoRestartDisconnect then
						autoRestartDisconnect()
						autoRestartDisconnect = nil
					end
				end
			end)
			table.insert(self._disconnects, cancelDisconnect)

			table.insert(self._disconnects, function()
				if autoRestartDisconnect then
					autoRestartDisconnect()
				end
			end)
		else
			-- Simple press skill (like M1, Dash, Summon) with hold-to-repeat
			local holdRepeatDisconnect: (() -> ())?

			local disconnect = action:OnPress(function()
				local characterModel = Players.LocalPlayer.Character
				if not characterModel then
					return
				end

				if not isSkillInCurrentMoveset(characterModel, data.Skill) then
					return
				end

				local character = getWcsCharacter()
				if not character then
					return
				end

				local skill = character:GetSkillFromConstructor(data.Skill)
				if skill then
					skill:Start()
					if holdRepeatDisconnect then
						holdRepeatDisconnect()
					end
					holdRepeatDisconnect = self:_setupHoldRepeat(data.Skill, data.Input)
				else
					warn(string.format("[InputService] Skill not found on character: %s", moveName))
				end
			end)
			table.insert(self._disconnects, disconnect)

			table.insert(self._disconnects, function()
				if holdRepeatDisconnect then
					holdRepeatDisconnect()
				end
			end)
		end
	end
end

function InputServiceClient:_clearInputs()
	-- Disconnect all callbacks
	for _, disconnect in self._disconnects do
		disconnect()
	end
	table.clear(self._disconnects)

	InputManager.DestroyCategory("Global")

	if self._activeMoveset then
		InputManager.DestroyCategory(self._activeMoveset)
	end
end

return InputServiceClient
