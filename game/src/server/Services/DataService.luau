-- Carrega e salva o perfil de cada jogador.
--
-- Trava de sessão: ao carregar, o servidor grava seu JobId no perfil. Outro
-- servidor que tente carregar o mesmo perfil espera a trava ser liberada (ou
-- expirar), o que evita duplicar itens ao trocar de servidor rapidamente.
--
-- No Studio sem acesso à API de DataStore, o perfil vive só na memória.

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Attributes = require(ReplicatedStorage.Shared.Data.Attributes)

local STORE_NAME = "Perfil_v1"
local LOCK_TIMEOUT = 120
local LOAD_ATTEMPTS = 5
local LOAD_RETRY_DELAY = 6
local AUTOSAVE_INTERVAL = 90

local DataService = {}

local profiles: { [Player]: any } = {}
local memoryOnly: { [Player]: boolean } = {}

local store: DataStore? = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result
	else
		warn("[DataService] DataStore indisponível:", result)
	end
end

local function template()
	return {
		version = 1,
		level = 1,
		xp = 0,
		coins = 0,
		attributePoints = 0,
		attributes = Attributes.defaults(),
	}
end

-- Preenche em `data` as chaves que existem em `defaults` e faltam nele.
local function reconcile(data: any, defaults: any)
	for key, value in defaults do
		if data[key] == nil then
			data[key] = value
		elseif type(value) == "table" and type(data[key]) == "table" then
			reconcile(data[key], value)
		end
	end
end

local function keyFor(player: Player): string
	return "u_" .. player.UserId
end

-- Devolve o perfil, ou nil se não foi possível carregar com segurança.
function DataService.load(player: Player): any?
	if not store then
		if RunService:IsStudio() then
			profiles[player] = template()
			memoryOnly[player] = true
			return profiles[player]
		end
		return nil
	end

	for attempt = 1, LOAD_ATTEMPTS do
		local locked = false
		local loaded = nil

		local ok, err = pcall(function()
			(store :: DataStore):UpdateAsync(keyFor(player), function(current)
				current = current or {}
				local lock = current._lock
				if lock and lock.jobId ~= game.JobId and os.time() - lock.time < LOCK_TIMEOUT then
					locked = true
					return nil
				end
				locked = false
				current._lock = { jobId = game.JobId, time = os.time() }
				loaded = current
				return current
			end)
		end)

		if not player.Parent then
			return nil
		end

		if ok and loaded and not locked then
			loaded._lock = nil
			reconcile(loaded, template())
			profiles[player] = loaded
			return loaded
		end

		if not ok then
			warn(`[DataService] Falha ao carregar {player.Name} (tentativa {attempt}):`, err)
			if RunService:IsStudio() then
				profiles[player] = template()
				memoryOnly[player] = true
				return profiles[player]
			end
		end

		task.wait(LOAD_RETRY_DELAY)
	end

	return nil
end

function DataService.get(player: Player): any?
	return profiles[player]
end

local function write(player: Player, release: boolean)
	local data = profiles[player]
	if not data or memoryOnly[player] or not store then
		return
	end

	local ok, err = pcall(function()
		(store :: DataStore):UpdateAsync(keyFor(player), function(current)
			local lock = current and current._lock
			if lock and lock.jobId ~= game.JobId then
				-- Outro servidor assumiu o perfil; não sobrescrever.
				return nil
			end
			local toSave = table.clone(data)
			toSave._lock = if release then nil else { jobId = game.JobId, time = os.time() }
			return toSave
		end)
	end)

	if not ok then
		warn(`[DataService] Falha ao salvar {player.Name}:`, err)
	end
end

function DataService.save(player: Player)
	write(player, false)
end

-- Salva, libera a trava e esquece o perfil. Chamar quando o jogador sai.
function DataService.release(player: Player)
	write(player, true)
	profiles[player] = nil
	memoryOnly[player] = nil
end

function DataService.start()
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for player in profiles do
				task.spawn(write, player, false)
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for player in profiles do
			pending += 1
			task.spawn(function()
				DataService.release(player)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end

return DataService
