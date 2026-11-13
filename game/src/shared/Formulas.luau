-- Todas as contas do jogo num só lugar. Funções puras: recebem números,
-- devolvem números. Balancear o jogo é mexer apenas neste arquivo.

local Formulas = {}

Formulas.MAX_LEVEL = 50
Formulas.BASE_WEAPON_DAMAGE = 8
Formulas.ATTACK_RANGE = 9
Formulas.ATTACK_STAMINA_COST = 6
Formulas.SPRINT_STAMINA_PER_SECOND = 14
Formulas.SPRINT_SPEED_BONUS = 8
Formulas.CRIT_MULTIPLIER = 1.75
Formulas.CHEAT_DEATH_COOLDOWN = 30
Formulas.CHEAT_DEATH_HEAL = 0.3
Formulas.JACKPOT_MULTIPLIER = 10

type Attrs = { [string]: number }

-- Progressão -----------------------------------------------------------------

function Formulas.xpToNext(level: number): number
	return math.floor(40 * level ^ 1.5)
end

-- Vida, fôlego e movimento ---------------------------------------------------

function Formulas.maxHealth(level: number, attrs: Attrs): number
	return 80 + attrs.vigor * 8 + (level - 1) * 6
end

function Formulas.maxStamina(attrs: Attrs): number
	return 70 + attrs.estamina * 6
end

function Formulas.staminaRegen(attrs: Attrs): number
	return 10 + attrs.estamina * 0.6
end

function Formulas.walkSpeed(attrs: Attrs): number
	return 16 + math.min(4, attrs.destreza * 0.1)
end

-- Combate --------------------------------------------------------------------

function Formulas.attackDamage(level: number, attrs: Attrs, weaponDamage: number): number
	return weaponDamage + attrs.forca * 0.9 + (level - 1) * 0.5
end

function Formulas.attackInterval(attrs: Attrs): number
	return math.max(0.35, 0.8 - attrs.destreza * 0.012)
end

function Formulas.critChance(attrs: Attrs): number
	return math.min(0.5, 0.02 + attrs.destreza * 0.006)
end

-- Sorte ----------------------------------------------------------------------
-- O atributo mais forte do jogo, de propósito. Com 5 pontos (valor inicial)
-- quase não aparece; quem investe pesado vira outra coisa: com 40 pontos,
-- 40% dos golpes dão 5x de dano, 24% dos golpes inimigos erram e 60% dos
-- golpes fatais são anulados.

function Formulas.luckyStrikeChance(attrs: Attrs): number
	return math.min(0.50, attrs.sorte * 0.01)
end

-- O multiplicador do golpe de sorte também cresce com a Sorte.
function Formulas.luckyStrikeMultiplier(attrs: Attrs): number
	return math.min(6, 3 + attrs.sorte * 0.05)
end

-- Chance de um golpe inimigo simplesmente errar.
function Formulas.luckyDodgeChance(attrs: Attrs): number
	return math.min(0.30, attrs.sorte * 0.006)
end

function Formulas.doubleXpChance(attrs: Attrs): number
	return math.min(0.50, attrs.sorte * 0.01)
end

function Formulas.cheatDeathChance(attrs: Attrs): number
	return math.min(0.75, attrs.sorte * 0.015)
end

function Formulas.coinMultiplier(attrs: Attrs): number
	return 1 + attrs.sorte * 0.03
end

-- Chance de uma recompensa em moedas sair multiplicada por JACKPOT_MULTIPLIER.
function Formulas.jackpotChance(attrs: Attrs): number
	return math.min(0.20, attrs.sorte * 0.004)
end

-- Multiplica o peso das raridades altas na tabela de drops (etapa 3).
function Formulas.rareDropMultiplier(attrs: Attrs): number
	return 1 + attrs.sorte * 0.08
end

-- Percepção ------------------------------------------------------------------

-- Distância em studs em que segredos e inimigos ocultos aparecem (etapa 5).
function Formulas.revealRadius(attrs: Attrs): number
	return 40 + attrs.percepcao * 4
end

return Formulas
