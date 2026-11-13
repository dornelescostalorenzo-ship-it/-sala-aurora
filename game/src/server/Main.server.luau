-- Ponto de entrada do servidor: monta o mundo, inicia os serviços na ordem
-- de dependência e acompanha a entrada e saída de jogadores.

local Players = game:GetService("Players")

local Services = script.Parent.Services
local CombatService = require(Services.CombatService)
local DataService = require(Services.DataService)
local EnemyService = require(Services.EnemyService)
local StatsService = require(Services.StatsService)
local WorldService = require(Services.WorldService)

WorldService.build()
DataService.start()
StatsService.start()
EnemyService.start()
CombatService.start()

local function onPlayerAdded(player: Player)
	local data = DataService.load(player)
	if not data then
		if player.Parent then
			player:Kick("Não foi possível carregar seus dados com segurança. Tente novamente em instantes.")
		end
		return
	end
	StatsService.setup(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	DataService.release(player)
end)

print("[Aurora] Servidor iniciado.")
