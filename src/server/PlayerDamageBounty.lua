
ReplicatedStorage = game.ReplicatedStorage
Events = ReplicatedStorage.Events
Assets = ReplicatedStorage.Assets
DamageShow = Events.ShowDamage
buffmodule = require(game.ReplicatedStorage.CharacterBuffModule)


maxBounty = 500

function damageanalysis(player,part,damage)
	
	local model = part:FindFirstAncestorWhichIsA("Model")
	
	if model:FindFirstChild("Humanoid") ~= nil and model.Name ~= player.Name then
		local humanoid = model:FindFirstChild("Humanoid")
		
		if humanoid.Health <= 0 then -- is the humanoid already dead?
			return 
		end
		
		local color = Color3.fromRGB(255,255,255)
		if part.Name == "Head" then -- did the player headshot?
			damage = damage * 2
			color = Color3.fromRGB(255,0,0)
		end
		
		-- player buffs
		local info = buffmodule.index[player.PlayerDataFolder.CurrentCharacter.Value]
		if info.Type == "Damage" then
			damage = math.round(damage * (info.Percentage / 100 + 1))
		end
		
		if game.Players:FindFirstChild(model.Name) ~= nil then -- check for PVP
			local otherplayer = game.Players:FindFirstChild(model.Name)
			if player:GetAttribute("PVP") == false or otherplayer:GetAttribute("PVP") == false then
				print("one player did not open PVP")
				DamageShow:FireClient(player,part.Position,0,Color3.fromRGB(255,255,0))
				return
			end
		end
		
		if model:GetAttribute("Innocent") == true then -- is the player attacking innocent NPC?
			DamageShow:FireClient(player,part.Position,0,Color3.fromRGB(255,255,0))
			return
		end
		if model.Humanoid.DisplayName == "Training Dummy" then -- player hitting training dummy
			Events.QuestProgressServer:Fire(player,"DummyHitting", 1)
			DamageShow:FireClient(player,part.Position,damage,color)
			return
		end
		
		if humanoid.Health - damage <= 0 then -- did the player kill the damaged humanoid?
			humanoid.Health = 0
			print("player"..player.Name.." killed "..model.Name)
			DamageShow:FireClient("KILL",Color3.fromRGB(255,0,0))
			Events.QuestProgressServer:Fire(player,"EnemyKilling", 1) -- quest event 
			
			if game.Players:FindFirstChild(model.Name) ~= nil then	 -- determine bounty earned and deducted
				local gold = game.Players:FindFirstChild(model.Name).PlayerDataFolder.Gold
				local bounty = game.Players:FindFirstChild(model.Name).PlayerDataFolder.Bounty
				
				if bounty ~= 0 then
					player.PlayerDataFolder.Gold.Value = player.PlayerDataFolder.Gold.Value + bounty
					gold.Value = math.max(0,gold.Value - bounty.Value)
					bounty.Value = 0
				end
			elseif model:FindFirstChild("Bounty") ~= nil then
				local bountyvalue = model:FindFirstChild("Bounty").Value
				player.PlayerDataFolder.Gold.Value = player.PlayerDataFolder.Gold.Value + bountyvalue
			end
		else -- damaged, did not die
			humanoid.Health = humanoid.Health - damage
			DamageShow:FireClient(player,part.Position,damage,color)
		end
		
		-- increased bounty by damaging players
		--if game.Players:FindFirstChild(model.Name) ~= nil then
			local bounty = player:FindFirstChild("PlayerDataFolder"):FindFirstChild("Bounty")
			local increasedamount = math.random(1,5)
			bounty.Value = math.clamp(bounty.Value + increasedamount, 0, maxBounty)
			wait(0.3)
			DamageShow:FireClient(player,part.Position,"Bounty + "..increasedamount,Color3.fromRGB(255,255,0))
		--end
	end
end

function givedamage(player,touch,object,damage,timespan)
	
	if touch == false then
		damageanalysis(player,object,damage)
	end
	
	local connection
	local touched = false
	
	connection = object.Touched:Connect(function(part)
		if touched == false then
			damageanalysis(player,part,damage)
		end
	end)
	
	wait(timespan)
	connection:Disconnect()
end

function changePlayerHealth(player, amount)
	local humanoid = player.Character:FindFirstChild("Humanoid")
	humanoid.Health = humanoid.Health + amount
end

Events.ChangePlayerHealth.OnServerEvent:Connect(changePlayerHealth)
Events.GiveDamage.Event:Connect(givedamage)



