local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local charm = require(ReplicatedStorage.Packages.charm)
local hitbox = require(ReplicatedStorage.Packages.hitbox)
local maid = require(ReplicatedStorage.Packages.maid)
local wcs = require(ReplicatedStorage.Packages.wcs)
local MoveRegistry = require(ReplicatedStorage.Shared.Modules.Data.Moves.MoveRegistry)
local M1 = wcs.RegisterSkill("M1")
local ClientUtil = require(ReplicatedStorage.Shared.Modules.Game.ClientUtil)
local KnockbackHandler = require(ReplicatedStorage.Shared.Modules.Utility.KnockbackHandler)
local Highlight = require(ReplicatedStorage.Shared.Visuals.Highlight)
local Ragdoll = require(ReplicatedStorage.Shared.Wcs.Conditions.States.Ragdoll)

local function getHitData(Data, Combo)
	local searchString = tostring(Combo)

	for key, data in pairs(Data) do
		if string.find(key, searchString) then
			return data, key
		end
	end

	warn("No data found for number: " .. searchString)
	return nil
end

function M1:OnConstruct()
	self.Combo = 1
	self.LastAttackTime = 0
	self._maid = maid.new()
end

function M1:OnStartServer()
	local character = self.Character.Instance
	self.char = character
	self.Data = MoveRegistry.get(character:GetAttribute("Moveset")).M1

	if tick() - self.LastAttackTime > self.Data.ComboTick then
		self.Combo = 1
	end
	self.LastAttackTime = tick()

	if CollectionService:HasTag(character, "Summoned") then
		self:Stand()
	else
		self:Hand()
	end

	self.Combo = self.Combo + 1
	print(self.Data)
	if self.Combo >= self.Data.Swings + 1 then
		self.Combo = 1
		self:ApplyCooldown(self.Data.EndCooldown)
	end
end

function M1:Hand()
	local Moveset = self.char:GetAttribute("Moveset")

	local HitData = getHitData(self.Data, self.Combo)
	local Combo = self.Combo

	local Time = ClientUtil.GetSequenceLength("M1-" .. Combo, Moveset)
	local Hit = ClientUtil.GetSequenceLength("M1-" .. Combo, Moveset, "Hit")

	ClientUtil.PlayAnimation("M1-" .. Combo, self.char, Moveset)
	self:Hit(HitData, Combo, Time, Hit)
end

function M1:Hit(HitData, Combo, Time, Hit)
	local Moveset = self.char:GetAttribute("Moveset")
	ClientUtil.PlaySound(HitData.SwingSound, self.Character.Instance)

	local params = {
		SizeOrPart = HitData.Part,
		InitialPosition = self.char.HumanoidRootPart.CFrame * HitData.CFrameOffset,
		SpatialOption = "InBox",
		DebounceTime = 1,
		Debris = Time - Hit,
		Debug = _G.Debug,
		Blacklist = { self.char },
	}

	local box, connected = hitbox.new(params)
	local hit = false
	box.HitSomeone:Connect(function(hitChars)
		for _, char in pairs(hitChars) do
			if char:IsDescendantOf(self.char) then
				continue
			end
			hit = true
			if Combo ~= self.Data.Swings then
				ClientUtil.PlayAnimation("H1-" .. Combo, char, Moveset)
			else
				local CharacterClass = wcs.Character
				print(char, CharacterClass.GetCharacterFromInstance(char))
				local RagdollEffect = Ragdoll.new(CharacterClass.GetCharacterFromInstance(char))
				RagdollEffect:Start(1.5)

				KnockbackHandler.Knockback(self.char, char, {
					Speed = 25,
					Time = 0.25,
					Relative = "Attacker",
				})
			end
		end
		if hit == true then
			ClientUtil.PlaySound(HitData.HitSound, self.Character.Instance)
		end
	end)

	task.wait(Hit)
	box:Start()
	task.wait((Time - Hit) % 90)
end

function M1:Stand()
	self.Data = self.Data.Stand
	local Moveset = self.char:GetAttribute("Moveset")
	self.StandObj = self.char:WaitForChild(Moveset)
	if not self.StandObj then
		warn("Stand not Found")
		return
	end

	local HitData = getHitData(self.Data, self.Combo)
	local Combo = self.Combo

	local Time = ClientUtil.GetSequenceLength("S1-" .. Combo, Moveset)
	local Hit = ClientUtil.GetSequenceLength("S1-" .. Combo, Moveset, "Hit")

	ClientUtil.PlayAnimation("S1-" .. self.Combo, self.StandObj, Moveset)

	self:Hit(HitData, Combo, Time, Hit)
end

return M1
