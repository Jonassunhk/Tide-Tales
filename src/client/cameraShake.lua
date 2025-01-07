
local player = game.Players.LocalPlayer
local char = player.Character or workspace:WaitForChild(player.Name,30)
local hum = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart") -- The HumanoidRootPart
local PlayerGui = player.PlayerGui
local BindableEvents = PlayerGui.BindableEvents
local RS = game.ReplicatedStorage
local Events = RS.Events

local ServerEvent = Events.CameraShakeEvent
local ClientEvent = BindableEvents.CameraShakeEvent
local CameraShaker = player.PlayerScripts:WaitForChild("CameraShaker")

local function camerashake()
	local CameraShaker = require(CameraShaker)
	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Scriptable
	local camShake = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCf)
		camera.CFrame = camera.CFrame * shakeCf
	end)

	camShake:Start()

	-- Explosion shake:
	camShake:Shake(CameraShaker.Presets.Explosion)
	wait(1)
	camera.CameraType = Enum.CameraType.Custom
end

ServerEvent.OnClientEvent:Connect(camerashake)
ClientEvent.Event:Connect(camerashake)

