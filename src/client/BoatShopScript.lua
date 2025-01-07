
local player = game.Players.LocalPlayer
local char = player.Character or workspace:WaitForChild(player.Name,30)
local hum = char:WaitForChild("Humanoid")
local root = hum.RootPart -- The HumanoidRootPart
local PlayerGui = player.PlayerGui
local BindableEvents = PlayerGui.BindableEvents
local currencyAnimation = require(PlayerGui:WaitForChild("SpecialEffectsGui").CurrencyAnimation)

local datafolder = player:WaitForChild("PlayerDataFolder")
local BarGui = PlayerGui.BarGui
local GoldValue = datafolder.Gold
local GemValue = datafolder.Gem
local experience = datafolder:FindFirstChild("Experience")
local level  = datafolder:FindFirstChild("Level")
local bounty = datafolder:FindFirstChild("Bounty")
local NoticeEvent = BindableEvents.NoticeEvent
local PVPButton = BarGui.PVPButton
local currentPVP = player:GetAttribute("PVP")
local pvpLocked = false

local pvpTimer = 0
local pvpTimeout = 60 -- seconds the player must wait before turning off pvp
local inputconfig = require(player.PlayerScripts.InputConfig)

local prevGold = GemValue.Value
local prevGem = GemValue.Value
local prevHealth = hum.Health

local RS = game.ReplicatedStorage
local Events = RS.Events
local CurrencyEvent = Events.RemoteChangeCurrency
local playerAttributeEvent = Events.ChangePlayerAttribute
local PVPLockEvent = BindableEvents.PVPLock

local black = Color3.new(0.3, 0.3, 0.3)
local white = Color3.new(1,1,1)

local levelindex = {
	100, -- 1
	250,
	545,
	725,
	850, -- 5
	950,
	1075,
	1200,
	1300,
	1420, -- 10
	1525,
	1650,
	1775,
	1875,
	2000, -- 15
	2375,
	2500,
	2630,
	2760,
	2825, -- 20
	3425,
	3725,
	4000,
	4300,
	4600, -- 25
	30000 -- cap 
}

local levelrewards = {
	["5"] = {
		Gold = 100,
		["Silver Bar"] = 2,
		["Gold Bar"] = 1
	},
	["10"] = {
		Gold = 200,
		["Gold Bar"] = 1,
		["Emerald"] = 1
	},
	["15"] = {
		Gold = 350,
		["Gold Bar"] = 2,
		["Ruby"] = 2,
		["Emerald"] = 1
	},
	["20"] = {
		Gold = 500,
		["Diamond"] = 2
	}
}

local function updatehealth()
	
	local maxhealth = hum.MaxHealth
	local newhealth = hum.Health
	
	if newhealth < prevHealth and currentPVP == true then -- reset pvp
		print("PVP resetted")
		pvpTimer = pvpTimeout
	end
	prevHealth = newhealth

	BarGui.HealthLabel.Text = "<b>"..newhealth.." | "..maxhealth.."</b>"

	if newhealth == 0 then 
		BarGui.Red.UIGradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, black),
			ColorSequenceKeypoint.new(1, black)
		}
	else 
		local ratio = math.round(newhealth / maxhealth * 100)
		ratio = math.clamp(ratio,1,100)

		local maxhealth = hum.MaxHealth
		BarGui.Red.UIGradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, white), -- (time, value)
			ColorSequenceKeypoint.new(0.01 * (ratio - 1), white),
			ColorSequenceKeypoint.new(0.01 * ratio, black),
			ColorSequenceKeypoint.new(1, black)
		}
	end
end

local function updateexperience()
	
	while experience.Value >= levelindex[level.Value] and level.Value < #levelindex do	
		CurrencyEvent:FireServer("Experience",-levelindex[level.Value])
		CurrencyEvent:FireServer("Level",1)
		Events.RemoteParticleEvent:FireServer(root)
		--NoticeEvent:Fire("Level up!","Yellow")
		currencyAnimation.levelUpAnimation()
		
		BarGui.LevelLabel.Text = "Level "..level.Value
		BarGui.ExperienceLabel.Text = experience.Value.." | "..levelindex[level.Value]
		wait(2)
	end
	
	BarGui.LevelLabel.Text = "Level "..level.Value
	BarGui.ExperienceLabel.Text = experience.Value.." | "..levelindex[level.Value]
	
	local ratio = math.round(experience.Value / levelindex[level.Value] * 100)
	ratio = math.clamp(ratio,1,100)
	
	BarGui.Purple.UIGradient.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.01 * (ratio - 1), 0),
		NumberSequenceKeypoint.new(0.01 * ratio, 1),
		NumberSequenceKeypoint.new(1, 1)
	}
end

local function updatebounty()
	BarGui.BountyLabel.Text = "Kill Value: "..bounty.Value
end

local function updategold()
	local newvalue = GoldValue.Value
	if prevGold < newvalue then
		currencyAnimation.CreateAnimation("Coin", newvalue - prevGold)
	end
	prevGold = newvalue
	BarGui.GoldLabel.Text = "<b>"..newvalue.."</b>"
end

local function updategem()
	local newvalue = GemValue.Value
	if prevGem < newvalue then
		currencyAnimation.CreateAnimation("Gem", newvalue - prevGem)
	end
	prevGem = newvalue
	BarGui.GemLabel.Text = "<b>"..newvalue.."</b>"
end

-- PVP rules
-- 1. if the player is damaged or the player's boat is damaged, the player cannot turn off PVP for 1 minute
-- 2. if the player damages others or other player's boat, the player cannot turn off PVP for 1 minute
-- 3. if the player is in a region that demands PVP, the player cannot turn off PVP

function changePVP()
	currentPVP = player:GetAttribute("PVP")
	if pvpLocked == true then
		BindableEvents.NoticeEvent:Fire("PVP required in your region", "Red")
		return
	end
	if currentPVP == true then -- pvp on
		if pvpTimer <= 0 then -- player has pvp on and can turn pvp off
			playerAttributeEvent:FireServer("PVP", false)
			setPVPUI("OFF")
		else
			-- player can't turn pvp off because the timer is still on
			BindableEvents.NoticeEvent:Fire("You must wait "..pvpTimer.." more seconds!", "Red")
		end
	else -- pvp false
		local result = BindableEvents.ConfirmationEvent:Invoke("You must wait "..pvpTimeout.." seconds before turning PVP off. The timer resets when you take or deal damage.")
		if result then
			playerAttributeEvent:FireServer("PVP", true)
			pvpTimer = pvpTimeout
			setPVPUI("ON")
		end
	end
end

function handlePVPEvent(action)
	if action == "Reset" then -- reset timer
		pvpTimer = pvpTimeout
	end
end

function lockPVP(state)
	if state == false then
		playerAttributeEvent:FireServer("PVP", true)
		pvpTimer = pvpTimeout
		setPVPUI("ON")
	else
		playerAttributeEvent:FireServer("PVP", true)
		setPVPUI("LOCK")
	end
	pvpLocked = state
end

function setPVPUI(state)
	if state == "LOCK" then
		PVPButton.Text = "ON ONLY"
		PVPButton.BackgroundColor3 = Color3.fromRGB(24, 237, 4)
	elseif state == "ON" then
		if pvpTimer > 0 then
			PVPButton.Text = "ON ("..tostring(pvpTimer)..")"
			PVPButton.BackgroundColor3 = Color3.fromRGB(24, 237, 4)
		elseif pvpTimer == 0 then
			PVPButton.Text = "ON"
		end
	elseif state == "OFF" then
		PVPButton.Text = "OFF"
		PVPButton.BackgroundColor3 = Color3.fromRGB(232, 69, 54)
	end
end

PVPButton.InputBegan:Connect(function(input)
	if inputconfig:CheckInput(input) then
		changePVP()
	end	
end)


updatehealth()
updategold()
updategem()
updateexperience()
updatebounty()
hum:GetPropertyChangedSignal("Health"):Connect(updatehealth)
hum.Died:Connect(updatehealth)
experience:GetPropertyChangedSignal("Value"):Connect(updateexperience)
GoldValue:GetPropertyChangedSignal("Value"):Connect(updategold)
GemValue:GetPropertyChangedSignal("Value"):Connect(updategem)
bounty:GetPropertyChangedSignal("Value"):Connect(updatebounty)
PVPLockEvent.Event:Connect(lockPVP)

-- TESTING --
if player.Name == "Lightninghuman2" then
	--CurrencyEvent:FireServer("Level",4)
	--CurrencyEvent:FireServer("Experience",500)
end

-- pvp preset
PVPButton.Text = "OFF"
PVPButton.BackgroundColor3 = Color3.fromRGB(232, 69, 54)

BarGui.Enabled = true
while true do -- set pvp update loop
	local currentPVP = player:GetAttribute("PVP")
	if pvpLocked then
		setPVPUI("LOCK")
	else
		if currentPVP then
			setPVPUI("ON")
		else
			setPVPUI("OFF")
		end
	end
	pvpTimer = pvpTimer - 1
	wait(1)
end



