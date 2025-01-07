


local RarityIndex = {}

local DropTypes = {

	Common = { -- out of 1000
		Common = 1000, -- 50%
		Rare = 500, -- 40%
		Epic = 100, -- 9%
		Legendary = 10, -- 0.9%
		Mythical = 1, -- 0.1%
	},

	Rare = {
		Common = 1000, -- 30%
		Rare = 700, -- 40%
		Epic = 300, -- 25%
		Legendary = 50, -- 4.8%
		Mythical = 2 -- 0.2%
	},

	Epic = {
		Common = 0, -- 0%
		Rare = 1000, -- 40%
		Epic = 600, -- 35%
		Legendary = 150, -- 14.5%
		Mythical = 5 -- 0.5%
	},

	Legendary = {
		Common = 0,
		Rare = 0,
		Epic = 1000, -- 70%
		Legendary = 300, -- 28%
		Mythical = 20 -- 2%
	}
}

local RS = game.ReplicatedStorage

function RarityIndex.randomitem(DropType,inventorytype)
	local number = math.random(1,1000)
	local rarityindex = DropTypes[DropType]
	local itemrarity = nil
	
	if number <= rarityindex.Mythical then itemrarity = "Mythical"
	elseif number <= rarityindex.Legendary then itemrarity = "Legendary"
	elseif number <= rarityindex.Epic then itemrarity = "Epic"
	elseif number <= rarityindex.Rare then itemrarity = "Rare"
	elseif number <= rarityindex.Common then itemrarity = "Common" end
	
	local raritylist = {}
	local items = RS:FindFirstChild(inventorytype):GetChildren()
	
	for i = 1, #items do
		if items[i]:GetAttribute("Rarity") == itemrarity then
			raritylist[#raritylist + 1] = items[i]
		end
	end
	
	local itemnumber = math.random(1,#raritylist)
--	print(itemrarity.." "..raritylist[itemnumber].Name)
	
	return raritylist[itemnumber].Name
end

return RarityIndex
