local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "ZarohubUI"

-- Bolinha flutuante
local floatBtn = Instance.new("TextButton", gui)
floatBtn.Size = UDim2.new(0, 60, 0, 60)
floatBtn.Position = UDim2.new(0, 20, 0.5, -30)
floatBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
floatBtn.Text = ""
floatBtn.AutoButtonColor = false
floatBtn.Active = true
Instance.new("UICorner", floatBtn).CornerRadius = UDim.new(1, 0)
local strokeFloat = Instance.new("UIStroke", floatBtn)
strokeFloat.Thickness = 2
strokeFloat.Color = Color3.fromRGB(0, 0, 0)

-- Painel principal
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 0, 0, 0) -- start fechado
frame.Position = UDim2.new(0.5, 0, 0.5, 0)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
frame.BorderSizePixel = 0
frame.Visible = false
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
frame.ClipsDescendants = true

-- Título (arrastável)
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
title.BackgroundTransparency = 0.3
title.Text = "⚡ ZAROHUB ⚡"
title.TextColor3 = Color3.fromRGB(255, 215, 0)
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.TextXAlignment = Enum.TextXAlignment.Center
title.Active = true

-- Menu lateral (vertical)
local menu = Instance.new("Frame", frame)
menu.Size = UDim2.new(0, 100, 1, -35)
menu.Position = UDim2.new(0, 0, 0, 35)
menu.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 10)

local menuScroll = Instance.new("ScrollingFrame", menu)
menuScroll.Size = UDim2.new(1, 0, 1, 0)
menuScroll.CanvasSize = UDim2.new(0, 0, 2, 0)
menuScroll.BackgroundTransparency = 1
menuScroll.ScrollBarThickness = 5
menuScroll.VerticalScrollBarInset = Enum.ScrollBarInset.Always

-- Conteúdo principal
local content = Instance.new("Frame", frame)
content.Size = UDim2.new(1, -100, 1, -35)
content.Position = UDim2.new(0, 100, 0, 35)
content.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Instance.new("UICorner", content).CornerRadius = UDim.new(0, 10)

local contentScroll = Instance.new("ScrollingFrame", content)
contentScroll.Size = UDim2.new(1, 0, 1, 0)
contentScroll.CanvasSize = UDim2.new(0, 0, 2, 0)
contentScroll.BackgroundTransparency = 1
contentScroll.ScrollBarThickness = 5
contentScroll.VerticalScrollBarInset = Enum.ScrollBarInset.Always

-- Botões do menu
local function criarBotao(texto, y)
	local btn = Instance.new("TextButton", menuScroll)
	btn.Size = UDim2.new(1, -20, 0, 50)
	btn.Position = UDim2.new(0, 10, 0, y)
	btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	btn.TextColor3 = Color3.fromRGB(255, 215, 0)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 18
	btn.Text = texto
	btn.AutoButtonColor = false
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)

	local stroke = Instance.new("UIStroke", btn)
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(255, 215, 0)
	stroke.Transparency = 0.5

	btn.MouseEnter:Connect(function()
		stroke.Transparency = 0
		btn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	end)
	btn.MouseLeave:Connect(function()
		stroke.Transparency = 0.5
		btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	end)

	return btn
end

local eventoBtn = criarBotao("Evento", 10)
local treinarBtn = criarBotao("Treinar", 70)
local ovosBtn = criarBotao("Ovos", 130)

-- Conteúdo de cada aba
local function criarTexto(txt)
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, -20, 0, 60)
	t.Position = UDim2.new(0, 10, 0, 10)
	t.Text = txt
	t.TextColor3 = Color3.fromRGB(255, 215, 0)
	t.Font = Enum.Font.GothamBold
	t.TextSize = 22
	t.BackgroundTransparency = 1
	return t
end

local eventoTexto = criarTexto("⚡ Conteúdo do Evento ⚡")
eventoTexto.Parent = contentScroll
local treinarTexto = criarTexto("💪 Conteúdo de Treinar")
treinarTexto.Visible = false
treinarTexto.Parent = contentScroll
local ovosTexto = criarTexto("🥚 Conteúdo dos Ovos")
ovosTexto.Visible = false
ovosTexto.Parent = contentScroll

local function mostrar(qual)
	eventoTexto.Visible = qual == "Evento"
	treinarTexto.Visible = qual == "Treinar"
	ovosTexto.Visible = qual == "Ovos"
end

eventoBtn.MouseButton1Click:Connect(function() mostrar("Evento") end)
treinarBtn.MouseButton1Click:Connect(function() mostrar("Treinar") end)
ovosBtn.MouseButton1Click:Connect(function() mostrar("Ovos") end)

-- Animações do painel
local painelAberto = false
local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function abrirPainel()
	frame.Visible = true
	local abrirSize = UDim2.new(0, 380, 0, 280)
	local abrirPos = UDim2.new(0.5, 0, 0.5, 0)
	local sizeTween = TweenService:Create(frame, tweenInfo, {Size = abrirSize})
	local posTween = TweenService:Create(frame, tweenInfo, {Position = abrirPos})
	sizeTween:Play()
	posTween:Play()
end

local function fecharPainel()
	local fecharSize = UDim2.new(0, 0, 0, 0)
	local fecharPos = UDim2.new(0.5, 0, 0.5, 0)
	local sizeTween = TweenService:Create(frame, tweenInfo, {Size = fecharSize})
	local posTween = TweenService:Create(frame, tweenInfo, {Position = fecharPos})
	sizeTween:Play()
	posTween:Play()
	sizeTween.Completed:Wait()
	frame.Visible = false
end

-- Lixeira
local trashArea = Instance.new("Frame", gui)
trashArea.Size = UDim2.new(0, 120, 0, 120)
trashArea.Position = UDim2.new(0.5, -60, 1, -130)
trashArea.BackgroundTransparency = 1
trashArea.Visible = false

local trashIcon = Instance.new("TextLabel", trashArea)
trashIcon.Size = UDim2.new(0, 50, 0, 50)
trashIcon.Position = UDim2.new(0.5, -25, 0.5, -25)
trashIcon.BackgroundTransparency = 1
trashIcon.Text = "🗑️"
trashIcon.TextScaled = true
trashIcon.TextColor3 = Color3.fromRGB(255, 0, 0)
trashIcon.Font = Enum.Font.GothamBold

-- Arrastar bolinha
local dragging = false
local dragInput, dragStart, startPos
local isDragging = false

floatBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		isDragging = false
		dragStart = input.Position
		startPos = floatBtn.Position
		trashArea.Visible = true
		trashIcon.TextTransparency = 1

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
				trashArea.Visible = false
				trashIcon.TextTransparency = 1

				local btnPos = floatBtn.AbsolutePosition
				local trashPos = trashArea.AbsolutePosition
				local trashSize = trashArea.AbsoluteSize
				local insideX = btnPos.X > trashPos.X and btnPos.X < trashPos.X + trashSize.X
				local insideY = btnPos.Y > trashPos.Y and btnPos.Y < trashPos.Y + trashSize.Y

				if insideX and insideY then
					gui:Destroy()
				end
			end
		end)
	end
end)

floatBtn.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		floatBtn.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
		isDragging = true

		local btnPos = floatBtn.AbsolutePosition + floatBtn.AbsoluteSize / 2
		local trashPos = trashArea.AbsolutePosition + trashArea.AbsoluteSize / 2
		local dist = (btnPos - trashPos).Magnitude
		local alpha = math.clamp(1 - dist / 200, 0, 1)
		trashIcon.TextTransparency = 1 - alpha
	end
end)

-- Corrigido: painel só abre se não for arrasto
floatBtn.MouseButton1Click:Connect(function()
	task.delay(0.05, function()
		if not isDragging then
			if painelAberto then
				fecharPainel()
			else
				abrirPainel()
			end
			painelAberto = not painelAberto
		end
	end)
end)

-- Arrastar painel
local draggingPanel = false
local panelDragInput, panelDragStart, panelStartPos

title.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingPanel = true
		panelDragStart = input.Position
		panelStartPos = frame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				draggingPanel = false
			end
		end)
	end
end)

title.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		panelDragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == panelDragInput and draggingPanel then
		local delta = input.Position - panelDragStart
		frame.Position = UDim2.new(
			panelStartPos.X.Scale, panelStartPos.X.Offset + delta.X,
			panelStartPos.Y.Scale, panelStartPos.Y.Offset + delta.Y
		)
	end
end)
