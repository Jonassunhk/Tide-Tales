

ReplicatedStorage = game.ReplicatedStorage
Events = ReplicatedStorage.Events
Assets = ReplicatedStorage.Assets

gunshops = workspace.GunShops:GetChildren()
boatshops = workspace.BoatShops:GetChildren()

for i = 1, #gunshops do
	gunshop = gunshops[i]
	gunshop.ProximityPart.ProximityPrompt.Triggered:Connect(function(player)
		Events.GunShopEvent:FireClient(player)
	end)
end


for i = 1, #boatshops do
	boatshop = boatshops[i]
	boatshop.ProximityPart.ProximityPrompt.Triggered:Connect(function(player)
		Events.BoatShopEvent:FireClient(player)
	end)
end




