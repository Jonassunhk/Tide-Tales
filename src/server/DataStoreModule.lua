-- Set up table to return to any script that requires this module script
local PlayerStatManager = {}
 
local DataStoreService = game:GetService("DataStoreService")
local playerData = DataStoreService:GetDataStore("PlayerDataTest") -- PlayerData, PlayerDataTest
local datamanager = require(script.DataStoreAssist)
local ReplicatedStorage = game.ReplicatedStorage
 
-- Table to hold player information for the current session
local sessionData = {}
local AUTOSAVE_INTERVAL = 20

-- Function that other scripts can call to change a player's stats
function PlayerStatManager.ChangeStat(player)
	local playerUserId = "Player_"..player.UserId
	--assert(typeof(sessionData[playerUserId][statName]) == typeof(value), "ChangeStat error: types do not match")
	if sessionData[playerUserId] ~= nil then
		local datafolder = player:FindFirstChild("PlayerDataFolder")
		if datafolder ~= nil then
		--	print("data change requested")
			sessionData[playerUserId] = datamanager.GenerateData(datafolder)
			print(player.Name.." data generated")
			print(sessionData[playerUserId])
		else
			warn("player data folder not found")
		end
	else
		warn("data store error, data does not exist")
	end
end

local function connectItem(player, item)
	item.Changed:Connect(function()
		PlayerStatManager.ChangeStat(player)
	end)
	item.AttributeChanged:Connect(function()
--		print("attribute changed for one stat")
		PlayerStatManager.ChangeStat(player)
	end)
end

local function dataconnection(player) -- make sure datastore updates after each change

	local datafolder = player:WaitForChild("PlayerDataFolder",60)

	local datas = datafolder:GetChildren()
	for i = 1, #datas do
		if datas[i]:IsA("Folder") then
			datas[i].ChildAdded:Connect(function(child)
				PlayerStatManager.ChangeStat(player)
				connectItem(player, child)
			end)
			datas[i].ChildRemoved:Connect(function()
				PlayerStatManager.ChangeStat(player)
			end)
			local items =  datas[i]:GetChildren()
			for i = 1, #items do
				connectItem(player, items[i])
			end
		else
			datas[i].Changed:Connect(function()
				PlayerStatManager.ChangeStat(player)
			end)
		end
	end
end

function PlayerStatManager.getplayerdata(UserID)
	print("retrieving data for "..tostring(UserID))
	local success, data = pcall(function()
		return playerData:GetAsync(UserID)
	end)
	if success then
		if data then
			print(UserID.." ID retrieval successful!")
			print(data)
		else
			print("no current data for player!")
		end
	else
		print("datastore error!")
	end
	return
end

-- Function to add player to the "sessionData" table
local function setupPlayerData(player)
	local playerUserId = "Player_" .. player.UserId
	local success, data = pcall(function()
		return playerData:GetAsync(playerUserId)
	end)
	if success then
		if data then -- if data then
			-- Data exists for this player
			--print(player.Name.." data retrieved")
			--print(data)
			sessionData[playerUserId] = data
			local datafolder = Instance.new("Folder",player)
			datafolder.Name = "PlayerDataFolder"
			datamanager.GetData(datafolder,data)
			datamanager.unify(datafolder,ReplicatedStorage.DefaultDataFolder) -- unify data with default
			--datamanager:removeoddity(datafolder) -- remove error data
			
			--if datamanager:CheckTester(player.Name) then
			--	print(player.Name.." is tester, currency granted")
			--	datafolder.Gold.Value = 0
			--	datafolder.Gem.Value = 0
			--	datafolder.Experience.Value = 0
			--	datafolder.Level.Value = 0
			--end
			--datafolder.MainQuestProgression.Value = 0
			--datafolder.MainQuestProgress.Value = 0
			--datafolder.Gold.Value = 100000
			--datafolder.Gem.Value = 100000
			if datafolder.Boats:FindFirstChild("Swift") == nil then -- free boat giveaway
				local swift = Instance.new("BoolValue", datafolder.Boats)
				swift.Name = "Swift"
			end
			
			datafolder.Quests:ClearAllChildren()
			datafolder.Collectibles:ClearAllChildren()
			
			
			print(player.Name.." data retrieved")
			print(data)
			sessionData[playerUserId] = datamanager.GenerateData(datafolder)
		else
			-- Data store is working, but no current data for this player
			print("no current data for player "..player.Name)
			local datafolder = ReplicatedStorage.DefaultDataFolder:Clone()
			datafolder.Name = "PlayerDataFolder"
			datafolder.Parent = player
			--if datamanager:CheckTester(player.Name) then
			--	print(player.Name.." is tester, currency granted")
			--	datafolder.Gold.Value = 0
			--	datafolder.Gem.Value = 200
			--end
			if datafolder.Boats:FindFirstChild("Swift") == nil then -- free boat giveaway
				local swift = Instance.new("BoolValue", datafolder.Boats)
				swift.Name = "Swift"
			end
			sessionData[playerUserId] = datamanager.GenerateData(datafolder)
		end
		
	else
		warn("Cannot access data store for player!")
	end
	dataconnection(player)
end
 
-- Function to save player's data
local function savePlayerData(playerUserId)
	if sessionData[playerUserId] then
		local success, err = pcall(function()
			playerData:SetAsync(playerUserId, sessionData[playerUserId])
		end)
		if not success then
			warn("Cannot save data for player!")
		end
	end
end
 
-- Function to save player data on exit
local function saveOnExit(player)
	local playerUserId = "Player_" .. player.UserId
	savePlayerData(playerUserId)
end
 
-- Function to periodically save player data
local function autoSave()
	while wait(AUTOSAVE_INTERVAL) do
		print("player data autosaved")
		for playerUserId, data in pairs(sessionData) do
			savePlayerData(playerUserId)
		end
	end
end

 
-- Start running "autoSave()" function in the background
spawn(autoSave)
 
-- Connect "setupPlayerData()" function to "PlayerAdded" event
game.Players.PlayerAdded:Connect(setupPlayerData)
 
-- Connect "saveOnExit()" function to "PlayerRemoving" event
game.Players.PlayerRemoving:Connect(saveOnExit)
 
return PlayerStatManager
