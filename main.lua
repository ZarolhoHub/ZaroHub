local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Criar GUI
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "ZarohubUI"

-- Botão flutuante
local floatBtn = Instance.new("TextButton", gui)
floatBtn.Size = UDim2.new(0, 60, 0, 60)
floatBtn.Position = UDim2.new(0, 20, 0.5, -30)
floatBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
floatBtn.Text = ""
floatBtn.Draggable = true
floatBtn.Active = true
floatBtn.AutoButtonColor = true
Instance.new("UICorner", floatBtn).CornerRadius = UDim.new(1, 0)

-- Contorno preto opcional
local stroke = Instance.new("UIStroke", floatBtn)
stroke.Thickness = 2
stroke.Color = Color3.fromRGB(0, 0, 0)
stroke.Transparency = 0.3

-- Painel principal
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 300, 0, 210)
frame.Position = UDim2.new(0.5, -150, 0.5, -100)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
frame.BorderSizePixel = 0
frame.Visible = false
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

-- Título
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundTransparency = 1
title.Text = "⚡ ZAROHUB ⚡"
title.TextColor3 = Color3.fromRGB(255, 215, 0)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextStrokeTransparency = 0.7
title.Visible = false

-- Detecção de jogo
local jogosSuportados = {
    [13127800756] = "Arm Wrestle Simulator"
}
local placeName = jogosSuportados[game.PlaceId]
local jogoSuportado = placeName ~= nil

local statusLabel = Instance.new("TextLabel", frame)
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.Position = UDim2.new(0, 0, 0, 35)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = jogoSuportado and ("🎮 Jogo detectado: " .. placeName) or "🚫 Jogo não suportado"
statusLabel.TextColor3 = jogoSuportado and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(255, 80, 80)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 14
statusLabel.TextStrokeTransparency = 0.7
statusLabel.Visible = false

-- Corpo do painel
local body = Instance.new("Frame", frame)
body.Size = UDim2.new(1, -20, 1, -60)
body.Position = UDim2.new(0, 10, 0, 60)
body.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Instance.new("UICorner", body).CornerRadius = UDim.new(0, 6)
body.Visible = false

-- Fade animado
local TweenService = game:GetService("TweenService")

local function fadeIn(obj)
    obj.Visible = true
    obj.BackgroundTransparency = 1
    title.Visible = true
    statusLabel.Visible = true
    body.Visible = true
    TweenService:Create(obj, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
end

local function fadeOut(obj)
    TweenService:Create(obj, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
    wait(0.3)
    obj.Visible = false
    title.Visible = false
    statusLabel.Visible = false
    body.Visible = false
end

floatBtn.MouseButton1Click:Connect(function()
    if frame.Visible then
        fadeOut(frame)
    else
        fadeIn(frame)
    end
end)

-- Abas
local abaFarm = Instance.new("TextButton", body)
abaFarm.Size = UDim2.new(0.5, -5, 0, 30)
abaFarm.Position = UDim2.new(0, 0, 0, 0)
abaFarm.Text = "Farm"
abaFarm.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
abaFarm.TextColor3 = Color3.fromRGB(255, 215, 0)
abaFarm.Font = Enum.Font.GothamBold
abaFarm.TextSize = 14
Instance.new("UICorner", abaFarm).CornerRadius = UDim.new(0, 6)

local abaUtils = Instance.new("TextButton", body)
abaUtils.Size = UDim2.new(0.5, -5, 0, 30)
abaUtils.Position = UDim2.new(0.5, 5, 0, 0)
abaUtils.Text = "Utilidades"
abaUtils.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
abaUtils.TextColor3 = Color3.fromRGB(255, 215, 0)
abaUtils.Font = Enum.Font.GothamBold
abaUtils.TextSize = 14
Instance.new("UICorner", abaUtils).CornerRadius = UDim.new(0, 6)

-- Frames das abas
local abaFarmFrame = Instance.new("Frame", body)
abaFarmFrame.Size = UDim2.new(1, 0, 1, -35)
abaFarmFrame.Position = UDim2.new(0, 0, 0, 35)
abaFarmFrame.BackgroundTransparency = 1
abaFarmFrame.Visible = true

local abaUtilsFrame = Instance.new("Frame", body)
abaUtilsFrame.Size = UDim2.new(1, 0, 1, -35)
abaUtilsFrame.Position = UDim2.new(0, 0, 0, 35)
abaUtilsFrame.BackgroundTransparency = 1
abaUtilsFrame.Visible = false

abaFarm.MouseButton1Click:Connect(function()
    abaFarmFrame.Visible = true
    abaUtilsFrame.Visible = false
end)

abaUtils.MouseButton1Click:Connect(function()
    abaFarmFrame.Visible = false
    abaUtilsFrame.Visible = true
end)

-- Criador de botões no estilo LDS
local function criarBotao(nome, posY, parent)
    local botao = Instance.new("TextButton", parent)
    botao.Size = UDim2.new(1, -20, 0, 35)
    botao.Position = UDim2.new(0, 10, 0, posY)
    botao.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    botao.TextColor3 = Color3.fromRGB(255, 215, 0)
    botao.Font = Enum.Font.GothamBold
    botao.TextSize = 14
    botao.Text = nome
    botao.AutoButtonColor = false
    Instance.new("UICorner", botao).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke", botao)
    stroke.Thickness = 1.2
    stroke.Color = Color3.fromRGB(255, 215, 0)
    stroke.Transparency = 0.4

    botao.MouseEnter:Connect(function()
        stroke.Transparency = 0
        botao.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    end)
    botao.MouseLeave:Connect(function()
        stroke.Transparency = 0.4
        botao.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    end)

    local ativo = false
    botao.MouseButton1Click:Connect(function()
        ativo = not ativo
        botao.Text = ativo and (nome .. " [ON]") or nome
        stroke.Color = ativo and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 215, 0)
    end)
end

-- Adiciona botões de exemplo na aba Farm
criarBotao("⚡ Auto Train", 0, abaFarmFrame)
criarBotao("🔁 Auto Rebirth", 45, abaFarmFrame)
