-- ============================================================
--  NexusUI  |  Roblox Executor UI Library
--  Usage:   loadstring(game:HttpGet("URL"))()
--  Version: 1.1.0  (with full error handling & executor compat)
-- ============================================================

local NexusUI = {}
NexusUI.__index = NexusUI

-- ─── Executor Compatibility Layer ────────────────────────────
-- Some executors don't fully support task.* — provide safe fallbacks
local function safeSpawn(fn, ...)
    if not fn then return end
    local args = {...}
    local ok, err

    -- Try task.spawn first (modern executors: Synapse X v3, KRNL, Fluxus, etc.)
    if task and task.spawn then
        ok, err = pcall(task.spawn, function()
            pcall(fn, table.unpack(args))
        end)
        if ok then return end
    end

    -- Fallback: coroutine (works on virtually all executors)
    local co = coroutine.create(function()
        local success, cbErr = pcall(fn, table.unpack(args))
        if not success then
            warn("[NexusUI] Callback error: " .. tostring(cbErr))
        end
    end)
    coroutine.resume(co)
end

-- Safe service getter — won't crash if a service is unavailable
local function getService(name)
    local ok, svc = pcall(function() return game:GetService(name) end)
    if ok and svc then return svc end
    warn("[NexusUI] Could not get service: " .. name)
    return nil
end

-- ─── Services ────────────────────────────────────────────────
local Players           = getService("Players")
local UserInputService  = getService("UserInputService")
local TweenService      = getService("TweenService")
local RunService        = getService("RunService")

if not Players then
    error("[NexusUI] FATAL: Players service unavailable — cannot continue.", 2)
end

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    -- Wait for LocalPlayer (sometimes needed in LocalScript context)
    LocalPlayer = Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LocalPlayer = Players.LocalPlayer
end

-- ─── Theme ───────────────────────────────────────────────────
local Theme = {
    Background    = Color3.fromRGB(18, 18, 24),
    Surface       = Color3.fromRGB(25, 25, 35),
    Card          = Color3.fromRGB(30, 30, 42),
    Accent        = Color3.fromRGB(120, 90, 255),
    AccentHover   = Color3.fromRGB(140, 110, 255),
    Text          = Color3.fromRGB(230, 230, 240),
    SubText       = Color3.fromRGB(140, 140, 160),
    Border        = Color3.fromRGB(50, 50, 68),
    SliderFill    = Color3.fromRGB(120, 90, 255),
    ToggleOn      = Color3.fromRGB(120, 90, 255),
    ToggleOff     = Color3.fromRGB(60, 60, 80),
    Shadow        = Color3.fromRGB(0, 0, 0),
    Font          = Enum.Font.GothamBold,
    FontRegular   = Enum.Font.Gotham,
}

-- ─── Helpers ─────────────────────────────────────────────────

-- Validate that a value is the expected type; return default if not
local function validate(val, expectedType, default, fieldName)
    if val == nil then return default end
    if type(val) ~= expectedType then
        warn(("[NexusUI] '%s' expected %s, got %s — using default"):format(
            tostring(fieldName), expectedType, type(val)))
        return default
    end
    return val
end

-- Safe tween — silently skips if TweenService unavailable
local function Tween(obj, props, dur, style, dir)
    if not TweenService then return end
    local ok, err = pcall(function()
        style = style or Enum.EasingStyle.Quad
        dir   = dir   or Enum.EasingDirection.Out
        TweenService:Create(obj, TweenInfo.new(dur or 0.18, style, dir), props):Play()
    end)
    if not ok then
        -- Fallback: apply properties directly without animation
        for k, v in pairs(props) do
            pcall(function() obj[k] = v end)
        end
    end
end

-- Instance factory with error catching
local function Create(class, props, children)
    local ok, obj = pcall(Instance.new, class)
    if not ok then
        warn("[NexusUI] Could not create Instance: " .. class)
        return nil
    end
    for k, v in pairs(props or {}) do
        local setOk, setErr = pcall(function() obj[k] = v end)
        if not setOk then
            warn(("[NexusUI] Property '%s' on %s failed: %s"):format(
                tostring(k), class, tostring(setErr)))
        end
    end
    for _, child in pairs(children or {}) do
        if child then
            pcall(function() child.Parent = obj end)
        end
    end
    return obj
end

-- Draggable window (with nil-safety)
local function MakeDraggable(frame, handle)
    if not frame or not handle or not UserInputService then return end
    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil

    local ok1 = pcall(function()
        handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging  = true
                dragStart = input.Position
                startPos  = frame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        handle.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                dragInput = input
            end
        end)
    end)

    local ok2 = pcall(function()
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                pcall(function()
                    frame.Position = UDim2.new(
                        startPos.X.Scale,
                        startPos.X.Offset + delta.X,
                        startPos.Y.Scale,
                        startPos.Y.Offset + delta.Y
                    )
                end)
            end
        end)
    end)

    if not (ok1 and ok2) then
        warn("[NexusUI] Drag setup encountered an issue — window may not be draggable")
    end
end

-- ─── Window ──────────────────────────────────────────────────
function NexusUI:Window(config)
    -- Validate config
    if type(config) ~= "table" then
        warn("[NexusUI] Window() expects a table config — using defaults")
        config = {}
    end

    local title    = validate(config.Title,    "string", "NexusUI",                   "Title")
    local size     = config.Size     or UDim2.new(0, 520, 0, 400)
    local position = config.Position or UDim2.new(0.5, -260, 0.5, -200)

    -- Guard: make sure size/position are UDim2
    if typeof(size) ~= "UDim2" then
        warn("[NexusUI] Window.Size must be UDim2 — using default")
        size = UDim2.new(0, 520, 0, 400)
    end
    if typeof(position) ~= "UDim2" then
        warn("[NexusUI] Window.Position must be UDim2 — using default")
        position = UDim2.new(0.5, -260, 0.5, -200)
    end

    -- ScreenGui — try PlayerGui first, then CoreGui
    local gui = Create("ScreenGui", {
        Name             = "NexusUI_" .. title,
        ResetOnSpawn     = false,
        ZIndexBehavior   = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset   = true,
    })
    if not gui then
        error("[NexusUI] Failed to create ScreenGui", 2)
    end

    -- Try Protected (only works in CoreGui context; silently skip if it fails)
    pcall(function() gui.Protected = true end)

    -- Parent to PlayerGui or CoreGui
    local parented = false
    local function tryParent(target)
        if not target then return false end
        local ok = pcall(function() gui.Parent = target end)
        return ok
    end

    local playerGui = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not tryParent(playerGui) then
        local coreGui = pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui")
        if not tryParent(coreGui) then
            warn("[NexusUI] Could not parent ScreenGui — GUI may not be visible")
        else
            parented = true
        end
    else
        parented = true
    end

    -- Shadow frame
    Create("ImageLabel", {
        Name                  = "Shadow",
        BackgroundTransparency = 1,
        Image                 = "rbxassetid://5554236805",
        ImageColor3           = Theme.Shadow,
        ImageTransparency     = 0.6,
        ScaleType             = Enum.ScaleType.Slice,
        SliceCenter           = Rect.new(23, 23, 277, 277),
        Size                  = UDim2.new(1, 30, 1, 30),
        Position              = UDim2.new(0, -15, 0, -15),
        ZIndex                = 0,
        Parent                = gui,
    })

    -- Main frame
    local main = Create("Frame", {
        Name             = "Main",
        BackgroundColor3  = Theme.Background,
        BorderSizePixel  = 0,
        Size             = size,
        Position         = position,
        ClipsDescendants = true,
        Parent           = gui,
    })
    if not main then error("[NexusUI] Failed to create Main frame", 2) end
    Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = main })
    Create("UIStroke",  { Color = Theme.Border, Thickness = 1, Parent = main })

    -- Title bar
    local titleBar = Create("Frame", {
        Name             = "TitleBar",
        BackgroundColor3  = Theme.Surface,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 44),
        Parent           = main,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = titleBar })
    -- Mask bottom corners
    Create("Frame", {
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 10),
        Position         = UDim2.new(0, 0, 1, -10),
        Parent           = titleBar,
    })
    -- Accent underline
    Create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel  = 0,
        Size             = UDim2.new(0, 40, 0, 2),
        Position         = UDim2.new(0, 14, 1, -1),
        Parent           = titleBar,
    })
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1, -50, 1, 0),
        Position               = UDim2.new(0, 14, 0, 0),
        Text                   = title,
        TextColor3             = Theme.Text,
        TextSize               = 15,
        Font                   = Theme.Font,
        TextXAlignment         = Enum.TextXAlignment.Left,
        Parent                 = titleBar,
    })

    -- Close button
    local closeBtn = Create("TextButton", {
        Name             = "Close",
        BackgroundColor3  = Color3.fromRGB(210, 60, 60),
        BorderSizePixel  = 0,
        Size             = UDim2.new(0, 14, 0, 14),
        Position         = UDim2.new(1, -24, 0.5, -7),
        Text             = "",
        AutoButtonColor  = false,
        Parent           = titleBar,
    })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = closeBtn })
    closeBtn.MouseButton1Click:Connect(function()
        pcall(function() gui:Destroy() end)
    end)
    closeBtn.MouseEnter:Connect(function()
        Tween(closeBtn, { BackgroundColor3 = Color3.fromRGB(240, 80, 80) })
    end)
    closeBtn.MouseLeave:Connect(function()
        Tween(closeBtn, { BackgroundColor3 = Color3.fromRGB(210, 60, 60) })
    end)

    -- Minimize button
    local minBtn = Create("TextButton", {
        Name             = "Minimize",
        BackgroundColor3  = Color3.fromRGB(200, 160, 40),
        BorderSizePixel  = 0,
        Size             = UDim2.new(0, 14, 0, 14),
        Position         = UDim2.new(1, -42, 0.5, -7),
        Text             = "",
        AutoButtonColor  = false,
        Parent           = titleBar,
    })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = minBtn })

    local minimized = false
    local fullSize  = size
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        Tween(main, {
            Size = minimized
                and UDim2.new(size.X.Scale, size.X.Offset, 0, 44)
                or fullSize
        }, 0.25, Enum.EasingStyle.Quart)
    end)

    MakeDraggable(main, titleBar)

    -- Content / pages area
    local content = Create("Frame", {
        Name             = "Content",
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 1, -44),
        Position         = UDim2.new(0, 0, 0, 44),
        ClipsDescendants = true,
        Parent           = main,
    })

    -- Tab bar
    local tabBar = Create("Frame", {
        Name             = "TabBar",
        BackgroundColor3  = Theme.Surface,
        BorderSizePixel  = 0,
        Size             = UDim2.new(0, 120, 1, 0),
        Parent           = content,
    })
    Create("UIListLayout", {
        FillDirection       = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Padding             = UDim.new(0, 4),
        Parent              = tabBar,
    })
    Create("UIPadding", {
        PaddingTop   = UDim.new(0, 10),
        PaddingLeft  = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        Parent       = tabBar,
    })

    -- Divider
    Create("Frame", {
        BackgroundColor3 = Theme.Border,
        BorderSizePixel  = 0,
        Size             = UDim2.new(0, 1, 1, 0),
        Position         = UDim2.new(0, 120, 0, 0),
        Parent           = content,
    })

    -- Page container
    local pages = Create("Frame", {
        Name             = "Pages",
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, -121, 1, 0),
        Position         = UDim2.new(0, 121, 0, 0),
        ClipsDescendants = true,
        Parent           = content,
    })

    local win = {
        Gui     = gui,
        Main    = main,
        TabBar  = tabBar,
        Pages   = pages,
        Tabs    = {},
        _active = nil,
    }

    -- ── Internal: switch active tab ──────────────────────────
    function win:_setActive(tab)
        if not tab then return end
        if win._active == tab then return end
        if win._active then
            pcall(function()
                Tween(win._active.Button, { TextColor3 = Theme.SubText, BackgroundTransparency = 1 })
                win._active.Indicator.Visible = false
                win._active.Page.Visible = false
            end)
        end
        win._active = tab
        pcall(function()
            Tween(tab.Button, { TextColor3 = Theme.Text, BackgroundTransparency = 0.85 })
            tab.Indicator.Visible = true
            tab.Page.Visible = true
        end)
    end

    -- ── Tab ──────────────────────────────────────────────────
    function win:Tab(tabConfig)
        if type(tabConfig) ~= "table" then
            warn("[NexusUI] Tab() expects a table — using defaults")
            tabConfig = {}
        end

        local name = validate(tabConfig.Name, "string", "Tab",  "Tab.Name")
        local icon = validate(tabConfig.Icon, "string", "☰",   "Tab.Icon")

        -- Tab button
        local tabBtn = Create("TextButton", {
            Name                   = name,
            BackgroundTransparency = 1,
            BackgroundColor3        = Theme.Card,
            BorderSizePixel        = 0,
            Size                   = UDim2.new(1, 0, 0, 34),
            Text                   = icon .. "  " .. name,
            TextColor3             = Theme.SubText,
            TextSize               = 12,
            Font                   = Theme.FontRegular,
            AutoButtonColor        = false,
            TextXAlignment         = Enum.TextXAlignment.Left,
            Parent                 = tabBar,
        })
        Create("UIPadding", { PaddingLeft = UDim.new(0, 8), Parent = tabBtn })
        Create("UICorner",  { CornerRadius = UDim.new(0, 6), Parent = tabBtn })

        local indicator = Create("Frame", {
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel  = 0,
            Size             = UDim2.new(0, 3, 0.6, 0),
            Position         = UDim2.new(0, -8, 0.2, 0),
            Parent           = tabBtn,
        })
        Create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = indicator })
        indicator.Visible = false

        -- Scrollable page
        local page = Create("ScrollingFrame", {
            Name                 = name .. "_Page",
            BackgroundTransparency = 1,
            BorderSizePixel      = 0,
            Size                 = UDim2.new(1, 0, 1, 0),
            CanvasSize           = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize  = Enum.AutomaticSize.Y,
            ScrollBarThickness   = 3,
            ScrollBarImageColor3 = Theme.Accent,
            Visible              = false,
            Parent               = pages,
        })
        Create("UIListLayout", {
            FillDirection       = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            Padding             = UDim.new(0, 6),
            Parent              = page,
        })
        Create("UIPadding", {
            PaddingTop    = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft   = UDim.new(0, 10),
            PaddingRight  = UDim.new(0, 14),
            Parent        = page,
        })

        local tab = {
            Button    = tabBtn,
            Page      = page,
            Indicator = indicator,
            Name      = name,
        }
        table.insert(win.Tabs, tab)

        if #win.Tabs == 1 then
            win:_setActive(tab)
        end

        tabBtn.MouseButton1Click:Connect(function()
            pcall(function() win:_setActive(tab) end)
        end)
        tabBtn.MouseEnter:Connect(function()
            if win._active ~= tab then
                Tween(tabBtn, { TextColor3 = Theme.Text, BackgroundTransparency = 0.8 })
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if win._active ~= tab then
                Tween(tabBtn, { TextColor3 = Theme.SubText, BackgroundTransparency = 1 })
            end
        end)

        -- ────────────────────────────────────────────────────
        -- SECTION
        -- ────────────────────────────────────────────────────
        function tab:Section(label)
            label = validate(label, "string", "Section", "Section.label")
            local sect = Create("Frame", {
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, 0, 0, 24),
                Parent                 = page,
            })
            Create("TextLabel", {
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, 0, 1, 0),
                Text                   = label:upper(),
                TextColor3             = Theme.Accent,
                TextSize               = 10,
                Font                   = Theme.Font,
                TextXAlignment         = Enum.TextXAlignment.Left,
                Parent                 = sect,
            })
            Create("Frame", {
                BackgroundColor3 = Theme.Border,
                BorderSizePixel  = 0,
                Size             = UDim2.new(1, 0, 0, 1),
                Position         = UDim2.new(0, 0, 1, -1),
                Parent           = sect,
            })
            return sect
        end

        -- ────────────────────────────────────────────────────
        -- LABEL
        -- ────────────────────────────────────────────────────
        function tab:Label(text)
            text = validate(text, "string", "", "Label.text")
            return Create("TextLabel", {
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, 0, 0, 22),
                Text                   = text,
                TextColor3             = Theme.SubText,
                TextSize               = 13,
                Font                   = Theme.FontRegular,
                TextXAlignment         = Enum.TextXAlignment.Left,
                Parent                 = page,
            })
        end

        -- ────────────────────────────────────────────────────
        -- BUTTON  (fully pcall-wrapped)
        -- ────────────────────────────────────────────────────
        function tab:Button(btnConfig)
            if type(btnConfig) ~= "table" then
                warn("[NexusUI] Button() expects a table")
                btnConfig = {}
            end

            local label    = validate(btnConfig.Name,     "string",   "Button",       "Button.Name")
            local callback = btnConfig.Callback
            if callback ~= nil and type(callback) ~= "function" then
                warn("[NexusUI] Button.Callback must be a function — ignoring")
                callback = nil
            end

            local container = Create("Frame", {
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, 0, 0, 38),
                Parent                 = page,
            })
            local btn = Create("TextButton", {
                BackgroundColor3 = Theme.Card,
                BorderSizePixel  = 0,
                Size             = UDim2.new(1, 0, 1, 0),
                Text             = label,
                TextColor3       = Theme.Text,
                TextSize         = 13,
                Font             = Theme.Font,
                AutoButtonColor  = false,
                Parent           = container,
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = btn })
            Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = btn })

            btn.MouseEnter:Connect(function()
                Tween(btn, { BackgroundColor3 = Theme.Accent })
            end)
            btn.MouseLeave:Connect(function()
                Tween(btn, { BackgroundColor3 = Theme.Card })
            end)

            btn.MouseButton1Click:Connect(function()
                -- Visual feedback
                pcall(function()
                    Tween(btn, { BackgroundColor3 = Theme.AccentHover }, 0.06)
                    task and task.delay and task.delay(0.12, function()
                        pcall(function() Tween(btn, { BackgroundColor3 = Theme.Card }) end)
                    end) or delay(0.12, function()
                        pcall(function() Tween(btn, { BackgroundColor3 = Theme.Card }) end)
                    end)
                end)
                -- Fire callback safely
                if callback then
                    safeSpawn(callback)
                end
            end)

            return btn
        end

        -- ────────────────────────────────────────────────────
        -- TOGGLE  (pcall-wrapped, with Set/Get API)
        -- ────────────────────────────────────────────────────
        function tab:Toggle(togConfig)
            if type(togConfig) ~= "table" then
                warn("[NexusUI] Toggle() expects a table")
                togConfig = {}
            end

            local label    = validate(togConfig.Name,    "string",  "Toggle",  "Toggle.Name")
            local default  = togConfig.Default
            if default == nil then default = false end
            if type(default) ~= "boolean" then
                warn("[NexusUI] Toggle.Default must be boolean — defaulting to false")
                default = false
            end
            local callback = togConfig.Callback
            if callback ~= nil and type(callback) ~= "function" then
                warn("[NexusUI] Toggle.Callback must be a function — ignoring")
                callback = nil
            end

            local state = default

            local container = Create("Frame", {
                BackgroundColor3 = Theme.Card,
                BorderSizePixel  = 0,
                Size             = UDim2.new(1, 0, 0, 42),
                Parent           = page,
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = container })
            Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = container })

            Create("TextLabel", {
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, -60, 1, 0),
                Position               = UDim2.new(0, 12, 0, 0),
                Text                   = label,
                TextColor3             = Theme.Text,
                TextSize               = 13,
                Font                   = Theme.FontRegular,
                TextXAlignment         = Enum.TextXAlignment.Left,
                Parent                 = container,
            })

            local track = Create("Frame", {
                BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff,
                BorderSizePixel  = 0,
                Size             = UDim2.new(0, 40, 0, 20),
                Position         = UDim2.new(1, -52, 0.5, -10),
                Parent           = container,
            })
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })

            local knob = Create("Frame", {
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel  = 0,
                Size             = UDim2.new(0, 14, 0, 14),
                Position         = state and UDim2.new(0, 23, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
                Parent           = track,
            })
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

            local function applyState(s, fire)
                pcall(function()
                    Tween(track, { BackgroundColor3 = s and Theme.ToggleOn or Theme.ToggleOff })
                    Tween(knob,  { Position = s and UDim2.new(0, 23, 0.5, -7) or UDim2.new(0, 3, 0.5, -7) })
                end)
                if fire and callback then
                    safeSpawn(callback, s)
                end
            end

            -- Clickable overlay
            local togBtn = Create("TextButton", {
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                Size                   = UDim2.new(1, 0, 1, 0),
                Text                   = "",
                Parent                 = container,
            })
            togBtn.MouseButton1Click:Connect(function()
                state = not state
                applyState(state, true)
            end)

            local togObj = {}
            function togObj:Set(val)
                if type(val) ~= "boolean" then
                    warn("[NexusUI] Toggle:Set() expects a boolean")
                    return
                end
                state = val
                applyState(state, true)
            end
            function togObj:Get() return state end
            return togObj
        end

        -- ────────────────────────────────────────────────────
        -- SLIDER  (pcall-wrapped, clamped, with Set/Get API)
        -- ────────────────────────────────────────────────────
        function tab:Slider(sliderConfig)
            if type(sliderConfig) ~= "table" then
                warn("[NexusUI] Slider() expects a table")
                sliderConfig = {}
            end

            local label    = validate(sliderConfig.Name,     "string",   "Slider",  "Slider.Name")
            local min      = validate(sliderConfig.Min,      "number",   0,         "Slider.Min")
            local max      = validate(sliderConfig.Max,      "number",   100,       "Slider.Max")
            local suffix   = validate(sliderConfig.Suffix,   "string",   "",        "Slider.Suffix")
            local callback = sliderConfig.Callback

            if callback ~= nil and type(callback) ~= "function" then
                warn("[NexusUI] Slider.Callback must be a function — ignoring")
                callback = nil
            end
            if min >= max then
                warn("[NexusUI] Slider.Min must be less than Slider.Max — adjusting")
                max = min + 1
            end

            local default = sliderConfig.Default
            if type(default) ~= "number" then default = min end
            local value = math.clamp(default, min, max)

            -- UI
            local container = Create("Frame", {
                BackgroundColor3 = Theme.Card,
                BorderSizePixel  = 0,
                Size             = UDim2.new(1, 0, 0, 54),
                Parent           = page,
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = container })
            Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = container })

            Create("TextLabel", {
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, -80, 0, 22),
                Position               = UDim2.new(0, 12, 0, 6),
                Text                   = label,
                TextColor3             = Theme.Text,
                TextSize               = 13,
                Font                   = Theme.FontRegular,
                TextXAlignment         = Enum.TextXAlignment.Left,
                Parent                 = container,
            })
            local valTxt = Create("TextLabel", {
                BackgroundTransparency = 1,
                Size                   = UDim2.new(0, 70, 0, 22),
                Position               = UDim2.new(1, -82, 0, 6),
                Text                   = tostring(value) .. suffix,
                TextColor3             = Theme.Accent,
                TextSize               = 13,
                Font                   = Theme.Font,
                TextXAlignment         = Enum.TextXAlignment.Right,
                Parent                 = container,
            })

            local trackBg = Create("Frame", {
                BackgroundColor3 = Theme.Border,
                BorderSizePixel  = 0,
                Size             = UDim2.new(1, -24, 0, 4),
                Position         = UDim2.new(0, 12, 0, 38),
                Parent           = container,
            })
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = trackBg })

            local function rel() return (value - min) / (max - min) end

            local fill = Create("Frame", {
                BackgroundColor3 = Theme.SliderFill,
                BorderSizePixel  = 0,
                Size             = UDim2.new(rel(), 0, 1, 0),
                Parent           = trackBg,
            })
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })

            local knob = Create("Frame", {
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel  = 0,
                Size             = UDim2.new(0, 14, 0, 14),
                Position         = UDim2.new(rel(), -7, 0.5, -7),
                Parent           = trackBg,
            })
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

            local dragging = false

            local function updateFromPos(inputX)
                local ok, err = pcall(function()
                    local absSize = trackBg.AbsoluteSize.X
                    local absPos  = trackBg.AbsolutePosition.X
                    if absSize <= 0 then return end
                    local r = math.clamp((inputX - absPos) / absSize, 0, 1)
                    value = math.floor(min + r * (max - min) + 0.5)
                    pcall(function() valTxt.Text = tostring(value) .. suffix end)
                    Tween(fill,  { Size     = UDim2.new(r, 0, 1, 0) }, 0.05)
                    Tween(knob,  { Position = UDim2.new(r, -7, 0.5, -7) }, 0.05)
                end)
                if not ok then
                    warn("[NexusUI] Slider update error: " .. tostring(err))
                end
                if callback then safeSpawn(callback, value) end
            end

            -- Hit zone
            local dragZone = Create("TextButton", {
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, 0, 0, 30),
                Position               = UDim2.new(0, 0, 0, 24),
                Text                   = "",
                Parent                 = container,
            })
            dragZone.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    updateFromPos(input.Position.X)
                end
            end)
            if UserInputService then
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        updateFromPos(input.Position.X)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)
            end

            local sliderObj = {}
            function sliderObj:Set(v)
                if type(v) ~= "number" then
                    warn("[NexusUI] Slider:Set() expects a number")
                    return
                end
                value = math.clamp(v, min, max)
                local r = (value - min) / (max - min)
                pcall(function() valTxt.Text = tostring(value) .. suffix end)
                Tween(fill, { Size     = UDim2.new(r, 0, 1, 0) })
                Tween(knob, { Position = UDim2.new(r, -7, 0.5, -7) })
                if callback then safeSpawn(callback, value) end
            end
            function sliderObj:Get() return value end
            return sliderObj
        end

        -- ────────────────────────────────────────────────────
        -- DROPDOWN  (pcall-wrapped, with Set/Get API)
        -- ────────────────────────────────────────────────────
        function tab:Dropdown(dropConfig)
            if type(dropConfig) ~= "table" then
                warn("[NexusUI] Dropdown() expects a table")
                dropConfig = {}
            end

            local label    = validate(dropConfig.Name,    "string",  "Dropdown",  "Dropdown.Name")
            local options  = dropConfig.Options
            if type(options) ~= "table" or #options == 0 then
                warn("[NexusUI] Dropdown.Options must be a non-empty table — using placeholder")
                options = {"Option 1"}
            end
            local default  = dropConfig.Default or options[1]
            local callback = dropConfig.Callback
            if callback ~= nil and type(callback) ~= "function" then
                warn("[NexusUI] Dropdown.Callback must be a function — ignoring")
                callback = nil
            end

            local selected = default
            local open     = false

            local container = Create("Frame", {
                BackgroundColor3 = Theme.Card,
                BorderSizePixel  = 0,
                Size             = UDim2.new(1, 0, 0, 42),
                ClipsDescendants = false,
                Parent           = page,
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = container })
            Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = container })

            Create("TextLabel", {
                BackgroundTransparency = 1,
                Size                   = UDim2.new(0.5, 0, 1, 0),
                Position               = UDim2.new(0, 12, 0, 0),
                Text                   = label,
                TextColor3             = Theme.Text,
                TextSize               = 13,
                Font                   = Theme.FontRegular,
                TextXAlignment         = Enum.TextXAlignment.Left,
                Parent                 = container,
            })
            local selTxt = Create("TextLabel", {
                BackgroundTransparency = 1,
                Size                   = UDim2.new(0.5, -36, 1, 0),
                Position               = UDim2.new(0.5, 0, 0, 0),
                Text                   = tostring(selected),
                TextColor3             = Theme.Accent,
                TextSize               = 13,
                Font                   = Theme.Font,
                TextXAlignment         = Enum.TextXAlignment.Right,
                Parent                 = container,
            })
            Create("TextLabel", {
                BackgroundTransparency = 1,
                Size                   = UDim2.new(0, 20, 0, 20),
                Position               = UDim2.new(1, -26, 0.5, -10),
                Text                   = "▾",
                TextColor3             = Theme.SubText,
                TextSize               = 14,
                Font                   = Theme.Font,
                Parent                 = container,
            })

            -- Dropdown list
            local listFrame = Create("Frame", {
                BackgroundColor3 = Theme.Surface,
                BorderSizePixel  = 0,
                Size             = UDim2.new(1, 0, 0, #options * 34 + 8),
                Position         = UDim2.new(0, 0, 1, 4),
                Visible          = false,
                ZIndex           = 10,
                Parent           = container,
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = listFrame })
            Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = listFrame })
            Create("UIListLayout", { Padding = UDim.new(0, 2), Parent = listFrame })
            Create("UIPadding", {
                PaddingTop    = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
                PaddingLeft   = UDim.new(0, 4), PaddingRight  = UDim.new(0, 4),
                Parent        = listFrame,
            })

            for _, opt in ipairs(options) do
                local optLabel = tostring(opt)
                local optBtn = Create("TextButton", {
                    BackgroundColor3       = Theme.Card,
                    BackgroundTransparency = 1,
                    BorderSizePixel        = 0,
                    Size                   = UDim2.new(1, 0, 0, 30),
                    Text                   = optLabel,
                    TextColor3             = (opt == selected) and Theme.Accent or Theme.Text,
                    TextSize               = 13,
                    Font                   = Theme.FontRegular,
                    ZIndex                 = 11,
                    Parent                 = listFrame,
                })
                Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = optBtn })
                optBtn.MouseEnter:Connect(function()
                    Tween(optBtn, { BackgroundTransparency = 0.7 })
                end)
                optBtn.MouseLeave:Connect(function()
                    Tween(optBtn, { BackgroundTransparency = 1 })
                end)
                optBtn.MouseButton1Click:Connect(function()
                    selected = opt
                    pcall(function() selTxt.Text = tostring(selected) end)
                    open = false
                    pcall(function() listFrame.Visible = false end)
                    if callback then safeSpawn(callback, selected) end
                end)
            end

            local openBtn = Create("TextButton", {
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, 0, 1, 0),
                Text                   = "",
                Parent                 = container,
            })
            openBtn.MouseButton1Click:Connect(function()
                open = not open
                pcall(function() listFrame.Visible = open end)
            end)

            local dropObj = {}
            function dropObj:Set(v)
                selected = v
                pcall(function() selTxt.Text = tostring(v) end)
            end
            function dropObj:Get() return selected end
            return dropObj
        end

        -- ────────────────────────────────────────────────────
        -- INPUT  (pcall-wrapped, with Set/Get API)
        -- ────────────────────────────────────────────────────
        function tab:Input(inputConfig)
            if type(inputConfig) ~= "table" then
                warn("[NexusUI] Input() expects a table")
                inputConfig = {}
            end

            local label    = validate(inputConfig.Name,        "string",  "Input",        "Input.Name")
            local default  = validate(inputConfig.Default,     "string",  "",             "Input.Default")
            local ph       = validate(inputConfig.Placeholder, "string",  "Type here...", "Input.Placeholder")
            local callback = inputConfig.Callback
            if callback ~= nil and type(callback) ~= "function" then
                warn("[NexusUI] Input.Callback must be a function — ignoring")
                callback = nil
            end

            local container = Create("Frame", {
                BackgroundColor3 = Theme.Card,
                BorderSizePixel  = 0,
                Size             = UDim2.new(1, 0, 0, 54),
                Parent           = page,
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = container })
            Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = container })

            Create("TextLabel", {
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, -12, 0, 20),
                Position               = UDim2.new(0, 12, 0, 6),
                Text                   = label,
                TextColor3             = Theme.Text,
                TextSize               = 12,
                Font                   = Theme.FontRegular,
                TextXAlignment         = Enum.TextXAlignment.Left,
                Parent                 = container,
            })

            local inputBg = Create("Frame", {
                BackgroundColor3 = Theme.Background,
                BorderSizePixel  = 0,
                Size             = UDim2.new(1, -24, 0, 22),
                Position         = UDim2.new(0, 12, 0, 26),
                Parent           = container,
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = inputBg })

            local box = Create("TextBox", {
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, -8, 1, 0),
                Position               = UDim2.new(0, 6, 0, 0),
                Text                   = default,
                PlaceholderText        = ph,
                TextColor3             = Theme.Text,
                PlaceholderColor3      = Theme.SubText,
                TextSize               = 12,
                Font                   = Theme.FontRegular,
                TextXAlignment         = Enum.TextXAlignment.Left,
                ClearTextOnFocus       = false,
                Parent                 = inputBg,
            })
            if box then
                box.FocusLost:Connect(function(enterPressed)
                    if callback then
                        safeSpawn(callback, box.Text, enterPressed)
                    end
                end)
            end

            local inputObj = {}
            function inputObj:Set(v)
                pcall(function() box.Text = tostring(v) end)
            end
            function inputObj:Get()
                return box and box.Text or ""
            end
            return inputObj
        end

        return tab
    end  -- win:Tab

    return win
end  -- NexusUI:Window

-- ─── Module return ───────────────────────────────────────────
return NexusUI
