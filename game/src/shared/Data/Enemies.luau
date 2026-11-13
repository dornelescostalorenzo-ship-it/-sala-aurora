-- Definições dos inimigos. Para criar um inimigo novo, acrescente uma entrada
-- aqui e cite a chave em Data/Regions.
--
-- behavior: "chase" (persegue e ataca de perto). Outros comportamentos
-- (atirador, guardião) entram na etapa 4.

return {
	orvalhito = {
		name = "Orvalhito",
		level = 1,
		behavior = "chase",
		health = 30,
		damage = 5,
		speed = 9,
		size = 3,
		color = Color3.fromRGB(110, 205, 235),
		aggroRange = 28,
		leashRange = 70,
		wanderRange = 18,
		attackRange = 3.5,
		attackCooldown = 1.6,
		attackWindup = 0.45,
		xp = 12,
		coins = { 1, 3 },
		respawn = 12,
	},

	orvalho_rubro = {
		name = "Orvalho Rubro",
		level = 3,
		behavior = "chase",
		health = 85,
		damage = 10,
		speed = 11,
		size = 4.5,
		color = Color3.fromRGB(225, 95, 85),
		aggroRange = 34,
		leashRange = 80,
		wanderRange = 22,
		attackRange = 4,
		attackCooldown = 1.4,
		attackWindup = 0.4,
		xp = 34,
		coins = { 3, 7 },
		respawn = 20,
	},
}
