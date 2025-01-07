
local player = game.Players.LocalPlayer
local char = player.Character or workspace:WaitForChild(player.Name,30)
local hum = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart") -- T ahe HumanoidRootPart
local PlayerGui = player.PlayerGui
local BindableEvents = PlayerGui.BindableEvents
local RS = game.ReplicatedStorage
local Events = RS.Events
local text = PlayerGui:WaitForChild("RegionGui").TextLabel
local tween = game:GetService("TweenService")
local PVPLockEvent = BindableEvents.PVPLock

local OutOfBounds = false
local pvpLock = false
local message = "You are going OUT OF BOUNDS! Turn back immediately before you take damage!"
local damageTick = 4
local timeInterval = 1
local waitTime = 5

local tweenInfo = TweenInfo.new(
	1, -- Time
	Enum.EasingStyle.Quad, -- EasingStyle
	Enum.EasingDirection.Out, -- EasingDirection
	-1, -- RepeatCount (when less than zero the tween will loop indefinitely)
	true, -- Reverses (tween will reverse once reaching it's goal)
	0 -- DelayTime
)

root.Touched:Connect(function(part)
	--print("root touched  "..part.Name)
	if part.Parent ~= nil and part.Parent:GetAttribute("LevelRequirement") ~= nil then
		
		print(player.Name.."touched border of "..part.Parent.Name)
		-- managing level
		local playerLevel = player:WaitForChild("PlayerDataFolder").Level.Value
		if playerLevel < part.Parent:GetAttribute("LevelRequirement") then
			text.Visible = true
			OutOfBounds = true
			print(player.Name.." going out of bounds")
			--spawn(beginCountdown)
		else
			text.Visible = false
			print(player.Name.." in bounds")
			OutOfBounds = false
		end
		
		-- pvp
		if pvpLock == false and part.parent:GetAttribute("PVP") == true then -- lock pvp
			pvpLock = true
			print(player.Name.."entered "..part.Parent.Name.." PVP lock turned on")
			BindableEvents.NoticeEvent:Fire("PVP must be on for your current region")
			PVPLockEvent:Fire(true)
		elseif pvpLock == true and part.parent:GetAttribute("PVP") == false then -- unlock pvp
			pvpLock = false
			print(player.Name.."entered "..part.Parent.Name.." PVP lock turned off")
			PVPLockEvent:Fire(false)
		end
	end
end)

local tween1 = tween:Create(text,tweenInfo,{TextTransparency = 1})
tween1:Play()

wait(2)
text.Visible = false

while true do
	if OutOfBounds then
		Events.ChangePlayerHealth:FireServer(damageTick * -1)		
	end
	wait(timeInterval)
end



