
local player = game.Players.LocalPlayer
local char = player.Character or workspace:WaitForChild(player.Name,30)
local hum = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart") -- T ahe HumanoidRootPart
local PlayerGui = player.PlayerGui
local BindableEvents = PlayerGui.BindableEvents
local RS = game.ReplicatedStorage
local Events = RS.Events
local RunService = game:GetService("RunService")
local camera = workspace.CurrentCamera
local inputconfig = require(player.PlayerScripts.InputConfig)
local cannonRemoteEvent = RS.Events.CannonRemoteEvent
local changeBoatAttributeEvent = RS.Events.ChangeBoatAttributeEvent
local gunGui = PlayerGui.GunGui
local themesongEvent = PlayerGui.BindableEvents.ThemeSongEvent
local soundEvent = PlayerGui.BindableEvents.SoundEvent

local playerBoat
local boatSteering = false
local autoMode = false
local target = nil

-- ui variables
local boatGUI = PlayerGui.BoatGui
local abilitiesFrame = boatGUI.BoatAbilitiesFrame
local cannonFrameTemplate = boatGUI.CannonFrameTemplate
local attackTemplate = boatGUI.AttackTemplate
local cancelTemplate = boatGUI.CancelTemplate
local cannonFrames = boatGUI.cannonFrames
local attackFrames = boatGUI.attackFrames
local HealthGui = boatGUI.BoatHealthFrame

--local upgradeButton = abilitiesFrame.UpgradeButton
local attackModeButton = abilitiesFrame.AttackModeButton

-- abilities frame
local abilitiesFrame = boatGUI.BoatAbilitiesFrame
local boostButton = abilitiesFrame.BoostButton
local boostCooldownLabel = abilitiesFrame.BoostCooldownFrame
local boostIcon = boatGUI.BoostIcon
local shieldButton = abilitiesFrame.ShieldButton
local shieldCooldownLabel = abilitiesFrame.ShieldCooldownFrame
local shieldIcon = boatGUI.ShieldIcon
local healButton = abilitiesFrame.HealButton
local healCooldownLabel = abilitiesFrame.HealCooldownFrame

-- variables
local shieldDuration = 3
local boostDuration = 3
local healDuration = 10
local healTicks = 10
local boostAmount = 50000
local healPercentage = 30

local cannonShowRadius = 300
local frameInterval = 0.03
local power = 200
local boatShowRadius = 500
local targetShowRadius = 550

local shieldCooldown = 10
local boostCooldown = 10
local healCooldown = 20
local shieldAvailable = true
local boostAvailable = true
local healAvailable = true


local function roundNumber(num, numDecimalPlaces)
	return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

local function connectCannon(newTemplateName, cannonName) -- connect click event to each cannon
	local newTemplate = cannonFrames:FindFirstChild(newTemplateName)
	local cannon = playerBoat.Cannons:FindFirstChild(cannonName)
	
	newTemplate.FireButton.InputBegan:Connect(function(input)
		if inputconfig:CheckInput(input) and cannon:GetAttribute("Reload") <= 0.02 then
			print("fire cannon")
			local damage = playerBoat:GetAttribute("Damage")
			cannonRemoteEvent:FireServer(cannonName, power, damage)
		end	
	end)
end

local function initializeCannonFrames()
	local cannons = playerBoat.Cannons:GetChildren();
	cannonFrames:ClearAllChildren()
	for i = 1, #cannons do
		local cannon = cannons[i]
		local newTemplate = cannonFrameTemplate:Clone()
		newTemplate.Name = cannon.Name
		newTemplate.Parent = cannonFrames
		connectCannon(newTemplate.Name, cannon.Name)
	end
end

local function updateCannonFrames() 
	local cannons = playerBoat.Cannons:GetChildren();
	for i = 1, #cannons do
		local cannon = cannons[i]
		local cannonPos = cannon.Cannon.Position
		if (cannonPos - camera.CFrame.Position).Magnitude < cannonShowRadius then
			local vector, onScreen = camera:WorldToScreenPoint(cannonPos)
			local viewportPoint = Vector2.new(vector.X, vector.Y)
			
			local newTemplate = cannonFrames:FindFirstChild(cannon.Name)
			newTemplate.Position = UDim2.new(0, viewportPoint.X, 0, viewportPoint.Y)
			if onScreen then
				newTemplate.Visible = true
			else 
				newTemplate.Visible = false
			end
			
			-- getting attributes of the cannon
			local reloadTime = cannon:GetAttribute("Reload")
			if reloadTime <= 0 then -- cannon ready to fire
				newTemplate.ZIndex = 10
				newTemplate.ReloadText.Text = "FIRE"
				
			else -- cannon not ready yet
				newTemplate.ZIndex = 5
				newTemplate.ReloadText.Text = tostring(roundNumber(reloadTime))
			end
		end
	end
end

local function closeAllAttackFrames()
	local templates = attackFrames:GetChildren()
	for i = 1, #templates do
		templates[i].Visible = false
	end
end

local function changeTarget(target)
	print("CLIENT: changing player target")
	if target == nil then
		themesongEvent:Fire("The Ocean")
		changeBoatAttributeEvent:FireServer("Target", "")
	else
		themesongEvent:Fire("Battle")
		changeBoatAttributeEvent:FireServer("Target", target.Name)
	end
end


local function connectAttackFrames(attackTemplate, boat)
	attackTemplate.TextButton.InputBegan:Connect(function(input)
		if inputconfig:CheckInput(input) then
			print("target selected")
			target = boat
			changeTarget(boat)
			soundEvent:Fire("SwordClash",0,false,false)
			closeAllAttackFrames()
		end	
	end)
end

local function updateAttackFrames()
	if target == nil then -- only show the boats that are within range and can be attacked
		cancelTemplate.Visible = false
		local boats = Events.getFolder:InvokeServer(workspace.ActiveBoats)
		--print(boats)
		local currentTemplates = attackFrames:GetChildren()
		
		-- remove extra templates
		for i = 1, #currentTemplates do
			if workspace.ActiveBoats:FindFirstChild(currentTemplates[i].Name) == nil then
				currentTemplates[i]:Destroy()
			end
		end
		-- set up current templates
		for i = 1, #boats do
			local boat = boats[i]
			local template = attackFrames:FindFirstChild(boat.Name)
			
			-- template not found, clone one
			if template == nil and boat ~= playerBoat and boat:FindFirstChild("MainBody") ~= nil then
				local clonedAttackTemplate = attackTemplate:Clone()
				clonedAttackTemplate.Parent = attackFrames
				clonedAttackTemplate.Name = boat.Name
				clonedAttackTemplate.Visible = false
				connectAttackFrames(clonedAttackTemplate, boat)
				template = clonedAttackTemplate
			end
			
			if boat:FindFirstChild("MainBody") ~= nil and template ~= nil then
				template.Visible = false
				local dis = (boat.MainBody.Position - playerBoat.MainBody.Position).Magnitude
				if dis <= boatShowRadius and boat:GetAttribute("Health") > 0 then
					local vector, onScreen = camera:WorldToScreenPoint(boat.MainBody.Position)
					local viewportPoint = Vector2.new(vector.X, vector.Y)
					if onScreen then
						template.Position = UDim2.new(0, viewportPoint.X, 0, viewportPoint.Y)
						template.Visible = true
					end
				end
			end
		end
	else  -- show the current target
		local currentTemplates = attackFrames:GetChildren()
		for i = 1, #currentTemplates do
			currentTemplates[i].Visible = false
		end
		if target:GetAttribute("Health") <= 0 then -- target boat is already sunk
			target = nil
			changeTarget(nil)
			cancelTemplate.Visible = false
			return
		end
		local dis = (target.MainBody.Position - playerBoat.MainBody.Position).Magnitude
		if dis > targetShowRadius then -- target boat is out of range
			target = nil
			cancelTemplate.Visible = false
			return
		end
		local vector, onScreen = camera:WorldToScreenPoint(target.MainBody.Position)
		local viewportPoint = Vector2.new(vector.X, vector.Y)
		if onScreen then
			cancelTemplate.Position = UDim2.new(0, viewportPoint.X, 0, viewportPoint.Y)
			cancelTemplate.Visible = true
		else
			cancelTemplate.Visible = false
		end
	end
end

local function updatehealth()
	
	local maxhealth = playerBoat:GetAttribute("MaxHealth")
	local health = playerBoat:GetAttribute("Health")

	local framesizex = HealthGui.Back.Size.X.Scale
	local framesizey = HealthGui.Back.Size.Y.Scale
	local ratio = health / maxhealth
	HealthGui.Green.Size = UDim2.new(ratio * framesizex,0,framesizey,0)
	HealthGui.Yellow:TweenSize(UDim2.new(ratio * framesizex,0,framesizey,0),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.3,true)
	HealthGui.healthText.Text = health.."/"..maxhealth
end

local function initializeBoatGUI()
	boatGUI.Enabled = true
	gunGui.Enabled = false
end

local function closeBoatGUI()
	boatGUI.Enabled = false
	gunGui.Enabled = true
end

local function onShieldButtonClicked()
	if shieldAvailable then
		shieldAvailable = false
		soundEvent:Fire("Shield",0,false,false)
		Events.ShieldRemoteEvent:FireServer(shieldDuration)
		shieldCooldownLabel.Visible = true
		shieldIcon.Visible = true
		for i = 1, shieldCooldown do
			if i == shieldDuration + 1 then
				shieldIcon.Visible = false
			end
			shieldCooldownLabel.Text = tostring(shieldCooldown - i + 1)
			wait(1)
		end
		shieldCooldownLabel.Visible = false
		shieldAvailable = true
	end
end

local function onBoostButtonClicked()
	if boostAvailable then
		boostAvailable = false
		soundEvent:Fire("Boost",0,false,false)
		Events.BoostRemoteEvent:FireServer(boostDuration, boostAmount)
		boostIcon.Visible = true
		boostCooldownLabel.Visible = true
		for i = 1, boostCooldown do
			if i == boostDuration + 1 then
				boostIcon.Visible = false
			end
			boostCooldownLabel.Text = tostring(boostCooldown - i + 1)
			wait(1)
		end
		boostCooldownLabel.Visible = false
		boostAvailable = true
	end
end

local function onHealButtonClicked()
	if healAvailable then
		healAvailable = false
		soundEvent:Fire("Heal",0,false,false)
		local healAmount = math.round(playerBoat:GetAttribute("MaxHealth") / 100 * healPercentage)
		Events.SlowHealRemoteEvent:FireServer(healTicks, healDuration, healAmount)
		healCooldownLabel.Visible = true
		for i = 1, healCooldown do
			healCooldownLabel.Text = tostring(healCooldown - i + 1)
			wait(1)
		end
		healCooldownLabel.Visible = false
		healAvailable = true
	end
end

local function setAttackMode(mode)
	if not mode then
		autoMode = false
		local frames = attackFrames:GetChildren()
		for i = 1, #frames do
			frames[i].Visible = false
		end
		cancelTemplate.Visible = false
		changeBoatAttributeEvent:FireServer("AutoAttack", false)
		attackModeButton.Text = "OFF"
		attackModeButton.BackgroundColor3 = Color3.fromRGB(232, 69, 54)
	else
		local frames = cannonFrames:GetChildren()
		for i = 1, #frames do
			frames[i].Visible = false
		end
		autoMode = true
		changeBoatAttributeEvent:FireServer("AutoAttack", true)
		attackModeButton.Text = "ON"
		attackModeButton.BackgroundColor3 = Color3.fromRGB(24, 237, 4)
	end
end

local connection

local function updateSteering()
	if autoMode then -- auto attacking
		local success, errorMessage = pcall(updateAttackFrames)
		if not success then
			warn(errorMessage)
		end
	else -- attacking with cannons
		--updateCannonFrames()
		local success, errorMessage = pcall(updateCannonFrames)
		if not success then
			warn(errorMessage)
		end
	end
end

RS.Events.PlayerBoatEvent.OnClientEvent:Connect(function(steering)
	if steering then
		boatSteering = true
		playerBoat = workspace.ActiveBoats:FindFirstChild(player.Name.."Boat")
		initializeBoatGUI()
		initializeCannonFrames()
		
		playerBoat.AttributeChanged:Connect(function(name)
			if name == "Health" or name == "MaxHealth" then
				updatehealth()
			end
		end)
		updatehealth()
		
		camera.CameraSubject = playerBoat.MainBody
		connection = RunService.RenderStepped:Connect(updateSteering)
	else 
		boatSteering = false
		closeBoatGUI()
		workspace.CurrentCamera.CameraSubject = hum
		connection:Disconnect()
	end
end)

local function updateAutoAttackFrames(action, child) -- remove and add attack templates
	if action == "Add" then
		if child:FindFirstChild("MainBody") ~= nil then
			local clonedAttackTemplate = attackTemplate:Clone()
			clonedAttackTemplate.Parent = attackFrames
			clonedAttackTemplate.Name = child.Name
			connectAttackFrames(clonedAttackTemplate, child)
		end
	elseif action == "Remove" then
		local template = attackFrames:FindFirstChild(child.Name)
		if template ~= nil then
			template:Destroy()
		end
	end
end
Events.ActiveBoatsEvent.OnClientEvent:Connect(updateAutoAttackFrames)

cancelTemplate.TextButton.InputBegan:Connect(function(input) -- cancel the target
	if inputconfig:CheckInput(input) then
		print("target cancelled")
		target = nil
		changeTarget(nil)
	end	
end)

attackModeButton.InputBegan:Connect(function(input)
	if inputconfig:CheckInput(input) then
		print("attack mode changed")
		setAttackMode(not autoMode)
	end	
end)

shieldButton.InputBegan:Connect(function(input)
	if inputconfig:CheckInput(input) then
		onShieldButtonClicked()
	end	
end)

boostButton.InputBegan:Connect(function(input)
	if inputconfig:CheckInput(input) then
		onBoostButtonClicked()
	end	
end)

healButton.InputBegan:Connect(function(input)
	if inputconfig:CheckInput(input) then
		onHealButtonClicked()
	end	
end)

setAttackMode(false)

gunGui.Enabled = true
boatGUI.Enabled = false
abilitiesFrame.Visible = true
cannonFrameTemplate.Visible = false
cancelTemplate.Visible = false
attackTemplate.Visible = false
boostIcon.Visible = false
shieldIcon.Visible = false
shieldCooldownLabel.Visible = false
boostCooldownLabel.Visible = false
HealthGui.Visible = true






