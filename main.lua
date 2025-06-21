-- Zarohub UI - Botão flutuante e painel 100% móveis
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "ZarohubUI"

-- 🔘 Botão flutuante real (TextButton circular amarelo)
local floatBtn = Instance.new("TextButton", gui)
floatBtn.Size = UDim2.new(0, 60, 0, 60)
floatBtn.Position = UDim2.new(0, 20, 0.5, -30)
floatBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0) -- Amarelo vibrante
floatBtn.BorderSizePixel = 0
floatBtn.Text = ""
floatBtn.Draggable = true
floatBtn.Active = true
floatBtn.AutoButtonColor = true

-- Canto arredondado
local floatCorner = Instance.new("UICorner", floatBtn)
floatCorner.CornerRadius = UDim.new(1, 0)

-- Contorno vermelho vibrante
local glow = Instance.new("UIStroke", floatBtn)
glow.Thickness = 2
glow.Color = Color3.fromRGB(255, 0, 0)
glow.Transparency = 0.2

-- 🧱 Painel principal
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 280, 0, 160)
frame.Position = UDim2.new(0.5, -140, 0.5, -80)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
frame.BorderSizePixel = 0
frame.Visible = false
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

-- 🏷️ Título
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundTransparency = 1
title.Text = "⚡ ZAROHUB ⚡"
title.TextColor3 = Color3.fromRGB(255, 215, 0)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextStrokeTransparency = 0.7

-- 🔲 Corpo do painel (reserva pra botões)
local body = Instance.new("Frame", frame)
body.Size = UDim2.new(1, -20, 1, -50)
body.Position = UDim2.new(0, 10, 0, 40)
body.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
body.BorderSizePixel = 0
Instance.new("UICorner", body).CornerRadius = UDim.new(0, 6)

-- 👁 Abrir/fechar painel ao clicar no botão flutuante
floatBtn.MouseButton1Click:Connect(function()
	frame.Visible = not frame.Visible
end)
