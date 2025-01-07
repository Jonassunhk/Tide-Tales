
ReplicatedStorage = game.ReplicatedStorage
Events = ReplicatedStorage.Events
Assets = ReplicatedStorage.Assets

local PhysicsService = game:GetService("PhysicsService")
local informevent = Events.InformEvent
characters = workspace.NPC:GetChildren()
local CollisionEvent = Events.SetCollision
local animations = ReplicatedStorage.Animations
local tradeevent = Events:FindFirstChild("TradeEvent")
local addquestevent = Events.AddQuestEvent

function dialogue(player,character,dialogues)
	local list = dialogues:GetChildren()
	for i = 1, #list do
		local text = dialogues:FindFirstChild(i)
		local name = character.Name
		if name == "Gold Merchant" or name == "Silver Merchant" or name == "Emerald Merchant" then
			name = "Merchants"
		end
		local back = informevent:InvokeClient(player,text.Value,name)
	end
end

function trade(character)
	
	local billboard = ReplicatedStorage.Assets.TradeBillboard:Clone() -- adding billboard
	billboard.Parent = character.Head
	billboard.CharacterName.Text = character.Name
	
	local ProximityPrompt = Assets.ProximityPrompt.TradePrompt:Clone()
	ProximityPrompt.Parent = character.HumanoidRootPart
	ProximityPrompt.ObjectText = character.Name

	ProximityPrompt.Triggered:Connect(function(player)
		local dialogues = character.Trade.Dialogues
		dialogue(player,character,dialogues)
		
		local trade = character.Trade
		local tradeofferinfo = {
			TraderName = "Merchants",
			PlayerGive = {
				Category = trade.Player.Category.Value,
				ItemName = trade.Player.Item.Value,
				Amount = trade.Player.Amount.Value
			},
			TraderGive = {
				Category = trade.Merchant.Category.Value,
				ItemName = trade.Merchant.Item.Value,
				Amount = trade.Merchant.Amount.Value
			}
		}
		tradeevent:FireClient(player,tradeofferinfo)
		
	end)
end


function InnocentNPCSetup(character)
	
	character:SetAttribute("Innocent",true)
	
	if character:FindFirstChild("Trade") ~= nil then trade(character) end
--	CollisionEvent:Fire(character,"InnocentNPC")
	
	local animation = animations.Idle
	character.HumanoidRootPart.Anchored = true
	local humanoid = character:FindFirstChild("Humanoid")
	humanoid.MaxHealth = 1000000
	humanoid.Health = 1000000
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	local idle = humanoid:LoadAnimation(animation)
	idle.Looped = true
	idle:Play()
	
	if character:FindFirstChild("Dialogues") ~= nil then
		local dialogues = character:FindFirstChild("Dialogues")
		
		local ProximityPrompt = Assets.ProximityPrompt.ChatPrompt:Clone()
		ProximityPrompt.Parent = character.HumanoidRootPart
		ProximityPrompt.ObjectText = character.Name
		
		ProximityPrompt.Triggered:Connect(function(player)
			dialogue(player,character,dialogues)
		end)
	end
	
end

for i = 1, #characters do
	character = characters[i]
	InnocentNPCSetup(character)
end

