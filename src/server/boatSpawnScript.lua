

ReplicatedStorage = game.ReplicatedStorage
Events = ReplicatedStorage.Events
Assets = ReplicatedStorage.Assets
boatoffset = CFrame.new(-20,0,-30)

activeboats = workspace.ActiveBoats
activeports = workspace.BoatSpawns
SpawnBoatEvent = Events.SpawnBoatEvent
noticeevent = Events.NoticeEvent
gameplayHelper = require(game:GetService("ServerScriptService").GameplayHelper)
buffmodule = require(game.ReplicatedStorage.CharacterBuffModule)
QuestEvent = Events.QuestEvent
upgrademodule = require(game.ReplicatedStorage.BoatUpgradeModule)

function CFrameToOrientation(CFrameValue)
	local sx, sy, sz, m00, m01, m02, m10, m11, m12, m20, m21, m22 = CFrameValue:GetComponents()

	local X = math.atan2(-m12, m22)

	local Y = math.asin(m02)

	local Z = math.atan2(-m01, m00)
	
	return math.deg(X), math.deg(Y), math.deg(Z)
end


function portavailable(player,port)
	local boats = activeboats:GetChildren()
	for i = 1, #boats do
		local boat = boats[i]
		if (boat.MainBody.Position - (port * boatoffset).Position).Magnitude < 25 then
			print("Another boat is too close!")
			noticeevent:FireClient(player,"Another boat is too close!","Yellow")
			return false
		end
		if (player.Character.HumanoidRootPart.Position - port.Position).Magnitude > 15 then
			print("player is too far away!")
			noticeevent:FireClient(player,"player is too far away!","Yellow")
			return false
		end
	end
	return true
end


function spawnboat(player,boatname,port) 

	if portavailable(player,port) then
		game.ReplicatedStorage.Events.QuestProgressServer:Fire(player, "BoatSpawning", 1)
		local boat = ReplicatedStorage.Boats:FindFirstChild(boatname):Clone()
		
		local playerboatoffset = boat:GetAttribute("BoatSpawnOffset")
		local offsetcframe = CFrame.new(playerboatoffset)
		
		boat.PrimaryPart = boat:FindFirstChild("MainBody")
		
		local X, Y, Z = CFrameToOrientation(port)
		-- setting attributes
		boat:SetAttribute("Owner",player.Name) -- the current owner
		boat:SetAttribute("OriginalOwner",player.Name) -- the original owner (never changes even when the boat is raided)
		boat:SetAttribute("StartingDegree",-Y + boat.PrimaryPart.Orientation.Y)
		boat:SetAttribute("BoatType", "Player")
		boat:SetAttribute("Target", "")
		boat:SetAttribute("AutoAttack", false)
		boat:SetAttribute("Shield", false)
		boat:SetAttribute("BoatName", boatname)
		
		local cframe = CFrame.new(0,0,0)
		
		print(Y)
		print(boat.PrimaryPart.Orientation.Y)
		
		local cframe = (port * offsetcframe * CFrame.new(0,50,0))
		
		boat:SetPrimaryPartCFrame(cframe)

		boat.Name = player.Name.."Boat"
	
		if activeboats:FindFirstChild(player.Name.."Boat") ~= nil then
			activeboats:FindFirstChild(player.Name.."Boat"):Destroy()
		end
		
		-- upgrades
		local boatData = player.PlayerDataFolder.Boats:FindFirstChild(boatname)
		local boatrarity = boat:GetAttribute("Rarity")
	
		if boatData ~= nil then
			if boatData:GetAttribute("HealthLevel") ~= nil then
				local level = boatData:GetAttribute("HealthLevel")
				boat:SetAttribute("MaxHealth", upgrademodule:getShipStat(boatrarity, boatname, "Health", level))
				boat:SetAttribute("Health", upgrademodule:getShipStat(boatrarity, boatname, "Health", level))
			end
			if boatData:GetAttribute("DamageLevel") ~= nil then
				local level = boatData:GetAttribute("DamageLevel")
				boat:SetAttribute("Damage", upgrademodule:getShipStat(boatrarity, boatname, "Damage", level))
			end
			if boatData:GetAttribute("ReloadLevel") ~= nil then
				local level = boatData:GetAttribute("ReloadLevel")
				boat:SetAttribute("Reload", upgrademodule:getShipStat(boatrarity, boatname, "Reload", level))
			end
		else
			warn(boatname.." item does not exist for "..player.Name)
		end
		
		-- character buffs
		local info = buffmodule.index[player.PlayerDataFolder.CurrentCharacter.Value]
		if info.Type == "Health" then
			local newHealth = math.round(boat:GetAttribute("MaxHealth") * (info.Percentage / 100 + 1))
			boat:SetAttribute("MaxHealth", newHealth)
			boat:SetAttribute("Health", newHealth)
		end
		
		if info.Type == "Damage" then
			local newDamage = math.round(boat:GetAttribute("Damage") * (info.Percentage / 100 + 1))
			boat:SetAttribute("Damage", newDamage)
		end
		
		
	
		--if boat:FindFirstChild("Cannons") ~= nil then
		--	local cannons = boat:FindFirstChild("Cannons"):GetChildren()
		--	for i = 1, #cannons do
		--		local cannon = cannons[i]
		--		cannon.Name = "Cannon"..i
		--		Events.CannonEvent:Fire(boat, cannon)
		--	end
		--end
		
		if player:GetAttribute("PVP") == true then
			gameplayHelper:changeBoatThemeColor(boat, "Red")
		else
			gameplayHelper:changeBoatThemeColor(boat, "Blue")
		end
		
		-- clone scripts
		local BoatScript = ReplicatedStorage.Assets.BoatScript:Clone()
		BoatScript.Parent = boat
		local BoatCannonScript = ReplicatedStorage.Assets.BoatCannonManager:Clone()
		BoatCannonScript.Parent = boat
		
		boat.MainBody.HealthBarGui.Enabled = true
		boat.MainBody.HealthBarGui.OwnerName.Text = player.Name
		boat.Parent = activeboats
		--player.Character.HumanoidRootPart.CFrame = boat.VehicleSeat.CFrame + CFrame.new(0,10,0)
	end
	--boat.Position = 
end

function proximityprompt(port)
	port.ProximityPrompt.Triggered:Connect(function(player)
		if portavailable(player,port.CFrame) then
			SpawnBoatEvent:FireClient(player,port)
		end
	end)
end

ports = activeports:GetChildren()
for i = 1, #ports do
	port = ports[i]:FindFirstChild("BoatSpawnPart")
	proximityprompt(port)
end

SpawnBoatEvent.OnServerEvent:Connect(spawnboat)



