-- Experiência, níveis, pontos de atributo e moedas.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Attributes = require(ReplicatedStorage.Shared.Data.Attributes)
local Formulas = require(ReplicatedStorage.Shared.Formulas)
local Net = require(ReplicatedStorage.Shared.Net)
local DataService = require(script.Parent.DataService)
local StatsService = require(script.Parent.StatsService)

local ProgressionService = {}

local random = Random.new()

function ProgressionService.awardXp(player: Player, amount: number)
	local data = DataService.get(player)
	if not data or data.level >= Formulas.MAX_LEVEL then
		return
	end

	if random:NextNumber() < Formulas.doubleXpChance(data.attributes) then
		amount *= 2
		Net.get("Notify"):FireClient(player, `Sorte! XP em dobro (+{amount})`, "luck")
	end

	data.xp += amount

	local leveled = false
	while data.level < Formulas.MAX_LEVEL and data.xp >= Formulas.xpToNext(data.level) do
		data.xp -= Formulas.xpToNext(data.level)
		data.level += 1
		data.attributePoints += Attributes.POINTS_PER_LEVEL
		leveled = true
	end
	if data.level >= Formulas.MAX_LEVEL then
		data.xp = 0
	end

	StatsService.refresh(player, leveled)
	if leveled then
		Net.get("Notify"):FireClient(player, `Nível {data.level}!`, "levelup")
	end
end

function ProgressionService.awardCoins(player: Player, amount: number)
	local data = DataService.get(player)
	if not data then
		return
	end
	data.coins += math.max(1, math.floor(amount * Formulas.coinMultiplier(data.attributes) + 0.5))
	player:SetAttribute("Coins", data.coins)
end

return ProgressionService
