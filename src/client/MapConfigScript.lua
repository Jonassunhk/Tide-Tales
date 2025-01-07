
local player = game.Players.LocalPlayer
local datafolder = player:WaitForChild("PlayerDataFolder", 60)
local char = player.Character or workspace:WaitForChild(player.Name,30)
local hum = char:WaitForChild("Humanoid", 30)
local root = char:WaitForChild("HumanoidRootPart") -- The HumanoidRootPart
local PlayerGui = player.PlayerGui
local BindableEvents = PlayerGui.BindableEvents
local RS = game.ReplicatedStorage
local Events = RS.Events
local Returnparts = Events.ReturnParts
local tag = game:GetService("CollectionService")
local userInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local mapplayerevent = Events.MapPlayerEvent
local mapresettime = 1
local runService = game:GetService("RunService")
local soundEvent = PlayerGui.BindableEvents:WaitForChild("SoundEvent")

local ContextAction = game:GetService("ContextActionService")
local mouse = player:GetMouse()
local size = PlayerGui.BarGui.AbsoluteSize
local ViewSizeY = size.Y
local ViewSizeX = size.X
local minimap = require(player.PlayerScripts:WaitForChild("Minimap"))
local minimapSettings = require(player.PlayerScripts:WaitForChild("Minimap").Settings)
local questmodule = require(game.ReplicatedStorage.QuestDataModule)
local inputconfig = require(player.PlayerScripts.InputConfig)
local inventoryhelper = require(player.PlayerScripts.InventoryHelper)
local scrollAmount = 0.2
local dragFactor = 2
local connection
local dragClickConnection
local dragConnection
local PlayerPosition = root.Position
local camera = workspace.CurrentCamera

minimap:Toggle()
local mapenlarged = false
local mapgui = PlayerGui.MapGui
mapgui.Enabled = true
mapgui.Legend.Visible = false
mapgui.TextButton.Visible = true
local scrollButton = mapgui.ScrollButton
local largeMapScale = 1

local minZoom = 0.75
local maxZoom = 7
local mapIconLowerThreshold = 2
local mapIconHigherThreshold = 3

local positionfolder = Instance.new("Folder",workspace)
local playerfolder = Instance.new("Folder",workspace)
local questIconFolder = Instance.new("Folder", workspace)
local questBillboard = game.ReplicatedStorage.Assets.QuestBillboard

local function clearQuestIcons()
	local questIcons = questIconFolder:GetChildren()
	for i = 1, #questIcons do
		minimap:RemoveBlip(questIcons[i])
		questIcons[i]:Destroy()
	end
end

local function createIconInstance(folder, position, tagname, name)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Position = position
	part.Parent = folder
	part.Name = name
	minimap:AddBlip(part,tagname)
	return part
end

local function tagMainQuestInstances()
	clearQuestIcons()
	local progress = datafolder.MainQuestProgression.Value
	if progress + 1 <= questmodule:getMainQuestLength() then -- still an active quest available
		local info = questmodule:getQuestInfo("MainQuest", progress + 1)
		if type(info.SpecificLocation) == "table" then -- multiple icons
			local parts = info.SpecificLocation
			for i = 1, #parts do
				local position = game.ReplicatedStorage.Events.StreamingHelper:InvokeServer(parts[i]) -- get part position from server
				local part = createIconInstance(questIconFolder, position, "Quest", "MainQuestLocation")
				local clonedbillboard = questBillboard:Clone()
				clonedbillboard.Parent = part
			end
		else
			local position = game.ReplicatedStorage.Events.StreamingHelper:InvokeServer(info.SpecificLocation) -- get part position from server
			local part = createIconInstance(questIconFolder, position, "Quest", "MainQuestLocation")
			local clonedbillboard = questBillboard:Clone()
			clonedbillboard.Parent = part
		end
	end
end

local function taginstances(add,folder,tagname,primarypartname)
	if not add then
		local points = positionfolder:GetChildren()
		for i = 1, #points do
			minimap:RemoveBlip(points[i])
			points[i]:Destroy()
		end
	else
		local list = Returnparts:InvokeServer(folder,tagname,primarypartname)
		for i = 1, #list do
			createIconInstance(positionfolder, list[i], tagname, tagname)
		end
	end
end

local function tagMapLabels(action)
	local list = game.ReplicatedStorage.MapIcons:GetChildren()
	for i = 1, #list do
		if action == true then
			minimap:AddBlip(list[i], list[i].Name)
		else
			minimap:RemoveBlip(list[i])
		end
	end
end


local function updateplayers()
	local list = Returnparts:InvokeServer(game.Players,"Ally","HumanoidRootPart")
	for key, value in pairs(list) do
		if playerfolder:FindFirstChild(key) == nil then
			createIconInstance(playerfolder, value, "Ally", key)
		else
			playerfolder:FindFirstChild(key).Position = value
		end
	end
end

local function mapplayer(player,action)
	if action == false then
		local playerpart = playerfolder:FindFirstChild(player.Name)
		if playerpart then
			playerpart:Destroy()
		end
	end
end

local function resetinstances(action)
	taginstances(action, workspace.Marketplaces,"Marketplace","MarketplacePart")
	taginstances(action, workspace.GunShops,"Gun Shop","ProximityPart")
	taginstances(action, workspace.BoatShops,"Boat Shop","ProximityPart")
	taginstances(action, workspace.NPC,"Merchant","HumanoidRootPart")
	taginstances(action, workspace.NPC,"Quest","HumanoidRootPart")
	taginstances(action, workspace.Banks,"Bank","ProximityPart")
end

local function enlargemap()
	--minimap:RotateManage(false)
	minimap:Reposition(UDim2.new(0.5,0,0.5,0),Vector2.new(0.5,0.5))
	minimap:Resize(UDim2.new(0,ViewSizeY * largeMapScale,0,ViewSizeY * largeMapScale))
	minimap:ChangeRoundness(UDim.new(0,0))
	
	mapgui.TextButton.Position = UDim2.new(0.5,0,0.4,0)
	mapgui.TextButton.Size = UDim2.new(0,ViewSizeY * largeMapScale,0,ViewSizeY * largeMapScale)
	
	minimap:SetOnePixel(4)
	scrollButton.Visible = true
end

local function reducemap()
--	minimap:RotateManage(true)
	local mapx = ViewSizeY / 3
	local mapy = ViewSizeY / 3
	minimap:SetOnePixel(2)

	minimap:Resize(UDim2.new(0,mapx,0,mapy))
	minimap:Reposition(UDim2.new(0.98,0,0.03,0),Vector2.new(1,0))
	minimap:ChangeRoundness(UDim.new(1,0))
	
	mapgui.TextButton.Position = UDim2.new(0.98,0,0.03,0)
	mapgui.TextButton.Size = UDim2.new(0,mapx,0,mapy)
	scrollButton.Visible = false
end

local function Drag()
	print("player begins dragging")
	local original = userInputService:GetMouseLocation()
	dragConnection = runService.Stepped:Connect(function()
		local new = userInputService:GetMouseLocation()
		local movement = Vector3.new(-new.X + original.X, 0,-new.Y + original.Y) * minimapSettings.Technical.onePixel * dragFactor
		--print(movement)
		local xChange = -camera.CFrame.LookVector * movement.Z
		local zChange = camera.CFrame.RightVector * movement.X
		print(xChange)
		PlayerPosition = PlayerPosition + xChange + zChange
		minimap:OverrideFocus(PlayerPosition)
		original = new
	end)
end

scrollButton.InputEnded:Connect(function(input)
	--print("end")
	if inputconfig:CheckInput(input) then
		if dragConnection ~= nil then
			dragConnection:Disconnect()
		end
	end
end)

local function configureGUI(state)
	--PlayerGui.MapGui.Enabled = state
	PlayerGui.BarGui.Enabled = not state
	PlayerGui.GunGui.Enabled = not state
end

local function setUp(state)
	mapgui.CloseButton.Visible = state
	mapgui.TextButton.Visible = not state
	mapgui.Background.Visible = state
	mapgui.Legend.Visible = state
	mapgui.ScrollButton.Visible = state
end



function configmap()
	soundEvent:Fire("Map",0,false,false)
	if mapenlarged == false then
		mapenlarged = true
		configureGUI(true)
		enlargemap()
		inventoryhelper:AddBlur()
		setUp(true)
		connection = scrollButton.InputChanged:Connect(function(input)
			if not mapenlarged or input.UserInputType ~= Enum.UserInputType.MouseWheel then
				return
			end
			local up = input.Position.Z > 0
			local currentPixel = minimapSettings.Technical.onePixel
			local prevPixel = currentPixel
			if up and currentPixel > minZoom then
				minimap:SetOnePixel(minimapSettings.Technical.onePixel - scrollAmount)
			elseif not up and currentPixel < maxZoom then
				minimap:SetOnePixel(minimapSettings.Technical.onePixel + scrollAmount)
			end
			
			currentPixel = minimapSettings.Technical.onePixel
			if currentPixel < mapIconLowerThreshold and prevPixel > mapIconLowerThreshold then
				resetinstances(true)
				tagMapLabels(false)
			elseif currentPixel > mapIconHigherThreshold and prevPixel < mapIconHigherThreshold then
				resetinstances(false)
				tagMapLabels(true)
			end
		end)

		PlayerPosition = root.Position
		dragClickConnection = scrollButton.InputBegan:Connect(function(input)
			--print("here")
			if inputconfig:CheckInput(input) then
				Drag()
			end
		end)
	else
		mapenlarged = false
		reducemap()
		inventoryhelper:DisableBlur()
		minimap:OverrideFocus(nil)
		configureGUI(false)
		setUp(false)
		if connection ~= nil then
			connection:Disconnect()
		end
		if dragClickConnection ~= nil then
			dragClickConnection:Disconnect()
		end
	end
end

function keyMPressed(actionName, inputState)
	if actionName == "ConfigMap" and inputState == Enum.UserInputState.End then
		configmap()
	end
end

reducemap()
setUp(false)
resetinstances(true)
tagMapLabels(false)

mapplayerevent.OnClientEvent:Connect(mapplayer)
ContextAction:BindAction("ConfigMap", keyMPressed, false, Enum.KeyCode.M)

mapgui.CloseButton.InputBegan:Connect(function(input)
	if inputconfig:CheckInput(input) then
		configmap()
	end
end)

mapgui.TextButton.InputBegan:Connect(function(input)
	if inputconfig:CheckInput(input) then
		configmap()
	end
end)

tagMainQuestInstances()
datafolder.MainQuestProgression.Changed:Connect(tagMainQuestInstances)

--while wait(mapresettime) do
--	spawn(function()
--		updateplayers()
--	end)
--end


--managefolder()







