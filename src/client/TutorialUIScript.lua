
local player = game.Players.LocalPlayer
local datafolder = player:WaitForChild("PlayerDataFolder", 30)
local char = player.Character or workspace:WaitForChild(player.Name,30)
local hum = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart") -- T ahe HumanoidRootPart
local PlayerGui = player.PlayerGui
local BindableEvents = PlayerGui.BindableEvents
local RS = game.ReplicatedStorage
local Events = RS.Events
local tutorialhelper = require(player.PlayerScripts.TutorialHelper)

local function gunUITutorial()
	print("step 1")
	tutorialhelper:lockButton(
		PlayerGui.InventoryGui,
		PlayerGui.InventoryGui.OpenButton,
		PlayerGui.InventoryGui.OpenButton,
		"Click the icon to open the backpack",
		nil --Enum.KeyCode.B
	)
	print("step 2")
	tutorialhelper:lockButton(
		PlayerGui.InventoryGui,
		PlayerGui.InventoryGui.InventoryFrame,
		PlayerGui.InventoryGui.InventoryFrame.Items:FindFirstChild("Revolver").TextButton,
		"Select the gun 'Revolver'",
		nil
	)
	print("step 3")
	tutorialhelper:lockButton(
		PlayerGui.InfoFrameGui,
		PlayerGui.InfoFrameGui:WaitForChild("WeaponsInfo"),
		PlayerGui.InfoFrameGui:WaitForChild("WeaponsInfo").Info.EquipButton,
		"Equip the gun by clicking 'Equip'",
		nil
	)
	print("step 4")
	tutorialhelper:lockButton(
		PlayerGui.InventoryGui,
		PlayerGui.InventoryGui.OpenButton,
		PlayerGui.InventoryGui.OpenButton,
		"Close the inventory by clicking the icon again",
		nil --Enum.KeyCode.B
	)
	print("step 5")
	tutorialhelper:lockButton(
		PlayerGui.GunGui,
		PlayerGui.GunGui.Gun2,
		PlayerGui.GunGui.Gun2.TextButton,
		"Now equip or unequip the Revolver by clicking the frame below or the '2' key",
		Enum.KeyCode.Two
	)
end

local function boatUITutorial()
	local prevJumpPower = hum.JumpPower 
	hum.JumpPower = 0 -- prevent player from getting off the boat
	wait(2)
	tutorialhelper:lockButton(
		PlayerGui.BoatGui,
		PlayerGui.BoatGui.BoatAbilitiesFrame,
		PlayerGui.BoatGui.BoatAbilitiesFrame.BoostButton,
		"Use the BOOST button to temporarily boost your boat's speed!",
		nil
	)
	wait(2)
	tutorialhelper:lockButton(
		PlayerGui.BoatGui,
		PlayerGui.BoatGui.BoatAbilitiesFrame,
		PlayerGui.BoatGui.BoatAbilitiesFrame.ShieldButton,
		"Use the SHIELD button to deflect all damage for a few seconds!",
		nil
	)
	wait(2)
	tutorialhelper:lockButton(
		PlayerGui.BoatGui,
		PlayerGui.BoatGui.BoatAbilitiesFrame,
		PlayerGui.BoatGui.BoatAbilitiesFrame.HealButton,
		"Use the HEAL button to slowly heal your boat!",
		nil
	)
	wait(2)
	tutorialhelper:lockButton(
		PlayerGui.BoatGui,
		PlayerGui.BoatGui.BoatUpgradeButton,
		PlayerGui.BoatGui.BoatUpgradeButton,
		"UPGRADE the boat by clicking on the boat icon!",
		nil
	)
	hum.JumpPower = prevJumpPower
end

local function mapUITutorial()
	
end

local function updateTutorial()
	local progress = datafolder.MainQuestProgression.Value
	if progress == 1 then -- gun UI tutorial
		gunUITutorial()
	elseif progress == 3 then
		mapUITutorial()
	end
end

datafolder.MainQuestProgression.Changed:Connect(updateTutorial)

RS.Events.PlayerBoatEvent.OnClientEvent:Connect(function(steering)
	local progress = datafolder.MainQuestProgression.Value
	if steering == true and progress == 6 then
		boatUITutorial()
	end
end)

updateTutorial()


