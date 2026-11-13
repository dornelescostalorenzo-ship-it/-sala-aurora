-- Regiões do mundo e seus grupos de inimigos. Cada grupo mantém `count`
-- inimigos vivos espalhados num círculo de raio `radius` ao redor de `center`.

return {
	campos_do_limiar = {
		name = "Campos do Limiar",
		recommendedLevel = 1,
		spawnGroups = {
			{ enemy = "orvalhito", center = Vector3.new(70, 0, -40), radius = 35, count = 6 },
			{ enemy = "orvalhito", center = Vector3.new(-80, 0, -60), radius = 35, count = 6 },
			{ enemy = "orvalhito", center = Vector3.new(0, 0, -130), radius = 40, count = 5 },
			{ enemy = "orvalho_rubro", center = Vector3.new(150, 0, -170), radius = 40, count = 4 },
			{ enemy = "orvalho_rubro", center = Vector3.new(-160, 0, -190), radius = 40, count = 4 },
		},
	},
}
