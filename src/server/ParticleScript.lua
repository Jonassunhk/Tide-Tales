
FastCastRedux = game.ServerScriptService.FastCastRedux

local fireEvent = game.ReplicatedStorage.Events.RifleBulletEvent
local CastFilter = game.ReplicatedStorage.Events.CastFilter
local DamageEvent = game.ReplicatedStorage.Events.GiveDamage
local FastCast = require(FastCastRedux)

local bulletsFolder = workspace:FindFirstChild("BulletFolder") or Instance.new("Folder", workspace)
bulletsFolder.Name = "BulletFolder"

local bulletTemplate = game.ReplicatedStorage.Assets.Bullet:Clone()

--FastCast.VisualizeCasts = true

local caster = FastCast.new()

local castParams = RaycastParams.new()
castParams.FilterType = Enum.RaycastFilterType.Exclude
castParams.IgnoreWater = true

local castBehavior = FastCast.newBehavior()
castBehavior.RaycastParams = castParams
castBehavior.Acceleration = Vector3.new(0, -workspace.Gravity / 2, 0)
castBehavior.AutoIgnoreContainer = false
castBehavior.CosmeticBulletContainer = bulletsFolder
castBehavior.CosmeticBulletTemplate = bulletTemplate

local function onEquipped(player,tool)
	castParams.FilterDescendantsInstances = {tool.Parent, bulletsFolder, player.Character}
end

local function onLengthChanged(cast, lastPoint, direction, length, velocity, bullet)
	if bullet then 
		local bulletLength = bullet.Size.Z/2
		local offset = CFrame.new(0, 0, -(length - bulletLength))
		bullet.CFrame = CFrame.lookAt(lastPoint, lastPoint + direction):ToWorldSpace(offset)
	end
end

local function onRayHit(cast, result, velocity, bullet)
	
	local hit = result.Instance
	
	local playername = cast.UserData.PlayerName
	local player = game.Players:FindFirstChild(playername)
	local bulletdamage = cast.UserData.BulletDamage
	
	DamageEvent:Fire(player,false,hit,bulletdamage)
	bullet:Destroy()
end

local function fire(player, mousePosition, tool, damage)
	
	tool.Handle.pow:Play()
	local origin = tool.Handle.Position -- firepoint 
	local direction = (mousePosition - origin).Unit
	
	local playerdata = {
		PlayerName = player.Name,
		BulletDamage = damage,
	}
	
	caster:Fire(origin, direction, 1500, castBehavior, playerdata)
end

fireEvent.OnServerEvent:Connect(fire)
CastFilter.Event:Connect(onEquipped)

caster.LengthChanged:Connect(onLengthChanged)
caster.RayHit:Connect(onRayHit)