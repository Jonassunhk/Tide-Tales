
--pistol shoot : 10007262158
-- pistol hold: 10007288479
-- pistol reload: 10008041415

local player = game.Players.LocalPlayer
local char = player.Character or workspace:WaitForChild(player.Name,60)
local hum = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart") -- The HumanoidRootPart
local PlayerGui = player.PlayerGui
local BindableEvents = PlayerGui.BindableEvents
local animationfolder = game.ReplicatedStorage.Animations

local animator = hum:FindFirstChild("Animator")
if animator  == nil then
	animator = Instance.new("Animator",hum)
end


BindableEvents.PlayAnimation.Event:Connect(function(action,name,speed)
	
	if action == "Remove" then
		local alltracks = animator:GetPlayingAnimationTracks()
		
		for i = 1, #alltracks do
			local track = alltracks[i]
			
			if track:GetAttribute("Added") == true then
				track:Stop(0.3)
			end
		end
		
		return
	end
	
	if action == "Add" then
		local animation = animationfolder:FindFirstChild(name)
		if animation ~= nil then
			
			local newanim = animator:LoadAnimation(animation)
			newanim:SetAttribute("Added",true)
			print("play anim")
			newanim:Play()
			if speed ~= nil then newanim:AdjustSpeed(speed) end
			
		else
			warn("Animation ".. name .. " not found")
		end
	end
end)
