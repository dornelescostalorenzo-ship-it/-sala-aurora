-- Gera o campo inicial por código: terreno, rio, árvores, pedras e luz.
-- É um mundo provisório para testar o combate; a etapa 5 o substitui por
-- regiões construídas à mão. A semente fixa mantém o mapa igual em todo servidor.

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local SEED = 2050
local HALF_SIZE = 400
local RIVER_Z = 120
local RIVER_WIDTH = 26
local TREE_COUNT = 70
local ROCK_COUNT = 30

local WorldService = {}

local function part(props: { [string]: any }, parent: Instance): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		(p :: any)[key] = value
	end
	p.Parent = parent
	return p
end

local function nearRiver(z: number): boolean
	return math.abs(z - RIVER_Z) < RIVER_WIDTH
end

local function buildTerrain()
	local terrain = Workspace.Terrain
	terrain:FillBlock(CFrame.new(0, -10, 0), Vector3.new(HALF_SIZE * 2, 20, HALF_SIZE * 2), Enum.Material.Grass)

	-- Leito do rio: cava um canal, forra de areia e enche de água.
	terrain:FillBlock(CFrame.new(0, -4, RIVER_Z), Vector3.new(HALF_SIZE * 2, 8, RIVER_WIDTH), Enum.Material.Air)
	terrain:FillBlock(CFrame.new(0, -9, RIVER_Z), Vector3.new(HALF_SIZE * 2, 4, RIVER_WIDTH + 8), Enum.Material.Sand)
	terrain:FillBlock(CFrame.new(0, -4.5, RIVER_Z), Vector3.new(HALF_SIZE * 2, 5, RIVER_WIDTH), Enum.Material.Water)
end

local function buildTree(rng: Random, position: Vector3, parent: Instance)
	local height = rng:NextNumber(9, 16)
	local model = Instance.new("Model")
	model.Name = "Arvore"

	part({
		Name = "Tronco",
		Size = Vector3.new(1.8, height, 1.8),
		CFrame = CFrame.new(position + Vector3.new(0, height / 2, 0)),
		Material = Enum.Material.Wood,
		Color = Color3.fromRGB(104, 74, 50),
	}, model)

	for _ = 1, rng:NextInteger(2, 4) do
		local size = rng:NextNumber(7, 12)
		local offset = Vector3.new(rng:NextNumber(-3, 3), height + rng:NextNumber(-2, 3), rng:NextNumber(-3, 3))
		part({
			Name = "Copa",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(size, size, size),
			CFrame = CFrame.new(position + offset),
			Material = Enum.Material.Grass,
			Color = Color3.fromRGB(rng:NextInteger(60, 95), rng:NextInteger(140, 175), rng:NextInteger(60, 85)),
			CanCollide = false,
		}, model)
	end

	model.Parent = parent
end

local function buildRock(rng: Random, position: Vector3, parent: Instance)
	local size = rng:NextNumber(2, 6)
	part({
		Name = "Pedra",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(size * 1.3, size, size * 1.1),
		CFrame = CFrame.new(position + Vector3.new(0, size * 0.2, 0))
			* CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0),
		Material = Enum.Material.Slate,
		Color = Color3.fromRGB(125, 128, 132),
	}, parent)
end

local function scatter(rng: Random, count: number, minDistance: number, build: (Random, Vector3, Instance) -> (), parent: Instance)
	local placed = 0
	local attempts = 0
	while placed < count and attempts < count * 20 do
		attempts += 1
		local x = rng:NextNumber(-HALF_SIZE + 20, HALF_SIZE - 20)
		local z = rng:NextNumber(-HALF_SIZE + 20, HALF_SIZE - 20)
		if Vector3.new(x, 0, z).Magnitude >= minDistance and not nearRiver(z) then
			build(rng, Vector3.new(x, 0, z), parent)
			placed += 1
		end
	end
end

local function buildLighting()
	Lighting.ClockTime = 14.5
	Lighting.Brightness = 2.6
	Lighting.OutdoorAmbient = Color3.fromRGB(140, 150, 160)
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.5

	if not Lighting:FindFirstChildOfClass("Atmosphere") then
		local atmosphere = Instance.new("Atmosphere")
		atmosphere.Density = 0.28
		atmosphere.Offset = 0.1
		atmosphere.Color = Color3.fromRGB(200, 215, 235)
		atmosphere.Decay = Color3.fromRGB(150, 175, 200)
		atmosphere.Haze = 1.2
		atmosphere.Parent = Lighting
	end

	if not Lighting:FindFirstChildOfClass("BloomEffect") then
		local bloom = Instance.new("BloomEffect")
		bloom.Intensity = 0.35
		bloom.Size = 24
		bloom.Threshold = 1.1
		bloom.Parent = Lighting
	end
end

function WorldService.build()
	if Workspace:FindFirstChild("Mundo") then
		return
	end

	-- A placa padrão dos modelos do Studio ficaria sobreposta ao terreno.
	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
	end

	local world = Instance.new("Folder")
	world.Name = "Mundo"
	world.Parent = Workspace

	buildTerrain()

	local rng = Random.new(SEED)
	scatter(rng, TREE_COUNT, 45, buildTree, world)
	scatter(rng, ROCK_COUNT, 25, buildRock, world)

	if not Workspace:FindFirstChildWhichIsA("SpawnLocation", true) then
		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "Chegada"
		spawn.Anchored = true
		spawn.Size = Vector3.new(10, 1, 10)
		spawn.CFrame = CFrame.new(0, 0.5, 20)
		spawn.Material = Enum.Material.Neon
		spawn.Color = Color3.fromRGB(150, 220, 255)
		spawn.Transparency = 0.5
		spawn.CanCollide = false
		spawn.Parent = world
	end

	buildLighting()
end

return WorldService
