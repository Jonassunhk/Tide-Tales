
local player = game.Players.LocalPlayer
local char = player.Character or workspace:WaitForChild(player.Name,30)
local hum = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart") -- T ahe HumanoidRootPart
local PlayerGui = player.PlayerGui
local BindableEvents = PlayerGui.BindableEvents
local RS = game.ReplicatedStorage
local Events = RS.Events
local inputconfig = require(player.PlayerScripts.InputConfig)

local settingsGui = PlayerGui.SettingsGui
local frame = settingsGui.Frame
local mainPage = frame.MainPage
local codePage = frame.CodePage

local function setVisibility(mainPageV, codePageV)
	mainPage.Visible = mainPageV
	
end

mainPage.CodeButton.InputBegan:Connect(function(input)
	if inputconfig:CheckInput(input) then
		
	end
end)









