

local player = game.Players.LocalPlayer
local char = player.Character or workspace:WaitForChild(player.Name,30)
local InformEvent = game.ReplicatedStorage.Events:WaitForChild("InformEvent")
local LocalInformEvent = player.PlayerGui.BindableEvents:WaitForChild("InformEvent")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInput = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local hum = char:WaitForChild("Humanoid")

local PlayerGui = player.PlayerGui
local InformGui = PlayerGui:WaitForChild("InformGui")
local BarGui = PlayerGui.BarGui
local text = InformGui.Frame.Information
local closebutton = InformGui.Frame.NextButton
InformGui.Frame.Visible = false
InformGui.Enabled = true

local characterviewport = PlayerGui.BindableEvents.CharacterViewport
local characters = game.ReplicatedStorage.Characters
local inputconfig = require(player.PlayerScripts.InputConfig)

local number = 0
local totalnumber = 0
local messages = {}
local colors = {}
local new = false
local clicked = true
local messagetime = true

local function stringtoarray(String)
	   local Array = {}
	   for i = 1, String:len() do
	  	 table.insert(Array, String:sub(i,i))
	end
	return Array
end

local function arraytostring(Array)
	local String = ""
	for i, v in ipairs(Array) do
		String = String..tostring(v)
	end
	return String
end

local function createdialogue(stringvalue,name,title)
	InformGui.Frame.Visible = true
	PlayerGui.GunGui.Enabled = false
	hum:UnequipTools()
	PlayerGui.BindableEvents.UnequipWeaponEvent:Fire(true)
	ProximityPromptService.Enabled = false
	local viewport = InformGui.Frame.CharacterViewport
	if characters:FindFirstChild(name) ~= nil and viewport.WorldModel:FindFirstChild(name) == nil then
		--print("event fired")
		characterviewport:Fire(InformGui.Frame.CharacterViewport,characters:FindFirstChild(name))
	end
	BarGui.Enabled = false
	if name ~= nil then
		InformGui.Frame.SpeakerName.Text = "<b>"..name.."</b>"
	else
		InformGui.Frame.SpeakerName.Text = ""
	end
	if title ~= nil then
		InformGui.Frame.SpeakerTitle.Text = "<b>"..title.."</b>"
	else
		InformGui.Frame.SpeakerTitle.Text = ""
	end
	local skip = false

	InformGui.Frame.TextButton.InputBegan:Connect(function(input)
		if inputconfig:CheckInput(input) then
			skip = true
		end
	end)
	
	local str = stringtoarray(stringvalue)
	local currentstr = {}
	for i = 1, stringvalue:len() do
		if skip then
			text.Text = "<b>"..stringvalue.."</b>"
			break
		end
		for j = 1, i + 1 do
			currentstr[j] = str[j]
		end
		local printstr = arraytostring(currentstr)
		text.Text = "<b>"..printstr.."</b>"
		local sound = InformGui.Sound:Clone()
		sound.Parent = InformGui
		sound:Destroy()
		wait(0.03)			
	end
	
	local temp = false
	while temp == false do
		local input = InformGui.Frame.TextButton.InputBegan:Wait()
		if inputconfig:CheckInput(input) then
			temp = true
		end
		wait(0.1)
	end
	InformGui.Sound:Play()
	InformGui.Frame.Visible = false
	BarGui.Enabled = true
	ProximityPromptService.Enabled = true
	PlayerGui.GunGui.Enabled = true
	return true
end

InformEvent.OnClientInvoke = createdialogue
LocalInformEvent.OnInvoke = createdialogue


