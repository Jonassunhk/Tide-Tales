

local player = game.Players.LocalPlayer
local char = player.Character or workspace:WaitForChild(player.Name,30)
local hum = char:WaitForChild("Humanoid")
local root = hum.RootPart -- The HumanoidRootPart
local PlayerGui = player.PlayerGui
local BindableEvents = PlayerGui.BindableEvents
local RS = game.ReplicatedStorage
local Events = RS.Events
local debris = game:GetService("Debris")
local tween = game:GetService("TweenService")
local camera = workspace.CurrentCamera

local gui = PlayerGui.DamageGui
gui.Enabled = true
gui.DamageLabel.Visible = false

local tweenInfo = TweenInfo.new(
	0.7, -- Time
	Enum.EasingStyle.Back, -- EasingStyle
	Enum.EasingDirection.In, -- EasingDirection
	0, -- RepeatCount (when less than zero the tween will loop indefinitely)
	false, -- Reverses (tween will reverse once reaching it's goal)
	0 -- DelayTime
)


local function showdamage(position,damageamount,color)
	
	local clonedLabel = gui.DamageLabel:Clone()
	clonedLabel.Parent = gui
	local vector, onScreen = camera:WorldToScreenPoint(position)
	local viewportPoint = Vector2.new(vector.X, vector.Y)
	
	if onScreen then
		clonedLabel.Visible = true
	else
		clonedLabel.Visible = false
	end
	clonedLabel.Position = UDim2.new(0, viewportPoint.X, 0, viewportPoint.Y)  + UDim2.new(0,0,-0.03,0)
	clonedLabel.Text = "<b>"..damageamount.."</b>"
	if color == nil then
		color = Color3.fromRGB(255,255,255)
	end
	clonedLabel.TextColor3 = color
	clonedLabel.TextTransparency = 0
	clonedLabel.TextStrokeTransparency = 0
	local newposition = UDim2.new(0, viewportPoint.X, 0, viewportPoint.Y) + UDim2.new(0,0,0.2,0)
	
	local properties = {
		Position = newposition,
		TextTransparency = 1,
		TextStrokeTransparency = 1
	}
	
	local newtween = tween:Create(clonedLabel,tweenInfo,properties)
	newtween:Play()
	wait(1)
	clonedLabel:Destroy()
end

Events.ShowDamage.OnClientEvent:Connect(showdamage)

