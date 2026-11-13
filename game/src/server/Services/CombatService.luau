-- Recebe os pedidos de ataque dos clientes e decide tudo no servidor:
-- se o golpe é permitido, quem ele acerta e quanto dano causa.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Formulas = require(ReplicatedStorage.Shared.Formulas)
local Net = require(ReplicatedStorage.Shared.Net)
local DataService = require(script.Parent.DataService)
local EnemyService = require(script.Parent.EnemyService)
local StatsService = require(script.Parent.StatsService)

local MAX_TARGETS = 3
local ARC_MIN_DOT = 0.2
-- Folga para a latência: o cliente pode pedir o golpe um pouco antes da hora.
local COOLDOWN_TOLERANCE = 0.9

local CombatService = {}

local lastAttack: { [Player]: number } = {}
local random = Random.new()

local function rollDamage(data: any): (number, string)
	local attrs = data.attributes
	local damage = Formulas.attackDamage(data.level, attrs, Formulas.BASE_WEAPON_DAMAGE)
	damage *= random:NextNumber(0.9, 1.1)

	local kind = "normal"
	if random:NextNumber() < Formulas.luckyStrikeChance(attrs) then
		damage *= Formulas.LUCKY_STRIKE_MULTIPLIER
		kind = "luck"
	elseif random:NextNumber() < Formulas.critChance(attrs) then
		damage *= Formulas.CRIT_MULTIPLIER
		kind = "crit"
	end

	return math.max(1, math.floor(damage + 0.5)), kind
end

local function onAttack(player: Player)
	local data = DataService.get(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not data or not humanoid or humanoid.Health <= 0 or not root then
		return
	end

	local now = os.clock()
	local interval = Formulas.attackInterval(data.attributes) * COOLDOWN_TOLERANCE
	if now - (lastAttack[player] or 0) < interval then
		return
	end
	if not StatsService.trySpend(player, Formulas.ATTACK_STAMINA_COST) then
		return
	end
	lastAttack[player] = now

	local targets = EnemyService.inArc((root :: BasePart).CFrame, Formulas.ATTACK_RANGE, ARC_MIN_DOT)
	local damageDealt = Net.get("DamageDealt")
	for index, enemy in targets do
		if index > MAX_TARGETS then
			break
		end
		local damage, kind = rollDamage(data)
		local position = enemy.root.Position + Vector3.new(0, enemy.def.size / 2 + 1, 0)
		EnemyService.damage(enemy, damage, player)
		damageDealt:FireClient(player, position, damage, kind)
	end
end

function CombatService.start()
	Net.get("Attack").OnServerEvent:Connect(onAttack)
	Players.PlayerRemoving:Connect(function(player)
		lastAttack[player] = nil
	end)
end

return CombatService
