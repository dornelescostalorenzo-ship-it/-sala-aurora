-- Interface principal: vida, fôlego, experiência, nível, moedas e avisos.
-- Lê os atributos que o servidor publica no Player; não decide nada.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local Net = require(ReplicatedStorage.Shared.Net)

local player = Players.LocalPlayer

local NOTIFY_COLORS = {
	luck = Color3.fromRGB(255, 215, 90),
	levelup = Color3.fromRGB(140, 230, 255),
	info = Color3.new(1, 1, 1),
}

local HudController = {}

local function make(className: string, props: { [string]: any }, parent: Instance?): any
	local instance = Instance.new(className)
	for key, value in props do
		(instance :: any)[key] = value
	end
	instance.Parent = parent
	return instance
end

local function makeBar(parent: Instance, order: number, color: Color3, height: number): (Frame, TextLabel)
	local back = make("Frame", {
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = Color3.fromRGB(20, 22, 28),
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
	}, parent)
	make("UICorner", { CornerRadius = UDim.new(0, 5) }, back)

	local fill = make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
	}, back)
	make("UICorner", { CornerRadius = UDim.new(0, 5) }, fill)

	local label = make("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = math.max(10, height - 6),
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeTransparency = 0.6,
		Text = "",
		ZIndex = 2,
	}, back)

	return fill, label
end

local function setBar(fill: Frame, label: TextLabel, value: number, max: number, text: string?)
	local ratio = if max > 0 then math.clamp(value / max, 0, 1) else 0
	TweenService:Create(fill, TweenInfo.new(0.15), { Size = UDim2.fromScale(ratio, 1) }):Play()
	label.Text = text or `{math.floor(value)} / {math.floor(max)}`
end

function HudController.start()
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	end)

	local gui = make("ScreenGui", {
		Name = "Hud",
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
	}, player:WaitForChild("PlayerGui"))

	local panel = make("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 16, 1, -16),
		Size = UDim2.new(0.28, 0, 0, 96),
		BackgroundTransparency = 1,
	}, gui)
	make("UISizeConstraint", { MinSize = Vector2.new(200, 96), MaxSize = Vector2.new(340, 96) }, panel)
	make("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 5),
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
	}, panel)

	local header = make("TextLabel", {
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeTransparency = 0.5,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "",
	}, panel)

	local healthFill, healthLabel = makeBar(panel, 2, Color3.fromRGB(215, 65, 65), 22)
	local staminaFill, staminaLabel = makeBar(panel, 3, Color3.fromRGB(95, 195, 110), 16)
	local xpFill, xpLabel = makeBar(panel, 4, Color3.fromRGB(110, 150, 240), 14)

	local toast = make("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.14),
		Size = UDim2.new(0.8, 0, 0, 34),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		TextSize = 26,
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeTransparency = 0.3,
		TextTransparency = 1,
		Text = "",
	}, gui)

	-- Atributos publicados pelo servidor -------------------------------------

	local function updateHeader()
		local level = player:GetAttribute("Level") or 1
		local coins = player:GetAttribute("Coins") or 0
		local points = player:GetAttribute("AttributePoints") or 0
		local text = `Nível {level}   •   {coins} moedas`
		if points > 0 then
			text ..= `   •   {points} pontos`
		end
		header.Text = text
	end

	local function updateStamina()
		setBar(staminaFill, staminaLabel, player:GetAttribute("Stamina") or 0, player:GetAttribute("MaxStamina") or 1)
	end

	local function updateXp()
		local xp = player:GetAttribute("XP") or 0
		local needed = player:GetAttribute("XPToNext") or 1
		setBar(xpFill, xpLabel, xp, needed, `XP {xp} / {needed}`)
	end

	for _, name in { "Level", "Coins", "AttributePoints" } do
		player:GetAttributeChangedSignal(name):Connect(updateHeader)
	end
	for _, name in { "Stamina", "MaxStamina" } do
		player:GetAttributeChangedSignal(name):Connect(updateStamina)
	end
	for _, name in { "XP", "XPToNext" } do
		player:GetAttributeChangedSignal(name):Connect(updateXp)
	end
	updateHeader()
	updateStamina()
	updateXp()

	-- Vida vem do Humanoid do personagem atual -------------------------------

	local function onCharacter(character: Model)
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		local function updateHealth()
			setBar(healthFill, healthLabel, humanoid.Health, humanoid.MaxHealth)
		end
		humanoid.HealthChanged:Connect(updateHealth)
		humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(updateHealth)
		updateHealth()
	end

	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end

	-- Avisos -----------------------------------------------------------------

	local toastId = 0
	Net.get("Notify").OnClientEvent:Connect(function(text: string, kind: string?)
		toastId += 1
		local id = toastId
		toast.Text = text
		toast.TextColor3 = NOTIFY_COLORS[kind or "info"] or NOTIFY_COLORS.info
		toast.TextTransparency = 0
		toast.TextStrokeTransparency = 0.3
		task.delay(2.2, function()
			if id == toastId then
				TweenService:Create(toast, TweenInfo.new(0.6), {
					TextTransparency = 1,
					TextStrokeTransparency = 1,
				}):Play()
			end
		end)
	end)
end

return HudController
