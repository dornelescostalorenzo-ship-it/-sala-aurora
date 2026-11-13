-- Ponto único de comunicação cliente/servidor. O servidor cria os
-- RemoteEvents; o cliente espera por eles. Use Net.get("Nome").
--
-- Cliente -> servidor: Attack(), Sprint(ativo: boolean)
-- Servidor -> cliente: DamageDealt(posicao: Vector3, valor: number, tipo: string)
--                      Notify(texto: string, tipo: string)

local RunService = game:GetService("RunService")

local REMOTE_NAMES = { "Attack", "Sprint", "DamageDealt", "Notify" }
local FOLDER_NAME = "Remotes"

local Net = {}

local folder: Instance

if RunService:IsServer() then
	local existing = script.Parent:FindFirstChild(FOLDER_NAME)
	if existing then
		folder = existing
	else
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		for _, name in REMOTE_NAMES do
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
		folder.Parent = script.Parent
	end
else
	folder = script.Parent:WaitForChild(FOLDER_NAME)
end

function Net.get(name: string): RemoteEvent
	return folder:WaitForChild(name) :: RemoteEvent
end

return Net
