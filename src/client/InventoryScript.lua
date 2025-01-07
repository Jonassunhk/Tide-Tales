

local player = game.Players.LocalPlayer
local char = player.Character or workspace:WaitForChild(player.Name,30)
local hum = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")-- The HumanoidRootPart
local PlayerGui = player.PlayerGui
local BindableEvents = PlayerGui.BindableEvents
local RS = game.ReplicatedStorage

local backpack = player.Backpack
local inventorygui = PlayerGui.InventoryGui
local inventoryframes = game.ReplicatedStorage.InventoryFrames
local itemlist = inventorygui.InventoryFrame.Items
local playerdatafolder = player:WaitForChild("PlayerDataFolder",30)
local loadviewportevent = BindableEvents.LoadViewport
local NoticeEvent = BindableEvents.NoticeEvent


local uigridlayout = inventoryframes.UIGridLayout
local equipevent = game.ReplicatedStorage.Events.EquipEvent
local connection
local maxitems = 48
local currentpage = 1
local inventorytype = "Weapons"
local inventoryhelper = require(player.PlayerScripts.InventoryHelper)
local inventoryinfo = require(player.PlayerScripts.InventoryInfo)
local inputconfig = require(player.PlayerScripts.InputConfig)
local ContextAction = game:GetService("ContextActionService")

-- formatting 

local enlargedsize = UDim2.new(0.095, 0,0.106, 0)
local smallsize = UDim2.new(0.073, 0,0.077, 0)
local yellowbackground = inventorygui.InventoryFrame.YellowBackground

-- gun inventory variables
local guntools = game.ReplicatedStorage.Weapons
local GunGui = PlayerGui.GunGui

-- collectibles variables

local collectibles = game.ReplicatedStorage.Collectibles
local collectiblesinfo = RS.Collectibles
local collectiblesimages = RS.CollectiblesImages

-- boats variables

local boats = RS.Boats
local boatmodels = RS.BoatModels
local green = Color3.fromRGB(69, 221, 82) 
local grey = Color3.fromRGB(128, 128, 128)
local spawnboatevent = RS.Events.SpawnBoatEvent

inventorygui.Enabled = true
inventorygui.InventoryFrame.Visible = false

local function portavailable()
	local ports = workspace.BoatSpawns:GetChildren()
	local closestport = ports[1]:GetAttribute("CFrame")
	for i = 1, #ports do
		local port = ports[i]:GetAttribute("CFrame")
		if port == nil then 
			warn("No port CFrame information")
			continue
		end
		if closestport == nil or (port.Position - root.Position).Magnitude < (closestport.Position - root.Position).Magnitude then
			closestport = port
		end
	end
	
	if closestport == nil then return end
		
	local boats = workspace.ActiveBoats:GetChildren()
	for i = 1, #boats do
		local boat = boats[i]
		if (boat:FindFirstChild("MainBody") ~= nil) then
			if (boat.MainBody.Position - closestport.Position).Magnitude < 25 then
				NoticeEvent:Fire("Another boat is too close!","Yellow")
				return nil
			end
		end
	end
	if (root.Position - closestport.Position).Magnitude > 15 then
		return nil
	end
	return closestport
end


local function loadcollectiblesinfo(itemname)
	inventoryinfo.ShowInfo("Collectibles",itemname)
end

local function gunitemclicked(toolname) 
	
	local frametemplate = inventoryinfo.ShowInfo("Weapons",toolname).Info
	local tool
	if player.Backpack:FindFirstChild(toolname) == nil then -- player hasn't used the gun yet
		tool = guntools:FindFirstChild(toolname)
	else
		tool = player.Backpack:FindFirstChild(toolname)
	end
	connection = frametemplate.EquipButton.InputBegan:Connect(function(input)
		if inputconfig:CheckInput(input) then
			if tool:GetAttribute("GunType") == "Pistol" then
				local viewport = GunGui.Gun2.ViewportFrame
				loadviewportevent:Fire(viewport,toolname,inventorytype)
				GunGui.Gun2:SetAttribute("CurrentGun",toolname)
				GunGui.AmmoLabel2.Text = tool:GetAttribute("Ammo").." / "..tool:GetAttribute("MaxAmmo")
				NoticeEvent:Fire("Press '2' or click to take out gun")
				
			elseif tool:GetAttribute("GunType") == "Rifle" then
				local viewport = GunGui.Gun1.ViewportFrame
				loadviewportevent:Fire(viewport,toolname,inventorytype)
				GunGui.Gun1:SetAttribute("CurrentGun",toolname)
				GunGui.AmmoLabel1.Text = tool:GetAttribute("Ammo").." / "..tool:GetAttribute("MaxAmmo")
				NoticeEvent:Fire("Press '1' or click to take out gun")
			end
			--equipevent:FireServer(toolname,"Gun")
			--GunGui
		end
	end)
end

function boatclicked(boatname)
	local infoframe = inventoryinfo.ShowInfo("Boats",boatname).Info

	if portavailable() ~= nil then
		infoframe.SpawnButton.BackgroundColor3 = green
		infoframe.FindHarborFrame.Visible = false
	else
		infoframe.SpawnButton.BackgroundColor3 = grey
		infoframe.FindHarborFrame.Visible = true
	end
	connection = infoframe.SpawnButton.InputBegan:Connect(function(input)
		if inputconfig:CheckInput(input) then
			if portavailable() ~= nil then
				local buildCost = game.ReplicatedStorage.Boats:FindFirstChild(boatname):GetAttribute("SpawnCost")
				if playerdatafolder.Gold.Value < buildCost then
					NoticeEvent:Fire("Insufficient Gold","Yellow")
				else
					RS.Events.RemoteChangeCurrency:FireServer("Gold",-buildCost)
					spawnboatevent:FireServer(boatname,portavailable())
				end
			else
				NoticeEvent:Fire("Unable to spawn boat, find unoccupied harbor","Yellow")
			end
		end
	end)
	
end


function clickitem(frame)
	
	local textbutton = frame.TextButton
	textbutton.InputBegan:Connect(function(input)
		if inputconfig:CheckInput(input) then
			if connection ~= nil then connection:Disconnect() end
			
			if inventorytype == "Weapons"  then
				gunitemclicked(frame.Name)
			elseif inventorytype == "Collectibles" then
				loadcollectiblesinfo(frame.Name)
			elseif inventorytype == "Boats" then
				boatclicked(frame.Name)
			end
		end
	end)
end

function updateinventory() -- guns, collectibles, boats
	
	itemlist:ClearAllChildren()
	local items = playerdatafolder:FindFirstChild(inventorytype):GetChildren()
	
	inventoryhelper:Sort(items,"Name")
	local x,y = inventoryhelper:PageDisplay(currentpage,items,maxitems)

	for i = x, y do
		local item = items[i]
		local frametemplate =  inventoryhelper:LoadItemFrame(inventorytype,item.Name)
		frametemplate.Parent = itemlist
		clickitem(frametemplate)
	end
	
	local grid = uigridlayout:Clone()
	grid.Parent = itemlist
	
end

function updatepage(nextpage) 
	local items = playerdatafolder:FindFirstChild(inventorytype):GetChildren()
	if nextpage == true and currentpage < 10 and currentpage * maxitems < #items then
		currentpage = currentpage + 1
		updateinventory()
	elseif nextpage == false and currentpage > 1 then
		currentpage = currentpage - 1	
		updateinventory()
	end
	inventorygui.InventoryFrame.PageNumber.Text = "<b> Page "..currentpage.." </b>"
end

function updateinventorytype(newtype)
	if newtype ~= inventorytype then
		inventorygui.InventoryFrame:FindFirstChild(inventorytype.."Icon").Size = smallsize
		inventorygui.InventoryFrame:FindFirstChild(newtype.."Icon").Size = enlargedsize
		inventorygui.InventoryFrame.YellowBackground.Position = inventorygui.InventoryFrame:FindFirstChild(newtype.."Icon").Position
		inventoryinfo.TurnOff()
		inventorytype = newtype
		currentpage = 1
		updateinventory()
	end
end

local function updateCollectibles() -- show message when players can carrying highly valuable collectibles
	local collectibles = playerdatafolder.Collectibles:GetChildren()
	local totalvalue = 0
	for i = 1, #collectibles do
		totalvalue += RS.Collectibles:FindFirstChild(collectibles[i].Name):GetAttribute("Cost")
	end
	if totalvalue >= 1000 then
		inventorygui.CollectiblesWarning.Visible = true
	else
		inventorygui.CollectiblesWarning.Visible = false
	end
end
updateCollectibles()

-- connecting to events 

updateinventory()
updateinventorytype("Weapons")


backpack.ChildAdded:Connect(function()
	updateinventory()
	inventorygui.OpenButton.RedLabel.Visible = true
end)
backpack.ChildRemoved:Connect(updateinventory)

inventorygui.InventoryFrame.NextButton.InputBegan:Connect(function(input)
	if inputconfig:CheckInput(input) then
		updatepage(true)
	end
end)

inventorygui.InventoryFrame.PrevButton.InputBegan:Connect(function(input)
	if inputconfig:CheckInput(input) then
		updatepage(false)
	end
end)

inventorygui.InventoryFrame.WeaponsButton.InputBegan:Connect(function(input)
	if inputconfig:CheckInput(input) then
		updateinventorytype("Weapons")
	end
	
end)

inventorygui.InventoryFrame.CollectiblesButton.InputBegan:Connect(function(input)
	if inputconfig:CheckInput(input) then
		updateinventorytype("Collectibles")
	end
	
end)

inventorygui.InventoryFrame.BoatsButton.InputBegan:Connect(function(input)
	if inputconfig:CheckInput(input) then
		updateinventorytype("Boats")
	end
end)

--inventorygui.InventoryFrame.CloseButton.InputBegan:Connect(function(input)
--	if inputconfig:CheckInput(input) then
--		inventoryhelper:DisableBlur()
--		inventorygui.InventoryFrame.Visible = false
--		inventoryinfo.TurnOff()
--	end
--end)


local function openinventory(actionName, inputState, inputObject)
	if inputState == nil or inputState == Enum.UserInputState.End then	
		if inventorygui.InventoryFrame.Visible == true then
			inventorygui.InventoryFrame.Visible = false
			inventoryhelper:DisableBlur()
			inventoryinfo.TurnOff()
		else 
			updateinventory()
			inventoryhelper:AddBlur()
			inventorygui.OpenButton.RedLabel.Visible = false
			inventorygui.InventoryFrame.Visible = true
		end
	end
end

inventorygui.OpenButton.InputBegan:Connect(function(input)
	if inputconfig:CheckInput(input) then
		openinventory()
	end
end)

playerdatafolder.Collectibles.ChildAdded:Connect(updateCollectibles)
playerdatafolder.Collectibles.ChildRemoved:Connect(updateCollectibles)

--ContextAction:BindAction("OpenInventory",openinventory,false,Enum.KeyCode.B)

BindableEvents.UpdateInventory.Event:Connect(function(inventorytype)
	updateinventorytype(inventorytype)
end)




