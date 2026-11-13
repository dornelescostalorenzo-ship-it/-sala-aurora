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
Formulas.LUCKY_STRIKE_MULTIPLIER = 3
Formulas.CHEAT_DEATH_COOLDOWN = 45

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
-- Com 5 pontos (valor inicial) os efeitos quase não aparecem; com 40 ou mais
-- o personagem dá dano triplo em um terço dos golpes e sobrevive a metade
-- dos golpes fatais.

function Formulas.luckyStrikeChance(attrs: Attrs): number
	return math.min(0.40, attrs.sorte * 0.008)
end

function Formulas.doubleXpChance(attrs: Attrs): number
	return math.min(0.35, attrs.sorte * 0.007)
end

function Formulas.cheatDeathChance(attrs: Attrs): number
	return math.min(0.60, attrs.sorte * 0.012)
end

function Formulas.coinMultiplier(attrs: Attrs): number
	return 1 + attrs.sorte * 0.02
end

-- Multiplica o peso das raridades altas na tabela de drops (etapa 3).
function Formulas.rareDropMultiplier(attrs: Attrs): number
	return 1 + attrs.sorte * 0.05
end

-- Percepção ------------------------------------------------------------------

-- Distância em studs em que segredos e inimigos ocultos aparecem (etapa 5).
function Formulas.revealRadius(attrs: Attrs): number
	return 40 + attrs.percepcao * 4
end

return Formulas
