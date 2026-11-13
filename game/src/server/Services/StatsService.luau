-- Transforma nível + atributos em valores finais (vida, fôlego, velocidade)
-- e cuida do que muda a cada instante: fôlego, corrida e dano recebido.
--
-- O estado visível é publicado como atributos do Player, que o Roblox
-- replica sozinho para o cliente: Level, XP, XPToNext, Coins,
-- AttributePoints, Stamina, MaxStamina.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Formulas = require(ReplicatedStorage.Shared.Formulas)
local Net = require(ReplicatedStorage.Shared.Net)
local DataService = require(script.Parent.DataService)

local STAMINA_REGEN_DELAY = 1

local StatsService = {}

type State = {
	stamina: number,
	maxStamina: number,
	regen: number,
	baseSpeed: number,
	sprinting: boolean,
	lastSpend: number,
	lastCheatDeath: number,
	connection: RBXScriptConnection?,
}

local states: { [Player]: State } = {}
local random = Random.new()

local function humanoidOf(player: Player): Humanoid?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		return humanoid
	end
	return nil
end

local function applySpeed(player: Player, state: State)
	local humanoid = humanoidOf(player)
	if humanoid then
		humanoid.WalkSpeed = state.baseSpeed + (if state.sprinting then Formulas.SPRINT_SPEED_BONUS else 0)
	end
end

-- Recalcula tudo a partir do perfil. Chamar após subir de nível, distribuir
-- pontos ou trocar de equipamento. `heal` enche a vida.
function StatsService.refresh(player: Player, heal: boolean?)
	local data = DataService.get(player)
	local state = states[player]
	if not data or not state then
		return
	end

	state.maxStamina = Formulas.maxStamina(data.attributes)
	state.regen = Formulas.staminaRegen(data.attributes)
	state.baseSpeed = Formulas.walkSpeed(data.attributes)
	state.stamina = math.min(state.stamina, state.maxStamina)

	player:SetAttribute("Level", data.level)
	player:SetAttribute("XP", data.xp)
	player:SetAttribute("XPToNext", Formulas.xpToNext(data.level))
	player:SetAttribute("Coins", data.coins)
	player:SetAttribute("AttributePoints", data.attributePoints)
	player:SetAttribute("MaxStamina", state.maxStamina)
	player:SetAttribute("Stamina", math.floor(state.stamina))

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local maxHealth = Formulas.maxHealth(data.level, data.attributes)
		humanoid.MaxHealth = maxHealth
		if heal then
			humanoid.Health = maxHealth
		end
		applySpeed(player, state)
	end
end

function StatsService.setup(player: Player)
	local data = DataService.get(player)
	if not data then
		return
	end

	local state: State = {
		stamina = Formulas.maxStamina(data.attributes),
		maxStamina = 0,
		regen = 0,
		baseSpeed = 16,
		sprinting = false,
		lastSpend = 0,
		lastCheatDeath = -math.huge,
		connection = nil,
	}
	states[player] = state

	local function onCharacter(character: Model)
		character:WaitForChild("Humanoid")
		state.sprinting = false
		state.stamina = state.maxStamina
		StatsService.refresh(player, true)
	end

	state.connection = player.CharacterAdded:Connect(onCharacter)
	StatsService.refresh(player)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end

function StatsService.cleanup(player: Player)
	local state = states[player]
	if state and state.connection then
		state.connection:Disconnect()
	end
	states[player] = nil
end

-- Gasta fôlego. Devolve false (sem gastar) se não houver o suficiente.
function StatsService.trySpend(player: Player, amount: number): boolean
	local state = states[player]
	if not state or state.stamina < amount then
		return false
	end
	state.stamina -= amount
	state.lastSpend = os.clock()
	player:SetAttribute("Stamina", math.floor(state.stamina))
	return true
end

function StatsService.setSprint(player: Player, active: boolean)
	local state = states[player]
	if not state then
		return
	end
	state.sprinting = active and state.stamina > 5
	applySpeed(player, state)
end

-- Todo dano de inimigos passa por aqui, para que a Sorte possa salvar o
-- jogador de um golpe fatal.
function StatsService.damagePlayer(player: Player, amount: number)
	local data = DataService.get(player)
	local state = states[player]
	local humanoid = humanoidOf(player)
	if not data or not state or not humanoid then
		return
	end

	if amount >= humanoid.Health then
		local now = os.clock()
		local offCooldown = now - state.lastCheatDeath >= Formulas.CHEAT_DEATH_COOLDOWN
		if offCooldown and random:NextNumber() < Formulas.cheatDeathChance(data.attributes) then
			state.lastCheatDeath = now
			humanoid.Health = 1
			Net.get("Notify"):FireClient(player, "Por um triz! A sorte te salvou.", "luck")
			return
		end
	end

	humanoid:TakeDamage(amount)
end

function StatsService.start()
	RunService.Heartbeat:Connect(function(dt)
		local now = os.clock()
		for player, state in states do
			local before = math.floor(state.stamina)
			local humanoid = humanoidOf(player)

			if state.sprinting and humanoid and humanoid.MoveDirection.Magnitude > 0 then
				state.stamina = math.max(0, state.stamina - Formulas.SPRINT_STAMINA_PER_SECOND * dt)
				state.lastSpend = now
				if state.stamina <= 0 then
					state.sprinting = false
					applySpeed(player, state)
				end
			elseif now - state.lastSpend >= STAMINA_REGEN_DELAY then
				state.stamina = math.min(state.maxStamina, state.stamina + state.regen * dt)
			end

			local after = math.floor(state.stamina)
			if after ~= before then
				player:SetAttribute("Stamina", after)
			end
		end
	end)

	Net.get("Sprint").OnServerEvent:Connect(function(player, active)
		if type(active) == "boolean" then
			StatsService.setSprint(player, active)
		end
	end)

	Players.PlayerRemoving:Connect(StatsService.cleanup)
end

return StatsService
