

local player = game.Players.LocalPlayer
local char = player.Character or workspace:WaitForChild(player.Name,30)
local hum = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart") -- The HumanoidRootPart
local PlayerGui = player.PlayerGui
local BindableEvents = PlayerGui.BindableEvents
local RS = game.ReplicatedStorage
local Events = RS.Events
local tween = game:GetService("TweenService")

local RegionGui = PlayerGui.RegionGui
local RegionEvent = BindableEvents.RegionChangeEvent
local regionframe =  RegionGui.Frame
local weatherchange = require(player.PlayerScripts.WeatherManagment)

local currentregion = nil

RegionGui.Enabled = true
regionframe.Visible = true
regionframe.BackgroundTransparency = 1
regionframe.RegionName.Visible = true
regionframe.RegionName.TextTransparency = 1

local tweenInfo = TweenInfo.new(
	1, -- Time
	Enum.EasingStyle.Quad, -- EasingStyle
	Enum.EasingDirection.Out, -- EasingDirection
	0, -- RepeatCount (when less than zero the tween will loop indefinitely)
	false, -- Reverses (tween will reverse once reaching it's goal)
	0 -- DelayTime
)

local function displayregion(regionname) 
	
	regionframe.RegionName.Text = regionname
	local tween1 = tween:Create(regionframe,tweenInfo,{BackgroundTransparency = 0})
	local tween2 = tween:Create(regionframe.RegionName,tweenInfo,{TextTransparency = 0})
	tween1:Play()
	tween2:Play()
	
	wait(3)
	
	local reversetween1 = tween:Create(regionframe,tweenInfo,{BackgroundTransparency = 1})
	local reversetween2 = tween:Create(regionframe.RegionName,tweenInfo,{TextTransparency = 1})
	reversetween1:Play()
	reversetween2:Play()
end

local function calculateregion()
	local playerregion = nil
	local regions = workspace.RegionParts:GetChildren()
	for i = 1, #regions do
		local region = regions[i]
		local regionroot = region.Position
		local regionsize = region.Size
		
		local regionminx = region.Position.X - region.Size.X / 2
		local regionmaxx = region.Position.X + region.Size.X / 2
		local regionminz = region.Position.Z - region.Size.Z / 2
		local regionmaxz = region.Position.Z + region.Size.Z / 2
		
		if (root.Position.X >= regionminx and root.Position.X <= regionmaxx and root.Position.Z >= regionminz and root.Position.Z <= regionmaxz) then
			playerregion = region.Name
			break
		end
	end
	if playerregion == nil then
		playerregion = "The Ocean"
	end
	if playerregion ~= currentregion then
		currentregion = playerregion
		weatherchange:ChangeWeather(playerregion)
		BindableEvents.RegionChangeEvent:Fire(currentregion)
		displayregion(currentregion) 
		
	end
end

BindableEvents.RegionChangeEvent.Event:Connect(displayregion)

while true do
	calculateregion()
	wait(7)
end

