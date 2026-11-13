-- Números de dano que sobem e somem sobre o inimigo atingido.

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local STYLES = {
	normal = { color = Color3.new(1, 1, 1), scale = 1, suffix = "" },
	crit = { color = Color3.fromRGB(255, 150, 60), scale = 1.35, suffix = "!" },
	luck = { color = Color3.fromRGB(255, 215, 90), scale = 1.7, suffix = " SORTE!" },
}

local DURATION = 0.9

local DamageNumbers = {}

local random = Random.new()

function DamageNumbers.show(position: Vector3, amount: number, kind: string?)
	local style = STYLES[kind or "normal"] or STYLES.normal

	local anchor = Instance.new("Attachment")
	anchor.WorldPosition = position + Vector3.new(random:NextNumber(-1, 1), 0, random:NextNumber(-1, 1))
	anchor.Parent = Workspace.Terrain

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromScale(6 * style.scale, 1.6 * style.scale)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.Parent = anchor

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = style.color
	label.TextStrokeTransparency = 0.2
	label.Text = `{amount}{style.suffix}`
	label.Parent = billboard

	local info = TweenInfo.new(DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(billboard, info, { StudsOffset = Vector3.new(0, 3.5, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(DURATION * 0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, DURATION * 0.5), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()

	Debris:AddItem(anchor, DURATION + 0.1)
end

return DamageNumbers
