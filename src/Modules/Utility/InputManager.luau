--!strict
--[[
	InputManager - Enhanced Input System for WCS
	
	A production-ready input manager supporting:
	- Press / Hold / Release detection
	- Phase-aware input routing
	- Cancellation hooks
	- Context-based input groups
	- Mouse button support via UserInputType
	
	USAGE:
	
	local InputManager = require(path.to.InputManager)
	
	-- Create a holdable action
	local barrage = InputManager.CreateAction("Barrage", {
		Category = "Combat",
		Keys = { KeyboardBinding = { Enum.KeyCode.E } },
		Mode = "Holdable",
		Cooldown = 0,
	})
	
	barrage:OnPress(function()
		print("Barrage started")
	end)
	
	barrage:OnRelease(function(heldDuration)
		print("Barrage released after", heldDuration, "seconds")
	end)
]]

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Special "keycodes" for mouse buttons (matches Roblox InputBinding behavior)
local MOUSE_LEFT_BUTTON = "MouseButton1"
local MOUSE_RIGHT_BUTTON = "MouseButton2"
local MOUSE_MIDDLE_BUTTON = "MouseButton3"

export type KeycodeSet = {
	KeyboardBinding: { Enum.KeyCode }?,
	GamepadBinding: { Enum.KeyCode }?,
	TouchButton: GuiButton?,
}

export type InputMode = "Press" | "Holdable" | "Toggle"

export type ActionConfig = {
	Category: string,
	Keys: KeycodeSet,
	Mode: InputMode?,
	Cooldown: number?,
	Priority: number?,
}

export type InputCallbacks = {
	OnPress: { (action: InputAction) -> () },
	OnRelease: { (action: InputAction, heldDuration: number) -> () },
	OnCancel: { (action: InputAction, source: string) -> () },
	OnHoldTick: { (action: InputAction, heldDuration: number) -> () },
}

export type InputAction = {
	-- Configuration
	Name: string,
	Category: string,
	Mode: InputMode,
	Keys: KeycodeSet,
	Cooldown: number,
	Priority: number,

	-- State
	Enabled: boolean,
	IsPressed: boolean,
	PressStartTime: number?,
	LastPressTime: number,
	DesiredState: boolean?,

	-- Methods
	OnPress: (self: InputAction, callback: (action: InputAction) -> ()) -> () -> (),
	OnRelease: (self: InputAction, callback: (action: InputAction, heldDuration: number) -> ()) -> () -> (),
	OnCancel: (self: InputAction, callback: (action: InputAction, source: string) -> ()) -> () -> (),
	OnHoldTick: (self: InputAction, callback: (action: InputAction, heldDuration: number) -> ()) -> () -> (),

	IsHeld: (self: InputAction) -> boolean,
	GetHeldDuration: (self: InputAction) -> number,
	SetEnabled: (self: InputAction, enabled: boolean) -> (),
	SetKeys: (self: InputAction, keys: KeycodeSet) -> (),
	Cancel: (self: InputAction, source: string?) -> (),
	Destroy: (self: InputAction) -> (),
}

-- Unified key type that can be KeyCode or mouse button string
type UnifiedKey = Enum.KeyCode | string

-- Internal storage
local Actions: { [string]: InputAction } = {}
local Categories: { [string]: { [string]: InputAction } } = {}
local KeyBindings: { [UnifiedKey]: { InputAction } } = {}
local HeldKeys: { [UnifiedKey]: boolean } = {}

local InputManager = {}

--[[
	Converts a KeyCode to a unified key for storage.
	Handles the special MouseLeftButton etc. keycodes.
]]
local function toUnifiedKey(keyCode: Enum.KeyCode): UnifiedKey
	local keyName = keyCode.Name

	-- Handle Roblox's special mouse "keycodes" used by InputBinding
	if keyName == "MouseLeftButton" or keyName == "MouseButton1" then
		return MOUSE_LEFT_BUTTON
	elseif keyName == "MouseRightButton" or keyName == "MouseButton2" then
		return MOUSE_RIGHT_BUTTON
	elseif keyName == "MouseMiddleButton" or keyName == "MouseButton3" then
		return MOUSE_MIDDLE_BUTTON
	end

	return keyCode
end

--[[
	Converts an InputObject to a unified key.
]]
local function inputToUnifiedKey(input: InputObject): UnifiedKey?
	local keyCode = input.KeyCode
	local inputType = input.UserInputType

	-- Handle mouse buttons via UserInputType
	if inputType == Enum.UserInputType.MouseButton1 then
		return MOUSE_LEFT_BUTTON
	elseif inputType == Enum.UserInputType.MouseButton2 then
		return MOUSE_RIGHT_BUTTON
	elseif inputType == Enum.UserInputType.MouseButton3 then
		return MOUSE_MIDDLE_BUTTON
	end

	-- Handle keyboard/gamepad via KeyCode
	if keyCode ~= Enum.KeyCode.Unknown then
		return keyCode
	end

	return nil
end

--[[
	Creates a connection-style subscription that can be disconnected.
]]
local function createSubscription<T>(list: { T }, callback: T): () -> ()
	table.insert(list, callback)

	return function()
		local index = table.find(list, callback)
		if index then
			table.remove(list, index)
		end
	end
end

--[[
	Internal: Handles input began events.
]]
local function onInputBegan(input: InputObject, gameProcessed: boolean)
	if gameProcessed then
		return
	end

	local unifiedKey = inputToUnifiedKey(input)
	if not unifiedKey then
		return
	end

	HeldKeys[unifiedKey] = true

	local boundActions = KeyBindings[unifiedKey]
	if not boundActions then
		return
	end

	-- Sort by priority (higher first)
	table.sort(boundActions, function(a, b)
		return a.Priority > b.Priority
	end)

	local now = tick()

	for _, action in boundActions do
		if not action.Enabled then
			continue
		end

		-- Check cooldown
		if now - action.LastPressTime < action.Cooldown then
			continue
		end

		if action.Mode == "Toggle" then
			-- Toggle mode: if pressed, release; if not pressed, press
			if action.IsPressed then
				-- Release toggle
				local heldDuration = if action.PressStartTime then now - action.PressStartTime else 0
				action.IsPressed = false
				action.PressStartTime = nil
				action.DesiredState = false
				action.LastPressTime = now

				-- Fire release callbacks
				local callbacks = (action :: any)._callbacks :: InputCallbacks
				for _, callback in callbacks.OnRelease do
					task.spawn(callback, action, heldDuration)
				end
			else
				-- Press toggle
				action.IsPressed = true
				action.PressStartTime = now
				action.LastPressTime = now
				action.DesiredState = true

				-- Fire press callbacks
				local callbacks = (action :: any)._callbacks :: InputCallbacks
				for _, callback in callbacks.OnPress do
					task.spawn(callback, action)
				end
			end
		else
			-- Holdable or Press mode
			if action.IsPressed then
				continue
			end

			-- Mark as pressed
			action.IsPressed = true
			action.PressStartTime = now
			action.LastPressTime = now
			action.DesiredState = true

			-- Fire press callbacks
			local callbacks = (action :: any)._callbacks :: InputCallbacks
			for _, callback in callbacks.OnPress do
				task.spawn(callback, action)
			end

			-- For press mode, immediately release (don't track hold state)
			if action.Mode == "Press" then
				action.IsPressed = false
				action.PressStartTime = nil
				action.DesiredState = nil
			end
		end

		break -- Only trigger first matching action (priority-based)
	end
end

--[[
	Internal: Handles input ended events.
]]
local function onInputEnded(input: InputObject)
	local unifiedKey = inputToUnifiedKey(input)
	if not unifiedKey then
		return
	end

	HeldKeys[unifiedKey] = nil

	local boundActions = KeyBindings[unifiedKey]
	if not boundActions then
		return
	end

	for _, action in boundActions do
		if not action.IsPressed then
			continue
		end

		if action.Mode == "Holdable" then
			local heldDuration = if action.PressStartTime then tick() - action.PressStartTime else 0

			action.IsPressed = false
			action.PressStartTime = nil
			action.DesiredState = false

			-- Fire release callbacks
			local callbacks = (action :: any)._callbacks :: InputCallbacks
			for _, callback in callbacks.OnRelease do
				task.spawn(callback, action, heldDuration)
			end
		elseif action.Mode == "Toggle" then
			-- Toggle mode only releases on next press, not on key release
			-- But we track that the key is no longer held for auto-restart logic
			action.DesiredState = false
		end
	end
end

-- Connect to input events
UserInputService.InputBegan:Connect(onInputBegan)
UserInputService.InputEnded:Connect(onInputEnded)

-- Hold tick heartbeat
RunService.Heartbeat:Connect(function()
	local now = tick()

	for _, action in Actions do
		if action.IsPressed and action.Mode == "Holdable" and action.PressStartTime then
			local heldDuration = now - action.PressStartTime

			local callbacks = (action :: any)._callbacks :: InputCallbacks
			for _, callback in callbacks.OnHoldTick do
				task.spawn(callback, action, heldDuration)
			end
		end
	end
end)

--[[
	Internal: Binds a unified key to an action.
]]
local function bindKey(unifiedKey: UnifiedKey, action: InputAction)
	if not KeyBindings[unifiedKey] then
		KeyBindings[unifiedKey] = {}
	end

	if not table.find(KeyBindings[unifiedKey], action) then
		table.insert(KeyBindings[unifiedKey], action)
	end
end

--[[
	Internal: Unbinds a unified key from an action.
]]
local function unbindKey(unifiedKey: UnifiedKey, action: InputAction)
	if KeyBindings[unifiedKey] then
		local index = table.find(KeyBindings[unifiedKey], action)
		if index then
			table.remove(KeyBindings[unifiedKey], index)
		end

		if #KeyBindings[unifiedKey] == 0 then
			KeyBindings[unifiedKey] = nil
		end
	end
end

--[[
	Internal: Binds all keys from a keyset.
]]
local function bindKeyset(keys: KeycodeSet, action: InputAction)
	if keys.KeyboardBinding then
		for _, key in keys.KeyboardBinding do
			local unifiedKey = toUnifiedKey(key)
			bindKey(unifiedKey, action)
		end
	end

	if keys.GamepadBinding then
		for _, key in keys.GamepadBinding do
			local unifiedKey = toUnifiedKey(key)
			bindKey(unifiedKey, action)
		end
	end
end

--[[
	Internal: Unbinds all keys from a keyset.
]]
local function unbindKeyset(keys: KeycodeSet, action: InputAction)
	if keys.KeyboardBinding then
		for _, key in keys.KeyboardBinding do
			local unifiedKey = toUnifiedKey(key)
			unbindKey(unifiedKey, action)
		end
	end

	if keys.GamepadBinding then
		for _, key in keys.GamepadBinding do
			local unifiedKey = toUnifiedKey(key)
			unbindKey(unifiedKey, action)
		end
	end
end

--[[
	Creates a new input action.
	
	@param name - Unique name for this action
	@param config - Action configuration
	@return InputAction
]]
function InputManager.CreateAction(name: string, config: ActionConfig): InputAction
	assert(name, "[InputManager] Action name is required")
	assert(config.Keys, "[InputManager] Keys configuration is required")

	if Actions[name] then
		warn("[InputManager] Action already exists:", name, "- returning existing")
		return Actions[name]
	end

	local callbacks: InputCallbacks = {
		OnPress = {},
		OnRelease = {},
		OnCancel = {},
		OnHoldTick = {},
	}

	local action: InputAction = {
		Name = name,
		Category = config.Category or "Default",
		Mode = config.Mode or "Press",
		Keys = config.Keys,
		Cooldown = config.Cooldown or 0,
		Priority = config.Priority or 1000,

		Enabled = true,
		IsPressed = false,
		PressStartTime = nil,
		LastPressTime = 0,
		DesiredState = nil,

		OnPress = function(self: InputAction, callback)
			return createSubscription(callbacks.OnPress, callback)
		end,

		OnRelease = function(self: InputAction, callback)
			return createSubscription(callbacks.OnRelease, callback)
		end,

		OnCancel = function(self: InputAction, callback)
			return createSubscription(callbacks.OnCancel, callback)
		end,

		OnHoldTick = function(self: InputAction, callback)
			return createSubscription(callbacks.OnHoldTick, callback)
		end,

		IsHeld = function(self: InputAction): boolean
			return self.IsPressed and self.Mode == "Holdable"
		end,

		GetHeldDuration = function(self: InputAction): number
			if self.PressStartTime then
				return tick() - self.PressStartTime
			end
			return 0
		end,

		SetEnabled = function(self: InputAction, enabled: boolean)
			self.Enabled = enabled

			if not enabled and self.IsPressed then
				-- Auto-cancel when disabled while pressed
				self:Cancel("Disabled")
			end
		end,

		SetKeys = function(self: InputAction, keys: KeycodeSet)
			unbindKeyset(self.Keys, self)
			self.Keys = keys
			bindKeyset(keys, self)
		end,

		Cancel = function(self: InputAction, source: string?)
			if not self.IsPressed then
				return
			end

			local heldDuration = self:GetHeldDuration()

			self.IsPressed = false
			self.PressStartTime = nil
			-- Keep DesiredState if key is still held (for auto-restart)
			if self.Mode == "Toggle" or self.Mode == "Holdable" then
				if InputManager.IsKeySetHeld(self.Keys) then
					-- Key still held, keep desired state for auto-restart
					self.DesiredState = true
				else
					self.DesiredState = false
				end
			else
				self.DesiredState = false
			end

			-- Fire cancel callbacks
			for _, callback in callbacks.OnCancel do
				task.spawn(callback, self, source or "Manual")
			end

			-- Also fire release for cleanup
			for _, callback in callbacks.OnRelease do
				task.spawn(callback, self, heldDuration)
			end
		end,

		Destroy = function(self: InputAction)
			-- Cancel if active
			if self.IsPressed then
				self:Cancel("Destroy")
			end

			-- Unbind keys
			unbindKeyset(self.Keys, self)

			-- Clear from storage
			Actions[self.Name] = nil

			if Categories[self.Category] then
				Categories[self.Category][self.Name] = nil
			end

			-- Clear callbacks
			table.clear(callbacks.OnPress)
			table.clear(callbacks.OnRelease)
			table.clear(callbacks.OnCancel)
			table.clear(callbacks.OnHoldTick)
		end,
	}

	-- Store internal callbacks reference
	(action :: any)._callbacks = callbacks

	-- Register
	Actions[name] = action

	if not Categories[config.Category or "Default"] then
		Categories[config.Category or "Default"] = {}
	end
	Categories[config.Category or "Default"][name] = action

	-- Bind keys
	bindKeyset(config.Keys, action)

	return action
end

--[[
	Gets an existing action by name.
]]
function InputManager.GetAction(name: string): InputAction?
	return Actions[name]
end

--[[
	Gets all actions in a category.
]]
function InputManager.GetCategory(category: string): { [string]: InputAction }
	return Categories[category] or {}
end

--[[
	Enables or disables all actions in a category.
]]
function InputManager.SetCategoryEnabled(category: string, enabled: boolean)
	local categoryActions = Categories[category]
	if not categoryActions then
		return
	end

	for _, action in categoryActions do
		action:SetEnabled(enabled)
	end
end

--[[
	Cancels all active actions in a category.
]]
function InputManager.CancelCategory(category: string, source: string?)
	local categoryActions = Categories[category]
	if not categoryActions then
		return
	end

	for _, action in categoryActions do
		if action.IsPressed then
			action:Cancel(source or "CategoryCancel")
		end
	end
end

--[[
	Destroys all actions in a category.
]]
function InputManager.DestroyCategory(category: string)
	local categoryActions = Categories[category]
	if not categoryActions then
		return
	end

	-- Collect action names first (avoid modifying while iterating)
	local actionNames = {}
	for name in categoryActions do
		table.insert(actionNames, name)
	end

	for _, name in actionNames do
		local action = categoryActions[name]
		if action then
			action:Destroy()
		end
	end

	Categories[category] = nil
end

--[[
	Gets debug info about all registered actions.
]]
function InputManager.GetDebugInfo(): { [string]: { Enabled: boolean, IsPressed: boolean, HeldDuration: number } }
	local info = {}

	for name, action in Actions do
		info[name] = {
			Enabled = action.Enabled,
			IsPressed = action.IsPressed,
			HeldDuration = action:GetHeldDuration(),
		}
	end

	return info
end

--[[
	Checks if any key in the keyset is currently physically held down.
]]
function InputManager.IsKeySetHeld(keys: KeycodeSet): boolean
	if keys.KeyboardBinding then
		for _, key in keys.KeyboardBinding do
			local unifiedKey = toUnifiedKey(key)
			if HeldKeys[unifiedKey] then
				return true
			end
		end
	end

	if keys.GamepadBinding then
		for _, key in keys.GamepadBinding do
			local unifiedKey = toUnifiedKey(key)
			if HeldKeys[unifiedKey] then
				return true
			end
		end
	end

	return false
end

--[[
	Checks if an action wants to be active (for auto-restart after cancellation).
]]
function InputManager.ShouldAutoRestart(action: InputAction): boolean
	if action.Mode ~= "Toggle" and action.Mode ~= "Holdable" then
		return false
	end

	if not action.DesiredState then
		return false
	end

	if action.IsPressed then
		return false
	end

	return InputManager.IsKeySetHeld(action.Keys)
end

--[[
	Simulates a press event for testing.
]]
function InputManager.SimulatePress(name: string)
	local action = Actions[name]
	if not action or not action.Enabled then
		return
	end

	action.IsPressed = true
	action.PressStartTime = tick()
	action.LastPressTime = tick()

	local callbacks = (action :: any)._callbacks :: InputCallbacks
	for _, callback in callbacks.OnPress do
		task.spawn(callback, action)
	end
end

--[[
	Simulates a release event for testing.
]]
function InputManager.SimulateRelease(name: string)
	local action = Actions[name]
	if not action or not action.IsPressed then
		return
	end

	local heldDuration = action:GetHeldDuration()

	action.IsPressed = false
	action.PressStartTime = nil

	local callbacks = (action :: any)._callbacks :: InputCallbacks
	for _, callback in callbacks.OnRelease do
		task.spawn(callback, action, heldDuration)
	end
end

return InputManager
