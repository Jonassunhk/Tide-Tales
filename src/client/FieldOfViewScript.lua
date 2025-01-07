
local player = game.Players.LocalPlayer
local char = player.Character or workspace:WaitForChild(player.Name,30)
local hum = char:WaitForChild("Humanoid")
local root = hum.RootPart -- The HumanoidRootPart
local PlayerGui = player.PlayerGui
local BindableEvents = PlayerGui.BindableEvents
local camera = workspace.CurrentCamera

local FieldOfView = BindableEvents.FieldOfView
local tween = game:GetService("TweenService")
local userInputService = game:GetService("UserInputService")
local UserGameSettings = UserSettings():GetService("UserGameSettings")

local tweenInfo = TweenInfo.new(
	0.4, -- Time
	Enum.EasingStyle.Quad, -- EasingStyle
	Enum.EasingDirection.Out, -- EasingDirection
	0, -- RepeatCount (when less than zero the tween will loop indefinitely)
	false, -- Reverses (tween will reverse once reaching it's goal)
	0 -- DelayTime
)

FieldOfView.Event:Connect(function(active,amount)
	if active == true then
		local newtween = tween:Create(camera,tweenInfo,{FieldOfView = amount})
		userInputService.MouseDeltaSensitivity = 0.1
		newtween:Play()
	else 
		local newtween = tween:Create(camera,tweenInfo,{FieldOfView = 65})
		userInputService.MouseDeltaSensitivity = 1
		newtween:Play()
	end
end)






