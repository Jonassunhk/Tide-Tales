
ReplicatedStorage = game.ReplicatedStorage
Events = ReplicatedStorage.Events
Assets = ReplicatedStorage.Assets

EquipEvent = Events.EquipEvent
CastFilter = Events.CastFilter

function equip(player,name,equiptype)
	
	local tool = player.Backpack:FindFirstChild(name)
	
	if tool == nil and equiptype == "Gun" then
		tool = ReplicatedStorage.Weapons:FindFirstChild(name):Clone()
		--tool:SetAttribute("Ammo", tool:GetAttribute("MaxAmmo"))
		tool.Parent = player.Backpack
	end
	
	if tool ~= nil then
		print("equipped")
		local hum = player.Character.Humanoid
		
		hum:UnequipTools()
		hum:EquipTool(tool)
				
		if equiptype == "Gun" then
			CastFilter:Fire(player,tool)
		end
	end
end

EquipEvent.OnServerEvent:Connect(equip)

-- preset ammo for all guns
local weapons = ReplicatedStorage.Weapons:GetChildren()
for i = 1, #weapons do
	if weapons[i]:GetAttribute("MaxAmmo") ~= nil then
		weapons[i]:SetAttribute("Ammo", weapons[i]:GetAttribute("MaxAmmo"))
	end
end

