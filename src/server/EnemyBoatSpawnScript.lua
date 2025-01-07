

ReplicatedStorage = game.ReplicatedStorage
Events = ReplicatedStorage.Events
Assets = ReplicatedStorage.Assets

local chestevent = Events.ChestEvent
local gameplayhelper = require(game.ServerScriptService.GameplayHelper)
local spawnRegions = workspace.EnemyBoatSpawns:GetChildren()


-- variables
local spawncooldown = 25
local eliteBoatSpawnCooldown = 130
local eliteBoatChance = 5 
local eliteHealthIncrease = 3
local eliteAttackIncrease = 5
local goldAwardIncrease = 4
local EXPAwardIncrease = 4

local function spawnEnemyBoat(boatname,pos)
	local boat = ReplicatedStorage.PirateBoats:FindFirstChild(boatname):Clone()
	
	local rand = math.random(1,eliteBoatChance)
	local elite = false
	if rand == 1 then -- elite boat
		elite = true 
		
		local normalHealth = boat:GetAttribute("MaxHealth")
		boat:SetAttribute("MaxHealth", normalHealth * eliteHealthIncrease)
		boat:SetAttribute("Health", normalHealth * eliteHealthIncrease)
		boat:SetAttribute("Damage", boat:GetAttribute("Damage") * eliteAttackIncrease)
		boat:SetAttribute("GoldAward", boat:GetAttribute("GoldAward") * goldAwardIncrease)
		boat:SetAttribute("EXPAward", boat:GetAttribute("EXPAward") * EXPAwardIncrease)
	end
	
	-- set sail color
	if elite then
		gameplayhelper:changeBoatThemeColor(boat, "Yellow")
	else
		gameplayhelper:changeBoatThemeColor(boat, "Black")
	end
	
	-- give unique name
	local count = 1
	while workspace.ActiveBoats:FindFirstChild(boatname..count) ~= nil do
		count = count + 1
	end
	boat.Name = boatname..count
	
	-- set attributes
	boat:SetAttribute("BoatType", "EnemyNPC")
	boat:SetAttribute("Target", "")
	boat:SetAttribute("AutoAttack", false)
	boat:SetAttribute("Shield", false)
	boat:SetAttribute("Elite", elite)
	
	-- spawn
	boat.PrimaryPart = boat:FindFirstChild("MainBody")
	boat:SetPrimaryPartCFrame(pos + Vector3.new(0,30,0)) 


	-- give scripts
	local BoatScript = ReplicatedStorage.Assets.BoatNPCScript:Clone()
	BoatScript.Parent = boat
	local cannonScript = ReplicatedStorage.Assets.BoatCannonManager:Clone()
	cannonScript.Parent = boat
	boat.MainBody.HealthBarGui.OwnerName.Text = boat:GetAttribute("Owner")
	--boat.MainBody.HealthBarGui.Green.BackgroundColor3 = Color3.fromRGB(255, 57, 75)
	boat.Parent = workspace.ActiveBoats
	return boat
end

local function consistentSpawning(spawnPoint, boatName)
	local boat = spawnEnemyBoat(boatName,spawnPoint.CFrame)
	local respawning = false
	boat.AttributeChanged:Connect(function(name)
		if respawning == false and name == "Health" and boat:GetAttribute("Health") <= 0 then
			respawning = true
			if boat:GetAttribute("Elite") == true then
				wait(eliteBoatSpawnCooldown)
			else
				wait(spawncooldown)
			end
			consistentSpawning(spawnPoint, boatName)
		end
	end)
end

for i = 1, #spawnRegions do
	region = spawnRegions[i]
	spawnPoints = region:GetChildren()
	local boatName = region:GetAttribute("SpawnBoatName")
	for j = 1, #spawnPoints do
		local spawnPoint = spawnPoints[j]
		consistentSpawning(spawnPoint, boatName)
	end
end

--spawnEnemyBoat("ArabicAlphaNPC",CFrame.new(2705.375, 310.757, -583.687))
--spawnEnemyBoat("BlackPearlNPC",CFrame.new(3005.375, 310.757, -583.687))
--spawnEnemyBoat("WandererNPC",CFrame.new(2700.375, 310.757, -583.687))