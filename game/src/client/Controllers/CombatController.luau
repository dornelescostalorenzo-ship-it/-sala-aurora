-- Entrada de combate: atacar e correr. O cliente só pede ao servidor e
-- mostra o efeito visual; o dano é sempre decidido no servidor.
--
-- Teclado/mouse: clique esquerdo ataca, Shift corre.
-- Controle: R2 ataca, L3 corre. Celular: botões na tela.

local ContextActionService = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Net = require(ReplicatedStorage.Shared.Net)
local DamageNumbers = require(script.Parent.DamageNumbers)

-- Animação padrão de golpe do Roblox para avatares R15.
local SLASH_ANIMATION_ID = "rbxassetid://522635514"
local LOCAL_COOLDOWN = 0.3

local player = Players.LocalPlayer

local CombatController = {}

local lastSwing = 0
local slashTrack: AnimationTrack? = nil

local function loadSlash(character: Model)
	slashTrack = nil
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local animator = humanoid:WaitForChild("Animator", 5)
	if not animator then
		return
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = SLASH_ANIMATION_ID
	local ok, track = pcall(function()
		return (animator :: Animator):LoadAnimation(animation)
	end)
	if ok then
		track.Priority = Enum.AnimationPriority.Action
		slashTrack = track
	end
end

local function slashEffect(root: BasePart)
	local arc = Instance.new("Part")
	arc.Name = "Corte"
	arc.Anchored = true
	arc.CanCollide = false
	arc.CanQuery = false
	arc.CanTouch = false
	arc.Material = Enum.Material.Neon
	arc.Color = Color3.fromRGB(235, 245, 255)
	arc.Transparency = 0.35
	arc.Size = Vector3.new(7, 0.15, 2.5)
	arc.CFrame = root.CFrame * CFrame.new(0, 0.5, -4) * CFrame.Angles(0, 0, math.rad(-18))
	arc.Parent = Workspace
	TweenService:Create(arc, TweenInfo.new(0.18), {
		Transparency = 1,
		Size = Vector3.new(9, 0.05, 3.5),
	}):Play()
	Debris:AddItem(arc, 0.25)
end

local function attack()
	local now = os.clock()
	if now - lastSwing < LOCAL_COOLDOWN then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root then
		return
	end
	if (player:GetAttribute("Stamina") or 0) < 6 then
		return
	end

	lastSwing = now
	Net.get("Attack"):FireServer()
	if slashTrack then
		slashTrack:Play(0.05)
	end
	slashEffect(root :: BasePart)
end

function CombatController.start()
	player.CharacterAdded:Connect(loadSlash)
	if player.Character then
		task.spawn(loadSlash, player.Character)
	end

	ContextActionService:BindAction("Atacar", function(_, state)
		if state == Enum.UserInputState.Begin then
			attack()
		end
		return Enum.ContextActionResult.Pass
	end, true, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2)
	ContextActionService:SetTitle("Atacar", "Atacar")
	ContextActionService:SetPosition("Atacar", UDim2.new(1, -95, 1, -150))

	local sprint = Net.get("Sprint")
	ContextActionService:BindAction("Correr", function(_, state)
		if state == Enum.UserInputState.Begin then
			sprint:FireServer(true)
		elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
			sprint:FireServer(false)
		end
		return Enum.ContextActionResult.Pass
	end, true, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3)
	ContextActionService:SetTitle("Correr", "Correr")
	ContextActionService:SetPosition("Correr", UDim2.new(1, -170, 1, -95))

	Net.get("DamageDealt").OnClientEvent:Connect(function(position: Vector3, amount: number, kind: string)
		DamageNumbers.show(position, amount, kind)
	end)
end

return CombatController
