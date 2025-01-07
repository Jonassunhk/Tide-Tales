

local player = game.Players.LocalPlayer
local char = player.Character or workspace:WaitForChild(player.Name)
local hum = char:WaitForChild("Humanoid")
local root = hum.RootPart -- The HumanoidRootPart
local PlayerGui = player.PlayerGui
local BindableEvents = PlayerGui.BindableEvents
local RS = game.ReplicatedStorage
local Events = RS.Events
local tween = game:GetService("TweenService")

local EffectGui = PlayerGui.ScreenEffectGui
local prevhealth = hum.MaxHealth
local damagedframe = EffectGui.DamagedFrame
local lowhealthframe = EffectGui.BloodFrame
local heartbeat = EffectGui.heartbeat

damagedframe.Visible = true
lowhealthframe.Visible = false
lowhealthframe.Frame.Visible = false
damagedframe.BackgroundTransparency = 1
lowhealthframe.BackgroundTransparency = 1
lowhealthframe.Frame.BackgroundTransparency = 0


local colorcorrection = workspace.CurrentCamera:FindFirstChild("ColorCorrection")
if colorcorrection == nil then
	colorcorrection = Instance.new("ColorCorrectionEffect",workspace.CurrentCamera)
end

local lowhealthtween = TweenInfo.new(
	0.5, -- Time
	Enum.EasingStyle.Quad, -- EasingStyle
	Enum.EasingDirection.Out, -- EasingDirection
	-1, -- RepeatCount (when less than zero the tween will loop indefinitely)
	true, -- Reverses (tween will reverse once reaching it's goal)
	0 -- DelayTime
)

local damagedtween = TweenInfo.new(
	0.2, -- Time
	Enum.EasingStyle.Quad, -- EasingStyle
	Enum.EasingDirection.Out, -- EasingDirection
	0, -- RepeatCount (when less than zero the tween will loop indefinitely)
	true, -- Reverses (tween will reverse once reaching it's goal)
	0 -- DelayTime
)

local lowhealthtween = tween:Create(lowhealthframe,lowhealthtween,{BackgroundTransparency = 0})
local damagedtween = tween:Create(damagedframe,damagedtween,{BackgroundTransparency = 0})

lowhealthtween:Play()
local cooldown = false

heartbeat.Volume = 0


hum.HealthChanged:Connect(function(newhealth)
	
	local ratio = (hum.MaxHealth - newhealth) / hum.MaxHealth
	if newhealth < 35 then
		print("play low health")
		heartbeat.Playing = true
		heartbeat.Volume = ratio / 2
		lowhealthframe.Visible = true
	else
		heartbeat.Playing = false
		lowhealthframe.Visible = false
	end
	colorcorrection.Saturation = -ratio / 2

	
	if newhealth < prevhealth and cooldown == false then
		cooldown = true
		prevhealth = newhealth
		damagedtween:Play()
		wait(0.5)
		damagedframe.BackgroundTransparency = 1
		cooldown = false
	else
		prevhealth = newhealth
	end
end)



