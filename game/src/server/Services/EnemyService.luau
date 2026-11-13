-- Cria os inimigos definidos em Data/Regions, controla a IA e trata a morte
-- e o ressurgimento.
--
-- Cada inimigo é um Model com uma única peça (HumanoidRootPart) e um
-- Humanoid, o que dá movimento com física e Humanoid:MoveTo de graça.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local EnemyData = require(ReplicatedStorage.Shared.Data.Enemies)
local Regions = require(ReplicatedStorage.Shared.Data.Regions)
local ProgressionService = require(script.Parent.ProgressionService)
local StatsService = require(script.Parent.StatsService)

local AI_TICK = 0.2
local ACTIVE_RANGE = 160

local EnemyService = {}

export type Enemy = {
	def: any,
	model: Model,
	humanoid: Humanoid,
	root: BasePart,
	healthBar: Frame,
	home: Vector3,
	group: any,
	alive: boolean,
	lastAttack: number,
	nextWander: number,
	damagers: { [Player]: boolean },
}

local enemies: { [Enemy]: boolean } = {}
local folder: Folder
local random = Random.new()

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function groundAt(x: number, z: number): Vector3
	local result = Workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -600, 0), rayParams)
	return if result then result.Position else Vector3.new(x, 0, z)
end

local function randomPointAround(center: Vector3, radius: number): Vector3
	local angle = random:NextNumber(0, math.pi * 2)
	local distance = radius * math.sqrt(random:NextNumber())
	return groundAt(center.X + math.cos(angle) * distance, center.Z + math.sin(angle) * distance)
end

local function buildModel(def: any): (Model, Humanoid, BasePart, Frame)
	local model = Instance.new("Model")
	model.Name = def.name

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Shape = Enum.PartType.Ball
	root.Size = Vector3.new(def.size, def.size, def.size)
	root.Color = def.color
	root.Material = Enum.Material.SmoothPlastic
	root.Transparency = 0.15
	root.TopSurface = Enum.SurfaceType.Smooth
	root.BottomSurface = Enum.SurfaceType.Smooth
	root.Parent = model

	for _, side in { -1, 1 } do
		local eye = Instance.new("Part")
		eye.Name = "Olho"
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.new(def.size * 0.16, def.size * 0.22, def.size * 0.16)
		eye.Color = Color3.fromRGB(25, 30, 40)
		eye.Material = Enum.Material.SmoothPlastic
		eye.CanCollide = false
		eye.Massless = true
		eye.CFrame = root.CFrame * CFrame.new(side * def.size * 0.2, def.size * 0.12, -def.size * 0.42)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = eye
		weld.Parent = eye
		eye.Parent = model
	end

	local humanoid = Instance.new("Humanoid")
	humanoid.RigType = Enum.HumanoidRigType.R15
	humanoid.HipHeight = 0
	humanoid.MaxHealth = def.health
	humanoid.Health = def.health
	humanoid.WalkSpeed = def.speed
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.BreakJointsOnDeath = false
	humanoid.Parent = model

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Placa"
	billboard.Size = UDim2.fromScale(5, 1.1)
	billboard.StudsOffset = Vector3.new(0, def.size * 0.5 + 1.4, 0)
	billboard.MaxDistance = 70
	billboard.AlwaysOnTop = false
	billboard.Adornee = root
	billboard.Parent = root

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 0.6)
	label.BackgroundTransparency = 1
	label.Text = `{def.name}  Nv. {def.level}`
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.4
	label.Parent = billboard

	local back = Instance.new("Frame")
	back.Position = UDim2.fromScale(0.1, 0.68)
	back.Size = UDim2.fromScale(0.8, 0.22)
	back.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	back.BorderSizePixel = 0
	back.Parent = billboard

	local fill = Instance.new("Frame")
	fill.Name = "Vida"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(225, 70, 70)
	fill.BorderSizePixel = 0
	fill.Parent = back

	model.PrimaryPart = root
	return model, humanoid, root, fill
end

local function spawnEnemy(group: any)
	local def = EnemyData[group.enemy]
	if not def then
		warn("[EnemyService] Inimigo desconhecido em Regions:", group.enemy)
		return
	end

	local home = randomPointAround(group.center, group.radius)
	local model, humanoid, root, healthBar = buildModel(def)
	model:PivotTo(CFrame.new(home + Vector3.new(0, def.size / 2 + 0.5, 0)))
	model.Parent = folder
	root:SetNetworkOwner(nil)

	local enemy: Enemy = {
		def = def,
		model = model,
		humanoid = humanoid,
		root = root,
		healthBar = healthBar,
		home = home,
		group = group,
		alive = true,
		lastAttack = 0,
		nextWander = os.clock() + random:NextNumber(1, 5),
		damagers = {},
	}
	enemies[enemy] = true
end

local function kill(enemy: Enemy)
	enemy.alive = false
	enemies[enemy] = nil

	local def = enemy.def
	for player in enemy.damagers do
		if player.Parent then
			ProgressionService.awardXp(player, def.xp)
			ProgressionService.awardCoins(player, random:NextInteger(def.coins[1], def.coins[2]))
		end
	end

	enemy.root.Anchored = true
	enemy.root.CanCollide = false
	local billboard = enemy.root:FindFirstChild("Placa")
	if billboard then
		billboard:Destroy()
	end
	TweenService:Create(enemy.root, TweenInfo.new(0.35), {
		Size = Vector3.new(0.2, 0.2, 0.2),
		Transparency = 1,
	}):Play()
	task.delay(0.5, function()
		enemy.model:Destroy()
	end)

	task.delay(def.respawn, spawnEnemy, enemy.group)
end

-- Aplica dano de um jogador. Devolve true se o inimigo morreu.
function EnemyService.damage(enemy: Enemy, amount: number, player: Player): boolean
	if not enemy.alive then
		return false
	end
	enemy.damagers[player] = true

	local health = math.max(0, enemy.humanoid.Health - amount)
	enemy.humanoid.Health = health
	enemy.healthBar.Size = UDim2.fromScale(health / enemy.def.health, 1)

	if health <= 0 then
		kill(enemy)
		return true
	end
	return false
end

-- Inimigos vivos dentro de `range` e no arco à frente de `origin`.
-- `minDot` 1 = exatamente à frente, 0 = até os lados, -1 = todos.
function EnemyService.inArc(origin: CFrame, range: number, minDot: number): { Enemy }
	local found = {}
	local look = origin.LookVector
	for enemy in enemies do
		local offset = enemy.root.Position - origin.Position
		local distance = offset.Magnitude - enemy.def.size / 2
		if distance <= range then
			local flat = Vector3.new(offset.X, 0, offset.Z)
			if flat.Magnitude < 1 or flat.Unit:Dot(look) >= minDot then
				table.insert(found, enemy)
			end
		end
	end
	return found
end

local function nearestPlayer(position: Vector3, range: number): (Player?, BasePart?, number)
	local best: Player? = nil
	local bestRoot: BasePart? = nil
	local bestDistance = range
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and root then
			local distance = ((root :: BasePart).Position - position).Magnitude
			if distance < bestDistance then
				best, bestRoot, bestDistance = player, root :: BasePart, distance
			end
		end
	end
	return best, bestRoot, bestDistance
end

local function attack(enemy: Enemy, player: Player, targetRoot: BasePart)
	local def = enemy.def
	enemy.lastAttack = os.clock()

	-- Aviso visual: o inimigo clareia antes do golpe, dando tempo de recuar.
	local original = def.color
	enemy.root.Color = Color3.new(1, 1, 1)
	task.delay(def.attackWindup, function()
		if not enemy.alive then
			return
		end
		enemy.root.Color = original
		if not targetRoot.Parent then
			return
		end
		local distance = (targetRoot.Position - enemy.root.Position).Magnitude - def.size / 2
		if distance <= def.attackRange + 2 then
			StatsService.damagePlayer(player, def.damage)
		end
	end)
end

local function think(enemy: Enemy, now: number)
	local def = enemy.def
	local position = enemy.root.Position

	local player, targetRoot, distance = nearestPlayer(position, ACTIVE_RANGE)
	if not player or not targetRoot then
		return -- ninguém por perto: inimigo dorme
	end

	local fromHome = (targetRoot.Position - enemy.home).Magnitude
	if distance <= def.aggroRange and fromHome <= def.leashRange then
		local reach = distance - def.size / 2
		if reach <= def.attackRange then
			enemy.humanoid:MoveTo(position)
			if now - enemy.lastAttack >= def.attackCooldown then
				attack(enemy, player, targetRoot)
			end
		else
			enemy.humanoid:MoveTo(targetRoot.Position)
		end
		return
	end

	if (position - enemy.home).Magnitude > def.wanderRange + 6 then
		enemy.humanoid:MoveTo(enemy.home)
	elseif now >= enemy.nextWander then
		enemy.nextWander = now + random:NextNumber(3, 7)
		enemy.humanoid:MoveTo(randomPointAround(enemy.home, def.wanderRange))
	end
end

function EnemyService.start()
	folder = Instance.new("Folder")
	folder.Name = "Inimigos"
	folder.Parent = Workspace
	-- Ignora inimigos e cenário (copas de árvore) ao procurar o chão.
	local ignore: { Instance } = { folder }
	local world = Workspace:FindFirstChild("Mundo")
	if world then
		table.insert(ignore, world)
	end
	rayParams.FilterDescendantsInstances = ignore

	for _, region in Regions do
		for _, group in region.spawnGroups do
			for _ = 1, group.count do
				spawnEnemy(group)
			end
		end
	end

	task.spawn(function()
		while true do
			task.wait(AI_TICK)
			local now = os.clock()
			for enemy in enemies do
				if enemy.alive then
					think(enemy, now)
				end
			end
		end
	end)
end

return EnemyService
