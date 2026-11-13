-- Os seis atributos do personagem. A ordem aqui é a ordem de exibição na interface.
-- Os efeitos numéricos ficam em Shared/Formulas; este arquivo só descreve.

local Attributes = {}

Attributes.START_VALUE = 5
Attributes.POINTS_PER_LEVEL = 3

Attributes.order = { "forca", "destreza", "estamina", "vigor", "sorte", "percepcao" }

Attributes.info = {
	forca = {
		name = "Força",
		description = "Aumenta o dano físico de cada golpe.",
	},
	destreza = {
		name = "Destreza",
		description = "Ataques mais rápidos, mais críticos e um pouco mais de velocidade.",
	},
	estamina = {
		name = "Estamina",
		description = "Mais fôlego para correr e atacar, e recuperação mais rápida.",
	},
	vigor = {
		name = "Vigor",
		description = "Aumenta a vida máxima.",
	},
	-- Sorte é fraca no começo e absurda no fim, de propósito: quase ninguém
	-- a escolhe primeiro, então quem aposta nela é recompensado.
	sorte = {
		name = "Sorte",
		description = "Golpes de sorte devastadores, inimigos que erram, XP em dobro, boladas de moedas, drops raros e chance de escapar da morte.",
	},
	percepcao = {
		name = "Percepção",
		description = "Revela inimigos, perigos e segredos a distâncias maiores.",
	},
}

function Attributes.defaults(): { [string]: number }
	local values = {}
	for _, key in Attributes.order do
		values[key] = Attributes.START_VALUE
	end
	return values
end

return Attributes
