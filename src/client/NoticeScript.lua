
local player = game.Players.LocalPlayer

local ClientEvent = player.PlayerGui.BindableEvents:WaitForChild("NoticeEvent")
local ServerEvent = game.ReplicatedStorage.Events.NoticeEvent
local RewardsServerEvent = game.ReplicatedStorage.Events.RewardsNoticeEvent
	
local PlayerGui = player.PlayerGui
local NoticeGui = PlayerGui:WaitForChild("NoticeGui")
local RewardsGui = PlayerGui:WaitForChild("RewardsNoticeGui")
NoticeGui.Frame.Visible = false
RewardsGui.Frame.Visible = false
local debris = game:GetService("Debris")
local tween = game:GetService("TweenService")

local screentexts
local tweenInfo = TweenInfo.new(
	0.2, -- Time
	Enum.EasingStyle.Quad, -- EasingStyle
	Enum.EasingDirection.Out, -- EasingDirection
	0, -- RepeatCount (when less than zero the tween will loop indefinitely)
	false, -- Reverses (tween will reverse once reaching it's goal)
	2.8 -- DelayTime
)

local function notice(text,color)
	
	local screentexts = NoticeGui.ScreenTexts:GetChildren()
	for i = 1, #screentexts do
		screentexts[i].Position = screentexts[i].Position - UDim2.new(0,0,0.04,0)
		screentexts[i].GroupTransparency += 0.2
	end
	
	local clonedtext = NoticeGui.Frame:Clone()
	clonedtext.Parent = NoticeGui.ScreenTexts
	clonedtext.Visible = true
	clonedtext.TextLabel.Text = "<b>"..text.."</b>"
	if color == "Yellow" then
		clonedtext.TextLabel.TextColor3 = script.Yellow.Value
	elseif color == "Red" then
		clonedtext.TextLabel.TextColor3 = script.Red.Value
	end
	local prevsize = clonedtext.Size
	clonedtext.Size = UDim2.new(0.01, 0,0.001, 0)
	
	clonedtext:TweenSize(
		prevsize,  -- endSize (required)
		Enum.EasingDirection.Out,    -- easingDirection (default Out)
		Enum.EasingStyle.Quad,      -- easingStyle (default Quad)
		0.3,                          -- time (default: 1)
		true                                       -- a function to call when the tween completes (default: nil)
	)
	
	script.Sound:Play()
	local newtween = tween:Create(clonedtext,tweenInfo,{GroupTransparency = 1})
	newtween:Play()
	debris:AddItem(clonedtext,3)
end

local function rewardsnotice(rarity,text)
	local screentexts = RewardsGui.ScreenTexts:GetChildren()
	for i = 1, #screentexts do
		screentexts[i].Position = screentexts[i].Position - UDim2.new(0,0,0.04,0)
	end

	local clonedtext = RewardsGui.Frame:Clone()
	clonedtext.Parent = RewardsGui.ScreenTexts
	clonedtext.Visible = true
	clonedtext.TextLabel.Text = "<b>"..text.."</b>"
	if rarity ~= "Common" then
		clonedtext.BackgroundColor3 = RewardsGui[rarity].Value
	end
	local prevsize = clonedtext.Size
	clonedtext.Size = UDim2.new(0.01, 0,0.001, 0)

	clonedtext:TweenSize(
		prevsize,  -- endSize (required)
		Enum.EasingDirection.Out,    -- easingDirection (default Out)
		Enum.EasingStyle.Quad,      -- easingStyle (default Quad)
		0.3,                          -- time (default: 1)
		true                                       -- a function to call when the tween completes (default: nil)
	)
	local newtween = tween:Create(clonedtext,tweenInfo,{GroupTransparency = 1})
	newtween:Play()
	debris:AddItem(clonedtext,3)
end

ClientEvent.Event:Connect(notice)
ServerEvent.OnClientEvent:Connect(notice)
RewardsServerEvent.OnClientEvent:Connect(rewardsnotice)

wait(4)
-- default: 108, 107, 88