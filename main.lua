-- Zarohub UI v1.0 - Visual, abas, detecção de jogo, animação

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local lp = Players.LocalPlayer

-- Criar a interface
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "ZarohubUI"

-- Botão flutuante (amarelo circular)
local floatBtn = Instance.new("TextButton", gui)
floatBtn.Size = UDim2.new(0, 60, 0, 60)
floatBtn.Position = UDim2.new(0, 20, 0.5, -30)
floatBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0) -- Amarelo vibrante
floatBtn.BorderSizePixel = 0
floatBtn.Text = ""
floatBtn.Draggable = true
floatBtn.Active = true
floatBtn.AutoButtonColor = true
Instance.new("UICorner", floatBtn).CornerRadius = UDim.new(1, 0)

-- Contorno preto
