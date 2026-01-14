local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientUtil = require(ReplicatedStorage.Shared.Modules.Game.ClientUtil)
local VFX = {}

function VFX.EmitAttachment(attachment: Attachment, CFrame: CFrame)
	local holder = attachment:Clone()

	holder.Parent = workspace.World.Effects
	holder.Name = "VFX_" .. attachment.Name .. ClientUtil.RNG(1, 1000000)
	holder.CFrame = CFrame

	for _, child in holder:GetDescendants() do
		if child:IsA("ParticleEmitter") then
			local count = child:GetAttribute("EmitCount") or 0
			local EmitDelay = child:GetAttribute("EmitDelay") or 0
			task.delay(EmitDelay, function()
				child:Emit(count)
			end)
		end
	end

	task.delay(5, function()
		if holder and holder.Parent then
			if _G.Debug then
				print("Memory Leak: VFX Attachment not destroyed", holder)
			end
			holder:Destroy()
		end
	end)

	return holder
end

return VFX
