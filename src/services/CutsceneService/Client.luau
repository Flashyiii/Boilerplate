--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CutsceneServiceClient = {}

local currentCutscene: {
	id: string,
	name: string,
	cameraPart: BasePart?,
	connection: RBXScriptConnection?,
}? =
	nil

local originalCameraSubject: Instance? = nil

local function getCameraPositionPart(): BasePart?
	local character = Players.LocalPlayer.Character
	if not character then
		return nil
	end

	local head = character:FindFirstChild("Head")
	if not head then
		return nil
	end

	return head:FindFirstChild("CameraPosition") :: BasePart?
end

local function lockCameraToPart(cameraPart: BasePart): RBXScriptConnection?
	local camera = workspace.CurrentCamera
	if not camera or not cameraPart then
		return nil
	end

	originalCameraSubject = camera.CameraSubject
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = cameraPart.CFrame

	local connection = RunService.RenderStepped:Connect(function()
		if cameraPart and cameraPart.Parent then
			camera.CFrame = cameraPart.CFrame
		end
	end)

	return connection
end

local function unlockCamera()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	camera.CameraType = Enum.CameraType.Custom

	local cameraPosition = getCameraPositionPart()
	if cameraPosition then
		camera.CameraSubject = cameraPosition
	elseif originalCameraSubject then
		camera.CameraSubject = originalCameraSubject
	end

	originalCameraSubject = nil
end

local function handleCutsceneStart(data: { cutsceneId: string, cutsceneName: string })
	if currentCutscene then
		CutsceneServiceClient.EndCutscene()
	end

	local character = Players.LocalPlayer.Character
	if character then
		character:SetAttribute("InCutscene", true)
	end

	local cameraRigName = "CutsceneCamera_" .. data.cutsceneId
	local cameraRig = workspace:WaitForChild(cameraRigName, 5) :: Model?
	local cameraPart = if cameraRig then cameraRig:WaitForChild("Camera", 2) :: BasePart? else nil

	local connection: RBXScriptConnection? = nil
	if cameraPart then
		connection = lockCameraToPart(cameraPart)
	end

	currentCutscene = {
		id = data.cutsceneId,
		name = data.cutsceneName,
		cameraPart = cameraPart,
		connection = connection,
	}
end

local function handleCutsceneEnd(data: { cutsceneId: string, cutsceneName: string })
	if not currentCutscene or currentCutscene.id ~= data.cutsceneId then
		return
	end

	CutsceneServiceClient.EndCutscene()
end

function CutsceneServiceClient.EndCutscene()
	if not currentCutscene then
		return
	end

	if currentCutscene.connection then
		currentCutscene.connection:Disconnect()
	end

	unlockCamera()

	local character = Players.LocalPlayer.Character
	if character then
		character:SetAttribute("InCutscene", nil)
	end

	currentCutscene = nil
end

function CutsceneServiceClient.IsInCutscene(): boolean
	return currentCutscene ~= nil
end

function CutsceneServiceClient.GetCurrentCutscene(): string?
	return if currentCutscene then currentCutscene.name else nil
end

local remoteConnected = false

local function connectRemote(remote: RemoteEvent)
	if remoteConnected then
		return
	end
	remoteConnected = true

	remote.OnClientEvent:Connect(function(action: string, data: any)
		if action == "Start" then
			handleCutsceneStart(data)
		elseif action == "End" then
			handleCutsceneEnd(data)
		end
	end)
end

function CutsceneServiceClient.init(self: typeof(CutsceneServiceClient))
	local remote = ReplicatedStorage:FindFirstChild("CutsceneRemote") :: RemoteEvent?
	if remote then
		connectRemote(remote)
	end

	ReplicatedStorage.ChildAdded:Connect(function(child)
		if child.Name == "CutsceneRemote" and child:IsA("RemoteEvent") then
			connectRemote(child)
		end
	end)
end

export type CutsceneServiceClient = typeof(CutsceneServiceClient)

return CutsceneServiceClient
