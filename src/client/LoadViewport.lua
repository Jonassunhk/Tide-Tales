

local player = game.Players.LocalPlayer
local char = player.Character or workspace:WaitForChild(player.Name,30)
local hum = char:WaitForChild("Humanoid")
local root = hum.RootPart -- The HumanoidRootPart
local PlayerGui = player.PlayerGui
local BindableEvents = PlayerGui.BindableEvents
local RS = game.ReplicatedStorage


local RS = game.ReplicatedStorage
local guntools = game.ReplicatedStorage.Weapons
local boatmodels = RS.BoatModels

function loadviewport(viewportframe,modelname,inventorytype,turn)

	viewportframe:ClearAllChildren()
	local model
	local offset
	if inventorytype == "Weapons" then
		viewportframe.Ambient = Color3.fromRGB(255,255,255)
		model = guntools:FindFirstChild(modelname).Model:Clone()
		offset = 3

	elseif inventorytype == "Boats" then
		viewportframe.Ambient = Color3.fromRGB(255,255,255)
		model = boatmodels:FindFirstChild(modelname):Clone()
		offset = 120
	end

	model.Parent = viewportframe

	local center = model:GetBoundingBox().Position
	local extentsize = math.max(model:GetExtentsSize().x,model:GetExtentsSize().z) / 2

	local viewportCamera = Instance.new("Camera",viewportframe)
	viewportframe.CurrentCamera = viewportCamera
	viewportCamera.FieldOfViewMode = Enum.FieldOfViewMode.Vertical
	viewportCamera.CFrame = CFrame.new(center + Vector3.new(offset,0,0), center)
	if inventorytype == "Weapons" then
		viewportCamera.CFrame = viewportCamera.CFrame * CFrame.Angles(0,0,math.rad(-35))
	elseif inventorytype == "Boats" then
		--	model.CFrame = model.CFrame * CFrame.Angles(0,math.rad(-35),0)
	end
	viewportCamera.FieldOfView = math.deg(math.atan(extentsize / offset)) * 2
	
	local degrees = 0
	
	if turn == true  then
		while model ~= nil do
			degrees = degrees + 0.5
			local rotationvector = Vector3.new(math.cos(math.rad(degrees)), 0, math.sin(math.rad(degrees))) * offset
			viewportCamera.CFrame = CFrame.new(rotationvector + center, center) 
			wait(0.05)
		end
	end
	
end

BindableEvents.LoadViewport.Event:Connect(loadviewport)
