-- put in serverscriptservice

-- Variables
local damageHeight = 30 -- The height at which the player will start getting damaged at
local lethalHeight = 90 -- The height at which the player will get killed
local ragdollHeight = 25

game:GetService("Players").PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function (char)
		
		local root = char:WaitForChild("HumanoidRootPart")
		local humanoid = char:WaitForChild("Humanoid")
		
		if humanoid and root then
			
			local headHeight
			
			wait(1) -- Prevent the player from dying on spawn
			humanoid.FreeFalling:Connect(function (state)
				if state then
					headHeight = root.Position.Y
				elseif not state and headHeight ~= nil then
					pcall(function ()
						
						local fell = headHeight - root.Position.Y
						
						if fell >= lethalHeight then
							humanoid.Health = 0
						elseif fell >= damageHeight then
							humanoid.Health = humanoid.Health - math.floor(fell)
						end
						if fell >= ragdollHeight then
							--print("ragdolled")
							--humanoid:ChangeState(1)
							--wait(1)
							--humanoid:ChangeState(2)
						end
					end)
				end
			end)
		end
	end)
end)