

ReplicatedStorage = game.ReplicatedStorage
Events = ReplicatedStorage.Events
Assets = ReplicatedStorage.Assets
players = game:GetService("Players")
players.CharacterAutoLoads = false
local PhysicsService = game:GetService("PhysicsService")
local collectionservice = game:GetService("CollectionService")

local CollisionEvent = Events.SetCollision
local SpawnEvent = Events.PlayerSpawnEvent
local respawndelay = 7
local dropitem = Events.BindableSpawnItem
local spawnpoints = workspace.SpawnParts
local mapplayerevent = Events.MapPlayerEvent

badgemanager = require(game.ServerScriptService.BadgeManager)
datastore = require(game.ServerScriptService.DataStoreModule)
buffmodule = require(game.ReplicatedStorage.CharacterBuffModule)


--datastore.getplayerdata(177304422)

function customspawnpoint(player, spawnLocationName) -- can be disabled for testing 
	local playerspawn = spawnpoints:FindFirstChild(spawnLocationName) -- currently set to best spawn
	player.Character.HumanoidRootPart.CFrame = playerspawn.CFrame + Vector3.new(0,5,0)
end

function playerspawnteam(player) -- set spawn points
	
	local spawngui = Assets.StarterGui:Clone()
	spawngui.Parent = player.PlayerGui
	local spawnLocationName = SpawnEvent:InvokeClient(player)
	
	local currentCharacter = player.PlayerDataFolder.CurrentCharacter.Value
	local character = ReplicatedStorage.Characters:FindFirstChild(currentCharacter):Clone()
	character.Name = player.Name
	player.Character = character
	character.Parent = workspace
	local rootpart = character:WaitForChild("HumanoidRootPart")
	rootpart.CollisionGroup = "PlayerRootPart"
	local animator = Instance.new("Animator",player.Character.Humanoid)
	local animationscript = Assets.Animate:Clone()
	animationscript.Parent = character
	
	local info = buffmodule.index[player.PlayerDataFolder.CurrentCharacter.Value]
	if info.Type == "Health" then
		local humanoid = character:WaitForChild("Humanoid")
		local newHealth = math.round(humanoid.MaxHealth * (info.Percentage / 100 + 1))
		humanoid.MaxHealth = newHealth
		humanoid.Health = newHealth
	end
	
	--character.HumanoidRootPart.CFrame = workspace.SpawnLocation.CFrame + Vector3.new(0,5,0)
	--player.Team = game.Teams:FindFirstChild(team)
	customspawnpoint(player, spawnLocationName)
	spawngui:Destroy()
end

function dropallcollectibles(player)
	local datafolder = player:WaitForChild("PlayerDataFolder")
	local collectibles = datafolder.Collectibles:GetChildren()
	local rootpart = player.Character.HumanoidRootPart
	for i = 1, #collectibles do
		dropitem:Fire(collectibles[i].Name,rootpart.Position)
	end
	datafolder.Collectibles:ClearAllChildren()
end

function setUpLeaderstats(player)
	local datafolder = player:WaitForChild("PlayerDataFolder", 60)
	local leaderstats = ReplicatedStorage.leaderstats:Clone()
	leaderstats.Parent = player
	leaderstats.Gold.Value = datafolder.Gold.Value
	leaderstats.Gem.Value = datafolder.Gem.Value
	leaderstats.Level.Value = datafolder.Level.Value
	
	datafolder.Gold.Changed:Connect(function(value)
		leaderstats.Gold.Value = value
	end)
	datafolder.Gem.Changed:Connect(function(value)
		leaderstats.Gem.Value = value
	end)
	datafolder.Level.Changed:Connect(function(value)
		leaderstats.Level.Value = value
	end)
end

game.Players.PlayerAdded:Connect(function(player)
	
	--local PlayerDataFolder = game.ReplicatedStorage.PlayerDataFolder:Clone()
	--PlayerDataFolder.Parent = player
	player:SetAttribute("ItemEquippable",true)
	player:SetAttribute("PVP",false)
	
	setUpLeaderstats(player)

	player.CharacterAdded:Connect(function(character)
		local humanoid = character:FindFirstChild("Humanoid")
		CollisionEvent:Fire(character,"Players")
		mapplayerevent:FireAllClients(player,true)
		collectionservice:AddTag(character,"Player")
		
		if badgemanager:checkbadge(player,2127779839) == false then -- give player join game badge
			print("player doesn't have badge")
			badgemanager:awardBadge(player,2127779839)
		else
			print("player do have badge")
		end
		
		if humanoid then
			humanoid.Died:Connect(function()
				dropallcollectibles(player)
				mapplayerevent:FireAllClients(player,false)
				wait(respawndelay)
				player.Character = nil
				character:Destroy()
				player.PlayerGui:ClearAllChildren()
				playerspawnteam(player)
			end)
		end
		
	end)
	player.CharacterRemoving:Connect(function(character)
		mapplayerevent:FireAllClients(player,false)
		dropallcollectibles(player)
	end)
	
	playerspawnteam(player)
end)


game.Players.PlayerRemoving:Connect(function(player)
	if workspace.ActiveBoats:FindFirstChild(player.Name.."Boat") ~= nil then -- clear boats
		local boat = workspace.ActiveBoats:FindFirstChild(player.Name.."Boat")
		boat:SetAttribute("Health", 0)
	end
end)