
local player = game.Players.LocalPlayer
local char = player.Character or workspace:WaitForChild(player.Name,30)
local hum = char:WaitForChild("Humanoid")
local root = hum.RootPart -- The HumanoidRootPart
local PlayerGui = player.PlayerGui
local BindableEvents = PlayerGui.BindableEvents
local RS = game.ReplicatedStorage
local Events = RS.Events

local playerdatafolder = player:WaitForChild("PlayerDataFolder",30)
local BankGui = PlayerGui.BankGui
local BankFrame = BankGui.BankFrame
local PlayerInventory = BankFrame.PlayerInventory
local BankInventory = BankFrame.BankInventory
local inventoryframes = RS.InventoryFrames
local uigridlayout = inventoryframes.UIGridLayout
local NoticeEvent = BindableEvents.NoticeEvent

local inventoryhelper = require(player.PlayerScripts.InventoryHelper)
local bankpage = 1
local playerpage = 1
local maxitems = 16
local itemperpage = 16
local maxbankitems = 16 -- playerdatafolder.InventoryData.MaxBankItems.Value
local maxplayeritems = 48 -- playerdatafolder.InventoryData.MaxInventoryItems.Value
AssetEvent = Events.GiveAsset
TakeAssetEvent = Events.TakeAsset
local inputconfig = require(player.PlayerScripts.InputConfig)

BankGui.Enabled = true
BankFrame.Visible = false

local function clickitem(kind,frame)
	local textbutton = frame.TextButton
	textbutton.InputBegan:Connect(function(input)
		if inputconfig:CheckInput(input) then
			if kind == "Collectibles" then
				local bankitems = playerdatafolder.BankCollectibles:GetChildren()
				if #bankitems >= maxbankitems then
					NoticeEvent:Fire("Bank storage limit reached!","Red")
				else
					AssetEvent:FireServer("BankCollectibles",frame.Name)
					TakeAssetEvent:FireServer("Collectibles",frame.Name)
				end
			elseif kind == "BankCollectibles" then
				local playeritems = playerdatafolder.Collectibles:GetChildren()
				if #playeritems >= maxplayeritems then
					NoticeEvent:Fire("Player inventory limit reached!","Red")
				else
					AssetEvent:FireServer("Collectibles",frame.Name)
					TakeAssetEvent:FireServer("BankCollectibles",frame.Name)
				end
				
			end
		end
	end)
end

local function updateinventory(page,kind,displayitems)
	
	--player inventory update
	displayitems:ClearAllChildren()
	local items = playerdatafolder[kind]:GetChildren()

	inventoryhelper:Sort(items,"Name")
	local x,y = inventoryhelper:PageDisplay(page,items,maxitems)

	for i = x, y do
		local item = items[i]
		local frametemplate =  inventoryhelper:LoadItemFrame("Collectibles",item.Name)
		frametemplate.Parent = displayitems
		clickitem(kind,frametemplate)
	end

	local grid = uigridlayout:Clone()
	grid.Parent = displayitems
end

local function updateplayerpage(pagechange) 
	local items = playerdatafolder:FindFirstChild("Collectibles"):GetChildren()
	if inventoryhelper:PageChange(playerpage + pagechange,items,itemperpage,10)  then
		playerpage += pagechange
		PlayerInventory.PageNumber.Text = "<b> Page "..playerpage.." </b>"
		updateinventory(playerpage,"Collectibles",PlayerInventory.Items)
	end
end

local function updatebankpage(pagechange)
	local items = playerdatafolder:FindFirstChild("BankCollectibles"):GetChildren()
	if inventoryhelper:PageChange(bankpage + pagechange,items,itemperpage,10)  then
		bankpage += pagechange
		BankInventory.PageNumber.Text = "<b> Page "..bankpage.." </b>"
		updateinventory(bankpage,"BankCollectibles",BankInventory.Items)
	end
end

-- events connections

updateinventory(playerpage,"Collectibles",PlayerInventory.Items)
updateinventory(bankpage,"BankCollectibles",BankInventory.Items)

playerdatafolder.Collectibles.ChildAdded:Connect(function()
	updateinventory(playerpage,"Collectibles",PlayerInventory.Items)
end)

playerdatafolder.Collectibles.ChildRemoved:Connect(function()
	updateinventory(playerpage,"Collectibles",PlayerInventory.Items)
end)

playerdatafolder.BankCollectibles.ChildAdded:Connect(function()
	updateinventory(bankpage,"BankCollectibles",BankInventory.Items)
end)

playerdatafolder.BankCollectibles.ChildRemoved:Connect(function()
	updateinventory(bankpage,"BankCollectibles",BankInventory.Items)
end)

BankFrame.CloseButton.InputBegan:Connect(function(input)
	if inputconfig:CheckInput(input) then
		BankFrame.Visible = false
	end
end)

BankInventory.NextButton.InputBegan:Connect(function(input)
	if inputconfig:CheckInput(input) then
		updatebankpage(1)
	end
end)

BankInventory.PrevButton.InputBegan:Connect(function(input)
	if inputconfig:CheckInput(input) then
		updatebankpage(-1)
	end
	
end)

PlayerInventory.NextButton.InputBegan:Connect(function(input)
	if inputconfig:CheckInput(input) then
		updateplayerpage(1)
	end
	
end)

PlayerInventory.PrevButton.InputBegan:Connect(function(input)
	if inputconfig:CheckInput(input) then
		updateplayerpage(-1)
	end
	
end)

Events.BankEvent.OnClientEvent:Connect(function()
	updateinventory(playerpage,"Collectibles",PlayerInventory.Items)
	updateinventory(bankpage,"BankCollectibles",BankInventory.Items)
	BankFrame.Visible = true
end)