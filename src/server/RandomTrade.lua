

local TradeOffer = {}

local RS = game.ReplicatedStorage

local possibletradeoffers =  {
	
}

function TradeOffer.generateitem(category,price,benefit)
	
	local function round(n)
		return math.floor(n + 0.5)
	end
	
	local possibleitems
	if category == "Currency" then
		local percentage
		if benefit == true then
			percentage = math.random(7,10) / 10
		else
			percentage = math.random(10,13) / 10
		end
		return round(price * percentage)
	else
		possibleitems = RS:FindFirstChild(category):GetChildren()
		local num = math.random(1,#possibleitems)
		
		local selecteditem = possibleitems[num]
		local itemcost = selecteditem:GetAttribute("Cost")
		local amount
		if benefit == true then
			amount = math.floor(price / itemcost)
		else
			amount = round(price / itemcost)
		end
		if amount == 0 then amount = 1 end
		
	end
end

local tradeoffersample = { -- sample trade offer format
	TraderName = "Merchants",
	PlayerGive = {
		Category = "Collectibles",
		ItemName = "Gold Bar",
		Amount = 3
	},
	TraderGive = {
		Category = "Currency",
		ItemName = "Gold",
		Amount = 2938
	}
}


return TradeOffer
