-- ZARO HUB
-- Fundo (opcional): preencha BG_IMAGE e/ou BG_VIDEO abaixo. Deixe "" para fundo liso.

local CONFIG = {
    NAME_A = "ZARO",
    NAME_B = "HUB",
    ACCENT = Color3.fromRGB(190, 255, 60),
    BG_IMAGE = "", -- "rbxassetid://123" ou link direto .png/.jpg
    BG_VIDEO = "https://raw.githubusercontent.com/ZarolhoHub/ZaroHub/main/fundo.webm", -- link direto .webm; "" desliga
    BG_DIM = 0.45, -- escurecimento do fundo (0 = sem escurecer)
}

local function main()
    local Players = game:GetService("Players")
    local RS = game:GetService("ReplicatedStorage")
    local TweenService = game:GetService("TweenService")
    local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

    local ENV = (getgenv and getgenv()) or _G
    if ENV.__ZaroHub then pcall(ENV.__ZaroHub) end
    if ENV.__AutoEggMenu then pcall(ENV.__AutoEggMenu) end

    local running = true
    local autoBuying = false
    local selected = "RibbonBlossom"
    local delayTime = 0.5
    local count = 0
    local multiOpen = true

    local auraOn = false
    local fightOn = false
    local voidOn = false
    local voidInterval = 2
    local voidSent = 0
    local sentAt = {}

    ----------------------------------------------------
    -- REMOTES E DADOS
    ----------------------------------------------------
    local function dig(root, path)
        local node = root
        for _, n in ipairs(path) do
            node = node and node:FindFirstChild(n)
        end
        return node
    end

    local eggRemote = dig(RS, { "Packages", "Knit", "Services", "EggService", "RF", "purchaseEgg" })
    local voidEvent = dig(RS, { "Packages", "Knit", "Services", "PetVoidService", "RE", "onCraftToVoid" })

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

    local function findGold()
        local folder = dig(PlayerGui, { "GameUI", "Menus", "Inventory", "Display", "Pets", "ScrollingFrame", "Pets" })
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

    ----------------------------------------------------
    -- ESTILO
    ----------------------------------------------------
    local ACCENT = CONFIG.ACCENT
    local BG = Color3.fromRGB(11, 11, 14)
    local PANEL = Color3.fromRGB(20, 20, 27)
    local ITEM = Color3.fromRGB(27, 27, 36)
    local LINE = Color3.fromRGB(46, 46, 58)
    local TXT = Color3.fromRGB(236, 236, 242)
    local DIM = Color3.fromRGB(122, 124, 140)
    local OFFT = Color3.fromRGB(48, 48, 60)
    local OFFK = Color3.fromRGB(150, 150, 164)
    local RED = Color3.fromRGB(255, 80, 90)

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

    local function stroke(o, color, th, transp)
        local s = Instance.new("UIStroke")
        s.Color = color
        s.Thickness = th
        s.Transparency = transp or 0
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        s.Parent = o
        return s
    end

    local function lbl(parent, text, x, y, w, h, size, color, align, font)
        return mk("TextLabel", {
            Position = UDim2.new(0, x, 0, y),
            Size = UDim2.new(0, w, 0, h),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = color or TXT,
            TextSize = size,
            Font = font or Enum.Font.GothamMedium,
            TextXAlignment = align or Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, parent)
    end

    -- barra fina centralizada (usada para desenhar ícones)
    local function bar(parent, w, h, color, x, y, rot)
        return mk("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, x, 0, y),
            Size = UDim2.new(0, w, 0, h),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            Rotation = rot or 0,
        }, parent)
    end

    local FULL = UDim2.new(1, 0, 1, 0)

    ----------------------------------------------------
    -- JANELA
    ----------------------------------------------------
    local gui = Instance.new("ScreenGui")
    gui.Name = "ZaroHub"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 999
    gui.Parent = PlayerGui

    local W, H = 430, 250
    local main = mk("Frame", {
        Size = UDim2.new(0, W, 0, H),
        Position = UDim2.new(0.5, -W / 2, 0.25, 0),
        BackgroundColor3 = BG,
        BorderSizePixel = 0,
        Active = true,
        Draggable = true,
    }, gui, 12)
    local mainStroke = stroke(main, LINE, 1)

    -- Fundo (imagem/vídeo opcionais)
    local bgLayer = mk("Frame", {
        Size = FULL,
        BackgroundColor3 = BG,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 0,
    }, main, 12)
    local bgImage = mk("ImageLabel", {
        Size = FULL,
        BackgroundTransparency = 1,
        ScaleType = Enum.ScaleType.Crop,
        Visible = false,
        ZIndex = 1,
    }, bgLayer)
    local bgVideo = mk("VideoFrame", {
        Size = FULL,
        BackgroundTransparency = 1,
        Looped = true,
        Volume = 0,
        Visible = false,
        ZIndex = 2,
    }, bgLayer)
    local bgDim = mk("Frame", {
        Size = FULL,
        BackgroundColor3 = BG,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ZIndex = 3,
    }, bgLayer)

    local function extOf(url, default)
        local clean = url:gsub("%?.*$", "")
        return clean:match("%.(%w+)$") or default
    end

    local function loadAsset(url, fname)
        if url:match("^rbxasset") then return url end
        if not (writefile and getcustomasset) then return nil end
        local ok, res = pcall(function()
            writefile(fname, game:HttpGet(url))
            return getcustomasset(fname)
        end)
        if ok then return res end
        return nil
    end

    local bgThread = task.spawn(function()
        if CONFIG.BG_VIDEO ~= "" then
            local a = loadAsset(CONFIG.BG_VIDEO, "zarohub_bg." .. extOf(CONFIG.BG_VIDEO, "webm"))
            if a and running then
                bgVideo.Video = a
                bgVideo.Visible = true
                bgVideo.Playing = true
                bgDim.BackgroundTransparency = CONFIG.BG_DIM
                return
            end
        end
        if CONFIG.BG_IMAGE ~= "" then
            local a = loadAsset(CONFIG.BG_IMAGE, "zarohub_bg." .. extOf(CONFIG.BG_IMAGE, "png"))
            if a and running then
                bgImage.Image = a
                bgImage.Visible = true
                bgDim.BackgroundTransparency = CONFIG.BG_DIM
            end
        end
    end)

    -- Traço de destaque no canto
    mk("Frame", {
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(0, 54, 0, 2),
        BackgroundColor3 = ACCENT,
        BorderSizePixel = 0,
        ZIndex = 5,
    }, main)

    ----------------------------------------------------
    -- BARRA DE TÍTULO (ícones desenhados)
    ----------------------------------------------------
    local function iconButton(x)
        return mk("TextButton", {
            Position = UDim2.new(0, x, 0, 6),
            Size = UDim2.new(0, 28, 0, 28),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 5,
        }, main)
    end

    local menuBtn = iconButton(8)
    for i = 0, 2 do
        local b = bar(menuBtn, 14, 2, DIM, 14, 8 + i * 6, 0)
        b.ZIndex = 6
    end

    local logo = mk("Frame", {
        Position = UDim2.new(0, 42, 0, 9),
        Size = UDim2.new(0, 22, 0, 22),
        BackgroundColor3 = ACCENT,
        BorderSizePixel = 0,
        ZIndex = 5,
    }, main, 5)
    mk("TextLabel", {
        Size = FULL,
        BackgroundTransparency = 1,
        Text = "Z",
        TextColor3 = BG,
        TextSize = 15,
        Font = Enum.Font.GothamBlack,
        ZIndex = 6,
    }, logo)

    local title = mk("TextLabel", {
        Position = UDim2.new(0, 72, 0, 8),
        Size = UDim2.new(0, 160, 0, 24),
        BackgroundTransparency = 1,
        RichText = true,
        Text = string.format('%s <font color="rgb(%d,%d,%d)">%s</font>', CONFIG.NAME_A,
            math.floor(ACCENT.R * 255), math.floor(ACCENT.G * 255), math.floor(ACCENT.B * 255), CONFIG.NAME_B),
        TextColor3 = TXT,
        TextSize = 15,
        Font = Enum.Font.GothamBlack,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
    }, main)

    local minBtn = iconButton(W - 70)
    local minBar = bar(minBtn, 12, 2, DIM, 14, 14, 0)
    minBar.ZIndex = 6

    local closeBtn = iconButton(W - 38)
    local cx1 = bar(closeBtn, 14, 2, DIM, 14, 14, 45)
    local cx2 = bar(closeBtn, 14, 2, DIM, 14, 14, -45)
    cx1.ZIndex = 6
    cx2.ZIndex = 6

    minBtn.MouseEnter:Connect(function() tween(minBar, 0.15, { BackgroundColor3 = TXT }) end)
    minBtn.MouseLeave:Connect(function() tween(minBar, 0.2, { BackgroundColor3 = DIM }) end)
    closeBtn.MouseEnter:Connect(function()
        tween(cx1, 0.15, { BackgroundColor3 = RED })
        tween(cx2, 0.15, { BackgroundColor3 = RED })
    end)
    closeBtn.MouseLeave:Connect(function()
        tween(cx1, 0.2, { BackgroundColor3 = DIM })
        tween(cx2, 0.2, { BackgroundColor3 = DIM })
    end)

    mk("Frame", {
        Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = LINE,
        BorderSizePixel = 0,
        ZIndex = 5,
    }, main)

    ----------------------------------------------------
    -- MENU LATERAL
    ----------------------------------------------------
    local sidebar = mk("Frame", {
        Position = UDim2.new(0, 8, 0, 48),
        Size = UDim2.new(0, 94, 0, 194),
        BackgroundColor3 = PANEL,
        BackgroundTransparency = 0.12,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 4,
    }, main, 10)
    stroke(sidebar, LINE, 1)

    local tabsScroll = mk("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 0,
        ZIndex = 5,
    }, sidebar)

    local indicator = mk("Frame", {
        Position = UDim2.new(0, 0, 0, 11),
        Size = UDim2.new(0, 3, 0, 22),
        BackgroundColor3 = ACCENT,
        BorderSizePixel = 0,
        ZIndex = 6,
    }, tabsScroll)

    local function newPage(visible)
        local p = mk("ScrollingFrame", {
            Position = UDim2.new(0, 110, 0, 48),
            Size = UDim2.new(0, 312, 0, 194),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = ACCENT,
            Visible = visible,
            ZIndex = 4,
        }, main)
        local l = Instance.new("UIListLayout")
        l.Padding = UDim.new(0, 6)
        l.SortOrder = Enum.SortOrder.LayoutOrder
        l.Parent = p
        return p
    end

    local pages, tabBtns, tabOrder = {}, {}, {}
    local function addTab(key, text)
        table.insert(tabOrder, key)
        local idx = #tabOrder
        local b = mk("TextButton", {
            Position = UDim2.new(0, 0, 0, 6 + (idx - 1) * 32),
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = DIM,
            TextSize = 12,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            ZIndex = 5,
        }, tabsScroll)
        mk("UIPadding", { PaddingLeft = UDim.new(0, 16) }, b)
        tabBtns[key] = b
        pages[key] = newPage(idx == 1)
        return pages[key]
    end

    local eggsPage = addTab("Eggs", "EGGS")
    local voidPage = addTab("Void", "VOID")
    local tpPage = addTab("Teleport", "TELEPORT")
    local qPage = addTab("Quests", "QUESTS")
    local aPage = addTab("Aura", "AURA")
    local lPage = addTab("Luta", "LUTA")
    tabBtns.Eggs.TextColor3 = ACCENT

    local sidebarOpen = true
    local function setSidebar(open)
        sidebarOpen = open
        tween(sidebar, 0.25, { Size = UDim2.new(0, open and 94 or 0, 0, 194) })
        for _, page in pairs(pages) do
            tween(page, 0.25, {
                Position = UDim2.new(0, open and 110 or 8, 0, 48),
                Size = UDim2.new(0, open and 312 or 414, 0, 194),
            })
        end
    end
    menuBtn.MouseButton1Click:Connect(function() setSidebar(not sidebarOpen) end)

    local function selectTab(name)
        for key, page in pairs(pages) do
            page.Visible = (key == name)
            tween(tabBtns[key], 0.2, { TextColor3 = key == name and ACCENT or DIM })
        end
        local idx = table.find(tabOrder, name) or 1
        tween(indicator, 0.2, { Position = UDim2.new(0, 0, 0, 11 + (idx - 1) * 32) })
    end
    for key, b in pairs(tabBtns) do
        b.MouseButton1Click:Connect(function() selectTab(key) end)
    end

    ----------------------------------------------------
    -- COMPONENTES
    ----------------------------------------------------
    local function row(page, order, h)
        local r = mk("Frame", {
            LayoutOrder = order,
            Size = UDim2.new(1, -8, 0, h),
            BackgroundColor3 = PANEL,
            BackgroundTransparency = 0.12,
            BorderSizePixel = 0,
            ZIndex = 4,
        }, page, 8)
        stroke(r, LINE, 1)
        return r
    end

    local pillDot -- definido mais abaixo
    local function updatePill()
        if pillDot then
            tween(pillDot, 0.2, { BackgroundColor3 = (autoBuying or voidOn or auraOn or fightOn) and ACCENT or OFFT })
        end
    end

    local function makeSwitch(parent, y, initial, onChange)
        local on = initial
        local track = mk("TextButton", {
            Position = UDim2.new(1, -56, 0, y),
            Size = UDim2.new(0, 44, 0, 22),
            BackgroundColor3 = on and ACCENT or OFFT,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 6,
        }, parent, 11)
        local knob = mk("Frame", {
            Position = on and UDim2.new(0, 25, 0, 3) or UDim2.new(0, 3, 0, 3),
            Size = UDim2.new(0, 16, 0, 16),
            BackgroundColor3 = on and BG or OFFK,
            BorderSizePixel = 0,
            ZIndex = 7,
        }, track, 8)
        track.MouseButton1Click:Connect(function()
            on = not on
            tween(track, 0.18, { BackgroundColor3 = on and ACCENT or OFFT })
            tween(knob, 0.18, {
                Position = on and UDim2.new(0, 25, 0, 3) or UDim2.new(0, 3, 0, 3),
                BackgroundColor3 = on and BG or OFFK,
            })
            if onChange then onChange(on) end
        end)
    end

    local function makeStepper(parent, y, init, step, lo, hi, fmt, onChange)
        local value = init
        local function sbtn(text, xoff)
            local b = mk("TextButton", {
                Position = UDim2.new(1, xoff, 0, y),
                Size = UDim2.new(0, 26, 0, 24),
                BackgroundColor3 = BG,
                Text = text,
                TextColor3 = TXT,
                TextSize = 15,
                Font = Enum.Font.GothamBold,
                AutoButtonColor = false,
                ZIndex = 6,
            }, parent, 6)
            stroke(b, LINE, 1)
            return b
        end
        local minus = sbtn("-", -150)
        local lab = lbl(parent, string.format(fmt, value), 0, 0, 66, 24, 13, ACCENT, Enum.TextXAlignment.Center, Enum.Font.Code)
        lab.Position = UDim2.new(1, -120, 0, y)
        lab.ZIndex = 6
        local plus = sbtn("+", -48)
        local function set(v)
            value = math.clamp(math.floor(v * 10 + 0.5) / 10, lo, hi)
            lab.Text = string.format(fmt, value)
            onChange(value)
        end
        minus.MouseButton1Click:Connect(function() set(value - step) end)
        plus.MouseButton1Click:Connect(function() set(value + step) end)
    end

    local function nameLabel(parent, text)
        local l = lbl(parent, text, 14, 0, 120, 48, 13, TXT, nil, Enum.Font.GothamBold)
        l.ZIndex = 6
        return l
    end

    local function valueChip(parent, text)
        local l = lbl(parent, text, 0, 0, 90, 48, 13, ACCENT, Enum.TextXAlignment.Right, Enum.Font.Code)
        l.Position = UDim2.new(1, -104, 0, 0)
        l.ZIndex = 6
        return l
    end

    ----------------------------------------------------
    -- PÁGINA EGGS
    ----------------------------------------------------
    local COLLAPSED_H, EXPANDED_H = 48, 196

    local card = row(eggsPage, 1, COLLAPSED_H)
    card.ClipsDescendants = true

    local header = mk("TextButton", {
        Size = UDim2.new(1, 0, 0, COLLAPSED_H),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 5,
    }, card)
    nameLabel(header, "Auto Egg")
    local selLabel = lbl(header, cleanName(selected), 0, 0, 96, 48, 11, DIM, Enum.TextXAlignment.Right)
    selLabel.Position = UDim2.new(1, -192, 0, 0)
    selLabel.ZIndex = 6

    -- Seta desenhada: ^ fechado, v aberto
    local chevron = mk("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(1, -80, 0, 24),
        Size = UDim2.new(0, 16, 0, 16),
        BackgroundTransparency = 1,
        ZIndex = 6,
    }, header)
    bar(chevron, 9, 2, ACCENT, 5, 9, -40).ZIndex = 6
    bar(chevron, 9, 2, ACCENT, 11, 9, 40).ZIndex = 6

    makeSwitch(card, 13, false, function(on)
        autoBuying = on
        tween(mainStroke, 0.2, { Color = (autoBuying or voidOn or auraOn or fightOn) and ACCENT or LINE })
        updatePill()
    end)

    local drop = mk("Frame", {
        Position = UDim2.new(0, 0, 0, 52),
        Size = UDim2.new(1, 0, 0, 140),
        BackgroundTransparency = 1,
        Visible = false,
        ZIndex = 5,
    }, card)

    local search = mk("TextBox", {
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -20, 0, 28),
        BackgroundColor3 = BG,
        PlaceholderText = "Buscar",
        PlaceholderColor3 = DIM,
        Text = "",
        TextColor3 = TXT,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        ZIndex = 6,
    }, drop, 6)
    mk("UIPadding", { PaddingLeft = UDim.new(0, 10) }, search)
    local searchStroke = stroke(search, LINE, 1)
    search.Focused:Connect(function() tween(searchStroke, 0.15, { Color = ACCENT }) end)
    search.FocusLost:Connect(function() tween(searchStroke, 0.2, { Color = LINE }) end)

    local list = mk("ScrollingFrame", {
        Position = UDim2.new(0, 10, 0, 34),
        Size = UDim2.new(1, -20, 0, 100),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = ACCENT,
        ZIndex = 6,
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
                local isSel = (raw == selected)
                local b = mk("TextButton", {
                    LayoutOrder = i,
                    Size = UDim2.new(1, -6, 0, 26),
                    BackgroundColor3 = ITEM,
                    Text = nm,
                    TextColor3 = isSel and ACCENT or TXT,
                    TextSize = 12,
                    Font = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    AutoButtonColor = false,
                    ZIndex = 7,
                }, list, 6)
                mk("UIPadding", { PaddingLeft = UDim.new(0, 12) }, b)
                if isSel then
                    mk("Frame", {
                        Position = UDim2.new(0, -12, 0.5, -7),
                        Size = UDim2.new(0, 3, 0, 14),
                        BackgroundColor3 = ACCENT,
                        BorderSizePixel = 0,
                        ZIndex = 8,
                    }, b)
                end
                b.MouseButton1Click:Connect(function()
                    selected = raw
                    selLabel.Text = nm
                    refreshList()
                end)
            end
        end
    end
    refreshList()
    search:GetPropertyChangedSignal("Text"):Connect(refreshList)

    local expanded = false
    header.MouseButton1Click:Connect(function()
        expanded = not expanded
        tween(chevron, 0.25, { Rotation = expanded and 180 or 0 })
        if expanded then
            drop.Visible = true
        else
            task.delay(0.26, function()
                if running and not expanded then drop.Visible = false end
            end)
        end
        tween(card, 0.25, { Size = UDim2.new(1, -8, 0, expanded and EXPANDED_H or COLLAPSED_H) })
    end)

    local rDelay = row(eggsPage, 2, 48)
    nameLabel(rDelay, "Delay")
    makeStepper(rDelay, 12, delayTime, 0.1, 0.1, 3, "%.1fs", function(v) delayTime = v end)

    local rMulti = row(eggsPage, 3, 48)
    nameLabel(rMulti, "Multi")
    makeSwitch(rMulti, 13, true, function(on) multiOpen = on end)

    local rCount = row(eggsPage, 4, 40)
    local lc = lbl(rCount, "Abertos", 14, 0, 120, 40, 13, TXT, nil, Enum.Font.GothamBold)
    lc.ZIndex = 6
    local countLabel = lbl(rCount, "0", 0, 0, 90, 40, 13, ACCENT, Enum.TextXAlignment.Right, Enum.Font.Code)
    countLabel.Position = UDim2.new(1, -104, 0, 0)
    countLabel.ZIndex = 6

    ----------------------------------------------------
    -- PÁGINA VOID
    ----------------------------------------------------
    local vRow = row(voidPage, 1, 48)
    nameLabel(vRow, "Auto Void")
    local voidStatus = lbl(vRow, "", 0, 0, 120, 48, 11, DIM, Enum.TextXAlignment.Right)
    voidStatus.Position = UDim2.new(1, -184, 0, 0)
    voidStatus.ZIndex = 6
    makeSwitch(vRow, 13, false, function(on)
        voidOn = on
        voidStatus.Text = on and "buscando" or ""
        tween(mainStroke, 0.2, { Color = (autoBuying or voidOn or auraOn or fightOn) and ACCENT or LINE })
        updatePill()
    end)

    local vInt = row(voidPage, 2, 48)
    nameLabel(vInt, "Intervalo")
    makeStepper(vInt, 12, voidInterval, 0.5, 0.5, 10, "%.1fs", function(v) voidInterval = v end)

    local vGold = row(voidPage, 3, 40)
    local lg = lbl(vGold, "Gold", 14, 0, 120, 40, 13, TXT, nil, Enum.Font.GothamBold)
    lg.ZIndex = 6
    local goldLabel = lbl(vGold, "-", 0, 0, 90, 40, 13, ACCENT, Enum.TextXAlignment.Right, Enum.Font.Code)
    goldLabel.Position = UDim2.new(1, -104, 0, 0)
    goldLabel.ZIndex = 6

    local vSent = row(voidPage, 4, 40)
    local ls = lbl(vSent, "Enviados", 14, 0, 120, 40, 13, TXT, nil, Enum.Font.GothamBold)
    ls.ZIndex = 6
    local sentLabel = lbl(vSent, "0", 0, 0, 90, 40, 13, ACCENT, Enum.TextXAlignment.Right, Enum.Font.Code)
    sentLabel.Position = UDim2.new(1, -104, 0, 0)
    sentLabel.ZIndex = 6

    ----------------------------------------------------
    -- PÁGINA TELEPORT
    ----------------------------------------------------
    do
    local zones = {}
    local selectedZone = nil
    local tpRemote = dig(RS, { "Packages", "Knit", "Services", "ZoneService", "RE", "teleport" })
    local SPAWN_PATH = { "Interactables", "Teleports", "Locations", "Spawn" }

    local function spawnOf(name)
        local zf = workspace:FindFirstChild("Zones")
        local z = zf and zf:FindFirstChild(name)
        return dig(z, SPAWN_PATH)
    end

    local function scanZones()
        zones = {}
        local zf = workspace:FindFirstChild("Zones")
        if zf then
            for _, z in ipairs(zf:GetChildren()) do
                if dig(z, SPAWN_PATH) then table.insert(zones, z.Name) end
            end
        end
        table.sort(zones, function(a, b)
            local na, nb = tonumber(a), tonumber(b)
            if na and nb then return na < nb end
            if na then return true end
            if nb then return false end
            return a < b
        end)
        if not selectedZone or not table.find(zones, selectedZone) then
            selectedZone = zones[1]
        end
    end

    local function zoneLabel(n)
        if tonumber(n) then return "Zona " .. n end
        return n
    end

    local tpCard = row(tpPage, 1, COLLAPSED_H)
    tpCard.ClipsDescendants = true

    local tpHeader = mk("TextButton", {
        Size = UDim2.new(1, 0, 0, COLLAPSED_H),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 5,
    }, tpCard)
    nameLabel(tpHeader, "Teleporte")
    local zSel = lbl(tpHeader, "-", 0, 0, 96, 48, 11, DIM, Enum.TextXAlignment.Right)
    zSel.Position = UDim2.new(1, -192, 0, 0)
    zSel.ZIndex = 6

    local tpChevron = mk("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(1, -80, 0, 24),
        Size = UDim2.new(0, 16, 0, 16),
        BackgroundTransparency = 1,
        ZIndex = 6,
    }, tpHeader)
    bar(tpChevron, 9, 2, ACCENT, 5, 9, -40).ZIndex = 6
    bar(tpChevron, 9, 2, ACCENT, 11, 9, 40).ZIndex = 6

    local goBtn = mk("TextButton", {
        Position = UDim2.new(1, -56, 0, 13),
        Size = UDim2.new(0, 44, 0, 22),
        BackgroundColor3 = ACCENT,
        Text = "IR",
        TextColor3 = BG,
        TextSize = 12,
        Font = Enum.Font.GothamBlack,
        AutoButtonColor = false,
        ZIndex = 6,
    }, tpCard, 6)

    local tpDrop = mk("Frame", {
        Position = UDim2.new(0, 0, 0, 52),
        Size = UDim2.new(1, 0, 0, 140),
        BackgroundTransparency = 1,
        Visible = false,
        ZIndex = 5,
    }, tpCard)

    local tpSearch = mk("TextBox", {
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -20, 0, 28),
        BackgroundColor3 = BG,
        PlaceholderText = "Buscar",
        PlaceholderColor3 = DIM,
        Text = "",
        TextColor3 = TXT,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        ZIndex = 6,
    }, tpDrop, 6)
    mk("UIPadding", { PaddingLeft = UDim.new(0, 10) }, tpSearch)
    local tpSearchStroke = stroke(tpSearch, LINE, 1)
    tpSearch.Focused:Connect(function() tween(tpSearchStroke, 0.15, { Color = ACCENT }) end)
    tpSearch.FocusLost:Connect(function() tween(tpSearchStroke, 0.2, { Color = LINE }) end)

    local tpList = mk("ScrollingFrame", {
        Position = UDim2.new(0, 10, 0, 34),
        Size = UDim2.new(1, -20, 0, 100),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = ACCENT,
        ZIndex = 6,
    }, tpDrop)
    local tpLayout = Instance.new("UIListLayout")
    tpLayout.Padding = UDim.new(0, 3)
    tpLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tpLayout.Parent = tpList

    local function refreshZoneList()
        for _, c in ipairs(tpList:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        zSel.Text = selectedZone and zoneLabel(selectedZone) or "-"
        local f = string.lower(tpSearch.Text)
        for i, name in ipairs(zones) do
            local label = zoneLabel(name)
            if f == "" or string.find(string.lower(label), f, 1, true) then
                local isSel = (name == selectedZone)
                local b = mk("TextButton", {
                    LayoutOrder = i,
                    Size = UDim2.new(1, -6, 0, 26),
                    BackgroundColor3 = ITEM,
                    Text = label,
                    TextColor3 = isSel and ACCENT or TXT,
                    TextSize = 12,
                    Font = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    AutoButtonColor = false,
                    ZIndex = 7,
                }, tpList, 6)
                mk("UIPadding", { PaddingLeft = UDim.new(0, 12) }, b)
                if isSel then
                    mk("Frame", {
                        Position = UDim2.new(0, -12, 0.5, -7),
                        Size = UDim2.new(0, 3, 0, 14),
                        BackgroundColor3 = ACCENT,
                        BorderSizePixel = 0,
                        ZIndex = 8,
                    }, b)
                end
                b.MouseButton1Click:Connect(function()
                    selectedZone = name
                    refreshZoneList()
                end)
            end
        end
    end
    scanZones()
    refreshZoneList()
    tpSearch:GetPropertyChangedSignal("Text"):Connect(refreshZoneList)

    local tpExpanded = false
    tpHeader.MouseButton1Click:Connect(function()
        tpExpanded = not tpExpanded
        tween(tpChevron, 0.25, { Rotation = tpExpanded and 180 or 0 })
        if tpExpanded then
            scanZones()
            refreshZoneList()
            tpDrop.Visible = true
        else
            task.delay(0.26, function()
                if running and not tpExpanded then tpDrop.Visible = false end
            end)
        end
        tween(tpCard, 0.25, { Size = UDim2.new(1, -8, 0, tpExpanded and EXPANDED_H or COLLAPSED_H) })
    end)

    local function flashGo(text)
        goBtn.Text = text
        task.delay(0.8, function()
            if running then goBtn.Text = "IR" end
        end)
    end

    goBtn.MouseButton1Click:Connect(function()
        if not selectedZone then scanZones() end
        local sp = selectedZone and spawnOf(selectedZone)
        if not sp then
            scanZones()
            refreshZoneList()
            flashGo("X")
            return
        end
        if not tpRemote then
            tpRemote = dig(RS, { "Packages", "Knit", "Services", "ZoneService", "RE", "teleport" })
        end
        if tpRemote then
            local ok = pcall(function() tpRemote:FireServer(sp) end)
            flashGo(ok and "OK" or "X")
        else
            flashGo("X")
        end
    end)

    end

    local claimLoop, qThreads = nil, {}
    ----------------------------------------------------
    -- PÁGINA QUESTS (Medal Merchant)
    ----------------------------------------------------
    do
    local questSlot = 1
    local autoClaim = false

    local function questRemote(name)
        return dig(RS, { "Packages", "Knit", "Services", "MedalMerchantQuestService", "RF", name })
    end

    local function actionButton(parent)
        return mk("TextButton", {
            Position = UDim2.new(1, -56, 0, 13),
            Size = UDim2.new(0, 44, 0, 22),
            BackgroundColor3 = ACCENT,
            Text = "GO",
            TextColor3 = BG,
            TextSize = 11,
            Font = Enum.Font.GothamBlack,
            AutoButtonColor = false,
            ZIndex = 6,
        }, parent, 6)
    end

    -- chama o remote e mostra o retorno no próprio botão (OK, NAO, X ou o valor)
    local function callQuest(btn, name, ...)
        local rem = questRemote(name)
        if not rem then
            btn.Text = "X"
            task.delay(1.2, function() if running then btn.Text = "GO" end end)
            return
        end
        local args = table.pack(...)
        local th = task.spawn(function()
            local ok, res = pcall(function()
                return rem:InvokeServer(table.unpack(args, 1, args.n))
            end)
            local txt
            if not ok then
                txt = "X"
            elseif res == nil or res == true then
                txt = "OK"
            elseif res == false then
                txt = "NAO"
            else
                txt = string.sub(tostring(res), 1, 4)
            end
            if running then
                btn.Text = txt
                task.delay(1.5, function() if running then btn.Text = "GO" end end)
            end
        end)
        table.insert(qThreads, th)
    end

    local qSlotRow = row(qPage, 1, 48)
    nameLabel(qSlotRow, "Quest")
    makeStepper(qSlotRow, 12, questSlot, 1, 1, 4, "%.0f", function(v) questSlot = math.floor(v + 0.5) end)

    local qAccept = row(qPage, 2, 48)
    nameLabel(qAccept, "Aceitar")
    local acceptBtn = actionButton(qAccept)
    acceptBtn.MouseButton1Click:Connect(function() callQuest(acceptBtn, "AcceptQuest", questSlot) end)

    local qClaim = row(qPage, 3, 48)
    nameLabel(qClaim, "Coletar")
    local claimBtn = actionButton(qClaim)
    claimBtn.MouseButton1Click:Connect(function() callQuest(claimBtn, "ClaimCompletedQuest") end)

    local qAbandon = row(qPage, 4, 48)
    nameLabel(qAbandon, "Abandonar")
    local abandonBtn = actionButton(qAbandon)
    abandonBtn.MouseButton1Click:Connect(function() callQuest(abandonBtn, "AbandonQuest") end)

    local qAuto = row(qPage, 5, 48)
    nameLabel(qAuto, "Auto Coletar")
    makeSwitch(qAuto, 13, false, function(on) autoClaim = on end)

    claimLoop = task.spawn(function()
        while running do
            if autoClaim then
                local rem = questRemote("ClaimCompletedQuest")
                if rem then pcall(function() rem:InvokeServer() end) end
            end
            task.wait(5)
        end
    end)

    end

    local auraLoop
    ----------------------------------------------------
    -- PÁGINA AURA
    ----------------------------------------------------
    do
    local auraInterval = 1
    local auraCount = 0

    local aRow = row(aPage, 1, 48)
    nameLabel(aRow, "Auto Roll")
    makeSwitch(aRow, 13, false, function(on)
        auraOn = on
        tween(mainStroke, 0.2, { Color = (autoBuying or voidOn or auraOn or fightOn) and ACCENT or LINE })
        updatePill()
    end)

    local aInt = row(aPage, 2, 48)
    nameLabel(aInt, "Intervalo")
    makeStepper(aInt, 12, auraInterval, 0.1, 0.1, 10, "%.1fs", function(v) auraInterval = v end)

    local aCount = row(aPage, 3, 40)
    local lac = lbl(aCount, "Rolls", 14, 0, 120, 40, 13, TXT, nil, Enum.Font.GothamBold)
    lac.ZIndex = 6
    local auraCountLabel = lbl(aCount, "0", 0, 0, 90, 40, 13, ACCENT, Enum.TextXAlignment.Right, Enum.Font.Code)
    auraCountLabel.Position = UDim2.new(1, -104, 0, 0)
    auraCountLabel.ZIndex = 6

    auraLoop = task.spawn(function()
        while running do
            if auraOn then
                local rem = dig(RS, { "Packages", "Knit", "Services", "AuraService", "RF", "Roll" })
                if rem then
                    local ok = pcall(function() rem:InvokeServer() end)
                    if ok then
                        auraCount = auraCount + 1
                        auraCountLabel.Text = tostring(auraCount)
                    end
                end
            end
            task.wait(auraInterval)
        end
    end)

    end

    ----------------------------------------------------
    -- PÁGINA LUTA (ArmWrestle)
    ----------------------------------------------------
    local fightLoop
    local fightConns, fightThreads = {}, {}
    do
        local critOn = false
        local clickInterval = 0.2
        local fights = 0
        local crits = 0
        local fighting = false
        local curGen = 1
        local fightStartedAt = 0
        local fighters = {}
        local selFighter = nil
        local UUID_PAT = "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$"
        local FIGHT_H = 166

        local function awRemote(kind, name)
            return dig(RS, { "Packages", "Knit", "Services", "ArmWrestleService", kind, name })
        end

        local function scanFighters()
            local prev = selFighter and (selFighter.zone .. "/" .. selFighter.npc)
            fighters = {}
            local root = dig(workspace, { "GameObjects", "ArmWrestling" })
            if root then
                for _, zf in ipairs(root:GetChildren()) do
                    local npcs = zf:FindFirstChild("NPC")
                    if npcs then
                        for _, n in ipairs(npcs:GetChildren()) do
                            table.insert(fighters, { zone = zf.Name, npc = n.Name })
                        end
                    end
                end
            end
            if #fighters == 0 then
                fighters = { { zone = "SumoStairway", npc = "BellyBrawler" } }
            end
            table.sort(fighters, function(a, b)
                if a.zone ~= b.zone then return a.zone < b.zone end
                return a.npc < b.npc
            end)
            local pick = nil
            for _, f in ipairs(fighters) do
                if prev and (f.zone .. "/" .. f.npc) == prev then pick = f end
            end
            if not pick then
                for _, f in ipairs(fighters) do
                    if f.npc == "BellyBrawler" then pick = f end
                end
            end
            selFighter = pick or fighters[1]
        end

        -- Cartão: Auto Luta + seletor de boss
        local fCard = row(lPage, 1, COLLAPSED_H)
        fCard.ClipsDescendants = true
        local fHeader = mk("TextButton", {
            Size = UDim2.new(1, 0, 0, COLLAPSED_H),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 5,
        }, fCard)
        nameLabel(fHeader, "Auto Luta")
        local fSel = lbl(fHeader, "-", 0, 0, 96, 48, 11, DIM, Enum.TextXAlignment.Right)
        fSel.Position = UDim2.new(1, -192, 0, 0)
        fSel.ZIndex = 6
        local fChev = mk("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(1, -80, 0, 24),
            Size = UDim2.new(0, 16, 0, 16),
            BackgroundTransparency = 1,
            ZIndex = 6,
        }, fHeader)
        bar(fChev, 9, 2, ACCENT, 5, 9, -40).ZIndex = 6
        bar(fChev, 9, 2, ACCENT, 11, 9, 40).ZIndex = 6

        local fDrop = mk("Frame", {
            Position = UDim2.new(0, 0, 0, 52),
            Size = UDim2.new(1, 0, 0, 110),
            BackgroundTransparency = 1,
            Visible = false,
            ZIndex = 5,
        }, fCard)
        local fList = mk("ScrollingFrame", {
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(1, -20, 0, 104),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = ACCENT,
            ZIndex = 6,
        }, fDrop)
        local fLayout = Instance.new("UIListLayout")
        fLayout.Padding = UDim.new(0, 3)
        fLayout.SortOrder = Enum.SortOrder.LayoutOrder
        fLayout.Parent = fList

        local function refreshFighterList()
            for _, c in ipairs(fList:GetChildren()) do
                if c:IsA("TextButton") then c:Destroy() end
            end
            fSel.Text = selFighter and selFighter.npc or "-"
            for i, f in ipairs(fighters) do
                local isSel = (f == selFighter)
                local b = mk("TextButton", {
                    LayoutOrder = i,
                    Size = UDim2.new(1, -6, 0, 26),
                    BackgroundColor3 = ITEM,
                    Text = f.npc .. "  -  " .. f.zone,
                    TextColor3 = isSel and ACCENT or TXT,
                    TextSize = 12,
                    Font = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    AutoButtonColor = false,
                    ZIndex = 7,
                }, fList, 6)
                mk("UIPadding", { PaddingLeft = UDim.new(0, 12) }, b)
                if isSel then
                    mk("Frame", {
                        Position = UDim2.new(0, -12, 0.5, -7),
                        Size = UDim2.new(0, 3, 0, 14),
                        BackgroundColor3 = ACCENT,
                        BorderSizePixel = 0,
                        ZIndex = 8,
                    }, b)
                end
                b.MouseButton1Click:Connect(function()
                    selFighter = f
                    fighting = false
                    refreshFighterList()
                end)
            end
        end
        scanFighters()
        refreshFighterList()

        local fExpanded = false
        fHeader.MouseButton1Click:Connect(function()
            fExpanded = not fExpanded
            tween(fChev, 0.25, { Rotation = fExpanded and 180 or 0 })
            if fExpanded then
                scanFighters()
                refreshFighterList()
                fDrop.Visible = true
            else
                task.delay(0.26, function()
                    if running and not fExpanded then fDrop.Visible = false end
                end)
            end
            tween(fCard, 0.25, { Size = UDim2.new(1, -8, 0, fExpanded and FIGHT_H or COLLAPSED_H) })
        end)

        makeSwitch(fCard, 13, false, function(on)
            fightOn = on
            if not on then
                fighting = false
                local th = task.spawn(function()
                    local sa = awRemote("RF", "SetAuto")
                    if sa then pcall(function() sa:InvokeServer(false) end) end
                end)
                table.insert(fightThreads, th)
            end
            tween(mainStroke, 0.2, { Color = (autoBuying or voidOn or auraOn or fightOn) and ACCENT or LINE })
            updatePill()
        end)

        local rCrit = row(lPage, 2, 48)
        nameLabel(rCrit, "Auto Crítico")
        makeSwitch(rCrit, 13, false, function(on) critOn = on end)

        local rSpeed = row(lPage, 3, 48)
        nameLabel(rSpeed, "Intervalo")
        makeStepper(rSpeed, 12, clickInterval, 0.1, 0.1, 2, "%.1fs", function(v) clickInterval = v end)

        local rFights = row(lPage, 4, 40)
        local l1 = lbl(rFights, "Lutas", 14, 0, 120, 40, 13, TXT, nil, Enum.Font.GothamBold)
        l1.ZIndex = 6
        local fightsLabel = lbl(rFights, "0", 0, 0, 90, 40, 13, ACCENT, Enum.TextXAlignment.Right, Enum.Font.Code)
        fightsLabel.Position = UDim2.new(1, -104, 0, 0)
        fightsLabel.ZIndex = 6

        local rCrits = row(lPage, 5, 40)
        local l2 = lbl(rCrits, "Críticos", 14, 0, 120, 40, 13, TXT, nil, Enum.Font.GothamBold)
        l2.ZIndex = 6
        local critsLabel = lbl(rCrits, "0", 0, 0, 90, 40, 13, ACCENT, Enum.TextXAlignment.Right, Enum.Font.Code)
        critsLabel.Position = UDim2.new(1, -104, 0, 0)
        critsLabel.ZIndex = 6

        -- procura um GUID dentro dos argumentos de um sinal
        local function findUuid(v, depth)
            if type(v) == "string" then
                if v:match(UUID_PAT) then return v end
            elseif type(v) == "table" and depth > 0 then
                for _, x in pairs(v) do
                    local r = findUuid(x, depth - 1)
                    if r then return r end
                end
            end
            return nil
        end

        local function hookSignal(name, fn)
            local r = awRemote("RE", name)
            if r and r:IsA("RemoteEvent") then
                table.insert(fightConns, r.OnClientEvent:Connect(fn))
            end
        end

        hookSignal("StartFightSignal", function(_, data)
            if type(data) == "table" and data.Generation then
                curGen = data.Generation
            end
            fighting = true
            fightStartedAt = os.clock()
        end)

        hookSignal("EndFightSignal", function()
            if fighting then
                fights = fights + 1
                fightsLabel.Text = tostring(fights)
            end
            fighting = false
        end)

        hookSignal("SpawnCritSignal", function(...)
            if not (critOn and fightOn and fighting and selFighter) then return end
            local id = findUuid(table.pack(...), 4)
            if not id then return end
            local f, gen = selFighter, curGen
            local th = task.spawn(function()
                local rem = awRemote("RF", "RequestCritHit")
                if not rem then return end
                local ok, res = pcall(function()
                    return rem:InvokeServer({ npcName = f.npc, zone = f.zone, generation = gen }, id)
                end)
                if ok and res == true then
                    crits = crits + 1
                    critsLabel.Text = tostring(crits)
                end
            end)
            table.insert(fightThreads, th)
        end)

        fightLoop = task.spawn(function()
            while running do
                if fightOn and selFighter then
                    local f = selFighter
                    if not fighting then
                        local sa = awRemote("RF", "SetAuto")
                        if sa then pcall(function() sa:InvokeServer(true, f.npc) end) end
                        local st = awRemote("RF", "RequestStartFight")
                        if st then pcall(function() st:InvokeServer(f.npc) end) end
                        local waited = 0
                        while fightOn and not fighting and waited < 2 do
                            task.wait(0.1)
                            waited = waited + 0.1
                        end
                        if fighting then
                            task.wait(0.9) -- contagem inicial da luta
                        else
                            task.wait(1)
                        end
                    else
                        local rc = awRemote("RF", "RequestClick")
                        if rc then
                            local ok, res = pcall(function()
                                return rc:InvokeServer(false, { npcName = f.npc, zone = f.zone, generation = curGen })
                            end)
                            if ok and type(res) == "table" and res.Health and res.MaxHealth and res.Health >= res.MaxHealth then
                                fighting = false
                            end
                        end
                        if os.clock() - fightStartedAt > 40 then fighting = false end
                        task.wait(clickInterval)
                    end
                else
                    task.wait(0.3)
                end
            end
        end)
    end

    ----------------------------------------------------
    -- PAINEL FLUTUANTE (minimizado)
    ----------------------------------------------------
    local pill = mk("TextButton", {
        Size = UDim2.new(0, 96, 0, 34),
        Position = UDim2.new(0.04, 0, 0.2, 0),
        BackgroundColor3 = BG,
        Text = "",
        AutoButtonColor = false,
        Visible = false,
        Active = true,
        Draggable = true,
    }, gui, 8)
    stroke(pill, LINE, 1)

    local mark = mk("Frame", {
        Size = UDim2.new(0, 34, 1, 0),
        BackgroundColor3 = ACCENT,
        BorderSizePixel = 0,
    }, pill, 8)
    mk("Frame", {
        Position = UDim2.new(1, -10, 0, 0),
        Size = UDim2.new(0, 10, 1, 0),
        BackgroundColor3 = ACCENT,
        BorderSizePixel = 0,
    }, mark)
    mk("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "Z",
        TextColor3 = BG,
        TextSize = 17,
        Font = Enum.Font.GothamBlack,
        ZIndex = 3,
    }, mark)
    mk("TextLabel", {
        Position = UDim2.new(0, 42, 0, 0),
        Size = UDim2.new(0, 36, 1, 0),
        BackgroundTransparency = 1,
        Text = CONFIG.NAME_A,
        TextColor3 = TXT,
        TextSize = 12,
        Font = Enum.Font.GothamBlack,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, pill)
    pillDot = mk("Frame", {
        Position = UDim2.new(1, -16, 0.5, -4),
        Size = UDim2.new(0, 8, 0, 8),
        BackgroundColor3 = OFFT,
        BorderSizePixel = 0,
    }, pill, 4)

    minBtn.MouseButton1Click:Connect(function()
        main.Visible = false
        pill.Visible = true
        bgVideo.Playing = false
    end)
    pill.MouseButton1Click:Connect(function()
        main.Visible = true
        pill.Visible = false
        if bgVideo.Visible then bgVideo.Playing = true end
    end)

    ----------------------------------------------------
    -- LOOPS
    ----------------------------------------------------
    local eggLoop = task.spawn(function()
        while running do
            if autoBuying then
                if not eggRemote then
                    eggRemote = dig(RS, { "Packages", "Knit", "Services", "EggService", "RF", "purchaseEgg" })
                end
                if eggRemote then
                    local ok = pcall(function()
                        eggRemote:InvokeServer(selected, nil, nil, false, nil, multiOpen and true or nil, nil)
                    end)
                    if ok then
                        count = count + 1
                        countLabel.Text = tostring(count)
                    end
                end
            end
            task.wait(delayTime)
        end
    end)

    local voidLoop = task.spawn(function()
        while running do
            if voidOn then
                if not voidEvent then
                    voidEvent = dig(RS, { "Packages", "Knit", "Services", "PetVoidService", "RE", "onCraftToVoid" })
                end
                local guid, total, found = findGold()
                if not found then
                    voidStatus.Text = "abra o inventário"
                elseif not voidEvent then
                    voidStatus.Text = "sem remote"
                else
                    goldLabel.Text = tostring(total)
                    if guid then
                        local ok = pcall(function() voidEvent:FireServer(guid) end)
                        if ok then
                            sentAt[guid] = os.clock()
                            voidSent = voidSent + 1
                            sentLabel.Text = tostring(voidSent)
                            voidStatus.Text = "enviando"
                        end
                    else
                        voidStatus.Text = "sem gold"
                    end
                end
            end
            task.wait(voidInterval)
        end
    end)

    ----------------------------------------------------
    -- FECHAR = ENCERRA TUDO
    ----------------------------------------------------
    local function shutdown()
        running = false
        autoBuying = false
        voidOn = false
        auraOn = false
        pcall(task.cancel, eggLoop)
        pcall(task.cancel, voidLoop)
        pcall(task.cancel, bgThread)
        pcall(task.cancel, claimLoop)
        pcall(task.cancel, auraLoop)
        pcall(task.cancel, fightLoop)
        for _, th in ipairs(fightThreads) do pcall(task.cancel, th) end
        for _, c in ipairs(fightConns) do pcall(function() c:Disconnect() end) end
        if fightOn then
            -- desliga o modo automático da luta no servidor
            local sa = dig(RS, { "Packages", "Knit", "Services", "ArmWrestleService", "RF", "SetAuto" })
            if sa then task.spawn(function() pcall(function() sa:InvokeServer(false) end) end) end
        end
        fightOn = false
        for _, th in ipairs(qThreads) do pcall(task.cancel, th) end
        pcall(function() bgVideo.Playing = false end)
        ENV.__ZaroHub = nil
        gui:Destroy()
    end
    ENV.__ZaroHub = shutdown
    closeBtn.MouseButton1Click:Connect(shutdown)
end

local ok, err = pcall(main)
if not ok then
    warn("[ZaroHub] ERRO: " .. tostring(err))
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
