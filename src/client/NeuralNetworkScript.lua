
local player = game.Players.LocalPlayer
local character = player.Character
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")
local debris = game:GetService("Debris")

local PlayerGui = player.PlayerGui
local ScreenGui = PlayerGui:WaitForChild("NeuralNetworkGui")
local event = game.ReplicatedStorage.CommunicationEvent

math.randomseed(os.clock()+os.time())

local Package = game:GetService("ReplicatedStorage").NNLibrary
local Base = require(Package.BaseRedirect)
local FeedforwardNetwork = require(Package.NeuralNetwork.FeedforwardNetwork)
local Momentum = require(Package.Optimizer.Momentum)

local clock = os.clock()
local Camera = workspace.CurrentCamera


----------------<<MAIN SETTINGS>>---------------------------------------------------------------

local setting = {
	Optimizer = Momentum.new();
	HiddenActivationName = "LeakyReLU";
	OutputActivationName = "Sigmoid";
	LearningRate = 0.3;
}

local epochs = 300
local batch_size = 300
local datasize = 300
local numOfGenerationsBeforeLearning = 1

----------------<<END OF MAIN SETTINGS>>---------------------------------------------------------------

inputs_model = {"x","y","z","d"}
outputs_model = {"out"}

local net = FeedforwardNetwork.new(inputs_model,2,4,outputs_model,setting)
local backProp = net:GetBackPropagator()
local dataset

function validate() 
	if humanoid.WalkSpeed > 18 then -- walking cheat
		return 1
	elseif lookingback() < 0 then -- camera cheat
		return 1 
	end

	return 0
end

local function magnitude_pruning(input,input_size,sparsity) -- sparsity is between 0 and 1

	local target_num = input_size * sparsity -- number of values that should be pruned
	local cnt = 1

	local values = {}
	for Key, Value in next, input do -- convert input dictionary to array
		values[cnt] = {Value,Key}
		print(cnt, values[cnt])
		cnt += 1
	end

	table.sort(values,function(a,b) -- sort by magnitude (there are no masks in Lua)
		return a[1]<b[1]
	end)
	--print(values)

	for i = 1, target_num, 1 do -- pruning
		input[values[i][2]] = 0
	end
	return input
end

function correct(output, ca)
	if math.abs(output-ca) < 0.3 then
		return true
	end

	return false
end

function lookingback() 
	local dot = Vector3.new(
		Camera.CFrame.LookVector.X, 
		0, 
		Camera.CFrame.LookVector.Z
	).Unit:Dot(Vector3.new(
		character.Head.CFrame.LookVector.X, 
		0, 
		character.Head.CFrame.LookVector.Z).Unit
	)
	return dot
end



function create_dataset(size) 
	print("Creating dataset")
	humanoid.WalkSpeed = 13
	local datas = {}
	for i = 1, size do 
		local a = root.Position
		--print(a)
		wait(0.1)
		local b = root.Position
		print(lookingback())

		local inputs = 
			{x=a.x-b.x, y=a.y-b.y, z=a.z-b.z, d=lookingback()} -- head vectors

		local outputs = {out=validate()}
		datas[i] = {inputs,outputs}
		wait(0.1)
		if i % 10 == 0 then
			humanoid.WalkSpeed += 0.6
		end
	end

	print("Dataset Complete")
	return datas
end

function train() -- training (pruning-aware)

	if dataset == nil then
		warn("Dataset is empty.")
		return
	end

	print("Training data...")
	for batch = 1, batch_size do

		local num = math.random(1,#dataset)

		local input = dataset[num][1]
		local correct = dataset[num][2]

		backProp:CalculateCost(input,correct)

		if os.clock()-clock >= 0.1 then
			clock = os.clock()
			wait()
		end

		if batch % numOfGenerationsBeforeLearning == 0 then
			backProp:Learn()
		end
	end
	print("Training finished!")
end

best_acc = 0

function test() -- testing  

	local totalRuns = 0
	local wins = 0
	for batch = 1, batch_size do
		local pruned_input = dataset[batch][1]
		local output = net(pruned_input) -- distributed computation
		local ca = dataset[batch][2]

		if correct(output.out,ca.out) then
			wins += 1
		end
		totalRuns += 1

		if os.clock()-clock >= 0.1 then
			clock = os.clock()
			wait()
		end
	end
	best_acc = math.max(best_acc,wins/totalRuns*(100))
	print(wins/totalRuns*(100).."% correct!")
end

local function compute_network()
	for i = 1, epochs do
		print("--------------------- epoch "..i.." ---------------------")
		train()
		test()
	end
	print("-------Best Accuracy: --------")
	print(best_acc)
end

local function actual_testing()
	local a = root.Position
	wait(0.1)
	local b = root.Position

	local lv = Vector3.new(Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z).Unit
	local hv = Vector3.new(character.Head.CFrame.LookVector.X, 0, character.Head.CFrame.LookVector.Z).Unit

	local inputs = 
		{x=a.x-b.x, y=a.y-b.y, z=a.z-b.z, d=lookingback()} -- head vectors

	event:FireServer(inputs)
	local output = net(inputs)

	print(output.out, lookingback())
	ScreenGui.BaseFrame.Output.Text = output.out
	if output.out > 0.7 then
		print("CHEATING")
		ScreenGui.BaseFrame.Status.Text = "Abnormal"
		ScreenGui.BaseFrame.Status.TextColor3 = Color3.fromRGB(233, 63, 24)
		ScreenGui.Frame.Visible = true
		ScreenGui.Frame.Output.Text = "Detection Network Output: "..tostring(output.out)
	else
		print("not cheating")
		ScreenGui.BaseFrame.Status.Text = "Normal"
		ScreenGui.BaseFrame.Status.TextColor3 = Color3.fromRGB(48, 222, 30)
		ScreenGui.Frame.Visible = false
	end
end


dataset = create_dataset(datasize)
compute_network()

while true do
	actual_testing()
	wait(0.3)
end

