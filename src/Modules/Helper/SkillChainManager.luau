--!strict

local ChainManager = {}
ChainManager.__index = ChainManager

export type ChainManager = {
	_chain: any?,
	_isCancelled: boolean,
	GetChain: (self: ChainManager) -> any?,
	SetChain: (self: ChainManager, chain: any?) -> (),
	MarkCancelled: (self: ChainManager) -> (),
	ShouldCleanupChain: (self: ChainManager) -> boolean,
	Reset: (self: ChainManager) -> (),
	DestroyChain: (self: ChainManager) -> (),
}

function ChainManager.new(): ChainManager
	local self = setmetatable({}, ChainManager)
	self._chain = nil
	self._isCancelled = false
	return self :: any
end

function ChainManager:GetChain(): any?
	return self._chain
end

function ChainManager:SetChain(chain: any?)
	self._chain = chain
end

function ChainManager:MarkCancelled()
	self._isCancelled = true
end

function ChainManager:ShouldCleanupChain(): boolean
	return self._isCancelled
end

function ChainManager:Reset()
	self._isCancelled = false
end

function ChainManager:DestroyChain()
	if self._chain then
		self._chain:Destroy()
		self._chain = nil
	end
end

return ChainManager
