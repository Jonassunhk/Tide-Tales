

local player = game.Players.LocalPlayer
local char = player.Character or workspace:WaitForChild(player.Name,30)
local hum = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart") -- T ahe HumanoidRootPart
local PlayerGui = player.PlayerGui
local BindableEvents = PlayerGui.BindableEvents
local RS = game.ReplicatedStorage
local Events = RS.Events
local datafolder = player:WaitForChild("PlayerDataFolder", 60)
local soundEvent = BindableEvents.SoundEvent

local inputconfig = require(player.PlayerScripts.InputConfig)
local imageLoader = require(player.PlayerScripts.imageLoader)

local boatAwardGui = PlayerGui.BoatAwardGui
local frame = boatAwardGui.Frame

local rarityColors = {
	Common = Color3.fromRGB(159, 159, 159),
	Rare = Color3.fromRGB(94, 220, 255),
	Epic = Color3.fromRGB(199, 110, 255),
	Legendary = Color3.fromRGB(255, 179, 1),
	Mythical = Color3.fromRGB(238, 11, 15)
}

local function showBoatAward(boatname)
	
	soundEvent:Fire("Upgrade",0,false,false)
	
	boatAwardGui.Enabled = true
	frame.Visible = true
	local boat = RS.Boats:FindFirstChild(boatname)
	local rarity = boat:GetAttribute("Rarity")
	
	frame.BoatRarity.Text = rarity
	frame.BoatName.Text = boatname
	imageLoader:loadImage(frame.BoatImage, boatname)
	
	-- add gradient
	frame.Background:ClearAllChildren()
	local gradient = game.ReplicatedStorage.RarityGradients:FindFirstChild(rarity):Clone()
	gradient.Parent = frame.Background
	
	-- add colors
	frame.BoatName.TextColor3 = rarityColors[rarity]
	frame.BoatRarity.TextColor3 = rarityColors[rarity]
end

datafolder.Boats.ChildAdded:Connect(function(child)
	showBoatAward(child.Name)
end)

frame.CloseButton.InputBegan:Connect(function(input)
	if inputconfig:CheckInput(input) then
		frame.Visible = false
	end
end)

boatAwardGui.Enabled = true
frame.Visible = false


