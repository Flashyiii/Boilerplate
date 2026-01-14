local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local wcs = require(ReplicatedStorage.Packages.wcs)
local MoveRegistry = require(ReplicatedStorage.Shared.Modules.Data.Moves.MoveRegistry)
local AnimationPlayer = require(ReplicatedStorage.Shared.Modules.Game.AnimationPlayer)
local TurnInvis = require(ReplicatedStorage.Shared.Modules.Helper.TurnInvis)
local InputManager = require(ReplicatedStorage.Shared.Modules.Utility.InputManager)
local EndLag = require(ReplicatedStorage.Shared.Wcs.Conditions.States.EndLag)
local Ragdoll = require(ReplicatedStorage.Shared.Wcs.Conditions.States.Ragdoll)
local Stun = require(ReplicatedStorage.Shared.Wcs.Conditions.States.Stun)

local RoadRoller = wcs.RegisterSkill("RoadRoller")

function RoadRoller:OnConstruct()
	self.MutualExclusives = {
		Stun,
		EndLag,
		Ragdoll,
	}

	self._mouseAction = nil
	self._mouseDisconnect = nil
end

function RoadRoller:CanCancel(): boolean
	return false
end

function RoadRoller:OnStartServer()
	local character = self.Character.Instance
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	local moveset = character:GetAttribute("Moveset")
	local Data = MoveRegistry.get(moveset).RoadRoller
	if not Data then
		return
	end
	self.Aiming = false
	self.Data = Data
	self.Moveset = moveset

	self:StartUp()
end

function RoadRoller:StartUp()
	local Animator = AnimationPlayer.new(self.Character.Instance)
	local handle = Animator:Play("RoadRollerAim", self.Moveset)
	handle:OnMarker("Aim", function()
		--self:Aim()
		--TurnInvis(self.Character.Instance, true, true, 0.3)
	end)
	handle:Play()
	handle:AwaitEnd()

	local function temp()
		self:Aim()
		TurnInvis(self.Character.Instance, true, true, 0.3)
	end
	temp()
end

function RoadRoller:Aim()
	self:StartAim()
	local startTick = tick()
	self.Aiming = true
	repeat
		task.wait(0.5)
	until tick() - startTick > self.Data.MaxDuration
	if self.Aiming == true then
		self:End()
		print("Aiming timed out")
	end
end

local CutscenePlayer = require(ReplicatedStorage.Shared.Modules.Game.CutscenePlayer.CutscenePlayer)

function RoadRoller:Roller()
	print("Starting Roller")

	local waiting = true
	local Stuneffect = Stun.new(self.Character)
	Stuneffect:Start(100)
	self.Cutscene = CutscenePlayer.new("RoadRoller")
		:SetOrigin(self.Character.Instance.HumanoidRootPart.CFrame)
		:SetCameraAnimation("CutSceenTestingCamera")
		:AddCharacter(self.Character.Instance, { position = true, animation = "RoadRollerAim", lockCamera = true })
		:OnEnd(function()
			waiting = false
			print(Stuneffect)
		end)
		:Play()

	repeat
		task.wait(0.5)
	until not waiting
	Stuneffect:End()
	self:End()
end

function RoadRoller:ConfirmRoller()
	print("Confirming Roller")
	self.Aiming = false
	self:Roller()
end

function RoadRoller:StartAim()
	local player = Players.LocalPlayer
	local character = self.Character.Instance

	if not character or character ~= player.Character then
		return
	end
	self.Timedout = false
	print("Starting Aim")

	self._mouseAction = InputManager.CreateAction("RoadRollerConfirm", {
		Category = "RoadRoller",
		Keys = {
			KeyboardBinding = { Enum.KeyCode.MouseLeftButton },
		},
		Mode = "Press",
		Cooldown = 0,
		Priority = 2000,
	})

	self._mouseDisconnect = self._mouseAction:OnPress(function()
		print("Confirming Roller")
		self:ConfirmRoller()
		if self._mouseAction then
			self._mouseAction:Destroy()
			self._mouseAction = nil
		end
		if self._mouseDisconnect then
			self._mouseDisconnect()
			self._mouseDisconnect = nil
		end
	end)
end

wcs.DefineMessage(RoadRoller.ConfirmRoller, {
	Type = "Event",
	Destination = "Server",
	Unreliable = false,
})
wcs.DefineMessage(RoadRoller.StartAim, {
	Type = "Event",
	Destination = "Client",
	Unreliable = false,
})

function RoadRoller:OnEndClient()
	print("Ending Aim")
	if self._mouseDisconnect then
		self._mouseDisconnect()
		self._mouseDisconnect = nil
	end

	if self._mouseAction then
		self._mouseAction:Destroy()
		self._mouseAction = nil
	end
end

function RoadRoller:OnEndServer()
	print("Ending RoadRoller")
	local Cooldown = self.Data.Cooldown or 5
	TurnInvis(self.Character.Instance, false, false, 0.3)
	self:ApplyCooldown(Cooldown)
end

return RoadRoller
