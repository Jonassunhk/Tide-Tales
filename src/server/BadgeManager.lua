local badgemanager = {}

local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")

local JoinGamebadgeID = 2127779839  -- join game badge

function badgemanager:checkbadge(player,badgeID)
	-- Check if the player has the badge
	local success, hasBadge = pcall(BadgeService.UserHasBadgeAsync, BadgeService, player.UserId, badgeID)

-- If there's an error, issue a warning and exit the function
	if not success then
		warn("Error while checking if player has badge!")
		return
	end
	
	return hasBadge
end

function badgemanager:awardBadge(player, badgeId)
	-- Fetch badge information
	local success, badgeInfo = pcall(BadgeService.GetBadgeInfoAsync, BadgeService, badgeId)
	if success then
		-- Confirm that badge can be awarded
		if badgeInfo.IsEnabled then
			-- Award badge
			local awarded, errorMessage = pcall(BadgeService.AwardBadge, BadgeService, player.UserId, badgeId)
			if not awarded then
				warn("Error while awarding badge:", errorMessage)
			end
		end
	else
		warn("Error while fetching badge info!")
	end
end

return badgemanager
