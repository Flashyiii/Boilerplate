--!strict

export type CharacterOptions = {
	position: (CFrame | boolean)?,
	lockCamera: boolean?,
	animation: string?,
	moveset: string?,
}

export type CharacterEntry = {
	character: Model,
	options: CharacterOptions,
	isPlayer: boolean,
	track: AnimationTrack?,
}

export type MarkerCallback = {
	character: Model,
	markerName: string,
	callback: () -> (),
}

export type CutsceneHandle = {
	SetOrigin: (self: CutsceneHandle, origin: CFrame) -> CutsceneHandle,
	SetCameraAnimation: (self: CutsceneHandle, animationName: string, moveset: string?) -> CutsceneHandle,
	AddCharacter: (self: CutsceneHandle, character: Model, options: CharacterOptions?) -> CutsceneHandle,
	OnMarker: (self: CutsceneHandle, character: Model, markerName: string, callback: () -> ()) -> CutsceneHandle,
	OnEnd: (self: CutsceneHandle, callback: () -> ()) -> CutsceneHandle,
	Play: (self: CutsceneHandle) -> CutsceneHandle,
	AwaitEnd: (self: CutsceneHandle) -> (),
	Stop: (self: CutsceneHandle) -> (),
	Destroy: (self: CutsceneHandle) -> (),
}

return nil
