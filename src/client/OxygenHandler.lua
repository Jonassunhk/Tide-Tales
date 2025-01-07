

local player = game.Players.LocalPlayer
local char = player.Character or workspace:WaitForChild(player.Name,30)
local hum = char:WaitForChild("Humanoid")
local root = hum.RootPart -- The HumanoidRootPart
local PlayerGui = player.PlayerGui
local BindableEvents = PlayerGui.BindableEvents
local RS = game.ReplicatedStorage
local Events = RS.Events

local bar = PlayerGui.BarGui.OxygenBar
local oxygenLabel = bar.OxygenAmount

local maxOxygen = 20
local currentOxygen = maxOxygen
local timePerLoss = 0.5
local isSwimming = false
bar.Visible = false

hum.StateChanged:Connect(function(oldState, newState)
	
	if newState == Enum.HumanoidStateType.Swimming then
		isSwimming = true	
	else
		isSwimming = false
	end
end)

while wait(timePerLoss) do
	
	
	if isSwimming and char.Head.Position.Y <= 294 then
		bar.Visible = true
		currentOxygen = math.clamp(currentOxygen - 1, 0, maxOxygen)
	else
		currentOxygen = math.clamp(currentOxygen + 1, 0, maxOxygen)
	end
	if currentOxygen == maxOxygen then
		bar.Visible = false
	end
	if currentOxygen < 1 then
		hum.Health = hum.Health - 5
	end
	local barScale = currentOxygen / maxOxygen
	local xscale = bar.Bar.Size.X.Scale
	local yscale = bar.Bar.Size.Y.Scale
	bar.Bar:TweenSize(UDim2.new(barScale * 0.972, 0, 0.803, 0), "Out", "Quad", timePerLoss)
	
	oxygenLabel.Text = "Oxygen"
end