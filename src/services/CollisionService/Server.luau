local CollisionService = {}

local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local CHARACTER_GROUP = "Characters"
local STAND_GROUP = "Stands"

local function InitializeCollisionGroups()
	if not PhysicsService:IsCollisionGroupRegistered(CHARACTER_GROUP) then
		PhysicsService:RegisterCollisionGroup(CHARACTER_GROUP)
	end

	if not PhysicsService:IsCollisionGroupRegistered(STAND_GROUP) then
		PhysicsService:RegisterCollisionGroup(STAND_GROUP)
	end

	PhysicsService:CollisionGroupSetCollidable(CHARACTER_GROUP, STAND_GROUP, false)
	PhysicsService:CollisionGroupSetCollidable(STAND_GROUP, STAND_GROUP, false)
	PhysicsService:CollisionGroupSetCollidable(CHARACTER_GROUP, CHARACTER_GROUP, false)
end

local function AddToCharacterGroup(part: BasePart)
	local success, err = pcall(function()
		part.CollisionGroup = CHARACTER_GROUP
	end)
	if not success then
		warn("Failed to set part.CollisionGroup to '" .. CHARACTER_GROUP .. "': " .. tostring(err))
	end
end

local function AddToStandGroup(part: BasePart)
	local success, err = pcall(function()
		part.CollisionGroup = STAND_GROUP
	end)
	if not success then
		warn("Failed to set part.CollisionGroup to '" .. STAND_GROUP .. "': " .. tostring(err))
	end
end

local function AddModelToGroup(model: Model, groupName: string)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			if groupName == CHARACTER_GROUP then
				AddToCharacterGroup(part)
			elseif groupName == STAND_GROUP then
				AddToStandGroup(part)
			end
		end
	end
end

function CollisionService.SetupCharacter(character: Model)
	AddModelToGroup(character, CHARACTER_GROUP)
end

function CollisionService.SetupStand(stand: Model)
	AddModelToGroup(stand, STAND_GROUP)
end

local function ListenForCharacterParts(character: Model)
	local connection
	connection = character.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			AddToCharacterGroup(descendant)
		end
	end)

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Died:Connect(function()
			connection:Disconnect()
		end)
	end
end

local function ListenForStandParts(stand: Model)
	local connection
	connection = stand.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			AddToStandGroup(descendant)
		end
	end)

	stand.AncestryChanged:Connect(function(child, parent)
		if parent == nil then
			connection:Disconnect()
		end
	end)
end

function CollisionService.init()
	InitializeCollisionGroups()

	for _, character in ipairs(workspace.World.Live:GetChildren()) do
		if character:FindFirstChildOfClass("Humanoid") then
			CollisionService.SetupCharacter(character)
			ListenForCharacterParts(character)
		end
	end

	local Players = game:GetService("Players")
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			CollisionService.SetupCharacter(character)
			ListenForCharacterParts(character)
		end)
	end)

	local function SetupStandTag(instance)
		if instance:IsA("Model") then
			CollisionService.SetupStand(instance)
			ListenForStandParts(instance)
		end
	end

	CollectionService:GetInstanceAddedSignal("Stand"):Connect(SetupStandTag)

	for _, stand in ipairs(CollectionService:GetTagged("Stand")) do
		SetupStandTag(stand)
	end
end

export type CollisionService = typeof(CollisionService)

return CollisionService
