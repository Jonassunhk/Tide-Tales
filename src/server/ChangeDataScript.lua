

ReplicatedStorage = game.ReplicatedStorage
Events = ReplicatedStorage.Events
Assets = ReplicatedStorage.Assets

AssetEvent = Events.GiveAsset
TakeAssetEvent = Events.TakeAsset
RemoteCurrencyEvent = Events.RemoteChangeCurrency
CurrencyEvent = Events.ChangeCurrency
QuestEvent = Events.QuestEvent
QuestProgressServerEvent = Events.QuestProgressServer
QuestProgressRemoteEvent = Events.QuestProgressRemote
ChangeBoatLevelEvent = Events.ChangeBoatLevelEvent
RewardsNoticeEvent = Events.RewardsNoticeEvent
PlayerAttributeEvent = Events.ChangePlayerAttribute
gameplayHelper = require(game:GetService("ServerScriptService").GameplayHelper)
QuestData = require(game.ReplicatedStorage.QuestDataModule)
buffmodule = require(game.ReplicatedStorage.CharacterBuffModule)

SSS = game:GetService("ServerScriptService")
globaldata = require(SSS.GlobalData)

function giveplayeritem(player,inventorytype,itemname,amount) 
	if amount == nil then amount = 1 end
	
	for i = 1, amount do
		
		local findtype = inventorytype
		if findtype == "BankCollectibles" then
			findtype = "Collectibles"
		end
		local item = ReplicatedStorage:FindFirstChild(findtype):FindFirstChild(itemname)
		local datafolder = player:WaitForChild("PlayerDataFolder") 
		if item and datafolder then
			local boolvalue = Instance.new("BoolValue")
			boolvalue.Name = itemname
			boolvalue.Parent = datafolder:FindFirstChild(inventorytype)
		else
			warn("item or datafolder don't exist")
		end
		if item:GetAttribute("Rarity") ~= nil then
			local text = itemname.." x "..amount
			RewardsNoticeEvent:FireClient(player,item:GetAttribute("Rarity"),text)
		end
	end
end

function takeplayeritem(player,inventorytype,itemname,amount)
	if amount == nil then amount = 1 end
	local currentamount = 0
	local datafolder = player:WaitForChild("PlayerDataFolder") 
	local items = datafolder:FindFirstChild(inventorytype):GetChildren()
	
	for i = 1, #items do
		if currentamount == amount then break end
		local item = items[i]
		if item.Name == itemname then
			item:Destroy()
			currentamount = currentamount + 1
		end
	end
end

function changecurrencyvalue(player,currencytype,amount)
	local datafolder = player:WaitForChild("PlayerDataFolder") 
	if datafolder then
		local currency = datafolder:FindFirstChild(currencytype)
		if typeof(amount) == "number" then -- is a currency
			
			-- player buffs?
			if currencytype == "Gold" then
				local info = buffmodule.index[player.PlayerDataFolder.CurrentCharacter.Value]
				if info.Type == "Gold Reward" then
					print("Gold Award amount boosted")
					amount = math.round(amount * (info.Percentage / 100 + 1))
				end
			end
			
			currency.Value = currency.Value + amount
			if amount > 0 and ReplicatedStorage.Currencies:FindFirstChild(currencytype) ~= nil then
				local rarity = ReplicatedStorage.Currencies[currencytype]:GetAttribute("Rarity")
				RewardsNoticeEvent:FireClient(player,rarity,currencytype.." x "..amount)
			end
		elseif typeof(amount) == "string" then
			currency.Value = amount
		end
	else
		warn("item or datafolder don't exist")
	end
end

function changePlayerAttribute(player, attributeName, value)
	player:SetAttribute(attributeName, value)
	if attributeName == "PVP" then
		local playerBoat = workspace.ActiveBoats:FindFirstChild(player.Name.."Boat")
		if playerBoat ~= nil then
			if value == true then
				gameplayHelper:changeBoatThemeColor(playerBoat, "Red")
			else
				gameplayHelper:changeBoatThemeColor(playerBoat, "Blue")
			end
		end
	end
end


function changeBoatLevelAttribute(player, boatName, statName, level)
	local datafolder = player:WaitForChild("PlayerDataFolder")
	datafolder.Boats:FindFirstChild(boatName):SetAttribute(statName.."Level", level)
end

function onAttributeChanged(player, attributeName, newValue)
	print("SERVER: changing attribute "..attributeName.." to "..tostring(newValue))
	local boat = workspace.ActiveBoats:FindFirstChild(player.Name.."Boat")
	if boat ~= nil then
		boat:SetAttribute(attributeName, newValue)
	end
end


function updatequest(player, operation, questType, questindex, progress)
	local datafolder = player:WaitForChild("PlayerDataFolder") 

	if operation == "Add" then -- adding a quest
		local newquest = Instance.new("IntValue",datafolder.Quests)
		newquest.Value = progress
		newquest.Name = questType
		newquest:SetAttribute("Index", questindex)
		local QuestCategory = QuestData:getQuestInfo(questType, questindex).QuestCategory
		newquest:SetAttribute("QuestCategory", QuestCategory)
		

	elseif operation == "Update" then -- updating a quest
		local quests = datafolder.Quests:GetChildren()
		for i = 1, #quests do
			if quests[i].Name == questType and quests[i]:GetAttribute("Index") == questindex  then
				quests[i].Value = progress
			end
		end
	elseif operation == "Remove" then -- removing a quest
		local quests = datafolder.Quests:GetChildren()
		for i = 1, #quests do
			if quests[i].Name == questType and quests[i]:GetAttribute("Index") == questindex  then
				quests[i]:Destroy()
			end
			if questType == "MainQuest" and questindex < QuestData:getMainQuestLength() then -- player can still do main quest
				globaldata:mainQuestUpdated(questindex + 1) -- update global data
				updatequest(player, "Add", "MainQuest", questindex + 1, 0) -- update main quest
			end
			datafolder.MainQuestProgression.Value = datafolder.MainQuestProgression.Value + 1
			datafolder.MainQuestProgress.Value = 0
		end
	end
end

function updatePlayerQuestProgress(player, questCategory, amount)
	local datafolder = player:WaitForChild("PlayerDataFolder", 30)
	local activequests = datafolder.Quests:GetChildren()
	for i = 1, #activequests do
		local activeQuest = activequests[i]
		if activeQuest:GetAttribute("QuestCategory") == questCategory then
			activeQuest.Value = activeQuest.Value + amount
			if activeQuest.Name == "MainQuest" then
				datafolder.MainQuestProgress.Value = datafolder.MainQuestProgress.Value + amount
			end
		end
	end
end

Events.ChangeBoatAttributeEvent.OnServerEvent:Connect(onAttributeChanged) -- event to change target for the player
ChangeBoatLevelEvent.OnServerEvent:Connect(changeBoatLevelAttribute)
TakeAssetEvent.OnServerEvent:Connect(takeplayeritem)
AssetEvent.OnServerEvent:Connect(giveplayeritem)

QuestEvent.OnServerEvent:Connect(updatequest) -- event to update, add, or remove a specific quest
QuestProgressServerEvent.Event:Connect(updatePlayerQuestProgress) -- bindable event to update quest progression
QuestProgressRemoteEvent.OnServerEvent:Connect(updatePlayerQuestProgress) -- remote event to update quest progression

RemoteCurrencyEvent.OnServerEvent:Connect(changecurrencyvalue)
CurrencyEvent.Event:Connect(changecurrencyvalue)
PlayerAttributeEvent.OnServerEvent:Connect(changePlayerAttribute)


