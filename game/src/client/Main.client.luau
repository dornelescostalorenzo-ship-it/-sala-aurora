-- Ponto de entrada do cliente.

local Controllers = script.Parent.Controllers

require(Controllers.HudController).start()
require(Controllers.CombatController).start()
