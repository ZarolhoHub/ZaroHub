--[[
    AUTO EGG • PREMIUM EDITION
    - Interface neon com borda animada, raios e partículas
    - Minimizável (orbe flutuante arrastável)
    - Fechar (X) encerra 100% o script: loops, conexões, animações e GUI
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Se o script for executado de novo, encerra a instância anterior
local ENV = (getgenv and getgenv()) or _G
if ENV.__AutoEggPremium_Shutdown then
    pcall(ENV.__AutoEggPremium_Shutdown)
end

-- RemoteFunction de compra (EggService)
local EggEvent = ReplicatedStorage:WaitForChild("Packages")
    :WaitForChild("Knit")
    :WaitForChild("Services")
    :WaitForChild("EggService")
    :WaitForChild("RF")
    :WaitForChild("purchaseEgg")

----------------------------------------------------
-- ESTADO
----------------------------------------------------
local alive = true
local autoBuying = false
local selectedEggRaw = "RibbonBlossom"
local buyDelay = 0.5
local purchases = 0
local availableEggs = {}

local connections = {}
local threads = {}

local function bind(signal, fn)
    local c = signal:Connect(fn)
    table.insert(connections, c)
    return c
end

local function spawnTracked(fn)
    local th = task.spawn(fn)
    table.insert(threads, th)
    return th
end

----------------------------------------------------
-- OVOS
----------------------------------------------------
local function cleanEggName(name)
    local r = name:gsub("_infstring", ""):gsub("infstring", ""):gsub("_string", "")
    return r
end

local function scanEggs()
    availableEggs = {}
    local rawList = {}
    local assets = ReplicatedStorage:FindFirstChild("Assets")
    local models = ReplicatedStorage:FindFirstChild("Models")
    local locations = {}

    local function add(inst)
        if inst then table.insert(locations, inst) end
    end
    add(ReplicatedStorage:FindFirstChild("Eggs"))
    add(assets and assets:FindFirstChild("Eggs"))
    add(models and models:FindFirstChild("Eggs"))

    for _, location in ipairs(locations) do
        for _, item in ipairs(location:GetChildren()) do
            if not table.find(rawList, item.Name) then
                table.insert(rawList, item.Name)
            end
        end
    end

    if #rawList == 0 then
        rawList = { selectedEggRaw }
    elseif not table.find(rawList, selectedEggRaw) then
        selectedEggRaw = rawList[1]
    end
    table.sort(rawList)

    for _, eggRaw in ipairs(rawList) do
        table.insert(availableEggs, { Raw = eggRaw, Clean = cleanEggName(eggRaw) })
    end
end

----------------------------------------------------
-- UTILITÁRIOS DE UI
----------------------------------------------------
local C = {
    bg = Color3.fromRGB(11, 9, 24),
    bg2 = Color3.fromRGB(28, 14, 56),
    panel = Color3.fromRGB(18, 14, 40),
    cyan = Color3.fromRGB(0, 230, 255),
    magenta = Color3.fromRGB(255, 60, 200),
    violet = Color3.fromRGB(140, 90, 255),
    green = Color3.fromRGB(20, 235, 140),
    red = Color3.fromRGB(255, 70, 100),
    gold = Color3.fromRGB(255, 210, 80),
    text = Color3.fromRGB(240, 242, 255),
    dim = Color3.fromRGB(150, 158, 205),
    white = Color3.new(1, 1, 1),
}
local boltColors = { C.cyan, C.magenta, C.violet, C.gold }

local function create(class, props, children)
    local inst = Instance.new(class)
    local parent
    for k, v in pairs(props or {}) do
        if k == "Parent" then parent = v else inst[k] = v end
    end
    for _, ch in ipairs(children or {}) do ch.Parent = inst end
    if parent then inst.Parent = parent end
    return inst
end

local function corner(r)
    return create("UICorner", { CornerRadius = UDim.new(0, r) })
end

local function circle()
    return create("UICorner", { CornerRadius = UDim.new(1, 0) })
end

local function stroke(color, thick, transp)
    return create("UIStroke", {
        Color = color,
        Thickness = thick,
        Transparency = transp or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

local function tween(obj, t, props, style, dir)
    local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

local function gradSeq(colors)
    local kps, n = {}, #colors
    for i, c in ipairs(colors) do
        kps[i] = ColorSequenceKeypoint.new((i - 1) / (n - 1), c)
    end
    return ColorSequence.new(kps)
end

local function makeLabel(props)
    local p = {
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextColor3 = C.text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }
    for k, v in pairs(props) do p[k] = v end
    return create("TextLabel", p)
end

----------------------------------------------------
-- GUI BASE
----------------------------------------------------
local ScreenGui = create("ScreenGui", {
    Name = "AutoEgg_Premium",
    ResetOnSpawn = false,
    DisplayOrder = 999,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
ScreenGui.Parent = PlayerGui

local function getViewport()
    local s = ScreenGui.AbsoluteSize
    if s.X > 0 and s.Y > 0 then return s end
    local cam = workspace.CurrentCamera
    return cam and cam.ViewportSize or Vector2.new(800, 400)
end

local W, H = 470, 250
local fit = 1

local function clampPos(x, y, halfW, halfH)
    local vp = getViewport()
    x = math.clamp(x, halfW, math.max(halfW, vp.X - halfW))
    y = math.clamp(y, halfH, math.max(halfH, vp.Y - halfH))
    return UDim2.fromOffset(x, y)
end

----------------------------------------------------
-- JANELA PRINCIPAL
----------------------------------------------------
local Holder = create("Frame", {
    Name = "Holder",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Size = UDim2.fromOffset(W, H),
    BackgroundTransparency = 1,
    Parent = ScreenGui,
})
local FitScale = create("UIScale", { Parent = Holder })

local Pop = create("Frame", {
    Name = "Pop",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Parent = Holder,
})
local PopScale = create("UIScale", { Scale = 0.6, Parent = Pop })

local Glow = create("ImageLabel", {
    Name = "Glow",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.new(1, 64, 1, 64),
    BackgroundTransparency = 1,
    Image = "rbxassetid://5028857084",
    ImageColor3 = C.cyan,
    ImageTransparency = 0.4,
    ScaleType = Enum.ScaleType.Slice,
    SliceCenter = Rect.new(24, 24, 276, 276),
    ZIndex = 0,
    Parent = Pop,
})

local MainFrame = create("Frame", {
    Name = "Main",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
    Active = true,
    ZIndex = 1,
    Parent = Pop,
}, { corner(14) })

local BgGrad = create("UIGradient", {
    Color = gradSeq({ C.bg, C.bg2, C.bg }),
    Rotation = 35,
    Parent = MainFrame,
})

local BorderStroke = stroke(C.white, 2, 0)
BorderStroke.Parent = MainFrame
local BorderGrad = create("UIGradient", {
    Color = gradSeq({ C.cyan, C.magenta, C.violet, C.cyan }),
    Parent = BorderStroke,
})

-- Camada de efeitos (raios + partículas)
local FX = create("Frame", {
    Name = "FX",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
    ZIndex = 1,
    Parent = MainFrame,
}, { corner(14) })

local particles = {}
for i = 1, 18 do
    local sz = math.random(2, 4)
    local f = create("Frame", {
        Size = UDim2.fromOffset(sz, sz),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = boltColors[math.random(#boltColors)],
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        Parent = FX,
    }, { circle() })
    particles[i] = {
        f = f,
        x = math.random(),
        y = math.random(),
        sp = 0.04 + math.random() * 0.08,
        ph = math.random() * 6.28,
        amp = 0.01 + math.random() * 0.02,
    }
end

----------------------------------------------------
-- CABEÇALHO
----------------------------------------------------
local Header = create("Frame", {
    Name = "Header",
    Size = UDim2.fromOffset(W, 44),
    BackgroundTransparency = 1,
    Active = true,
    ZIndex = 3,
    Parent = MainFrame,
})

local Title = makeLabel({
    Position = UDim2.fromOffset(16, 4),
    Size = UDim2.fromOffset(220, 22),
    Text = "AUTO EGG",
    TextSize = 19,
    Font = Enum.Font.GothamBold,
    TextColor3 = C.white,
    Parent = Header,
})
local TitleGrad = create("UIGradient", {
    Color = gradSeq({ C.cyan, C.white, C.magenta }),
    Parent = Title,
})

makeLabel({
    Position = UDim2.fromOffset(17, 26),
    Size = UDim2.fromOffset(220, 12),
    Text = "PREMIUM EDITION",
    TextSize = 9,
    Font = Enum.Font.GothamMedium,
    TextColor3 = C.dim,
    Parent = Header,
})

local Line = create("Frame", {
    Position = UDim2.fromOffset(12, 44),
    Size = UDim2.fromOffset(W - 24, 1),
    BackgroundColor3 = C.white,
    BorderSizePixel = 0,
    ZIndex = 3,
    Parent = MainFrame,
})
create("UIGradient", {
    Color = gradSeq({ C.cyan, C.magenta, C.violet }),
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0.2),
        NumberSequenceKeypoint.new(1, 1),
    }),
    Parent = Line,
})

local function headerButton(text, x, hoverColor)
    local idle = Color3.fromRGB(34, 30, 66)
    local b = create("TextButton", {
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.fromOffset(x, 8),
        BackgroundColor3 = idle,
        BackgroundTransparency = 0.15,
        Text = text,
        TextColor3 = C.text,
        TextSize = 15,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        ZIndex = 4,
        Parent = Header,
    }, { corner(8), stroke(C.white, 1, 0.88) })
    b.MouseEnter:Connect(function() tween(b, 0.15, { BackgroundColor3 = hoverColor }) end)
    b.MouseLeave:Connect(function() tween(b, 0.2, { BackgroundColor3 = idle }) end)
    return b
end

local MinBtn = headerButton("–", W - 74, C.violet)
local CloseBtn = headerButton("X", W - 40, C.red)

----------------------------------------------------
-- PAINEL ESQUERDO (CONTROLES)
----------------------------------------------------
local function panel(x, w)
    return create("Frame", {
        Position = UDim2.fromOffset(x, 52),
        Size = UDim2.fromOffset(w, 186),
        BackgroundColor3 = C.panel,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = MainFrame,
    }, { corner(12), stroke(C.white, 1, 0.9) })
end

local Left = panel(12, 176)
local Right = panel(198, 260)

local StatusDot = create("Frame", {
    Position = UDim2.fromOffset(14, 12),
    Size = UDim2.fromOffset(10, 10),
    BackgroundColor3 = C.red,
    BorderSizePixel = 0,
    Parent = Left,
}, { circle() })

local StatusLabel = makeLabel({
    Position = UDim2.fromOffset(32, 7),
    Size = UDim2.fromOffset(130, 20),
    Text = "INATIVO",
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    TextColor3 = C.dim,
    Parent = Left,
})

local ToggleBtn = create("TextButton", {
    Position = UDim2.fromOffset(10, 32),
    Size = UDim2.fromOffset(156, 42),
    BackgroundColor3 = C.violet,
    Text = "LIGAR AUTO OVOS",
    TextColor3 = C.white,
    TextSize = 13,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
    Parent = Left,
}, { corner(10) })
local ToggleStroke = stroke(C.magenta, 2, 0.15)
ToggleStroke.Parent = ToggleBtn
local ToggleGrad = create("UIGradient", {
    Color = gradSeq({ C.white, Color3.fromRGB(185, 185, 185), C.white }),
    Parent = ToggleBtn,
})

makeLabel({
    Position = UDim2.fromOffset(14, 84),
    Size = UDim2.fromOffset(150, 12),
    Text = "OVO SELECIONADO",
    TextSize = 9,
    Font = Enum.Font.GothamBold,
    TextColor3 = C.dim,
    Parent = Left,
})
local SelectedName = makeLabel({
    Position = UDim2.fromOffset(14, 96),
    Size = UDim2.fromOffset(150, 18),
    Text = cleanEggName(selectedEggRaw),
    TextSize = 13,
    Font = Enum.Font.GothamBold,
    TextColor3 = C.cyan,
    Parent = Left,
})

makeLabel({
    Position = UDim2.fromOffset(14, 120),
    Size = UDim2.fromOffset(150, 12),
    Text = "PEDIDOS ENVIADOS",
    TextSize = 9,
    Font = Enum.Font.GothamBold,
    TextColor3 = C.dim,
    Parent = Left,
})
local PurchaseLabel = makeLabel({
    Position = UDim2.fromOffset(14, 132),
    Size = UDim2.fromOffset(150, 20),
    Text = "0",
    TextSize = 16,
    Font = Enum.Font.GothamBold,
    Parent = Left,
})

local function smallBtn(text, x)
    local idle = Color3.fromRGB(34, 30, 66)
    local b = create("TextButton", {
        Position = UDim2.fromOffset(x, 156),
        Size = UDim2.fromOffset(28, 24),
        BackgroundColor3 = idle,
        Text = text,
        TextColor3 = C.text,
        TextSize = 15,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        Parent = Left,
    }, { corner(7), stroke(C.white, 1, 0.88) })
    b.MouseEnter:Connect(function() tween(b, 0.15, { BackgroundColor3 = C.violet }) end)
    b.MouseLeave:Connect(function() tween(b, 0.2, { BackgroundColor3 = idle }) end)
    return b
end

local DelayMinus = smallBtn("-", 10)
local DelayPlus = smallBtn("+", 130)
local DelayLabel = makeLabel({
    Position = UDim2.fromOffset(42, 156),
    Size = UDim2.fromOffset(84, 24),
    Text = "DELAY 0.5s",
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Center,
    TextColor3 = C.text,
    Parent = Left,
})

----------------------------------------------------
-- PAINEL DIREITO (PESQUISA + LISTA)
----------------------------------------------------
local SearchBox = create("TextBox", {
    Position = UDim2.fromOffset(10, 10),
    Size = UDim2.fromOffset(206, 28),
    BackgroundColor3 = Color3.fromRGB(10, 8, 24),
    PlaceholderText = "🔍 Pesquisar ovo...",
    PlaceholderColor3 = C.dim,
    Text = "",
    TextColor3 = C.text,
    TextSize = 12,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false,
    Parent = Right,
}, { corner(8), create("UIPadding", { PaddingLeft = UDim.new(0, 10) }) })
local SearchStroke = stroke(C.white, 1, 0.85)
SearchStroke.Parent = SearchBox

local RefreshBtn = create("TextButton", {
    Position = UDim2.fromOffset(222, 10),
    Size = UDim2.fromOffset(28, 28),
    BackgroundColor3 = Color3.fromRGB(34, 30, 66),
    Text = "↻",
    TextColor3 = C.text,
    TextSize = 16,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
    Parent = Right,
}, { corner(8), stroke(C.white, 1, 0.88) })
RefreshBtn.MouseEnter:Connect(function() tween(RefreshBtn, 0.15, { BackgroundColor3 = C.violet }) end)
RefreshBtn.MouseLeave:Connect(function() tween(RefreshBtn, 0.2, { BackgroundColor3 = Color3.fromRGB(34, 30, 66) }) end)

local CountLabel = makeLabel({
    Position = UDim2.fromOffset(12, 43),
    Size = UDim2.fromOffset(236, 14),
    Text = "0 ovos",
    TextSize = 10,
    Font = Enum.Font.GothamMedium,
    TextColor3 = C.dim,
    Parent = Right,
})

local ScrollFrame = create("ScrollingFrame", {
    Position = UDim2.fromOffset(10, 60),
    Size = UDim2.fromOffset(240, 118),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = C.cyan,
    Parent = Right,
})
create("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 4),
    Parent = ScrollFrame,
})

local COLOR_IDLE = Color3.fromRGB(28, 26, 56)
local COLOR_HOVER = Color3.fromRGB(44, 38, 90)
local COLOR_SELECTED = Color3.fromRGB(62, 40, 150)

local eggButtons = {}

local function refreshSelection()
    for _, e in ipairs(eggButtons) do
        local sel = (e.Raw == selectedEggRaw)
        tween(e.Btn, 0.2, {
            BackgroundColor3 = sel and COLOR_SELECTED or COLOR_IDLE,
            TextColor3 = sel and C.white or C.dim,
        })
        tween(e.Stroke, 0.2, { Transparency = sel and 0 or 1 })
        tween(e.Dot, 0.2, { BackgroundTransparency = sel and 0 or 1 })
    end
    SelectedName.Text = cleanEggName(selectedEggRaw)
end

local function applyFilter()
    local f = string.lower(SearchBox.Text or "")
    local n = 0
    for _, e in ipairs(eggButtons) do
        local show = (f == "") or (string.find(string.lower(e.Clean), f, 1, true) ~= nil)
        e.Btn.Visible = show
        if show then n += 1 end
    end
    CountLabel.Text = n .. (n == 1 and " ovo" or " ovos")
end

local function buildList()
    for _, e in ipairs(eggButtons) do e.Btn:Destroy() end
    eggButtons = {}
    scanEggs()

    for i, egg in ipairs(availableEggs) do
        local sel = (egg.Raw == selectedEggRaw)
        local btn = create("TextButton", {
            Name = egg.Raw,
            LayoutOrder = i,
            Size = UDim2.new(1, -8, 0, 28),
            BackgroundColor3 = sel and COLOR_SELECTED or COLOR_IDLE,
            Text = egg.Clean,
            TextColor3 = sel and C.white or C.dim,
            TextSize = 12,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            AutoButtonColor = false,
            Parent = ScrollFrame,
        }, {
            corner(8),
            create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 24) }),
        })
        local st = stroke(C.cyan, 1.5, sel and 0 or 1)
        st.Parent = btn
        local dot = create("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 16, 0.5, 0),
            Size = UDim2.fromOffset(8, 8),
            BackgroundColor3 = C.cyan,
            BackgroundTransparency = sel and 0 or 1,
            BorderSizePixel = 0,
            Parent = btn,
        }, { circle() })

        btn.MouseEnter:Connect(function()
            if selectedEggRaw ~= egg.Raw then tween(btn, 0.15, { BackgroundColor3 = COLOR_HOVER }) end
        end)
        btn.MouseLeave:Connect(function()
            if selectedEggRaw ~= egg.Raw then tween(btn, 0.2, { BackgroundColor3 = COLOR_IDLE }) end
        end)
        btn.MouseButton1Click:Connect(function()
            if not alive then return end
            selectedEggRaw = egg.Raw
            refreshSelection()
        end)

        table.insert(eggButtons, { Raw = egg.Raw, Clean = egg.Clean, Btn = btn, Stroke = st, Dot = dot })
    end

    applyFilter()
    refreshSelection()
end

buildList()

SearchBox:GetPropertyChangedSignal("Text"):Connect(applyFilter)
SearchBox.Focused:Connect(function()
    tween(SearchStroke, 0.2, { Color = C.cyan, Transparency = 0, Thickness = 1.5 })
end)
SearchBox.FocusLost:Connect(function()
    tween(SearchStroke, 0.25, { Color = C.white, Transparency = 0.85, Thickness = 1 })
end)
RefreshBtn.MouseButton1Click:Connect(function()
    if not alive then return end
    tween(RefreshBtn, 0.4, { Rotation = RefreshBtn.Rotation + 360 }, Enum.EasingStyle.Quint)
    buildList()
end)

----------------------------------------------------
-- ORBE MINIMIZADO
----------------------------------------------------
local OrbRoot = create("Frame", {
    Name = "Orb",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Size = UDim2.fromOffset(58, 58),
    Position = UDim2.fromOffset(80, 120),
    BackgroundTransparency = 1,
    Visible = false,
    Parent = ScreenGui,
})
local OrbScale = create("UIScale", { Scale = 0, Parent = OrbRoot })

local OrbGlow = create("ImageLabel", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.new(1, 44, 1, 44),
    BackgroundTransparency = 1,
    Image = "rbxassetid://5028857084",
    ImageColor3 = C.cyan,
    ImageTransparency = 0.35,
    ScaleType = Enum.ScaleType.Slice,
    SliceCenter = Rect.new(24, 24, 276, 276),
    ZIndex = 0,
    Parent = OrbRoot,
})

local OrbRing = create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(58, 58),
    BackgroundTransparency = 1,
    ZIndex = 1,
    Parent = OrbRoot,
}, { circle() })
local OrbRingStroke = stroke(C.cyan, 2, 0.5)
OrbRingStroke.Parent = OrbRing

local OrbBtn = create("TextButton", {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = C.bg2,
    Text = "🥚",
    TextSize = 26,
    TextColor3 = C.white,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
    ZIndex = 2,
    Parent = OrbRoot,
}, { circle() })
local OrbStroke = stroke(C.white, 3, 0)
OrbStroke.Parent = OrbBtn
local OrbGrad = create("UIGradient", {
    Color = gradSeq({ C.cyan, C.magenta, C.violet, C.cyan }),
    Parent = OrbStroke,
})

local OrbDot = create("Frame", {
    Position = UDim2.new(1, -14, 0, 0),
    Size = UDim2.fromOffset(14, 14),
    BackgroundColor3 = C.green,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 3,
    Parent = OrbRoot,
}, { circle(), stroke(C.bg, 2, 0) })

----------------------------------------------------
-- ARRASTAR (mouse + toque)
----------------------------------------------------
local function makeDraggable(handle, target, halfFn, onTap)
    local dragging, startInput, startPos, moved = false, nil, nil, false

    bind(handle.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = false
            startInput = input.Position
            startPos = target.Position
        end
    end)

    bind(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - startInput
            if d.Magnitude > 6 then moved = true end
            if moved then
                local hw, hh = halfFn()
                target.Position = clampPos(startPos.X.Offset + d.X, startPos.Y.Offset + d.Y, hw, hh)
            end
        end
    end)

    bind(UserInputService.InputEnded, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            if not moved and onTap then onTap() end
        end
    end)
end

local function holderHalf() return (W * fit) / 2, (H * fit) / 2 end
local function orbHalf() return 29, 29 end

----------------------------------------------------
-- MINIMIZAR / RESTAURAR
----------------------------------------------------
local animToken = 0

local function showMain()
    animToken += 1
    local tok = animToken
    local o = OrbRoot.Position
    local hw, hh = holderHalf()
    Holder.Position = clampPos(o.X.Offset, o.Y.Offset, hw, hh)
    PopScale.Scale = 0.6
    Holder.Visible = true
    tween(PopScale, 0.4, { Scale = 1 }, Enum.EasingStyle.Back)
    tween(OrbScale, 0.15, { Scale = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    task.delay(0.16, function()
        if alive and tok == animToken then OrbRoot.Visible = false end
    end)
end

local function showOrb()
    animToken += 1
    local tok = animToken
    local h = Holder.Position
    OrbRoot.Position = clampPos(h.X.Offset, h.Y.Offset, 29, 29)
    OrbScale.Scale = 0
    OrbRoot.Visible = true
    tween(PopScale, 0.2, { Scale = 0.5 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    tween(OrbScale, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
    task.delay(0.21, function()
        if alive and tok == animToken then Holder.Visible = false end
    end)
end

makeDraggable(Header, Holder, holderHalf, nil)
makeDraggable(OrbBtn, OrbRoot, orbHalf, showMain)
bind(MinBtn.MouseButton1Click, showOrb)

----------------------------------------------------
-- AJUSTE DE TELA
----------------------------------------------------
local function updateFit()
    local vp = getViewport()
    fit = math.clamp(math.min((vp.X - 16) / W, (vp.Y - 16) / H), 0.45, 1)
    FitScale.Scale = fit
    local hw, hh = holderHalf()
    local p = Holder.Position
    Holder.Position = clampPos(p.X.Offset, p.Y.Offset, hw, hh)
end

do
    local vp = getViewport()
    Holder.Position = UDim2.fromOffset(vp.X / 2, vp.Y / 2)
    updateFit()
end
bind(ScreenGui:GetPropertyChangedSignal("AbsoluteSize"), updateFit)

-- Animação de entrada
tween(PopScale, 0.5, { Scale = 1 }, Enum.EasingStyle.Back)

----------------------------------------------------
-- LIGAR / DESLIGAR
----------------------------------------------------
local function setActive(on)
    autoBuying = on
    if on then
        tween(ToggleBtn, 0.3, { BackgroundColor3 = C.green, TextColor3 = Color3.fromRGB(4, 24, 18) })
        tween(ToggleStroke, 0.3, { Color = C.cyan })
        ToggleBtn.Text = "AUTO OVOS LIGADO"
        StatusLabel.Text = "COMPRANDO"
        tween(StatusLabel, 0.3, { TextColor3 = C.green })
        StatusDot.BackgroundColor3 = C.green
        BorderGrad.Color = gradSeq({ C.green, C.cyan, C.violet, C.green })
        OrbGrad.Color = gradSeq({ C.green, C.cyan, C.green })
        OrbDot.Visible = true
    else
        tween(ToggleBtn, 0.3, { BackgroundColor3 = C.violet, TextColor3 = C.white })
        tween(ToggleStroke, 0.3, { Color = C.magenta })
        ToggleBtn.Text = "LIGAR AUTO OVOS"
        StatusLabel.Text = "INATIVO"
        tween(StatusLabel, 0.3, { TextColor3 = C.dim })
        StatusDot.BackgroundColor3 = C.red
        StatusDot.Size = UDim2.fromOffset(10, 10)
        StatusDot.Position = UDim2.fromOffset(14, 12)
        BorderGrad.Color = gradSeq({ C.cyan, C.magenta, C.violet, C.cyan })
        OrbGrad.Color = gradSeq({ C.cyan, C.magenta, C.violet, C.cyan })
        OrbDot.Visible = false
    end
end

bind(ToggleBtn.MouseButton1Click, function()
    if not alive then return end
    setActive(not autoBuying)
end)

local function setDelay(v)
    buyDelay = math.clamp(math.floor(v * 10 + 0.5) / 10, 0.1, 3)
    DelayLabel.Text = string.format("DELAY %.1fs", buyDelay)
end
bind(DelayMinus.MouseButton1Click, function() setDelay(buyDelay - 0.1) end)
bind(DelayPlus.MouseButton1Click, function() setDelay(buyDelay + 0.1) end)

----------------------------------------------------
-- RAIOS
----------------------------------------------------
local function segment(parent, a, b, thickness, color, transp)
    local dx, dy = b.X - a.X, b.Y - a.Y
    local len = math.sqrt(dx * dx + dy * dy)
    return create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2),
        Size = UDim2.fromOffset(len + 1, thickness),
        Rotation = math.deg(math.atan2(dy, dx)),
        BackgroundColor3 = color,
        BackgroundTransparency = transp,
        BorderSizePixel = 0,
        Visible = false,
        Parent = parent,
    })
end

local function strike()
    if not alive or not Holder.Visible then return end

    local color
    if autoBuying then
        color = (math.random() < 0.5) and C.green or C.cyan
    else
        color = boltColors[math.random(#boltColors)]
    end
    local core = color:Lerp(C.white, 0.75)

    local group = create("CanvasGroup", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Parent = FX,
    })

    local steps = math.random(8, 11)
    local x = math.random(30, W - 30)
    local pts = { Vector2.new(x, -6) }
    for i = 1, steps do
        x = math.clamp(x + math.random(-34, 34), 6, W - 6)
        pts[#pts + 1] = Vector2.new(x, (H + 6) * i / steps)
    end

    local reveal = {}
    local function addSeg(a, b, step)
        reveal[step] = reveal[step] or {}
        table.insert(reveal[step], segment(group, a, b, 7, color, 0.82))
        table.insert(reveal[step], segment(group, a, b, 2, core, 0))
    end

    for i = 1, #pts - 1 do addSeg(pts[i], pts[i + 1], i) end

    -- ramificação
    local bi = math.random(3, steps - 3)
    local dir = (math.random() < 0.5) and -1 or 1
    local prev = pts[bi]
    for j = 1, 4 do
        local nxt = Vector2.new(
            math.clamp(prev.X + dir * math.random(14, 30), 6, W - 6),
            prev.Y + math.random(14, 24)
        )
        addSeg(prev, nxt, bi + j - 1)
        prev = nxt
    end

    -- clarão no brilho da janela
    tween(Glow, 0.08, { ImageTransparency = 0.1 })

    for s = 1, steps do
        if not alive then return end
        if reveal[s] then
            for _, f in ipairs(reveal[s]) do f.Visible = true end
        end
        task.wait(0.012)
    end

    task.wait(0.05)
    if not alive then return end
    group.GroupTransparency = 0.55
    task.wait(0.04)
    group.GroupTransparency = 0
    tween(Glow, 0.4, { ImageTransparency = 0.4 })
    task.wait(0.08)
    if not alive then return end
    tween(group, 0.3, { GroupTransparency = 1 })
    task.wait(0.32)
    group:Destroy()
end

for i = 1, 2 do
    spawnTracked(function()
        task.wait(0.4 * i)
        while alive do
            local wait = autoBuying and (0.1 + math.random() * 0.4) or (0.8 + math.random() * 1.4)
            task.wait(wait)
            if alive then pcall(strike) end
        end
    end)
end

----------------------------------------------------
-- ANIMAÇÃO CONTÍNUA
----------------------------------------------------
local t = 0
bind(RunService.RenderStepped, function(dt)
    t += dt

    if Holder.Visible then
        BorderGrad.Rotation = (t * 90) % 360
        BgGrad.Offset = Vector2.new(math.sin(t * 0.6) * 0.25, 0)
        TitleGrad.Offset = Vector2.new(math.sin(t * 1.2) * 0.3, 0)
        ToggleGrad.Offset = Vector2.new(math.sin(t * (autoBuying and 3.5 or 1.5)) * 0.5, 0)
        Glow.ImageColor3 = Color3.fromHSV(0.5 + 0.35 * (0.5 + 0.5 * math.sin(t * 0.7)), 0.85, 1)

        local speed = autoBuying and 2.2 or 1
        for _, p in ipairs(particles) do
            p.y -= p.sp * speed * dt
            if p.y < -0.05 then
                p.y = 1.05
                p.x = math.random()
            end
            p.f.Position = UDim2.fromScale(p.x + math.sin(t * 1.5 + p.ph) * p.amp, p.y)
            p.f.BackgroundTransparency = 0.3 + 0.5 * (0.5 + 0.5 * math.sin(t * 2 + p.ph))
        end

        if autoBuying then
            local s = 10 + 3 * math.sin(t * 6)
            StatusDot.Size = UDim2.fromOffset(s, s)
            StatusDot.Position = UDim2.fromOffset(14 + (10 - s) / 2, 12 + (10 - s) / 2)
        end
    end

    if OrbRoot.Visible then
        OrbGrad.Rotation = (t * 160) % 360
        OrbGlow.ImageColor3 = Color3.fromHSV(0.5 + 0.35 * (0.5 + 0.5 * math.sin(t * 0.9)), 0.85, 1)
        local p = (t % 1.6) / 1.6
        local sz = 58 + p * 34
        OrbRing.Size = UDim2.fromOffset(sz, sz)
        OrbRingStroke.Transparency = 0.3 + p * 0.7
        OrbRingStroke.Color = autoBuying and C.green or C.cyan
    end
end)

----------------------------------------------------
-- LOOP DE COMPRA (mesma assinatura capturada pelo Cobalt)
----------------------------------------------------
spawnTracked(function()
    while alive do
        if autoBuying and selectedEggRaw ~= "" then
            local ok = pcall(function()
                EggEvent:InvokeServer(
                    selectedEggRaw,
                    nil,
                    nil,
                    false,
                    nil,
                    nil,
                    nil
                )
            end)
            if ok then
                purchases += 1
                PurchaseLabel.Text = tostring(purchases)
            end
        end
        task.wait(buyDelay)
    end
end)

----------------------------------------------------
-- FECHAR = ENCERRA TUDO
----------------------------------------------------
local function shutdown()
    if not alive then return end
    alive = false
    autoBuying = false

    for _, c in ipairs(connections) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(connections)

    for _, th in ipairs(threads) do
        pcall(task.cancel, th)
    end
    table.clear(threads)

    ENV.__AutoEggPremium_Shutdown = nil

    -- animação rápida de saída e remoção total da GUI
    pcall(function()
        tween(PopScale, 0.18, { Scale = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        tween(OrbScale, 0.18, { Scale = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    end)
    task.delay(0.2, function()
        pcall(function() ScreenGui:Destroy() end)
    end)
end

ENV.__AutoEggPremium_Shutdown = shutdown
CloseBtn.MouseButton1Click:Connect(shutdown)
