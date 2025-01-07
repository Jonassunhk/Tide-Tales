

local player = game.Players.LocalPlayer
local char = player.Character or workspace:WaitForChild(player.Name,30)
local hum = char:WaitForChild("Humanoid")
local root = hum.RootPart -- The HumanoidRootPart
local PlayerGui = player.PlayerGui
local BindableEvents = PlayerGui.BindableEvents
local RS = game.ReplicatedStorage
local Events = RS.Events
local confirmation = BindableEvents.ConfirmationEvent

local QuestGui = PlayerGui.QuestGui
local QuestFrame = QuestGui.QuestFrame
local JournalFrame = QuestGui.JournalFrame
local QuestDataModule = require(game.ReplicatedStorage.QuestDataModule)

local ContextAction = game:GetService("ContextActionService")
local inputconfig = require(player.PlayerScripts.InputConfig)
QuestGui.OpenButton.RedLabel.Visible = false

local BindableEvents = PlayerGui.BindableEvents
local characterevent = BindableEvents.CharacterViewport
local loadviewport = BindableEvents.LoadViewport
local NoticeEvent = BindableEvents.NoticeEvent
local localquestevent = BindableEvents.QuestEvent
local LoadViewport = BindableEvents.LoadViewport

local QuestGui = PlayerGui.QuestGui
local QuestFrame = QuestGui.QuestFrame
local JournalFrame = QuestGui.JournalFrame
local Quests = JournalFrame.Quests
local MiniQuestDisplay = QuestGui.MiniQuestDisplay

local QuestFormat = RS.Assets.Quest
local MainQuestFormat = RS.Assets.MainQuest
local collectibles = RS.Collectibles
local collectibleimages = RS.CollectiblesImages
local assetevent = Events.GiveAsset
local currencyevent = Events.RemoteChangeCurrency
local currencies = RS.Currencies
local inventoryframes = RS.InventoryFrames
local questevent = Events.QuestEvent
local QuestProgressRemote = Events.QuestProgressRemote
local QuestPrompt = RS.Assets.ProximityPrompt.QuestPrompt


local Weapons = RS.Weapons
local characters = RS.Characters
local Boats = RS.Boats
local datafolder = player:WaitForChild("PlayerDataFolder", 60)
local playerlevel = datafolder.Level

local QuestData = require(game.ReplicatedStorage.QuestDataModule)
local inputconfig = require(player.PlayerScripts.InputConfig)

local function getitemframe(itemname,amount,special) -- getting item frame from RS

	local item = collectibles:FindFirstChild(itemname) or currencies:FindFirstChild(itemname)
	local rarity = item:GetAttribute("Rarity")
	local frame = inventoryframes[rarity.."Frame"]:Clone()
	local image = collectibleimages[itemname]:Clone()
	image.Parent = frame
	if amount then
		frame.Amount.Visible = true
		frame.Amount.Text = "<b>"..amount.."</b>"
	end
	return frame
end

function intialize() -- intializing quest gui
	QuestGui.Enabled = true
	JournalFrame.Visible = false
	QuestFrame.Visible = false
end

function returnrewards(itemrewards,parent) -- returing all the reward frames for a parent frame
	for key, value in pairs(itemrewards) do
		local frame = getitemframe(key,value)
		frame.Parent = parent
	end
end

function DisplayQuestInfo(questinfo,toggle) -- displaying big frame quest info
	JournalFrame.Visible = false
	local NewQuest = QuestFrame:Clone()
	NewQuest.QuestName.Text = "<b>"..questinfo.QuestName.."</b>"
	NewQuest.QuestGiver.Text = "<b>"..questinfo.QuestGiver.."</b>"
	NewQuest.QuestInfo.Text = questinfo.QuestInfo
	NewQuest.EXPReward.Text = "EXP Reward: "..questinfo.EXPReward
	NewQuest.ShortQuestInfo.Text = "<b>"..questinfo.QuestShortInfo.."</b>"
	local itemrewards = questinfo.ItemRewards
	returnrewards(itemrewards,NewQuest.Rewards)

	local character = characters[questinfo.QuestGiver] -- generating character
	NewQuest.Visible = true
	NewQuest.Parent = QuestGui
	characterevent:Fire(NewQuest.CharacterViewport,character)

	NewQuest.CloseButton.InputBegan:Connect(function(input)
		if inputconfig:CheckInput(input) then
			NewQuest:Destroy()
			if toggle then JournalFrame.Visible = true end
			script.Event:Fire()
		end
	end)
	script.Event.Event:Wait()
	return true
end

local function giveItemRewards(itemrewards) -- giving the rewards to players 
	for key, value in pairs(itemrewards) do
		if key == "Gold" or key == "Gem" then
			currencyevent:FireServer(key,value)
		else
			assetevent:FireServer("Collectibles",key,value)
		end
	end
end

local function giveRewards(questType, questIndex)
	local questInfo = QuestData:getQuestInfo(questType, questIndex)
	local itemrewards = questInfo.ItemRewards 
	currencyevent:FireServer("Experience",questInfo.EXPReward)
	giveItemRewards(itemrewards) 
	questevent:FireServer("Remove", questType, questIndex)
end

local function setUpProximityPrompts(questType, questIndex)
	local questInfo = QuestData:getQuestInfo(questType, questIndex)

	if questInfo.QuestCategory == "TalkToNPC" then
		local newPrompt = QuestPrompt:Clone()
		local NPCName = questInfo.QuestGiver
		
		local position = game.ReplicatedStorage.Events.StreamingHelper:InvokeServer(questInfo.SpecificLocation)
		local part = Instance.new("Part")
		part.Anchored = true
		part.CanCollide = false
		part.Transparency = 1
		part.Position = position - Vector3.new(0,3,0)
		part.Parent = workspace
		newPrompt.Parent = part
		
		newPrompt.Enabled = true
		newPrompt.Triggered:Connect(function()
			newPrompt.Enabled = false
			local dialogues = questInfo.Dialogues
			for i = 1, #dialogues do
				BindableEvents.InformEvent:Invoke(dialogues[i],NPCName)
			end
			RS.Events.QuestProgressRemote:FireServer("TalkToNPC", 1)
			part:Destroy()
		end)
	end
end

local function updateStaticQuests()
	local boats = datafolder.Boats:GetChildren()
	for i = 1, #boats do
		Events.QuestProgressRemote:FireServer("Own"..boats[i].Name, 1)
	end
	local level = datafolder.Level.Value
	Events.QuestProgressRemote:FireServer("Level"..level, 1)
end

local function updateQuest(questType, questindex, currentProgress)
	local quest = Quests:FindFirstChild(questType..questindex)
	if quest ~= nil then
		local questInfo = QuestData:getQuestInfo(questType, questindex)

		local progressbar = quest.Bar.Progress
		local ratio = math.min(currentProgress / questInfo.Goal, 1)
		local xscale = progressbar.Size.X.Scale
		progressbar.Size = UDim2.new(ratio,0,progressbar.Size.Y.Scale,0)
		quest.Bar.TextLabel.Text = currentProgress.." / "..questInfo.Goal.." Completed"

		if questType == "MainQuest" then
			MiniQuestDisplay.Visible = true
			MiniQuestDisplay.TextLabel.Text = questInfo.QuestShortInfo..": "..currentProgress.." / "..questInfo.Goal
			if currentProgress >= questInfo.Goal then
				MiniQuestDisplay.TextLabel.Text = questInfo.QuestShortInfo..": Completed!"
			end
		end

		if currentProgress >= questInfo.Goal then
			giveRewards(questType, questindex)
			NoticeEvent:Fire("Quest Completed!")
			--quest.CompletedFrame.Visible = true
			--QuestGui.OpenButton.RedLabel.Visible = true 
			--if questInfo.QuestCategory == "TalkToNPC" then -- auto give rewards if NPC talk
			--	giveRewards(questType, questindex)
			--else
			--	quest.CompletedFrame.TextButton.InputBegan:Connect(function(input) -- have players click
			--		if inputconfig:CheckInput(input) then
			--			giveRewards(questType, questindex)
			--		end
			--	end)
			--end
		else
			quest.CompletedFrame.Visible = false
		end
	else
		warn("Something went wrong, updating quest "..questType..questindex.." on nil UI")
	end
end

local function resetQuest(activeQuest)
	print("player quest resetted")
	local questType = activeQuest.Name
	local questindex = activeQuest:GetAttribute("Index")

	local newquest
	local questInfo = QuestData:getQuestInfo(questType, questindex)
	if questType == "SideQuest" then
		newquest = QuestFormat:Clone()
	elseif questType == "MainQuest" then
		newquest = MainQuestFormat:Clone()
	else
		warn("Quest type "..questType.." does not match current types")
		return
	end
	local progress = activeQuest.Value

	-- set up new quest frame
	newquest.Name = questType..questindex
	newquest.QuestName.Text = "<b>"..questInfo.QuestName.."</b>"
	local itemrewards = questInfo.ItemRewards 
	returnrewards(itemrewards,newquest.Rewards)
	newquest.Visible = true
	newquest.Parent = Quests

	newquest.InfoButton.InputBegan:Connect(function(input) -- show quest info when clicked 
		if inputconfig:CheckInput(input) then
			DisplayQuestInfo(questInfo,true)
		end
	end)
	activeQuest.Changed:Connect(function(value) -- update quest value once value changed
		updateQuest(questType, questindex, value)
	end)
	updateQuest(questType, questindex, progress)
	setUpProximityPrompts(questType, questindex) -- if there are talk to npc quests, this will set it up
end

local function resetQuests() -- displaying mini quest in journal page
	local objects = Quests:GetChildren()
	for i = 1, #objects do
		if objects[i]:IsA("Frame") then
			objects[i]:Destroy()
		end
	end
	updateStaticQuests()
	MiniQuestDisplay.Visible = false
	local activequests = datafolder.Quests:GetChildren()
	table.sort(activequests, function(a,b)
		return a.Value < b.Value
	end)

	for i = 1, #activequests do
		resetQuest(activequests[i])
	end
end

datafolder.Quests.ChildAdded:Connect(resetQuests)
datafolder.Quests.ChildRemoved:Connect(resetQuests)
resetQuests()

-- for some players, main quest doesn't exist
if datafolder.Quests:FindFirstChild("MainQuest") == nil then 
	local MainQuestProgression = datafolder.MainQuestProgression.Value
	local progress = datafolder.MainQuestProgress.Value
	if MainQuestProgression < QuestData:getMainQuestLength() then
		print("Player has not started main quest")
		questevent:FireServer("Add","MainQuest", MainQuestProgression + 1, progress) -- give player main quest
	else
		-- player has finished main quest, no need to create quest
	end
end

JournalFrame.CloseButton.InputBegan:Connect(function(input)
	if inputconfig:CheckInput(input) then
		JournalFrame.Visible = false
	end
end)

QuestGui.OpenButton.InputBegan:Connect(function(input)
	if inputconfig:CheckInput(input) then
		JournalFrame.Visible = true
		QuestGui.OpenButton.RedLabel.Visible = false
	end
end)

local function openjournal(actionName, inputState, inputObject)
	if inputState == nil or inputState == Enum.UserInputState.End then
		if JournalFrame.Visible == true then
			JournalFrame.Visible = false
		else
			JournalFrame.Visible = true
			QuestGui.OpenButton.RedLabel.Visible = false
		end
	end
end

ContextAction:BindAction("OpenJournal",openjournal,false,Enum.KeyCode.V)
updateStaticQuests()

--Events.AddQuestEvent.OnClientEvent:Connect(function(proximityprompt,questindex)
	
--	proximityprompt.Enabled = false
	
--	local questinfo = QuestDataModule:returninfo(questindex)
--	local success = QuestModule.DisplayQuestInfo(questinfo,false)
--	if confirmation:Invoke("Do you want to take this quest for the rewards?") then
--		QuestModule:AddQuest(questindex) 
--	end
--	proximityprompt.Enabled = true
--end)


