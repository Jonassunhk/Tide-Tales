
local player = game.Players.LocalPlayer
local char = player.Character or workspace:WaitForChild(player.Name,30)
local hum = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart") -- T ahe HumanoidRootPart
local PlayerGui = player.PlayerGui
local RS = game.ReplicatedStorage

local Events = RS.Events
local BindableEvents = PlayerGui.BindableEvents
local soundEvent = PlayerGui.BindableEvents.SoundEvent
local NoticeEvent = PlayerGui.BindableEvents.NoticeEvent
local inputconfig = require(player.PlayerScripts.InputConfig)
local imageLoader = require(player.PlayerScripts.imageLoader)

local dataFolder = player:WaitForChild("PlayerDataFolder",60)
local boatsDataFolder = dataFolder:WaitForChild("Boats")

local boatGui = PlayerGui:WaitForChild("BoatGui")
local upgradeFrame = boatGui.BoatUpgradeFrame
local OpenButton = boatGui.BoatUpgradeButton
local closeButton = upgradeFrame.CloseButton
local globalMaxLevel = 7

local playerBoat
local boatname
local boatRarity
local boatData
local healthLevel
local reloadLevel
local damageLevel
local connection

local colorIndex = {
	Health = Color3.fromRGB(60, 232, 26),
	Reload = Color3.fromRGB(70, 153, 239),
	Damage = Color3.fromRGB(254, 85, 61)
}

local boatUpgradeModule = require(RS:WaitForChild("BoatUpgradeModule"))
local upgradeIndex =  boatUpgradeModule.upgradeIndex
local statToAttribute = boatUpgradeModule.statToAttribute

local function showLevel(statName, maxLevel, currentLevel)
	local frameGroup = upgradeFrame:FindFirstChild(statName.."Frame")
	
	for i = 1, globalMaxLevel do
		frameGroup:FindFirstChild(i).Visible = false
	end
	for i = 1, maxLevel do
		frameGroup:FindFirstChild(i).Visible = true
		frameGroup:FindFirstChild(i).BackgroundColor3 = Color3.fromRGB(255, 251, 201)
	end
	for i = 1, currentLevel do
		frameGroup:FindFirstChild(i).BackgroundColor3 = colorIndex[statName]
	end
	
	upgradeFrame:FindFirstChild(statName.."UpgradeFrame").TextLabel.Text = boatUpgradeModule.getUpgradeCost(boatUpgradeModule, boatRarity, statName, currentLevel)
end

function roundNumber(num, numDecimalPlaces)
	return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

local function updateUI()
	upgradeFrame.BoatName.Text = boatname
	
	for stat, attributeName in pairs(statToAttribute) do
		local statLevel = boatData:GetAttribute(stat.."Level")
		if statLevel == nil then
			Events.ChangeBoatLevelEvent:FireServer(boatname, stat, 0)
			statLevel = 0
		end
		local currentStat = boatUpgradeModule:getShipStat(boatRarity, playerBoat:GetAttribute("BoatName"), stat, statLevel)
		upgradeFrame:FindFirstChild(stat.."Label").Text = stat..": "..roundNumber(currentStat, 1)
		showLevel(stat, upgradeIndex[boatRarity].MaxLevel, statLevel)
	end
end

local function onUpgradeButtonClicked(statName)
	local currentLevel = boatData:GetAttribute(statName.."Level")
	local cost = boatUpgradeModule.getUpgradeCost(boatUpgradeModule, boatRarity, statName, currentLevel)
	local playerGold = dataFolder:FindFirstChild("Gold").Value
	
	if cost == "MAXED" then -- level already maxed out
		NoticeEvent:Fire("Already maxed")
	elseif playerGold >= cost then -- player has enough gold
		soundEvent:Fire("Upgrade",0,false,false)
		print("player upgraded stat "..statName.." to level "..tostring(currentLevel + 1))
		Events.RemoteChangeCurrency:FireServer("Gold", -cost)
		Events.ChangeBoatLevelEvent:FireServer(boatname, statName, currentLevel + 1)
		local currentStat = playerBoat:GetAttribute(statToAttribute[statName])
		Events.ChangeBoatAttributeEvent:FireServer(statToAttribute[statName], currentStat + upgradeIndex[boatRarity][statName].IncreaseAmount)
		--updateUI()
	else -- not enough 
		NoticeEvent:Fire("Not enough gold", "Red")
	end
end


local function updatePlayerBoatInfo()
	playerBoat = workspace.ActiveBoats:FindFirstChild(player.Name.."Boat")
	boatname = playerBoat:GetAttribute("BoatName")
	boatRarity = playerBoat:GetAttribute("Rarity")
	boatData = boatsDataFolder:FindFirstChild(boatname)
	imageLoader:loadImage(upgradeFrame.BoatImage, boatname)
	connection = boatData.AttributeChanged:Connect(function(name)
		updateUI()
	end)
	updateUI()
end

closeButton.InputBegan:Connect(function(input)
	if inputconfig:CheckInput(input) then
		upgradeFrame.Visible = false
	end	
end)

OpenButton.InputBegan:Connect(function(input)
	if inputconfig:CheckInput(input) then
		playerBoat = workspace.ActiveBoats:FindFirstChild(player.Name.."Boat")
		if playerBoat ~= nil and playerBoat:GetAttribute("OriginalOwner") == player.Name then
			upgradeFrame.Visible = true
			updatePlayerBoatInfo()
			
		end
	end	
end)

upgradeFrame.HealthUpgradeFrame.TextButton.InputBegan:Connect(function(input)
	if inputconfig:CheckInput(input) then
		onUpgradeButtonClicked("Health")
	end	
end)

upgradeFrame.ReloadUpgradeFrame.TextButton.InputBegan:Connect(function(input)
	if inputconfig:CheckInput(input) then
		onUpgradeButtonClicked("Reload")
	end	
end)

upgradeFrame.DamageUpgradeFrame.TextButton.InputBegan:Connect(function(input)
	if inputconfig:CheckInput(input) then
		onUpgradeButtonClicked("Damage")
	end	
end)

upgradeFrame.Visible = false

--updatePlayerBoatInfo()




