
ReplicatedStorage = game.ReplicatedStorage
Events = ReplicatedStorage.Events
Assets = ReplicatedStorage.Assets

boostParticles = ReplicatedStorage.Effects.BoostParticles
shieldParticles = ReplicatedStorage.Effects.ShieldParticles
healParticles = ReplicatedStorage.Effects.HealParticles


local function shield(player, duration)
	local boat = workspace.ActiveBoats:FindFirstChild(player.Name.."Boat")
	
	if boat ~= nil then
		boat:SetAttribute("Shield", true)
		
		local particles = shieldParticles:Clone()
		particles.Parent = boat.MainBody
		
		wait(duration)
		
		particles:Destroy()
		boat:SetAttribute("Shield", false)
	end
end

local function boost(player, duration, amount)
	local boat = workspace.ActiveBoats:FindFirstChild(player.Name.."Boat")
	if boat ~= nil then
		local originalMaxSpeed = boat:GetAttribute("MaxSpeed")
		local originalAcceleration = boat:GetAttribute("Acceleration")

		boat:SetAttribute("MaxSpeed", originalMaxSpeed + amount)
		boat:SetAttribute("Acceleration", originalAcceleration + amount * 3)
		
		local particles = boostParticles:Clone()
		particles.Parent = boat.MainBody
		
		wait(duration)
		
		particles:Destroy()
		boat:SetAttribute("MaxSpeed", originalMaxSpeed)
		boat:SetAttribute("Acceleration", originalAcceleration)
	end
end

local function SlowHeal(player, ticks, totalTime, totalAmount)
	local boat = workspace.ActiveBoats:FindFirstChild(player.Name.."Boat")
	if boat ~= nil then
		
		local tickAmount = math.round(totalAmount / ticks)
		local tickTimeInterval = math.round(totalTime / ticks)
		
		local prevHealth = boat:GetAttribute("Health")
		local damaged = false
		local event
		local particles = healParticles:Clone()
		particles.Parent = boat.MainBody
		
		event = boat.AttributeChanged:Connect(function(name) -- stop healing when damaged
			if name == "Health" and boat:GetAttribute("Health") < prevHealth then
				damaged = true
				event:Disconnect()
				particles:Destroy()
			end
			prevHealth = boat:GetAttribute("Health")
		end)
		
		local prevHealth = boat:GetAttribute("Health")
		for i = 1, ticks do
			if damaged then break end
			boat:SetAttribute("Health", math.clamp(boat:GetAttribute("Health") + tickAmount, 0, boat:GetAttribute("MaxHealth")))
			wait(tickTimeInterval)
		end
		if event ~= nil then
			event:Disconnect()
			particles:Destroy()
		end
	end
	
end

Events.ShieldRemoteEvent.OnServerEvent:Connect(shield)
Events.BoostRemoteEvent.OnServerEvent:Connect(boost)
Events.SlowHealRemoteEvent.OnServerEvent:Connect(SlowHeal)



