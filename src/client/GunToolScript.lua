
-- local script common variables
local player = game.Players.LocalPlayer
local char = player.Character or workspace:WaitForChild(player.Name,30)
local hum = char:WaitForChild("Humanoid")
local root = hum.RootPart -- The HumanoidRootPart
local PlayerGui = player.PlayerGui
local camera = workspace.CurrentCamera
local mouse = player:GetMouse()

--mouse.Icon = "http://www.roblox.com/asset?id=990041241"
local gungui = PlayerGui.GunGui
local gunshot = require(player.PlayerScripts.ShotEffect)
local cameramodule = require(player.PlayerScripts.CameraModule)
local ContextAction = game:GetService("ContextActionService")
local infoFrame = gungui.InfoFrame

local inputconfig = require(player.PlayerScripts.InputConfig)

-- services
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")
--local waistconfig = require(player.PlayerScripts.WaistConfig)
local recoil = require(player.PlayerScripts.Recoil)

-- events
local AnimationEvent = PlayerGui.BindableEvents.PlayAnimation
local FieldOfView = PlayerGui.BindableEvents.FieldOfView
local RifleShootEvent = game.ReplicatedStorage.Events.RifleBulletEvent
local EquipEvent = game.ReplicatedStorage.Events.EquipEvent
local UnequipWeaponEvent = PlayerGui.BindableEvents.UnequipWeaponEvent

-- disable backpack
local StarterGui = game:GetService("StarterGui")
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

-- others
local cooldown = false
local gunequipped = nil
local gunplace = nil
local switchcooldown = false
local Gun1 = gungui.Gun1
local Gun2 = gungui.Gun2
local EquippedColor = Color3.fromRGB(254, 228, 136)
local UnequippedColor = Color3.fromRGB(122, 123, 115)

-- gunproperties

local damage
local ammo
local maxammo
local reloadspeed
local guntype
local firespeed

function getproperties(tool)
	damage = tool:GetAttribute("Damage")
	ammo = tool:GetAttribute("Ammo")
	maxammo = tool:GetAttribute("MaxAmmo")
	reloadspeed = tool:GetAttribute("ReloadTime")
	guntype = tool:GetAttribute("GunType")
	firespeed = tool:GetAttribute("FireSpeed")
end


function aim(actionName, inputState, inputObject)
	if actionName == "Aim" and inputState == Enum.UserInputState.Begin then
		FieldOfView:Fire(true,25)
	elseif actionName == "Aim" and inputState == Enum.UserInputState.End then
		FieldOfView:Fire(false)
	end
end

function mobileconfig()
	ContextAction:SetTitle("Fire","Fire")
	ContextAction:SetPosition("Fire",UDim2.new(0.806, 0,0.705, 0))
	ContextAction:SetTitle("Aim","Aim")
	ContextAction:SetPosition("Aim",UDim2.new(0.92, 0,0.606, 0))
	ContextAction:SetTitle("Reload","Reload")
	ContextAction:SetPosition("Aim",UDim2.new(0.724, 0,0.726, 0))
end

function GunActivated(actionName, inputState, inputObject) 
	
	if cooldown == false and ammo > 0 and actionName == "Fire" and inputState == Enum.UserInputState.End then
		cooldown = true
		ammo = ammo - 1
		spawn(function()
			
			cameramodule:Enable()
		end)
		
		gunequipped:SetAttribute("Ammo",ammo)
		gungui:FindFirstChild("AmmoLabel"..gunplace).Text = ammo.." / "..maxammo

		-- get position from center of screen
		local raycastParams = RaycastParams.new()
		-- raycastParams.FilterDescendantsInstances = { character } <-- fill this in yourself

		local VIEWPORT_SIZE = camera.ViewportSize -- current size of the screen -- if you're raycasting multiple times, this will have to be redefined!
		local CAST_LENGTH = 2000 -- distance to raycast

		local unitRay = camera:ScreenPointToRay(VIEWPORT_SIZE.X / 2, VIEWPORT_SIZE.Y / 2) -- account for the 36px TopBar inset --+ game:GetService("GuiService"):GetGuiInset().Y
		local raycastResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * CAST_LENGTH, raycastParams)
		if raycastResult and raycastResult.Position then -- .Position is the Vector3 (the Hit.Position) of the center of the screen
			print(tostring(raycastResult).." "..tostring(raycastResult.Position))
			RifleShootEvent:FireServer(raycastResult.Position,gunequipped,damage)
		end
		
		AnimationEvent:Fire("Add", guntype.."Fire")
		gunshot:gunshot(gunequipped)
		
		wait(1 * firespeed)
		cooldown = false
		
	elseif cooldown == false and ammo == 0 then
		reloadgun()
	end
end

function GunEquipped(tool,gunswitch) --script.Parent.Equipped:Connect(function()
	
	getproperties(tool)
	if not gunswitch then
		cameramodule:shiftLock(true)
	end
	gunequipped = tool
	AnimationEvent:Fire("Add", guntype.."Idle")
	UserInputService.MouseIconEnabled = false
	gungui.aimIcon.Visible = true
	--local mouse = player:GetMouse()
	--while mouse.Icon ~= "rbxasset://SystemCursors/Cross" do
	--	mouse.Icon = "rbxasset://SystemCursors/Cross"
	--end 
	
	gungui:FindFirstChild("AmmoLabel"..gunplace).Text = ammo.." / "..maxammo
	gungui:FindFirstChild("Gun"..gunplace).UIStroke.Color = EquippedColor
	gungui.Enabled = true
	ContextAction:BindAction("Aim", aim, true, Enum.KeyCode.Q, Enum.UserInputType.MouseButton2, Enum.KeyCode.ButtonR1)
	ContextAction:BindAction("Reload", reloadgun, true, Enum.KeyCode.R, Enum.KeyCode.ButtonR2)
	ContextAction:BindAction("Fire",GunActivated,false,Enum.UserInputType.MouseButton1,Enum.KeyCode.ButtonR3)
	mobileconfig()
	infoFrame.Visible = true
	infoFrame.UnequipInfo.Text = "UNEQUIP: "..gunplace
end

function GunUnequipped(resetcamera) -- script.Parent.Unequipped:Connect(function()
	gunequipped = nil
	if gunplace == nil then -- no gun is equipped in the first place
		return
	end
	if resetcamera then
		cameramodule:shiftLock(false)
		FieldOfView:Fire(false)
	end
	AnimationEvent:Fire("Remove")
	gungui:FindFirstChild("Gun"..gunplace).UIStroke.Color = UnequippedColor
	UserInputService.MouseIconEnabled = true
	gungui.aimIcon.Visible = false
	--player:GetMouse().Icon = "rbxasset://SystemCursors/Arrow0"
	ContextAction:UnbindAction("Aim")
	ContextAction:UnbindAction("Reload")
	ContextAction:UnbindAction("Fire")
	infoFrame.Visible = false
end

function reloadgun(actionName, inputState, inputObject)
	if cooldown == false and actionName == "Reload" and inputState == Enum.UserInputState.Begin then
		cooldown = true
		
		FieldOfView:Fire(false)
		local previousgun = gunequipped.Name
		AnimationEvent:Fire("Add",guntype.."Reload",reloadspeed)
		gunequipped.Handle.Reload:Play()
		wait(3 * (2 - reloadspeed) + 0.1)

		if gunequipped ~= nil and previousgun == gunequipped.Name then
			ammo = maxammo
			gunequipped:SetAttribute("Ammo",ammo)
			gungui:FindFirstChild("AmmoLabel"..gunplace).Text = ammo.." / "..maxammo
		end
		cooldown = false
	end
end

function loadgun(gunnum)
	
	if gungui["Gun"..gunnum]:GetAttribute("CurrentGun") == "None" 
		or not player:GetAttribute("ItemEquippable") or switchcooldown or 
		player:GetAttribute("ItemEquippable") == false then
		return 
	end
	switchcooldown = true
	hum:UnequipTools()
	local gunswitch = false
	
	if gunequipped ~= nil and gunequipped.Name == gungui["Gun"..gunnum]:GetAttribute("CurrentGun") then	
		GunUnequipped(true)
	else
		if gunequipped ~= nil and gunequipped.Name ~= gungui["Gun"..gunnum]:GetAttribute("CurrentGun") then
			gunswitch = true
			GunUnequipped(false)
		end
		local toolname = gungui["Gun"..gunnum]:GetAttribute("CurrentGun") 
		EquipEvent:FireServer(toolname,"Gun")
		local tool = char:WaitForChild(toolname)
		gunplace = gunnum
		GunEquipped(tool,gunswitch)
	end
	wait(0.2)
	switchcooldown = false
end

function connectgunload(actionName, inputState, inputObject)
	if actionName == "EquipSlot1" and inputState == Enum.UserInputState.Begin then
		loadgun(1)
	elseif actionName == "EquipSlot2" and inputState == Enum.UserInputState.Begin then
		loadgun(2)
	end
end

gungui.Gun1.TextButton.InputBegan:Connect(function(input)
	if inputconfig:CheckInput(input) then
		loadgun(1)
	end
end)


gungui.Gun2.TextButton.InputBegan:Connect(function(input)
	if inputconfig:CheckInput(input) then
		loadgun(2)
	end
end)


hum.StateChanged:Connect(function(old,new)
	if new.Value ~= 8 and new.Value ~= 3 and new.Value ~= 7 and new.Value ~= 5 then
		if gunequipped ~= nil then
			hum:UnequipTools()
			GunUnequipped(true)
		end
	end
end)

infoFrame.Visible = false
UserInputService.MouseIconEnabled = true
gungui.aimIcon.Visible = false

UnequipWeaponEvent.Event:Connect(GunUnequipped)
ContextAction:BindAction("EquipSlot1", connectgunload, false, Enum.KeyCode.One, Enum.KeyCode.ButtonL1)
ContextAction:BindAction("EquipSlot2", connectgunload, false, Enum.KeyCode.Two, Enum.KeyCode.ButtonL2)












