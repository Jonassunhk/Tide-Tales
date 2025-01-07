

local player = game.Players.LocalPlayer
local char = player.Character or workspace:WaitForChild(player.Name,30)
local hum = char:WaitForChild("Humanoid")
local root = hum.RootPart -- The HumanoidRootPart
local PlayerGui = player.PlayerGui
local BindableEvents = PlayerGui.BindableEvents
local RS = game.ReplicatedStorage
local Events = RS.Events
local ContextAction = game:GetService("ContextActionService")
local inputconfig = require(player.PlayerScripts.InputConfig)

local ServerEvent = Events.ConfirmationEvent
local ClientEvent = BindableEvents.ConfirmationEvent

local confirmationgui = PlayerGui.ConfirmationGui
local ConfirmButton = confirmationgui.Frame.AcceptButton
local DeclineButton = confirmationgui.Frame.DeclineButton

local subevent = BindableEvents.ConfirmationSubEvent
confirmationgui.Enabled = true
confirmationgui.Frame.Visible = false

local connection1
local connection2

local function confirmed(actionName, inputState, inputObject)
	if actionName == "ConfirmationAccept" and inputState == Enum.UserInputState.End then
		subevent:Fire(true)
	end
end

local function declined(actionName, inputState, inputObject)
	if actionName == "ConfirmationDecline" and inputState == Enum.UserInputState.End then
		subevent:Fire(false)
	end
end


local function beginconfirmation(text)
	confirmationgui.Enabled = true
	confirmationgui.Frame.Visible = true
	confirmationgui.Frame.Information.Text = text
	
	connection1 = ConfirmButton.InputBegan:Connect(function(input)
		if inputconfig:CheckInput(input) then
			subevent:Fire(true)
		end
	end)
	
	connection2 = DeclineButton.InputBegan:Connect(function(input)
		if inputconfig:CheckInput(input) then
			subevent:Fire(false)
		end
		
	end)
	
	--ContextAction:BindAction("ConfirmationAccept", confirmed, true, Enum.KeyCode.P, Enum.KeyCode.ButtonA)
	--ContextAction:BindAction("ConfirmationDecline", declined, true, Enum.KeyCode.O, Enum.KeyCode.ButtonB)
	local result = subevent.Event:Wait()
	--ContextAction:UnbindAction("ConfirmationAccept")
	--ContextAction:UnbindAction("ConfirmationDecline")
	confirmationgui.Enabled = false
	return result
end

ServerEvent.OnClientInvoke = beginconfirmation
ClientEvent.OnInvoke = beginconfirmation



