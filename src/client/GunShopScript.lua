

local player = game.Players.LocalPlayer
local char = player.Character or workspace:WaitForChild(player.Name,30)
local PlayerGui = player.PlayerGui
local BindableEvents = PlayerGui.BindableEvents
local RS = game.ReplicatedStorage
local Events = RS.Events

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local Confirmation = BindableEvents.ConfirmationEvent
local shopgui = PlayerGui:WaitForChild("CurrencyShopGui")
local prompts = shopgui.Frame.Prompts:GetChildren()
shopgui.Enabled = true
shopgui.Frame.Visible = false

local inputconfig = require(player.PlayerScripts.InputConfig)

-- Function to prompt purchase of the developer product
local function promptPurchase(productID)
	local player = Players.LocalPlayer
	MarketplaceService:PromptProductPurchase(player, productID)
end

local function connectprompt(prompt)
	local promptID = prompt.Name
	
	prompt.InputBegan:Connect(function(input)
		if inputconfig:CheckInput(input) then
			print(promptID)
			if Confirmation:Invoke("Are you sure you want to purchase this item? (Make sure your internet connection is stable)") then
				promptPurchase(promptID)
			end
		end
	end)
end

for i = 1, #prompts do
	connectprompt(prompts[i])
end

shopgui.OpenButton.InputBegan:Connect(function(input)
	if inputconfig:CheckInput(input) then
		shopgui.Frame.Visible = true
	end
	
end)

shopgui.Frame.CloseButton.InputBegan:Connect(function(input)
	if inputconfig:CheckInput(input) then
		shopgui.Frame.Visible = false
	end
end)


