
local player = game.Players.LocalPlayer
local char = player.Character or workspace:WaitForChild(player.Name,30)
local hum = char:WaitForChild("Humanoid")
local root = hum.RootPart -- The HumanoidRootPart
local PlayerGui = player.PlayerGui
local BindableEvents = PlayerGui.BindableEvents
local RS = game.ReplicatedStorage
local Events = RS.Events

local function managegui(action,ignorelist)
	
	local guis = PlayerGui:GetChildren()
	for i = 1, #guis do
		local gui = guis[i]
		local ignored = false
		for j = 1, #ignorelist do
			if ignorelist[j] == gui.Name then
				ignored = true
			end
		end
		if ignored == false and gui:IsA("ScreenGui") then
			gui.Enabled = action
		end
	end
end

BindableEvents.ManageGui.Event:Connect(managegui)


