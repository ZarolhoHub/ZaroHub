
-- Zarohub UI - Visual renovado com botão circular e paleta preta/amarelo
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "ZarohubUI"

-- 🔘 Botão flutuante visual (círculo amarelo vibrante)
local floatBtn = Instance.new("Frame", gui)
floatBtn.Size = UDim2.new(0, 60, 0, 60)
floatBtn.Position = UDim2.new(0, 20, 0.5, -30)
floatBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0) -- Amarelo vibrante
floatBtn.BorderSizePixel = 0
floatBtn.Active = true
floatBtn.Draggable = true

local floatCorner = Instance.new("UICorner", floatBtn)
floatCorner.CornerRadius = UDim.new(1, 0)

-- ✨ Brilho simulando botão clicável
local glow = Instance.new("UIStroke", floatBtn)
glow.Thickness = 2
glow.Color = Color3.fromRGB(255, 0, 0) -- Vermelho (borda)
glow.Transparency = 0.2

-- ▶️ Invisível botão de clique sobre o frame
local floatClick = Instance.new("TextButton", floatBtn)
floatClick.Size = UDim2.new(1, 0, 1, 0)
floatClick.BackgroundTransparency = 1
floatClick.Text = ""

-- 🧱 Painel principal
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 280, 0, 160)
frame.Position = UDim2.new(0.5, -140, 0.5, -80)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15) -- Preto base
frame.BorderSizePixel = 0
frame.Visible = false
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

-- 🏷️ Título com a nova identidade
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundTransparency = 1
title.Text = "⚡ ZAROHUB ⚡"
title.TextColor3 = Color3.fromRGB(255, 215, 0)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextStrokeTransparency = 0.7

-- 🔲 Área interna para botões (futuro)
local body = Instance.new("Frame", frame)
body.Size = UDim2.new(1, -20, 1, -50)
body.Position = UDim2.new(0, 10, 0, 40)
body.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
body.BorderSizePixel = 0
Instance.new("UICorner", body).CornerRadius = UDim.new(0, 6)

-- 👁 Abrir/fechar o painel ao clicar no botão visual
floatClick.MouseButton1Click:Connect(function()
	frame.Visible = not frame.Visible
end)
