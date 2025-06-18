-- ZAROLOHO HUB V1 - Arm Wrestle Simulator (AUTO TRAIN)
local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local char = lp.Character or lp.CharacterAdded:Wait()
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "ZarolhoHub"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 240, 0, 140)
frame.Position = UDim2.new(0.5, -120, 0.5, -70)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "⚡ Zarolho Hub ⚡"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 18

local btn = Instance.new("TextButton", frame)
btn.Size = UDim2.new(1, -20, 0, 40)
btn.Position = UDim2.new(0, 10, 0, 50)
btn.BackgroundColor3 = Color3.fromRGB(80, 120, 200)
btn.Text = "Ativar Auto Train"
btn.TextColor3 = Color3.new(1, 1, 1)
btn.Font = Enum.Font.Gotham
btn.TextSize = 14

local ativo = false
btn.MouseButton1Click:Connect(function()
    ativo = not ativo
    btn.Text = ativo and "Desativar Auto Train" or "Ativar Auto Train"

    while ativo do
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("ClickDetector") and v.Parent and v.Parent.Name:lower():find("train") then
                fireclickdetector(v)
            end
        end
        wait(0.2)
    end
end)
