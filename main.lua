-- AUTO EGG • Abas: Eggs (abrir ovos) e Void (craft de pets Void)
-- "=" abre/fecha o menu lateral | "-" minimiza | "X" fecha e encerra tudo

local function main()
    local Players = game:GetService("Players")
    local RS = game:GetService("ReplicatedStorage")
    local TweenService = game:GetService("TweenService")
    local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

    local ENV = (getgenv and getgenv()) or _G
    if ENV.__AutoEggMenu then pcall(ENV.__AutoEggMenu) end

    local running = true
    local autoBuying = false
    local selected = "RibbonBlossom"
    local delayTime = 0.5
    local count = 0
    local multiOpen = true -- 6º argumento do purchaseEgg: abertura múltipla (máximo da conta)

    ----------------------------------------------------
    -- REMOTE E OVOS
    ----------------------------------------------------
    local function findRemote()
        local node = RS
        for _, n in ipairs({ "Packages", "Knit", "Services", "EggService", "RF", "purchaseEgg" }) do
            node = node and node:FindFirstChild(n)
        end
        return node
    end
    local remote = findRemote()

    local function cleanName(n)
        local r = n:gsub("_infstring", ""):gsub("infstring", ""):gsub("_string", "")
        return r
    end

    local eggs = {}
    local places = {}
    local function addPlace(p) if p then table.insert(places, p) end end
    addPlace(RS:FindFirstChild("Eggs"))
    addPlace(RS:FindFirstChild("Assets") and RS.Assets:FindFirstChild("Eggs"))
    addPlace(RS:FindFirstChild("Models") and RS.Models:FindFirstChild("Eggs"))
    for _, place in ipairs(places) do
        for _, item in ipairs(place:GetChildren()) do
            if not table.find(eggs, item.Name) then table.insert(eggs, item.Name) end
        end
    end
    if #eggs == 0 then eggs = { selected } end
    table.sort(eggs)

    ----------------------------------------------------
    -- UTILITÁRIOS
    ----------------------------------------------------
    local BG = Color3.fromRGB(18, 16, 38)
    local PANEL = Color3.fromRGB(32, 29, 62)
    local PANEL2 = Color3.fromRGB(46, 42, 88)
    local ACCENT = Color3.fromRGB(130, 90, 255)
    local CYAN = Color3.fromRGB(0, 210, 255)
    local GREEN = Color3.fromRGB(30, 215, 120)
    local RED = Color3.fromRGB(225, 60, 85)
    local OFFC = Color3.fromRGB(72, 66, 112)
    local DIM = Color3.fromRGB(160, 165, 210)
    local WHITE = Color3.new(1, 1, 1)

    local function tween(o, t, props)
        local tw = TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
        tw:Play()
        return tw
    end

    local function mk(class, props, parent, radius)
        local o = Instance.new(class)
        for k, v in pairs(props) do o[k] = v end
        if radius then
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, radius)
            c.Parent = o
        end
        o.Parent = parent
        return o
    end

    local function stroke(o, color, th)
        local s = Instance.new("UIStroke")
        s.Color = color
        s.Thickness = th
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        s.Parent = o
        return s
    end

    local function lbl(parent, text, x, y, w, h, size, color, align)
        return mk("TextLabel", {
            Position = UDim2.new(0, x, 0, y),
            Size = UDim2.new(0, w, 0, h),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = color or WHITE,
            TextSize = size,
            Font = Enum.Font.GothamBold,
            TextXAlignment = align or Enum.TextXAlignment.Left,
        }, parent)
    end

    local function btn(parent, text, x, y, w, h, color, size)
        return mk("TextButton", {
            Position = UDim2.new(0, x, 0, y),
            Size = UDim2.new(0, w, 0, h),
            BackgroundColor3 = color,
            Text = text,
            TextColor3 = WHITE,
            TextSize = size or 13,
            Font = Enum.Font.GothamBold,
            AutoButtonColor = false,
        }, parent, 8)
    end

    ----------------------------------------------------
    -- JANELA
    ----------------------------------------------------
    local gui = Instance.new("ScreenGui")
    gui.Name = "AutoEgg_Menu"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 999
    gui.Parent = PlayerGui

    local main = mk("Frame", {
        Size = UDim2.new(0, 440, 0, 270),
        Position = UDim2.new(0.5, -220, 0.25, 0),
        BackgroundColor3 = BG,
        BorderSizePixel = 0,
        Active = true,
        Draggable = true,
    }, gui, 14)
    local mainStroke = stroke(main, ACCENT, 2)

    -- Barra de título
    local menuBtn = btn(main, "=", 10, 6, 28, 26, PANEL2, 16)
    lbl(main, "AUTO EGG", 46, 6, 200, 26, 17, WHITE)
    local minBtn = btn(main, "-", 366, 6, 28, 26, PANEL2, 16)
    local closeBtn = btn(main, "X", 402, 6, 28, 26, RED, 13)

    ----------------------------------------------------
    -- MENU LATERAL
    ----------------------------------------------------
    local sidebar = mk("Frame", {
        Position = UDim2.new(0, 8, 0, 42),
        Size = UDim2.new(0, 104, 0, 220),
        BackgroundColor3 = PANEL,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, main, 10)
    lbl(sidebar, "MENU", 14, 8, 80, 16, 10, DIM)
    local eggsTab = btn(sidebar, "🥚  Eggs", 6, 28, 92, 34, ACCENT, 13)
    local voidTab = btn(sidebar, "🌀  Void", 6, 68, 92, 34, PANEL2, 13)

    local content = mk("ScrollingFrame", {
        Position = UDim2.new(0, 120, 0, 42),
        Size = UDim2.new(0, 312, 0, 220),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = ACCENT,
    }, main)
    local cLayout = Instance.new("UIListLayout")
    cLayout.Padding = UDim.new(0, 8)
    cLayout.SortOrder = Enum.SortOrder.LayoutOrder
    cLayout.Parent = content

    local voidPage = mk("ScrollingFrame", {
        Position = UDim2.new(0, 120, 0, 42),
        Size = UDim2.new(0, 312, 0, 220),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = ACCENT,
        Visible = false,
    }, main)
    local vLayout = Instance.new("UIListLayout")
    vLayout.Padding = UDim.new(0, 8)
    vLayout.SortOrder = Enum.SortOrder.LayoutOrder
    vLayout.Parent = voidPage

    local sidebarOpen = true
    local function setSidebar(open)
        sidebarOpen = open
        tween(sidebar, 0.25, { Size = UDim2.new(0, open and 104 or 0, 0, 220) })
        for _, page in ipairs({ content, voidPage }) do
            tween(page, 0.25, {
                Position = UDim2.new(0, open and 120 or 8, 0, 42),
                Size = UDim2.new(0, open and 312 or 424, 0, 220),
            })
        end
    end
    menuBtn.MouseButton1Click:Connect(function() setSidebar(not sidebarOpen) end)

    -- Troca de abas
    local function selectTab(name)
        content.Visible = (name == "Eggs")
        voidPage.Visible = (name == "Void")
        tween(eggsTab, 0.2, { BackgroundColor3 = name == "Eggs" and ACCENT or PANEL2 })
        tween(voidTab, 0.2, { BackgroundColor3 = name == "Void" and ACCENT or PANEL2 })
    end
    eggsTab.MouseButton1Click:Connect(function() selectTab("Eggs") end)
    voidTab.MouseButton1Click:Connect(function() selectTab("Void") end)

    ----------------------------------------------------
    -- CARTÃO: DROPDOWN DE OVOS + SWITCH
    ----------------------------------------------------
    local COLLAPSED_H, EXPANDED_H = 48, 196

    local card = mk("Frame", {
        LayoutOrder = 1,
        Size = UDim2.new(1, -10, 0, COLLAPSED_H),
        BackgroundColor3 = PANEL,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, content, 10)
    local cardStroke = stroke(card, ACCENT, 1.5)

    local header = mk("TextButton", {
        Size = UDim2.new(1, 0, 0, COLLAPSED_H),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
    }, card)
    lbl(header, "Auto Egg", 14, 6, 150, 20, 14, WHITE)
    local selLabel = lbl(header, "Ovo: " .. cleanName(selected), 14, 26, 150, 16, 11, CYAN)
    local arrow = lbl(header, "^", 0, 0, 28, COLLAPSED_H, 18, CYAN, Enum.TextXAlignment.Center)
    arrow.Position = UDim2.new(1, -96, 0, 0)

    -- Switch deslizante
    local track = mk("TextButton", {
        Position = UDim2.new(1, -58, 0, 12),
        Size = UDim2.new(0, 46, 0, 24),
        BackgroundColor3 = OFFC,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 2,
    }, card, 12)
    local knob = mk("Frame", {
        Position = UDim2.new(0, 3, 0, 3),
        Size = UDim2.new(0, 18, 0, 18),
        BackgroundColor3 = WHITE,
        BorderSizePixel = 0,
        ZIndex = 3,
    }, track, 9)

    local function setActive(on)
        autoBuying = on
        tween(track, 0.2, { BackgroundColor3 = on and GREEN or OFFC })
        tween(knob, 0.2, { Position = on and UDim2.new(0, 25, 0, 3) or UDim2.new(0, 3, 0, 3) })
        tween(mainStroke, 0.2, { Color = on and GREEN or ACCENT })
        tween(cardStroke, 0.2, { Color = on and GREEN or ACCENT })
    end
    track.MouseButton1Click:Connect(function() setActive(not autoBuying) end)

    -- Área que aparece ao expandir
    local drop = mk("Frame", {
        Position = UDim2.new(0, 0, 0, 52),
        Size = UDim2.new(1, 0, 0, 140),
        BackgroundTransparency = 1,
        Visible = false,
    }, card)

    local search = mk("TextBox", {
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -20, 0, 28),
        BackgroundColor3 = BG,
        PlaceholderText = "Pesquisar ovo...",
        PlaceholderColor3 = DIM,
        Text = "",
        TextColor3 = WHITE,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        ClearTextOnFocus = false,
    }, drop, 8)

    local list = mk("ScrollingFrame", {
        Position = UDim2.new(0, 10, 0, 34),
        Size = UDim2.new(1, -20, 0, 100),
        BackgroundColor3 = BG,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = CYAN,
    }, drop)
    local lLayout = Instance.new("UIListLayout")
    lLayout.Padding = UDim.new(0, 3)
    lLayout.SortOrder = Enum.SortOrder.LayoutOrder
    lLayout.Parent = list

    local function refreshList()
        for _, c in ipairs(list:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        local f = string.lower(search.Text)
        for i, raw in ipairs(eggs) do
            local nm = cleanName(raw)
            if f == "" or string.find(string.lower(nm), f, 1, true) then
                local b = btn(list, nm, 0, 0, 0, 26, raw == selected and ACCENT or PANEL, 12)
                b.Size = UDim2.new(1, -8, 0, 26)
                b.LayoutOrder = i
                b.MouseButton1Click:Connect(function()
                    selected = raw
                    selLabel.Text = "Ovo: " .. nm
                    refreshList()
                end)
            end
        end
    end
    refreshList()
    search:GetPropertyChangedSignal("Text"):Connect(refreshList)

    -- Expandir / recolher
    local expanded = false
    header.MouseButton1Click:Connect(function()
        expanded = not expanded
        arrow.Text = expanded and "v" or "^"
        if expanded then
            drop.Visible = true
        else
            task.delay(0.26, function()
                if running and not expanded then drop.Visible = false end
            end)
        end
        tween(card, 0.25, { Size = UDim2.new(1, -10, 0, expanded and EXPANDED_H or COLLAPSED_H) })
    end)

    ----------------------------------------------------
    -- CARTÃO: DELAY
    ----------------------------------------------------
    local card2 = mk("Frame", {
        LayoutOrder = 2,
        Size = UDim2.new(1, -10, 0, 48),
        BackgroundColor3 = PANEL,
        BorderSizePixel = 0,
    }, content, 10)
    stroke(card2, PANEL2, 1.5)
    lbl(card2, "Delay", 14, 0, 100, 48, 14, WHITE)

    local minus = btn(card2, "-", 0, 0, 28, 24, PANEL2, 15)
    minus.Position = UDim2.new(1, -150, 0, 12)
    local delayLabel = lbl(card2, "0.5s", 0, 0, 70, 24, 13, CYAN, Enum.TextXAlignment.Center)
    delayLabel.Position = UDim2.new(1, -118, 0, 12)
    local plus = btn(card2, "+", 0, 0, 28, 24, PANEL2, 15)
    plus.Position = UDim2.new(1, -42, 0, 12)

    local function setDelay(v)
        delayTime = math.clamp(math.floor(v * 10 + 0.5) / 10, 0.1, 3)
        delayLabel.Text = string.format("%.1fs", delayTime)
    end
    minus.MouseButton1Click:Connect(function() setDelay(delayTime - 0.1) end)
    plus.MouseButton1Click:Connect(function() setDelay(delayTime + 0.1) end)

    ----------------------------------------------------
    -- CARTÃO: ABRIR MÁXIMO (multi)
    ----------------------------------------------------
    local card4 = mk("Frame", {
        LayoutOrder = 3,
        Size = UDim2.new(1, -10, 0, 48),
        BackgroundColor3 = PANEL,
        BorderSizePixel = 0,
    }, content, 10)
    stroke(card4, PANEL2, 1.5)
    lbl(card4, "Abrir máximo (multi)", 14, 0, 180, 48, 13, WHITE)
    local mTrack = mk("TextButton", {
        Position = UDim2.new(1, -58, 0, 12),
        Size = UDim2.new(0, 46, 0, 24),
        BackgroundColor3 = GREEN,
        Text = "",
        AutoButtonColor = false,
    }, card4, 12)
    local mKnob = mk("Frame", {
        Position = UDim2.new(0, 25, 0, 3),
        Size = UDim2.new(0, 18, 0, 18),
        BackgroundColor3 = WHITE,
        BorderSizePixel = 0,
    }, mTrack, 9)
    mTrack.MouseButton1Click:Connect(function()
        multiOpen = not multiOpen
        tween(mTrack, 0.2, { BackgroundColor3 = multiOpen and GREEN or OFFC })
        tween(mKnob, 0.2, { Position = multiOpen and UDim2.new(0, 25, 0, 3) or UDim2.new(0, 3, 0, 3) })
    end)

    ----------------------------------------------------
    -- CARTÃO: PEDIDOS
    ----------------------------------------------------
    local card3 = mk("Frame", {
        LayoutOrder = 4,
        Size = UDim2.new(1, -10, 0, 40),
        BackgroundColor3 = PANEL,
        BorderSizePixel = 0,
    }, content, 10)
    stroke(card3, PANEL2, 1.5)
    local countLabel = lbl(card3, "Pedidos enviados: 0", 14, 0, 250, 40, 12, WHITE)

    ----------------------------------------------------
    -- ABA VOID: manda pets Gold para a máquina Void
    ----------------------------------------------------
    local voidOn = false
    local voidInterval = 2
    local voidSent = 0
    local sentAt = {}
    local voidEvent = nil

    local function findVoidEvent()
        local node = RS
        for _, n in ipairs({ "Packages", "Knit", "Services", "PetVoidService", "RE", "onCraftToVoid" }) do
            node = node and node:FindFirstChild(n)
        end
        return node
    end
    voidEvent = findVoidEvent()

    -- Pets do inventário: cada Frame (nome = GUID) tem um "Toggle" com atributos (Tier, Multiplier, GUID...)
    local function findGold()
        local folder = PlayerGui
        for _, n in ipairs({ "GameUI", "Menus", "Inventory", "Display", "Pets", "ScrollingFrame", "Pets" }) do
            folder = folder and folder:FindFirstChild(n)
        end
        if not folder then return nil, 0, false end

        local best, bestMult, total = nil, nil, 0
        for _, fr in ipairs(folder:GetChildren()) do
            local tg = fr:FindFirstChild("Toggle")
            if tg and string.find(string.lower(tostring(tg:GetAttribute("Tier") or "")), "gold", 1, true)
                and not fr:GetAttribute("VoidMachine") and not fr:GetAttribute("EndTime") then
                total = total + 1
                local guid = tg:GetAttribute("GUID") or fr.Name
                local recent = sentAt[guid] and (os.clock() - sentAt[guid] < 30)
                if not recent then
                    local m = tonumber(tg:GetAttribute("Multiplier")) or 0
                    if not best or m < bestMult then
                        best, bestMult = guid, m
                    end
                end
            end
        end
        return best, total, true
    end

    local function voidCard(order, h)
        local c = mk("Frame", {
            LayoutOrder = order,
            Size = UDim2.new(1, -10, 0, h),
            BackgroundColor3 = PANEL,
            BorderSizePixel = 0,
        }, voidPage, 10)
        stroke(c, ACCENT, 1.5)
        return c
    end

    -- Cartão 1: switch
    local vc1 = voidCard(1, 48)
    lbl(vc1, "Auto Void", 14, 6, 150, 20, 14, WHITE)
    local voidStatus = lbl(vc1, "Parado", 14, 26, 170, 16, 11, CYAN)
    local vTrack = mk("TextButton", {
        Position = UDim2.new(1, -58, 0, 12),
        Size = UDim2.new(0, 46, 0, 24),
        BackgroundColor3 = OFFC,
        Text = "",
        AutoButtonColor = false,
    }, vc1, 12)
    local vKnob = mk("Frame", {
        Position = UDim2.new(0, 3, 0, 3),
        Size = UDim2.new(0, 18, 0, 18),
        BackgroundColor3 = WHITE,
        BorderSizePixel = 0,
    }, vTrack, 9)
    vTrack.MouseButton1Click:Connect(function()
        voidOn = not voidOn
        tween(vTrack, 0.2, { BackgroundColor3 = voidOn and GREEN or OFFC })
        tween(vKnob, 0.2, { Position = voidOn and UDim2.new(0, 25, 0, 3) or UDim2.new(0, 3, 0, 3) })
        voidStatus.Text = voidOn and "Procurando pet Gold..." or "Parado"
    end)

    -- Cartão 2: intervalo
    local vc2 = voidCard(2, 48)
    lbl(vc2, "Intervalo", 14, 0, 100, 48, 14, WHITE)
    local vMinus = btn(vc2, "-", 0, 0, 28, 24, PANEL2, 15)
    vMinus.Position = UDim2.new(1, -150, 0, 12)
    local vDelayLabel = lbl(vc2, "2.0s", 0, 0, 70, 24, 13, CYAN, Enum.TextXAlignment.Center)
    vDelayLabel.Position = UDim2.new(1, -118, 0, 12)
    local vPlus = btn(vc2, "+", 0, 0, 28, 24, PANEL2, 15)
    vPlus.Position = UDim2.new(1, -42, 0, 12)
    local function setVoidInterval(v)
        voidInterval = math.clamp(math.floor(v * 10 + 0.5) / 10, 0.5, 10)
        vDelayLabel.Text = string.format("%.1fs", voidInterval)
    end
    vMinus.MouseButton1Click:Connect(function() setVoidInterval(voidInterval - 0.5) end)
    vPlus.MouseButton1Click:Connect(function() setVoidInterval(voidInterval + 0.5) end)

    -- Cartão 3: contadores
    local vc3 = voidCard(3, 54)
    local goldLabel = lbl(vc3, "Pets Gold disponíveis: -", 14, 6, 270, 20, 12, WHITE)
    local sentLabel = lbl(vc3, "Enviados para a máquina: 0", 14, 28, 270, 20, 12, WHITE)

    -- Cartão 4: aviso
    local vc4 = voidCard(4, 70)
    local info = lbl(vc4, "Envia o pet Gold de menor multiplicador para a máquina Void. Abra o inventário de pets ao menos uma vez para a lista carregar.", 14, 6, 270, 58, 11, DIM)
    info.TextWrapped = true
    info.TextYAlignment = Enum.TextYAlignment.Top
    info.Font = Enum.Font.Gotham

    local voidLoop = task.spawn(function()
        while running do
            if voidOn then
                if not voidEvent then voidEvent = findVoidEvent() end
                local guid, total, found = findGold()
                if not found then
                    voidStatus.Text = "Inventário de pets não carregado"
                elseif not voidEvent then
                    voidStatus.Text = "Remote da máquina não achado"
                else
                    goldLabel.Text = "Pets Gold disponíveis: " .. total
                    if guid then
                        local ok = pcall(function() voidEvent:FireServer(guid) end)
                        if ok then
                            sentAt[guid] = os.clock()
                            voidSent = voidSent + 1
                            sentLabel.Text = "Enviados para a máquina: " .. voidSent
                            voidStatus.Text = "Enviando Gold..."
                        end
                    else
                        voidStatus.Text = "Nenhum Gold livre no momento"
                    end
                end
            end
            task.wait(voidInterval)
        end
    end)

    ----------------------------------------------------
    -- MINIMIZAR (botão flutuante)
    ----------------------------------------------------
    local orb = mk("TextButton", {
        Size = UDim2.new(0, 48, 0, 48),
        Position = UDim2.new(0.05, 0, 0.2, 0),
        BackgroundColor3 = ACCENT,
        Text = "🥚",
        TextSize = 22,
        TextColor3 = WHITE,
        AutoButtonColor = false,
        Visible = false,
        Active = true,
        Draggable = true,
    }, gui, 24)
    stroke(orb, CYAN, 2)

    minBtn.MouseButton1Click:Connect(function()
        main.Visible = false
        orb.Visible = true
    end)
    orb.MouseButton1Click:Connect(function()
        main.Visible = true
        orb.Visible = false
    end)

    ----------------------------------------------------
    -- LOOP DE COMPRA
    ----------------------------------------------------
    local loop = task.spawn(function()
        while running do
            if autoBuying then
                if not remote then remote = findRemote() end
                if remote then
                    local ok = pcall(function()
                        remote:InvokeServer(selected, nil, nil, false, nil, multiOpen and true or nil, nil)
                    end)
                    if ok then
                        count = count + 1
                        countLabel.Text = "Pedidos enviados: " .. count
                    end
                end
            end
            task.wait(delayTime)
        end
    end)

    ----------------------------------------------------
    -- FECHAR = ENCERRA TUDO
    ----------------------------------------------------
    local function shutdown()
        running = false
        autoBuying = false
        pcall(task.cancel, loop)
        pcall(task.cancel, voidLoop)
        ENV.__AutoEggMenu = nil
        gui:Destroy()
    end
    ENV.__AutoEggMenu = shutdown
    closeBtn.MouseButton1Click:Connect(shutdown)
end

local ok, err = pcall(main)
if not ok then
    warn("[AutoEgg] ERRO: " .. tostring(err))
    local pg = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    local g = Instance.new("ScreenGui")
    g.ResetOnSpawn = false
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -20, 0, 100)
    l.Position = UDim2.new(0, 10, 0, 10)
    l.BackgroundColor3 = Color3.fromRGB(40, 20, 30)
    l.TextColor3 = Color3.fromRGB(255, 120, 130)
    l.TextWrapped = true
    l.TextSize = 13
    l.Text = "ERRO: " .. tostring(err)
    l.Parent = g
    g.Parent = pg
end
