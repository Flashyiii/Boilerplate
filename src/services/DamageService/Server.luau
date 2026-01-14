local ReplicatedStorage = game:GetService("ReplicatedStorage")

local wcs = require(ReplicatedStorage.Packages.wcs)
local DamageIndicator = require(ReplicatedStorage.Shared.Visuals.DamageIndicator)
local Stun = require(ReplicatedStorage.Shared.Wcs.Conditions.States.Stun)

local DamageServiceServer = {}
DamageServiceServer.__index = DamageServiceServer

function DamageServiceServer.init(self: DamageServiceServer) end

local DamageCache = {}

type AttackOptions = {
	BaseDamage: number,
	BlockDamage: number,
	Stun: number?,
	Knockback: (any) -> ()?,
	Callback: (string) -> (),
}

function DamageServiceServer.CalculateDamage(
	self: DamageServiceServer,
	attacker: Model,
	target: Model,
	data: AttackOptions?
): number
	return data.BaseDamage or 0
end

function DamageServiceServer.GetStatus(self: DamageServiceServer, attacker: Model, target: Model)
	local wcs_attacker = wcs.Character.GetCharacterFromInstance(attacker)
	local wcs_target = wcs.Character.GetCharacterFromInstance(target)

	local StatusEffects = wcs_target:GetAllStatusEffects()

	for _, effect in pairs(StatusEffects) do
		if effect.Name == "IFrame" then
			return "IFrame"
		end
		if effect.Name == "Ragdoll" then
			return "Ragdoll"
		end
		if effect.Name == "Block" then
			local Perfect = tick() - effect.PerfectTimeStamp
			if Perfect < 0.5 then
				return "Block"
			else
				return "PerfectBlock"
			end
		end
	end
	return "Hit"
end

function DamageServiceServer.CacheAttack(self: DamageServiceServer, attacker: Model, target: Model)
	if not DamageCache[attacker] then
		DamageCache[attacker] = {}
	end

	table.insert(DamageCache[attacker], {
		attacker = attacker,
		target = target,
		startTime = tick(),
	})
end

function DamageServiceServer.SubmitDamage(
	self: DamageServiceServer,
	attacker: Model,
	target: Model,
	options: AttackOptions,
	Callback: (string) -> ()?
)
	self:CacheAttack(attacker, target)

	if not DamageCache[attacker] then
		return
	end

	local AttackerHumanoid = attacker:FindFirstChild("Humanoid")
	AttackerHumanoid.Died:Once(function()
		DamageCache[attacker] = nil
	end)

	for i, attack in pairs(DamageCache[attacker]) do
		if attack.target == target and not target:GetAttribute("TimeStopped") then
			local damage = self:CalculateDamage(attacker, target, options)
			self:ApplyDamage(attacker, target, damage)
			self:ApplyHit(target, 0.25)

			if options.Stun and options.Stun > 0 then
				self:ApplyStun(target, options.Stun)
			end
			if Callback then
				Callback("Damage")
			end
			table.remove(DamageCache[attacker], i)
		end
		task.wait(0.1)
	end
end

function DamageServiceServer.ApplyDamage(self: DamageServiceServer, attacker: Model, target: Model, damage: number)
	local Indicator = DamageIndicator.new(target, {
		Value = damage,
	})
	Indicator:Start()
end

function DamageServiceServer.ApplyStun(self: DamageServiceServer, target: Model, duration: number)
	local wcs_target = wcs.Character.GetCharacterFromInstance(target)
	local StunEffect = Stun.new(wcs_target)
	StunEffect:Start(duration)
end

function DamageServiceServer.ApplyHit(self: DamageServiceServer, target: Model, duration: number)
	local wcs_target = wcs.Character.GetCharacterFromInstance(target)
	local HitEffect = require(ReplicatedStorage.Shared.Wcs.Conditions.States.Hit).new(wcs_target)
	HitEffect:Start(duration)
end

function DamageServiceServer.Attack(self: DamageServiceServer, attacker: Model, target: Model, options: AttackOptions)
	local status = self:GetStatus(attacker, target)
	if status == "Hit" then
		if options.Callback then
			options.Callback(status)
		end
		self:SubmitDamage(attacker, target, options, options.Callback)
	end
end

export type DamageServiceServer = typeof(DamageServiceServer) & {}
return DamageServiceServer
