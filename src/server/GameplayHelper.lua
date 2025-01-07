local gameplayhelper = {}


ReplicatedStorage = game.ReplicatedStorage
Events = ReplicatedStorage.Events
Assets = ReplicatedStorage.Assets

local CurrentNPC = workspace.NPC
local CurrentEnemyNPC = workspace.EnemyNPC
local Boats = workspace.ActiveBoats
local tagservice = game:GetService("CollectionService")
local EnemyNPC = ReplicatedStorage.EnemyNPC

local debris = game:GetService("Debris")
local ShowDamage = Events.ShowDamage
local NoticeEvent = Events.NoticeEvent
local QuestEvent = Events.QuestProgressServer
local PVPEvent = Events.PVPEvent

local buffmodule = require(game.ReplicatedStorage.CharacterBuffModule)


function gameplayhelper.findNearestEnemy(selfobj: Instance,pos: Vector3,targetdis: number)
	local list = CurrentEnemyNPC:GetChildren()
	if targetdis == nil then
		targetdis = 1000000
	end
	local temp = nil
	local dis = 10000000
	
	for i = 1, #list do
		local temp2 = list[i]
		if (temp2.className == "Model") then
			local rootpart = temp2:findFirstChild("HumanoidRootPart")
			local humanoid = temp2:findFirstChild("Humanoid")
			
			if rootpart ~= nil and humanoid ~= nil and humanoid.Health > 0 then
				if (rootpart.Position - pos).Magnitude < dis then
					temp = temp2
					dis = (temp.Position - pos).Magnitude
				end
			end
		end
	end
	if temp ~= nil and dis < targetdis then
		local rootpart = temp:findFirstChild("HumanoidRootPart")
		return temp,rootpart
	end
end

function gameplayhelper:findNearestBoat(selfobj: Instance,pos: Vector3,targetdis: number)
	local list = Boats:GetChildren()
	if targetdis == nil then
		targetdis = 1000000
	end
	local temp = nil
	local dis = 10000000
	for i = 1, #list do
		local temp2 = list[i]
		if (temp2.className == "Model") and temp2.Name ~= selfobj.Name then
			local rootpart = temp2:findFirstChild("MainBody")
			if rootpart ~= nil and temp2:GetAttribute("Health") > 0 then
				if (rootpart.Position - pos).Magnitude < dis then
					temp = temp2
					dis = (rootpart.Position - pos).Magnitude
				end
			end
		end
	end
	if temp ~= nil and dis < targetdis then
		local rootpart = temp:findFirstChild("MainBody")
		return temp,rootpart
	end
end

function gameplayhelper:findNearestBoatOfType(selfobj: Instance,pos: Vector3,targetdis: number, boatType: string)
	local list = Boats:GetChildren()
	if targetdis == nil then
		targetdis = 1000000
	end
	local temp = nil
	local dis = 10000000
	for i = 1, #list do
		local temp2 = list[i]
		if (temp2.className == "Model") and temp2.Name ~= selfobj.Name and temp2:GetAttribute("BoatType") == boatType then
			local rootpart = temp2:findFirstChild("MainBody")
			if rootpart ~= nil and temp2:GetAttribute("Health") > 0 then
				if (rootpart.Position - pos).Magnitude < dis then
					temp = temp2
					dis = (rootpart.Position - pos).Magnitude
				end
			end
		end
	end
	if temp ~= nil and dis < targetdis then
		local rootpart = temp:findFirstChild("MainBody")
		return temp,rootpart
	end
end

function gameplayhelper:changeBoatThemeColor(boat, colorName)
	local color = script:FindFirstChild(colorName).Value
	if color ~= nil and boat:FindFirstChild("SailColors") ~= nil then
		local sailcolors = boat:FindFirstChild("SailColors"):GetChildren()
		for i = 1, #sailcolors do
			if sailcolors[i]:IsA("Beam") then
				sailcolors[i].Color = ColorSequence.new{
					ColorSequenceKeypoint.new(0, color),
					ColorSequenceKeypoint.new(1, color),
				}
			elseif sailcolors[i]:IsA("BasePart") then
				sailcolors[i].Color = color
			end
		end
	end
	boat.MainBody.HealthBarGui.Frame.BackgroundColor3 = color
	if colorName == "Yellow" then -- the text should be black color if the background color is bright
		boat.MainBody.HealthBarGui.OwnerName.TextColor3 = Color3.fromRGB(0,0,0)
	end
end
	
function gameplayhelper:findNearestPlayer(pos: Vector3,targetdis: number,player: Instance)
	
	if targetdis == nil then
		targetdis = 1000000
	end
	
	local players = game.Players:GetChildren()
	local temp = nil
	local dis = 10000000
	
	for i = 1, #players do
		if player ~= nil and (players[i].Team == player.Team or players[i] == player) then
			continue
		end
		local character = players[i].Character
		if character ~= nil then
			local rootpart = character:FindFirstChild("HumanoidRootPart")
			local humanoid = character:findFirstChild("Humanoid")
			
			if rootpart ~= nil and humanoid ~= nil and humanoid.Health > 0 then
				if (rootpart.Position - pos).Magnitude < dis then
					temp = character
					dis =  (rootpart.Position - pos).Magnitude
				end
			end
		end
	end
	
	if temp ~= nil and dis < targetdis then
		local rootpart = temp:findFirstChild("HumanoidRootPart")
		return temp,rootpart
	end
end	

function gameplayhelper:GiveDamage(char: Instance,instance: Instance,damageamount: number,duration: number,targettag: string)
	local damage
	local listofdamage = {}
	if instance == nil then return end
	damage = instance.Touched:Connect(function(part)
		if part.Parent:FindFirstChild("Humanoid") ~= nil and part.Parent ~= char then
			local onlist = false
			for i = 1, #listofdamage do
				if part.Parent == listofdamage[i] then
					onlist = true
				end
			end
			if onlist == false and tagservice:HasTag(part.Parent,targettag) then
				listofdamage[#listofdamage + 1] = part.Parent 
				local humanoid = part.Parent:FindFirstChild("Humanoid")
				humanoid.Health = humanoid.Health - damageamount
			end
		end
	end)
	wait(duration)
	damage:Disconnect()
end

-- track damage 
function gameplayhelper:UpdateModelDamageTracker(model: Instance, name: string, damageAmount: number)
	local damageTracker = model:FindFirstChild("DamageTracker")
	if damageTracker == nil then
		damageTracker = Instance.new("Folder")
		damageTracker.Name = "DamageTracker"
		damageTracker.Parent = model
	end
	local damage = damageTracker:FindFirstChild(name)
	if damage == nil then
		damage = Instance.new("IntValue")
		damage.Name = name
		damage.Parent = damageTracker
	end
	damage.Value = damage.Value + damageAmount
end

-- percentage of damage dealt
function gameplayhelper:CheckDamageTrackerPercentage(model: Instance, name: string)
	local damageTracker = model:FindFirstChild("DamageTracker") -- damage tracker doesn't exist
	if damageTracker == nil then
		return 0
	end
	local damage = damageTracker:FindFirstChild(name) -- the player did not do any damage
	if damage == nil then
		return 0
	end
	local maxDamage = 0
	local damageDealers = damageTracker:GetChildren()
	for i = 1, #damageDealers do
		maxDamage += damageDealers[i].Value
	end
	return damage / maxDamage
end

function findBoatModel(model)
	if model == workspace then 
		return nil
	elseif model:GetAttribute("Health") ~= nil and model:GetAttribute("Health") > 0 then
		return model
	else
		return findBoatModel(model.Parent)
	end
end

function gameplayhelper:CheckPVP(player1, player2)
	return player1:GetAttribute("PVP") == true and player2:GetAttribute("PVP") == true
end

function gameplayhelper:DamageBoat(originalModel, player, originPos, damage, critProbability)
	
	local model = findBoatModel(originalModel)
	if model == nil then
		return
	end
	
	if model:GetAttribute("BoatType") == "Decoy" then
		ShowDamage:FireClient(player,originPos, damage, Color3.fromRGB(150,150,150))
		QuestEvent:Fire(player, "DecoyHitting", 1)
		return
	end

	-- check if boat has shield
	if model:GetAttribute("Shield") ~= nil and model:GetAttribute("Shield") == true then 
		if player ~= nil then
			ShowDamage:FireClient(player,originPos, 0, Color3.fromRGB(150,150,150))
		end
		return
	end
	
	-- if player vs player, check if pvp for both players are on
	local damagedBoatOwner = model:GetAttribute("Owner")
	if game.Players:FindFirstChild(damagedBoatOwner) ~= nil and player ~= nil then
		local player2 = game.Players:FindFirstChild(damagedBoatOwner)
		
		if self:CheckPVP(player, player2) == true then -- both players have pvp ON, reset timer for both players
			PVPEvent:FireClient(player,"Reset")
			PVPEvent:FireClient(player2,"Reset")
		else
			ShowDamage:FireClient(player,originPos,0, Color3.fromRGB(255,255,0))
			return
		end
	end
	
	-- critical hit
	local criticalHit = false
	local health = model:GetAttribute("Health")
	
	if critProbability > 0 then
		local critChance = math.random(1,critProbability) 
		if critChance == 1 then
			criticalHit = true
			damage = damage * 2
		end
	end
	

	if player ~= nil then -- only for players
		if model:GetAttribute("BoatType") == "EnemyNPC" then -- update damage tracker
			print("Updating damage tracker: "..player.Name.." dealt "..damage.." damage")
			self.UpdateModelDamageTracker(self, model, player.Name, damage)
		end
		if (health - damage) <= 0 then
				--NoticeEvent:FireClient(player,"Boat destroyed!","Yellow")
			QuestEvent:Fire(player,"BoatSinking", 1)
			QuestEvent:Fire(player,"Defeating"..model:GetAttribute("Owner"), 1)
			if model:GetAttribute("Elite") == true then
				QuestEvent:Fire(player,"DefeatingElite"..model:GetAttribute("Owner"), 1)
			end
		else
			--NoticeEvent:FireClient(player,"Boat hit")
		end
		if criticalHit then
			ShowDamage:FireClient(player,originPos,damage, Color3.fromRGB(255,0,0))
		else
			ShowDamage:FireClient(player,originPos,damage)
		end
		QuestEvent:Fire(player,"BoatDamaging", damage)
	end

	if (health - damage) <= 0 and model:GetAttribute("BoatType") == "EnemyNPC" then

		local goldAward = model:GetAttribute("GoldAward") -- give gold
		if goldAward ~= nil then
			print(model.Name.." sunk, giving gold of total "..goldAward.." to players")
			self.AllocatePlayerDamageCurrency(self, model, "Gold", goldAward)
		end
		local expAward = model:GetAttribute("EXPAward") -- give exp
		if expAward ~= nil then
			print(model.Name.." sunk, giving EXP of total "..expAward.." to players")
			self.AllocatePlayerDamageCurrency(self, model, "Experience", expAward)
		end
	end
	model:SetAttribute("Health",math.max(0,health - damage))
	return
end

function gameplayhelper:AllocatePlayerDamageCurrency(model: Instance, currencyType: string, totalCurrency: number)
	local damageTracker = model:FindFirstChild("DamageTracker") -- damage tracker doesn't exist
	if damageTracker == nil then
		print("damage tracker does not exist")
		return
	end
	local damageDealers = damageTracker:GetChildren()
	
	local maxDamage = 0 -- calculate max damage
	for i = 1, #damageDealers do
		maxDamage += damageDealers[i].Value
	end
	
	for i = 1, #damageDealers do
		local damageDealer = damageDealers[i]
		local player = game.Players:FindFirstChild(damageDealer.Name)
		if player ~= nil then
			local playerCurrency = math.floor(damageDealer.Value / maxDamage * totalCurrency) 
			Events.ChangeCurrency:Fire(player, currencyType, playerCurrency)
		end
	end
end

function gameplayhelper:SpawnEnemy(location: CFrame,name: string,randomfactor: number)
	
	local offset = Vector3.new(0,0,0)
	if randomfactor ~= nil then
		local randomx = math.random(0,randomfactor * 2) - randomfactor
		local randomz = math.random(0,randomfactor * 2) - randomfactor
		offset = Vector3.new(randomx,0,randomz)
	end
	local enemy
	if name == "Random" then
		local enemies = EnemyNPC:GetChildren()
		local randomnum = math.random(1,#enemies)
		enemy = enemies[randomnum]:Clone()
	else
		enemy = EnemyNPC:FindFirstChild(name):Clone()
	end
	if enemy ~= nil then
		local damagescript = Assets.DamageScript:Clone()
		damagescript.Parent = enemy
		enemy:WaitForChild("HumanoidRootPart").CFrame = location + Vector3.new(0,5,0) + offset
		enemy.Parent = CurrentEnemyNPC
		tagservice:AddTag(enemy,"Enemy")
	else
		warn("Enemy not found")
	end
end
	
return gameplayhelper
