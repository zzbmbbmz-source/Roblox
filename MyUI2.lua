--[[
    MyUI - A lightweight Roblox UI library (WindUI-inspired style)
    Features: Window, Tabs, Sections, Button, Toggle, Slider, Dropdown, Input, Notify
    Usage:
        local MyUI = loadstring(game:HttpGet("URL_TO_THIS_FILE"))()
        local Window = MyUI:CreateWindow({ Title = "My Hub", SubTitle = "v1.0" })
        local Tab = Window:CreateTab("Main")
        Tab:CreateButton({ Title = "Click me", Callback = function() print("clicked") end })
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local MyUI = {}
MyUI.__index = MyUI

-- ===== Theme (Sci-Fi Cyan/Purple) =====
local Theme = {
    Background = Color3.fromRGB(10, 12, 20),
    Secondary  = Color3.fromRGB(16, 19, 30),
    Stroke     = Color3.fromRGB(45, 55, 75),
    Accent     = Color3.fromRGB(0, 220, 255),   -- cyan
    Accent2    = Color3.fromRGB(170, 80, 255),  -- purple
    Text       = Color3.fromRGB(230, 240, 255),
    SubText    = Color3.fromRGB(140, 150, 175),
    Font       = Enum.Font.GothamMedium,
}

-- ===== Helpers =====
local function tween(obj, props, time, style, dir)
    local t = TweenService:Create(obj, TweenInfo.new(
        time or 0.2,
        style or Enum.EasingStyle.Quad,
        dir or Enum.EasingDirection.Out
    ), props)
    t:Play()
    return t
end

local function new(class, props, children)
    local inst = Instance.new(class)
    for prop, value in pairs(props or {}) do
        inst[prop] = value
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

local function corner(radius)
    return new("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
end

local function stroke(color, thickness)
    return new("UIStroke", {
        Color = color or Theme.Stroke,
        Thickness = thickness or 1,
    })
end

-- Animated cyan -> purple glowing gradient border, used for the sci-fi window frame
local function glowStroke(thickness)
    local strokeInst = new("UIStroke", {
        Thickness = thickness or 2,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })

    local gradient = new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,    Theme.Accent),
            ColorSequenceKeypoint.new(0.5,  Theme.Accent2),
            ColorSequenceKeypoint.new(1,    Theme.Accent),
        }),
    })
    gradient.Parent = strokeInst

    -- Slowly rotate the gradient for a "glowing" sci-fi look
    task.spawn(function()
        while strokeInst.Parent do
            gradient.Rotation = (gradient.Rotation + 1.5) % 360
            task.wait(0.03)
        end
    end)

    return strokeInst
end

-- Drag handling that also distinguishes a plain click (used by the floating toggle button,
-- which must be freely draggable AND clickable to open/close the window)
local function makeDraggableButton(button, onClick)
    local dragging = false
    local moved = false
    local dragStart, startPos

    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = false
            dragStart = input.Position
            startPos = button.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            if delta.Magnitude > 4 then
                moved = true
            end
            button.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            if not moved and onClick then
                onClick()
            end
        end
    end)
end

local function makeDraggable(topBar, frame)
    local dragging, dragStart, startPos

    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ===== Root ScreenGui =====
local function getScreenGui()
    local existing = PlayerGui:FindFirstChild("MyUI")
    if existing then existing:Destroy() end
    return new("ScreenGui", {
        Name = "MyUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = PlayerGui,
    })
end

-- ===== Window =====
function MyUI:CreateWindow(config)
    config = config or {}
    local title = config.Title or "MyUI"
    local subTitle = config.SubTitle or ""
    local size = config.Size or UDim2.fromOffset(560, 380)

    local ScreenGui = getScreenGui()

    local Main = new("Frame", {
        Name = "Main",
        Size = size,
        Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2),
        BackgroundColor3 = Theme.Background,
        Parent = ScreenGui,
    }, { corner(10), glowStroke(2) })

    -- Drives the scale + easing open/close animation
    local WindowScale = new("UIScale", { Scale = 1, Parent = Main })

    local TopBar = new("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = Theme.Secondary,
        Parent = Main,
    }, { corner(10) })

    new("TextLabel", {
        Text = title,
        Font = Theme.Font,
        TextSize = 16,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 4),
        Size = UDim2.new(1, -32, 0, 20),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TopBar,
    })

    new("TextLabel", {
        Text = subTitle,
        Font = Theme.Font,
        TextSize = 12,
        TextColor3 = Theme.SubText,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 22),
        Size = UDim2.new(1, -32, 0, 16),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TopBar,
    })

    local CloseBtn = new("TextButton", {
        Text = "×",
        Font = Theme.Font,
        TextSize = 20,
        TextColor3 = Theme.SubText,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(32, 32),
        Position = UDim2.new(1, -40, 0, 6),
        Parent = TopBar,
    })

    makeDraggable(TopBar, Main)

    -- ===== Floating ☰ / ✕ toggle button (freely draggable, opens/closes the window) =====
    local ToggleButton = new("TextButton", {
        Name = "ToggleButton",
        Size = UDim2.fromOffset(44, 44),
        Position = UDim2.fromOffset(20, 20),
        BackgroundColor3 = Theme.Secondary,
        Text = "✕",
        Font = Theme.Font,
        TextSize = 18,
        TextColor3 = Theme.Accent,
        AutoButtonColor = false,
        Parent = ScreenGui,
    }, { corner(22), glowStroke(2) })

    local isOpen = true

    local function setOpen(open)
        isOpen = open
        if open then
            Main.Visible = true
            ToggleButton.Text = "✕"
            tween(WindowScale, { Scale = 1 }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        else
            ToggleButton.Text = "☰"
            tween(WindowScale, { Scale = 0 }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In)
            task.delay(0.25, function()
                if not isOpen then
                    Main.Visible = false
                end
            end)
        end
    end

    CloseBtn.MouseButton1Click:Connect(function()
        setOpen(false)
    end)

    makeDraggableButton(ToggleButton, function()
        setOpen(not isOpen)
    end)

    local TabList = new("Frame", {
        Name = "TabList",
        Size = UDim2.new(0, 130, 1, -54),
        Position = UDim2.new(0, 0, 0, 50),
        BackgroundColor3 = Theme.Secondary,
        Parent = Main,
    }, { corner(8) })

    local TabListLayout = new("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    TabListLayout.Parent = TabList

    new("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        Parent = TabList,
    })

    local PageHolder = new("Frame", {
        Name = "PageHolder",
        Size = UDim2.new(1, -146, 1, -54),
        Position = UDim2.new(0, 138, 0, 50),
        BackgroundTransparency = 1,
        Parent = Main,
    })

    local Window = setmetatable({
        Main = Main,
        TabList = TabList,
        PageHolder = PageHolder,
        Tabs = {},
        _firstTab = true,
    }, { __index = MyUI })

    return Window
end

-- ===== Tab =====
function MyUI:CreateTab(name)
    local TabButton = new("TextButton", {
        Text = name,
        Font = Theme.Font,
        TextSize = 14,
        TextColor3 = Theme.SubText,
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.3,
        Size = UDim2.new(1, 0, 0, 32),
        Parent = self.TabList,
    }, { corner(6) })

    local Page = new("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = self._firstTab,
        Parent = self.PageHolder,
    })

    new("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Page,
    })

    if self._firstTab then
        TabButton.BackgroundColor3 = Theme.Accent
        TabButton.TextColor3 = Color3.fromRGB(15, 15, 15)
        self._firstTab = false
        self._activeTabButton = TabButton
    end

    TabButton.MouseButton1Click:Connect(function()
        for _, t in pairs(self.Tabs) do
            t.Page.Visible = false
            tween(t.Button, { BackgroundColor3 = Theme.Background, TextColor3 = Theme.SubText }, 0.15)
        end
        Page.Visible = true
        tween(TabButton, { BackgroundColor3 = Theme.Accent, TextColor3 = Color3.fromRGB(15, 15, 15) }, 0.15)
    end)

    local Tab = setmetatable({
        Button = TabButton,
        Page = Page,
    }, { __index = MyUI })

    table.insert(self.Tabs, Tab)
    return Tab
end

-- ===== Components (added to a Tab's Page) =====

function MyUI:CreateButton(config)
    config = config or {}
    local Button = new("TextButton", {
        Text = config.Title or "Button",
        Font = Theme.Font,
        TextSize = 14,
        TextColor3 = Theme.Text,
        BackgroundColor3 = Theme.Secondary,
        Size = UDim2.new(1, 0, 0, 38),
        Parent = self.Page,
    }, { corner(6), stroke() })

    Button.MouseButton1Click:Connect(function()
        tween(Button, { BackgroundColor3 = Theme.Accent }, 0.1)
        task.wait(0.1)
        tween(Button, { BackgroundColor3 = Theme.Secondary }, 0.15)
        if config.Callback then
            local ok, err = pcall(config.Callback)
            if not ok then warn("[MyUI] Button callback error: " .. tostring(err)) end
        end
    end)

    return Button
end

function MyUI:CreateToggle(config)
    config = config or {}
    local state = config.Default or false

    local Holder = new("Frame", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = Theme.Secondary,
        Parent = self.Page,
    }, { corner(6), stroke() })

    new("TextLabel", {
        Text = config.Title or "Toggle",
        Font = Theme.Font,
        TextSize = 14,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -60, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Holder,
    })

    local Switch = new("Frame", {
        Size = UDim2.fromOffset(40, 20),
        Position = UDim2.new(1, -50, 0.5, -10),
        BackgroundColor3 = state and Theme.Accent or Theme.Background,
        Parent = Holder,
    }, { corner(10) })

    local Knob = new("Frame", {
        Size = UDim2.fromOffset(16, 16),
        Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Parent = Switch,
    }, { corner(8) })

    local ClickArea = new("TextButton", {
        Text = "",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = Holder,
    })

    ClickArea.MouseButton1Click:Connect(function()
        state = not state
        tween(Switch, { BackgroundColor3 = state and Theme.Accent or Theme.Background }, 0.15)
        tween(Knob, { Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8) }, 0.15)
        if config.Callback then
            pcall(config.Callback, state)
        end
    end)

    return Holder
end

function MyUI:CreateSlider(config)
    config = config or {}
    local min = config.Min or 0
    local max = config.Max or 100
    local value = config.Default or min

    local Holder = new("Frame", {
        Size = UDim2.new(1, 0, 0, 54),
        BackgroundColor3 = Theme.Secondary,
        Parent = self.Page,
    }, { corner(8), stroke(Theme.Stroke, 1) })

    new("TextLabel", {
        Text = config.Title or "Slider",
        Font = Theme.Font,
        TextSize = 14,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 8),
        Size = UDim2.new(1, -90, 0, 18),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Holder,
    })

    local ValueLabel = new("TextLabel", {
        Text = tostring(value),
        Font = Theme.Font,
        TextSize = 13,
        TextColor3 = Theme.Accent,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -60, 0, 8),
        Size = UDim2.fromOffset(46, 18),
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = Holder,
    })

    -- Thin track line
    local Track = new("Frame", {
        Size = UDim2.new(1, -32, 0, 4),
        Position = UDim2.new(0, 16, 1, -16),
        BackgroundColor3 = Theme.Background,
        Parent = Holder,
    }, { corner(2) })

    local Fill = new("Frame", {
        Size = UDim2.new((value - min) / math.max(max - min, 1), 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        Parent = Track,
    }, { corner(2) })

    -- Round drag handle (dot) that rides at the end of the fill
    local Knob = new("Frame", {
        Size = UDim2.fromOffset(14, 14),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new((value - min) / math.max(max - min, 1), 0, 0.5, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        ZIndex = 2,
        Parent = Track,
    }, { corner(7), stroke(Theme.Accent, 2) })

    local dragging = false

    local function setFromX(xPos)
        local rel = math.clamp((xPos - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
        value = math.floor(min + (max - min) * rel + 0.5)
        Fill.Size = UDim2.new(rel, 0, 1, 0)
        Knob.Position = UDim2.new(rel, 0, 0.5, 0)
        ValueLabel.Text = tostring(value)
        if config.Callback then pcall(config.Callback, value) end
    end

    local function beginDrag(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            tween(Knob, { Size = UDim2.fromOffset(18, 18) }, 0.1)
            setFromX(input.Position.X)
        end
    end

    Track.InputBegan:Connect(beginDrag)
    Knob.InputBegan:Connect(beginDrag)

    UserInputService.InputEnded:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            tween(Knob, { Size = UDim2.fromOffset(14, 14) }, 0.1)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end)

    return Holder
end

function MyUI:CreateDropdown(config)
    config = config or {}
    local options = config.Options or {}
    local selected = config.Default or options[1]
    local open = false

    local Holder = new("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Theme.Secondary,
        ClipsDescendants = true,
        Parent = self.Page,
    }, { corner(8), stroke(Theme.Accent, 1) })

    -- The visible pill: "<selected value>  ▼"
    local Header = new("TextButton", {
        Text = "",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 40),
        Parent = Holder,
    })

    local SelectedLabel = new("TextLabel", {
        Text = tostring(selected or config.Title or "Select"),
        Font = Theme.Font,
        TextSize = 14,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 0),
        Size = UDim2.new(1, -44, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Header,
    })

    local Arrow = new("TextLabel", {
        Text = "▼",
        Font = Theme.Font,
        TextSize = 12,
        TextColor3 = Theme.Accent,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -30, 0, 0),
        Size = UDim2.fromOffset(20, 40),
        Parent = Header,
    })

    local OptionsFrame = new("Frame", {
        Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(1, 0, 0, #options * 30),
        BackgroundTransparency = 1,
        Parent = Holder,
    })

    local ListLayout = new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder })
    ListLayout.Parent = OptionsFrame

    for _, option in ipairs(options) do
        local OptButton = new("TextButton", {
            Text = "  " .. tostring(option),
            Font = Theme.Font,
            TextSize = 13,
            TextColor3 = Theme.SubText,
            BackgroundColor3 = Theme.Secondary,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 30),
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = OptionsFrame,
        })

        OptButton.MouseEnter:Connect(function()
            tween(OptButton, { BackgroundTransparency = 0, TextColor3 = Theme.Accent }, 0.1)
        end)
        OptButton.MouseLeave:Connect(function()
            tween(OptButton, { BackgroundTransparency = 1, TextColor3 = Theme.SubText }, 0.1)
        end)

        OptButton.MouseButton1Click:Connect(function()
            selected = option
            SelectedLabel.Text = tostring(option)
            if config.Callback then pcall(config.Callback, option) end
        end)
    end

    Header.MouseButton1Click:Connect(function()
        open = not open
        local targetHeight = open and (40 + #options * 30) or 40
        tween(Holder, { Size = UDim2.new(1, 0, 0, targetHeight) }, 0.2)
        tween(Arrow, { Rotation = open and 180 or 0 }, 0.2)
    end)

    return Holder
end

function MyUI:CreateInput(config)
    config = config or {}

    local Holder = new("Frame", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = Theme.Secondary,
        Parent = self.Page,
    }, { corner(6), stroke() })

    new("TextLabel", {
        Text = config.Title or "Input",
        Font = Theme.Font,
        TextSize = 14,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(0.4, 0, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Holder,
    })

    local Box = new("TextBox", {
        Text = config.Default or "",
        PlaceholderText = config.Placeholder or "...",
        Font = Theme.Font,
        TextSize = 13,
        TextColor3 = Theme.Text,
        BackgroundColor3 = Theme.Background,
        Position = UDim2.new(0.42, 0, 0.5, -12),
        Size = UDim2.new(0.55, 0, 0, 24),
        ClearTextOnFocus = false,
        Parent = Holder,
    }, { corner(6) })

    Box.FocusLost:Connect(function(enterPressed)
        if config.Callback then
            pcall(config.Callback, Box.Text, enterPressed)
        end
    end)

    return Holder
end

-- ===== Notifications =====
function MyUI:Notify(config)
    config = config or {}
    local ScreenGui = PlayerGui:FindFirstChild("MyUI")
    if not ScreenGui then return end

    local Notif = new("Frame", {
        Size = UDim2.fromOffset(260, 60),
        Position = UDim2.new(1, -280, 1, -80),
        BackgroundColor3 = Theme.Secondary,
        Parent = ScreenGui,
    }, { corner(8), stroke() })

    new("TextLabel", {
        Text = config.Title or "Notification",
        Font = Theme.Font,
        TextSize = 14,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 8),
        Size = UDim2.new(1, -24, 0, 18),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Notif,
    })

    new("TextLabel", {
        Text = config.Content or "",
        Font = Theme.Font,
        TextSize = 12,
        TextColor3 = Theme.SubText,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 28),
        Size = UDim2.new(1, -24, 0, 28),
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Notif,
    })

    task.delay(config.Duration or 3, function()
        tween(Notif, { Position = UDim2.new(1, 20, 1, -80) }, 0.3)
        task.wait(0.3)
        Notif:Destroy()
    end)

    return Notif
end

return MyUI
