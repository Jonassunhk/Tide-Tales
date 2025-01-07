
local player = game.Players.LocalPlayer
local char = player.Character or workspace:WaitForChild(player.Name,30)
local hum = char:WaitForChild("Humanoid")
local root = hum.RootPart -- The HumanoidRootPart
local PlayerGui = player.PlayerGui
local BindableEvents = PlayerGui.BindableEvents
local RS = game.ReplicatedStorage
local Events = RS.Events

local datafolder = player:WaitForChild("PlayerDataFolder")
local characterviewport = BindableEvents.CharacterViewport
local LoadViewport = BindableEvents.LoadViewport
local tradegui = PlayerGui.TradeGui
local inventoryframes = RS.InventoryFrames
local collectibleimages = RS.CollectiblesImages
local NoticeEvent = BindableEvents.NoticeEvent
local collectibles = RS.Collectibles
local TradeEvent = Events.TradeEvent
local inputconfig = require(player.PlayerScripts.InputConfig)

local currencyevent = Events.RemoteChangeCurrency
local takeasset = Events.TakeAsset
local giveasset = Events.GiveAsset
tradegui.Enabled = true
tradegui.Frame.Visible = false

local function determine(category,itemname,amount)
	if category == "Currency" then
		return datafolder:FindFirstChild(itemname).Value >= amount
	end
	local currentamount = 0
	local categoryitems = datafolder:FindFirstChild(category):GetChildren()
	
	for i = 1, #categoryitems do
		if categoryitems[i].Name == itemname then
			currentamount = currentamount + 1
		end
	end
	
	return currentamount >= amount
end

local tradeoffersample = { -- sample trade offer format
	TraderName = "Merchants",
	PlayerGive = {
		Category = "Collectibles",
		ItemName = "Gold Bar",
		Amount = 3
	},
	TraderGive = {
		Category = "Currency",
		ItemName = "Gold",
		Amount = 2938
	}
}

local function loaditem(category,itemname,targetframe) -- only collectibles for now
	local image,frame
	if category == "Currency" then
		frame = inventoryframes:FindFirstChild("RareFrame"):Clone()
	else
		local item = RS:FindFirstChild(category):FindFirstChild(itemname)
		local rarity = item:GetAttribute("Rarity")
		frame = inventoryframes:FindFirstChild(rarity.."Frame"):Clone()
	end
	image = collectibleimages:FindFirstChild(itemname):Clone()
	frame.Parent = targetframe.Parent
	frame.Size = targetframe.Size
	frame.Position = targetframe.Position
	image.Parent = frame
end

local function tradeoffer(tradeofferinfo)
	local frame = tradegui.Frame:Clone()
	frame.Parent = tradegui
	frame.Visible = true
	
	local traderitem = tradeofferinfo.TraderGive
	local playeritem = tradeofferinfo.PlayerGive
	
	frame.PlayerName.Text = player.Name
	frame.TraderName.Text = tradeofferinfo.TraderName
	frame.PlayerItem.Text = playeritem.ItemName.." x "..playeritem.Amount
	frame.TraderItem.Text = traderitem.ItemName.." x "..traderitem.Amount
	frame.TradeInformation.Text = "Give "..playeritem.Amount.." "..playeritem.ItemName.." for "..tradeofferinfo.TraderName.."'s "..traderitem.Amount.." "..traderitem.ItemName
	
	loaditem(playeritem.Category,playeritem.ItemName,frame.PlayerGive)
	loaditem(traderitem.Category,traderitem.ItemName,frame.MerchantGive)
	
	local character = RS.Characters:FindFirstChild(tradeofferinfo.TraderName)
	if character ~= nil then
		characterviewport:Fire(frame.CharacterViewport,character)
	end
	frame.DeclineButton.InputBegan:Connect(function(input)
		if inputconfig:CheckInput(input) then
			NoticeEvent:Fire("Trade offer declined")
			frame:Destroy()
		end
	end)
	
	frame.AcceptButton.InputBegan:Connect(function(input)

		if inputconfig:CheckInput(input) then
			if determine(playeritem.Category,playeritem.ItemName,playeritem.Amount) then
				NoticeEvent:Fire("Trade Successful")
				BindableEvents.QuestEvent:Fire("MerchantTrade")
				if playeritem.Category == "Currency" then
					currencyevent:FireServer(playeritem.ItemName,-playeritem.Amount)
				else
					takeasset:FireServer(playeritem.Category,playeritem.ItemName,playeritem.Amount)
				end 
				if traderitem.Category == "Currency" then
					currencyevent:FireServer(traderitem.ItemName,traderitem.Amount)
				else
					giveasset:FireServer(traderitem.Category,traderitem.ItemName,traderitem.Amount)
				end
				frame:Destroy()
				
			else
				NoticeEvent:Fire("Not enough material",Color3.new(255,0,0))
				frame:Destroy()
			end
		end
	end)
end

TradeEvent.OnClientEvent:Connect(tradeoffer)

