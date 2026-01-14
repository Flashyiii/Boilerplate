--!strict

export type MarkerData = {
	Name: string,
	Time: number,
	Value: string?,
}

export type KeyframeData = {
	Time: number,
	Markers: { MarkerData },
}

export type AnimationInfo = {
	Id: string,
	Length: number,
	Keyframes: { KeyframeData },
	Markers: { [string]: number },
	FrameRate: number,
	TotalFrames: number,
}

export type ChainMode = "AutoContinue" | "ContinueOnRequest" | "PauseOnLastFrame"

export type MarkerCallback = (time: number, value: string?) -> ()
export type ChainMarkerCallback = (animName: string, index: number, time: number, value: string?) -> ()
export type FrameCallback = (frame: number) -> ()
export type EndCallback = () -> ()
export type IndexCallback = (index: number, animName: string) -> ()
export type AnimationEndCallback = (animName: string, index: number) -> ()

export type AnimationHandle = {
	Play: (self: AnimationHandle) -> AnimationHandle,
	Stop: (self: AnimationHandle, fadeTime: number?) -> AnimationHandle,
	Pause: (self: AnimationHandle) -> AnimationHandle,
	Resume: (self: AnimationHandle) -> AnimationHandle,
	Continue: (self: AnimationHandle) -> AnimationHandle,
	SetSpeed: (self: AnimationHandle, speed: number) -> AnimationHandle,
	SetPriority: (self: AnimationHandle, priority: Enum.AnimationPriority) -> AnimationHandle,
	SetFadeTime: (self: AnimationHandle, fadeTime: number) -> AnimationHandle,
	PauseOnLastFrame: (self: AnimationHandle, enabled: boolean?) -> AnimationHandle,
	SetAutoStopDelay: (self: AnimationHandle, delay: number?) -> AnimationHandle,
	OnAutoStopDelay: (self: AnimationHandle, callback: EndCallback) -> AnimationHandle,
	SetRange: (self: AnimationHandle, startTime: number?, endTime: number?) -> AnimationHandle,
	FromMarker: (self: AnimationHandle, markerName: string) -> AnimationHandle,
	ToMarker: (self: AnimationHandle, markerName: string) -> AnimationHandle,
	OnMarker: (self: AnimationHandle, markerName: string, callback: MarkerCallback) -> AnimationHandle,
	OnFrame: (self: AnimationHandle, frame: number, callback: FrameCallback) -> AnimationHandle,
	OnFrameRange: (
		self: AnimationHandle,
		startFrame: number,
		endFrame: number,
		callback: FrameCallback
	) -> AnimationHandle,
	OnEnd: (self: AnimationHandle, callback: EndCallback) -> AnimationHandle,
	OnNearEnd: (self: AnimationHandle, callback: EndCallback) -> AnimationHandle,
	IsPlaying: (self: AnimationHandle) -> boolean,
	IsWaiting: (self: AnimationHandle) -> boolean,
	GetAnimationName: (self: AnimationHandle) -> string,
	GetTimePosition: (self: AnimationHandle) -> number,
	AwaitEnd: (self: AnimationHandle) -> (),
	Destroy: (self: AnimationHandle) -> (),
}

export type ChainHandle = {
	Play: (self: ChainHandle) -> ChainHandle,
	Continue: (self: ChainHandle) -> ChainHandle,
	Skip: (self: ChainHandle) -> ChainHandle,
	Stop: (self: ChainHandle, fadeTime: number?) -> ChainHandle,
	Pause: (self: ChainHandle) -> ChainHandle,
	Resume: (self: ChainHandle) -> ChainHandle,
	SetSpeed: (self: ChainHandle, speed: number) -> ChainHandle,
	SetPriority: (self: ChainHandle, priority: Enum.AnimationPriority) -> ChainHandle,
	SetIndexPriority: (self: ChainHandle, index: number, priority: Enum.AnimationPriority) -> ChainHandle,
	SetFadeTime: (self: ChainHandle, fadeTime: number) -> ChainHandle,
	SetIndex: (self: ChainHandle, index: number) -> ChainHandle,
	SetAutoStopDelay: (self: ChainHandle, delay: number?) -> ChainHandle,
	ContinueOnRequest: (self: ChainHandle, enabled: boolean?) -> ChainHandle,
	AutoContinue: (self: ChainHandle, enabled: boolean?) -> ChainHandle,
	PauseOnLastFrame: (self: ChainHandle, enabled: boolean?) -> ChainHandle,
	OnMarker: (self: ChainHandle, markerName: string, callback: ChainMarkerCallback) -> ChainHandle,
	OnIndex: (self: ChainHandle, index: number, callback: IndexCallback) -> ChainHandle,
	OnAnimationEnd: (self: ChainHandle, callback: AnimationEndCallback) -> ChainHandle,
	OnChainEnd: (self: ChainHandle, callback: EndCallback) -> ChainHandle,
	OnAutoStopDelay: (self: ChainHandle, callback: EndCallback) -> ChainHandle,
	IsPlaying: (self: ChainHandle) -> boolean,
	IsWaiting: (self: ChainHandle) -> boolean,
	GetCurrentIndex: (self: ChainHandle) -> number,
	GetCurrentAnimation: (self: ChainHandle) -> string?,
	IsLastAnimation: (self: ChainHandle) -> boolean,
	AwaitEnd: (self: ChainHandle) -> (),
	AwaitAnimation: (self: ChainHandle) -> (),
	Destroy: (self: ChainHandle) -> (),
}

export type AnimationPlayer = {
	Play: (self: AnimationPlayer, animName: string, moveset: string?) -> AnimationHandle,
	Chain: (self: AnimationPlayer, animations: { string }, moveset: string?) -> ChainHandle,
	Pause: (self: AnimationPlayer) -> AnimationPlayer,
	Resume: (self: AnimationPlayer) -> AnimationPlayer,
	Stop: (self: AnimationPlayer, fadeTime: number?) -> AnimationPlayer,
	StopAll: (self: AnimationPlayer, fadeTime: number?) -> AnimationPlayer,
	StopLast: (self: AnimationPlayer, animNames: { string }, fadeTime: number?) -> AnimationPlayer,
	IsPlaying: (self: AnimationPlayer, animName: string?) -> boolean,
	GetActiveHandle: (self: AnimationPlayer) -> AnimationHandle?,
	GetActiveChain: (self: AnimationPlayer) -> ChainHandle?,
	GetTrack: (self: AnimationPlayer, animName: string, moveset: string?) -> AnimationTrack?,
	GetAnimationInfo: (self: AnimationPlayer, animName: string, moveset: string?) -> AnimationInfo?,
	GetLength: (self: AnimationPlayer, animName: string, moveset: string?) -> number,
	GetMarkerTime: (self: AnimationPlayer, animName: string, markerName: string, moveset: string?) -> number?,
	Preload: (self: AnimationPlayer, animations: { string }, moveset: string?) -> AnimationPlayer,
	Destroy: (self: AnimationPlayer) -> (),
}

return nil
