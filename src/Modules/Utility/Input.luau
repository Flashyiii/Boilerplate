type KeycodeSet = {
	KeyboardBinding: { Enum.KeyCode }?,
	GamepadBinding: { Enum.KeyCode }?,
	TouchBinding: { GuiButton }?,
}

export type InputInstance = {
	ChangeKeys: (self: InputInstance, NewKeys: KeycodeSet) -> (),
	Connect: (self: InputInstance, Func: (any) -> ()) -> RBXScriptConnection,
	SetState: (self: InputInstance, State: boolean) -> (),
	SetContextState: (self: InputInstance, State: boolean) -> (),

	Keys: KeycodeSet,
	Callbacks: { (any) -> () },
	Context: InputContext,
	Action: InputAction,
	Cooldown: number,
	LastPressTime: number,
	Enabled: boolean,
	PressConnection: RBXScriptConnection?,
}

local ActionTemplate = Instance.new("InputAction")
ActionTemplate.Parent = script

local ContextTemplate = Instance.new("InputContext")
ContextTemplate.Parent = script
ContextTemplate.Sink = false
ContextTemplate.Priority = 1000
ContextTemplate.Enabled = true

local _Input = {}
_Input.__index = _Input
_Input.Categorys = {}

local function CreateBinding(Name: string)
	local Binding = Instance.new("InputBinding")
	Binding.Name = Name
	return Binding
end

local function ApplyBindings(Action: InputAction, Keys: KeycodeSet)
	local Existing = {
		KeyboardBinding = {},
		GamepadBinding = {},
		TouchBinding = {},
	}

	for _, Child in Action:GetChildren() do
		if Child:IsA("InputBinding") and Existing[Child.Name] then
			table.insert(Existing[Child.Name], Child)
		end
	end

	for _, Key in { "KeyboardBinding", "GamepadBinding" } do
		local Values = Keys[Key]
		local Bindings = Existing[Key]

		if Values then
			for i, Value in Values do
				local Binding = Bindings[i]
				if Binding then
					Binding.KeyCode = Value
				else
					local NewBinding = CreateBinding(Key)
					NewBinding.KeyCode = Value
					NewBinding.Parent = Action
				end
			end
		end

		for i = (Values and #Values + 1 or 1), #Bindings do
			Bindings[i]:Destroy()
		end
	end

	local Touch = Keys.TouchBinding
	local TouchBindings = Existing.TouchBinding

	if Touch then
		for i, Button in Touch do
			local Binding = TouchBindings[i]
			if Binding then
				Binding.UIButton = Button
			else
				local NewBinding = CreateBinding("TouchBinding")
				NewBinding.UIButton = Button
				NewBinding.Parent = Action
			end
		end
	end

	for i = (Touch and #Touch + 1 or 1), #TouchBindings do
		TouchBindings[i]:Destroy()
	end
end

local function SetupContext(Category: string)
	if _Input.Categorys[Category] then
		return _Input.Categorys[Category].Context
	end

	local Context = ContextTemplate:Clone()
	Context.Name = Category
	Context.Parent = script

	_Input.Categorys[Category] = {
		Context = Context,
		Actions = {},
	}

	return Context
end

local function ConnectTrigger(Binding: InputInstance)
	if Binding.PressConnection then
		Binding.PressConnection:Disconnect()
	end

	Binding.PressConnection = Binding.Action.Pressed:Connect(function()
		if not Binding.Enabled then
			return
		end

		local Time = tick()
		if Time - Binding.LastPressTime < Binding.Cooldown then
			return
		end
		Binding.LastPressTime = Time

		for _, Callback in Binding.Callbacks do
			Callback()
		end
	end)
end

function _Input.New(Category: string, Name: string, Keys: KeycodeSet, Cooldown: number?): InputInstance
	local Context = SetupContext(Category)
	local Action = ActionTemplate:Clone()
	Action.Name = Name
	Action.Parent = Context

	ApplyBindings(Action, Keys)

	local Binding = setmetatable({
		Context = Context,
		Action = Action,
		Callbacks = {},
		Keys = Keys,
		Cooldown = Cooldown or 0,
		LastPressTime = 0,
		Enabled = Action.Enabled,
		PressConnection = nil,
	}, _Input) :: InputInstance

	_Input.Categorys[Category].Actions[Name] = Binding

	ConnectTrigger(Binding)

	return Binding
end

function _Input:ChangeKeys(NewKeys: KeycodeSet)
	self.Keys = NewKeys
	ApplyBindings(self.Action, NewKeys)
	ConnectTrigger(self)
end

function _Input:Connect(Func: (any) -> ())
	table.insert(self.Callbacks, Func)
	local Binding = self
	local Connected = true

	local Connection = {}

	function Connection:Disconnect()
		if not Connected then
			return
		end

		Connected = false
		for i, Callback in Binding.Callbacks do
			if Callback == Func then
				table.remove(Binding.Callbacks, i)
				break
			end
		end
	end

	return Connection
end

function _Input:SetContextState(State: boolean)
	self.Context.Enabled = State
end

function _Input:SetState(State: boolean)
	self.Enabled = State
end

return _Input
