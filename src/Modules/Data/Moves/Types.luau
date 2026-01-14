--!strict
--[[
	MoveData Types
	
	Type definitions for move/skill data in the MoveRegistry system.
	Supports both simple skills and phase-aware cancellation.
]]

export type KeycodeSet = {
	KeyboardBinding: { Enum.KeyCode }?,
	GamepadBinding: { Enum.KeyCode }?,
	TouchBinding: { GuiButton }?,
}

export type InputMode = "Press" | "Holdable" | "Toggle"

export type PhaseAnimations = {
	Startup: string?,
	Loop: string?,
	Main: string?,
	End: string?,
	[string]: string?, -- Custom phase names
}

export type HitboxConfig = {
	Size: Vector3?,
	Offset: CFrame?,
	Part: BasePart?,
	Duration: number?,
}

export type SoundConfig = {
	Startup: string?,
	Loop: string?,
	Hit: string?,
	End: string?,
	[string]: string?,
}

--[[
	Base move data that all moves share.
]]
export type BaseMoveData = {
	-- Reference to the WCS skill class
	Skill: any,

	-- Input binding
	Input: KeycodeSet?,
	InputMode: InputMode?,

	-- Cooldown (for non-phase skills, or as default)
	Cooldown: number?,

	-- Priority for input conflicts
	Priority: number?,

	-- UI display
	Shown: boolean?,
	DisplayName: string?,
	Description: string?,
	Icon: string?,

	-- Simple cancellation flag (for non-phase skills)
	CanCancel: boolean?,
}

--[[
	Extended move data for phase-aware skills.
]]
export type PhaseAwareMoveData = BaseMoveData & {
	-- Phase durations
	StartupDuration: number?,
	MainDuration: number?,
	EndDuration: number?,
	MaxDuration: number?, -- For holdable skills

	-- Phase animations
	Animations: PhaseAnimations?,

	-- Combat intervals
	HitInterval: number?,

	-- Combat data
	BaseDamage: number?,

	-- Hitbox
	Hitbox: HitboxConfig?,

	-- Sounds
	Sounds: SoundConfig?,
}

--[[
	M1 (Basic Attack) move data.
]]
export type M1MoveData = BaseMoveData & {
	ComboTick: number?,
	Swings: number?,
	EndCooldown: number?,
	EndLag: number?,

	-- Per-swing data (M1, M2, M3, etc. or M1234 for batch)
	[string]: {
		CFrameOffset: CFrame?,
		Part: Vector3?,
		SwingSound: string?,
		HitSound: string?,
	}?,

	-- Stand-specific overrides
	Stand: {
		Swings: number?,
		EndCooldown: number?,
		[string]: any?,
	}?,
}

--[[
	Summon skill data.
]]
export type SummonMoveData = BaseMoveData & {
	AuraColor: ColorSequence?,
	Unsummon: ColorSequence?,
}

--[[
	Dash skill data.
]]
export type DashMoveData = BaseMoveData & {
	Duration: number?,
	Speed: number?,
	EndLagDuration: number?,
}

--[[
	Complete moveset registry type.
]]
export type MovesetRegistry = {
	M1: M1MoveData?,
	Dash: DashMoveData?,
	Summon: SummonMoveData?,
	Barrage: PhaseAwareMoveData?,
	[string]: BaseMoveData?,
}

return nil
