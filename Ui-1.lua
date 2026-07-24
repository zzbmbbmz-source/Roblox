--[[
    MyUI - A lightweight Roblox UI library (Sci-Fi HUD style)
    Features: Window, Tabs (with icons), Sections, Button, Toggle, Slider, Dropdown, Input, Notify
    Usage:
        local MyUI = loadstring(game:HttpGet("URL_TO_THIS_FILE"))()
        local Window = MyUI:CreateWindow({ Title = "My Hub", SubTitle = "v1.0" })
        local Tab = Window:CreateTab("Main")
        Tab:CreateButton({ Title = "Click me", Callback = function() print("clicked") end })
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local MyUI = {}
MyUI.__index = MyUI

-- ===== Theme (Sci-Fi Cyan/Purple HUD) =====
local Theme = {
    Background = Color3.fromRGB(6, 9, 16),
    Secondary  = Color3.fromRGB(13, 17, 28),
    Stroke     = Color3.fromRGB(40, 50, 70),
    Accent     = Color3.fromRGB(0, 220, 255),   -- cyan
    Accent2    = Color3.fromRGB(170, 80, 255),  -- purple
    Text       = Color3.fromRGB(235, 244, 255),
    SubText    = Color3.fromRGB(130, 145, 170),
    Font       = Enum.Font.GothamMedium,
    FontBold   = Enum.Font.GothamBold,
    FontBlack  = Enum.Font.GothamBlack,
}

-- Status colors for CreateLabel / Notify "Type" (ใช้ทำข้อความสวยๆ แบบ สำเร็จ/เตือน/ผิดพลาด)
local StatusColors = {
    Info    = Theme.Accent,
    Success = Color3.fromRGB(70, 220, 130),
    Warning = Color3.fromRGB(255, 190, 60),
    Error   = Color3.fromRGB(255, 70, 90),
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

local function stroke(color, thickness, transparency)
    return new("UIStroke", {
        Color = color or Theme.Stroke,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
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

    task.spawn(function()
        while strokeInst.Parent do
            gradient.Rotation = (gradient.Rotation + 1.5) % 360
            task.wait(0.03)
        end
    end)

    return strokeInst
end

-- Thin L-shaped accent brackets in the four corners of a frame, for a HUD look
local function addCornerBrackets(parent, length, thickness)
    length = length or 18
    thickness = thickness or 2
    local corners = {
        { anchor = Vector2.new(0, 0), pos = UDim2.new(0, 8, 0, 8),   flipH = false, flipV = false },
        { anchor = Vector2.new(1, 0), pos = UDim2.new(1, -8, 0, 8),  flipH = true,  flipV = false },
        { anchor = Vector2.new(0, 1), pos = UDim2.new(0, 8, 1, -8),  flipH = false, flipV = true  },
        { anchor = Vector2.new(1, 1), pos = UDim2.new(1, -8, 1, -8), flipH = true,  flipV = true  },
    }
    for _, c in ipairs(corners) do
        local Holder = new("Frame", {
            Size = UDim2.fromOffset(length, length),
            AnchorPoint = c.anchor,
            Position = c.pos,
            BackgroundTransparency = 1,
            ZIndex = 5,
            Parent = parent,
        })
        new("Frame", {
            Size = UDim2.new(1, 0, 0, thickness),
            Position = c.flipV and UDim2.new(0, 0, 1, -thickness) or UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            ZIndex = 5,
            Parent = Holder,
        })
        new("Frame", {
            Size = UDim2.new(0, thickness, 1, 0),
            Position = c.flipH and UDim2.new(1, -thickness, 0, 0) or UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            ZIndex = 5,
            Parent = Holder,
        })
    end
end

-- Small row of angled accent ticks used to decorate the section header bar
local function addStripeDecor(parent, alignment)
    local Holder = new("Frame", {
        Size = UDim2.fromOffset(64, 16),
        AnchorPoint = Vector2.new(alignment == "left" and 0 or 1, 0.5),
        Position = alignment == "left" and UDim2.new(0, 16, 0.5, 0) or UDim2.new(1, -16, 0.5, 0),
        BackgroundTransparency = 1,
        Parent = parent,
    })
    for i = 1, 7 do
        new("Frame", {
            Size = UDim2.fromOffset(2, 12),
            Position = UDim2.fromOffset((i - 1) * 8, 2),
            Rotation = 20,
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 0.15 + (i * 0.1),
            BorderSizePixel = 0,
            Parent = Holder,
        })
    end
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
    local size = config.Size or UDim2.fromOffset(760, 460)
    -- Scale = ตัวคูณขนาด UI ทั้งหมด เช่น 0.5 = ครึ่งหนึ่งของขนาดเดิม, 1 = ขนาดปกติ
    local targetScale = config.Scale or 1

    local ScreenGui = getScreenGui()

    local Main = new("Frame", {
        Name = "Main",
        Size = size,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundColor3 = Theme.Background,
        Parent = ScreenGui,
    }, { corner(12), glowStroke(2) })

    addCornerBrackets(Main, 20, 2)

    -- Drives the scale + easing open/close animation.
    -- เริ่มต้นที่ targetScale เลย ทำให้ทุกอย่างในหน้าต่างย่อ/ขยายตามอัตราส่วนเดียวกันทันที
    -- ตอนปิดจะ tween ลงไปที่ 0 ตอนเปิดจะ tween กลับไปที่ targetScale (ไม่ใช่ 1 ตรงๆ)
    local WindowScale = new("UIScale", { Scale = targetScale, Parent = Main })

    -- ===== Top bar =====
    local TopBar = new("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 74),
        BackgroundColor3 = Theme.Secondary,
        Parent = Main,
    }, { corner(12) })

    new("Frame", { -- masks the bottom corners so TopBar only rounds at the top
        Size = UDim2.new(1, 0, 0, 12),
        Position = UDim2.new(0, 0, 1, -12),
        BackgroundColor3 = Theme.Secondary,
        BorderSizePixel = 0,
        Parent = TopBar,
    })

    new("TextLabel", {
        Text = string.upper(title),
        Font = Theme.FontBlack,
        TextSize = 26,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(24, 14),
        Size = UDim2.new(1, -120, 0, 30),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TopBar,
    })

    new("TextLabel", {
        Text = subTitle,
        Font = Theme.Font,
        TextSize = 13,
        TextColor3 = Theme.SubText,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(25, 42),
        Size = UDim2.new(1, -120, 0, 18),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TopBar,
    })

    -- Diamond-shaped close button (rotated square) in the top-right corner
    local CloseBtn = new("TextButton", {
        Text = "",
        Rotation = 45,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -26, 0, 30),
        Size = UDim2.fromOffset(30, 30),
        BackgroundColor3 = Theme.Background,
        AutoButtonColor = false,
        Parent = TopBar,
    }, { corner(6), stroke(Theme.Accent, 1) })

    new("Frame", {
        Size = UDim2.new(0.6, 0, 0, 2),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Rotation = -45,
        BackgroundColor3 = Theme.Accent,
        Parent = CloseBtn,
    })

    makeDraggable(TopBar, Main)

    -- ===== Floating hamburger / close toggle button (freely draggable, opens/closes the window) =====
    -- Built from plain Frames instead of text glyphs, since the Gotham font
    -- doesn't include some symbols and renders them as empty "tofu" boxes.
    local ToggleButton = new("TextButton", {
        Name = "ToggleButton",
        Size = UDim2.fromOffset(44, 44),
        Position = UDim2.fromOffset(20, 20),
        BackgroundColor3 = Theme.Secondary,
        Text = "",
        AutoButtonColor = false,
        Parent = ScreenGui,
    }, { corner(22), glowStroke(2) })

    local HamburgerHolder = new("Frame", {
        Size = UDim2.fromOffset(20, 14),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = ToggleButton,
    })
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        Parent = HamburgerHolder,
    })
    for i = 1, 3 do
        new("Frame", {
            Size = UDim2.new(1, 0, 0, 2),
            BackgroundColor3 = Theme.Accent,
            LayoutOrder = i,
            Parent = HamburgerHolder,
        }, { corner(1) })
    end

    local CloseHolder = new("Frame", {
        Size = UDim2.fromOffset(18, 18),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 1,
        Visible = true,
        Parent = ToggleButton,
    })
    new("Frame", {
        Size = UDim2.new(1, 0, 0, 2),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Rotation = 45,
        BackgroundColor3 = Theme.Accent,
        Parent = CloseHolder,
    }, { corner(1) })
    new("Frame", {
        Size = UDim2.new(1, 0, 0, 2),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Rotation = -45,
        BackgroundColor3 = Theme.Accent,
        Parent = CloseHolder,
    }, { corner(1) })

    local isOpen = true

    local function setOpen(open)
        isOpen = open
        if open then
            Main.Visible = true
            CloseHolder.Visible = true
            HamburgerHolder.Visible = false
            tween(WindowScale, { Scale = targetScale }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        else
            CloseHolder.Visible = false
            HamburgerHolder.Visible = true
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

    -- ===== Sidebar (tab list) =====
    local TabList = new("Frame", {
        Name = "TabList",
        Size = UDim2.new(0, 190, 1, -90),
        Position = UDim2.new(0, 12, 0, 82),
        BackgroundColor3 = Theme.Secondary,
        Parent = Main,
    }, { corner(10) })

    new("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = TabList,
    })

    new("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = TabList,
    })

    -- ===== Content area =====
    local PageHolder = new("Frame", {
        Name = "PageHolder",
        Size = UDim2.new(1, -226, 1, -90),
        Position = UDim2.new(0, 214, 0, 82),
        BackgroundTransparency = 1,
        Parent = Main,
    })

    local Header = new("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 46),
        BackgroundColor3 = Theme.Secondary,
        Parent = PageHolder,
    }, { corner(8) })

    local HeaderLabel = new("TextLabel", {
        Text = "",
        Font = Theme.FontBlack,
        TextSize = 22,
        TextColor3 = Theme.Accent,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = Header,
    })

    addStripeDecor(Header, "left")
    addStripeDecor(Header, "right")

    local PagesContainer = new("Frame", {
        Name = "PagesContainer",
        Size = UDim2.new(1, 0, 1, -54),
        Position = UDim2.new(0, 0, 0, 54),
        BackgroundTransparency = 1,
        Parent = PageHolder,
    })

    local Window = setmetatable({
        Main = Main,
        TabList = TabList,
        PagesContainer = PagesContainer,
        HeaderLabel = HeaderLabel,
        Tabs = {},
        _firstTab = true,
        _windowScale = WindowScale,
        _targetScale = targetScale,
        _isOpen = true,
    }, { __index = MyUI })

    return Window
end

-- ปรับขนาด UI ทั้งหน้าต่างได้ตอน runtime เช่น Window:SetScale(0.5) เพื่อย่อครึ่งหนึ่ง
-- animate = true (ค่าเริ่มต้น) จะ tween ให้ลื่นไหล, false จะเปลี่ยนทันที
function MyUI:SetScale(scale, animate)
    self._targetScale = scale
    if animate == false then
        self._windowScale.Scale = scale
    else
        tween(self._windowScale, { Scale = scale }, 0.25)
    end
end

-- ===== Tab =====
-- name: ชื่อแท็บ | icon (optional): rbxassetid:// ถ้าไม่ใส่จะใช้จุดสี่เหลี่ยมเล็กแบบเดิม
local function setIconColor(icon, color, transparency)
    if icon:IsA("ImageLabel") then
        tween(icon, { ImageColor3 = color, ImageTransparency = transparency or 0 }, 0.15)
    else
        tween(icon, { BackgroundColor3 = color }, 0.15)
    end
end

function MyUI:CreateTab(name, icon)
    local isFirst = self._firstTab

    local TabButton = new("TextButton", {
        Text = "",
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = isFirst and 0 or 0.4,
        Size = UDim2.new(1, 0, 0, 42),
        AutoButtonColor = false,
        Parent = self.TabList,
    }, { corner(8), stroke(Theme.Accent, 1, isFirst and 0 or 1) })

    local ActiveStroke = TabButton:FindFirstChildOfClass("UIStroke")

    local IconSlot
    if icon then
        IconSlot = new("ImageLabel", {
            Size = UDim2.fromOffset(18, 18),
            Position = UDim2.fromOffset(10, 12),
            BackgroundTransparency = 1,
            Image = icon,
            ImageColor3 = isFirst and Theme.Accent or Theme.SubText,
            Parent = TabButton,
        })
    else
        IconSlot = new("Frame", {
            Size = UDim2.fromOffset(10, 10),
            Position = UDim2.fromOffset(14, 16),
            BackgroundColor3 = isFirst and Theme.Accent or Theme.SubText,
            Parent = TabButton,
        }, { corner(3) })
    end

    local Label = new("TextLabel", {
        Text = string.upper(name),
        Font = Theme.FontBold,
        TextSize = 14,
        TextColor3 = isFirst and Theme.Text or Theme.SubText,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(34, 0),
        Size = UDim2.new(1, -56, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TabButton,
    })

    local Chevron = new("TextLabel", {
        Text = ">",
        Font = Theme.FontBold,
        TextSize = 16,
        TextColor3 = Theme.Accent,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -26, 0, 0),
        Size = UDim2.fromOffset(18, 42),
        Visible = isFirst,
        Parent = TabButton,
    })

    local Page = new("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = isFirst,
        Parent = self.PagesContainer,
    })

    new("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Page,
    })

    if isFirst then
        self._firstTab = false
        self.HeaderLabel.Text = string.upper(name)
    end

    TabButton.MouseButton1Click:Connect(function()
        for _, t in pairs(self.Tabs) do
            t.Page.Visible = false
            tween(t.Button, { BackgroundTransparency = 0.4 }, 0.15)
            setIconColor(t.Icon, Theme.SubText)
            tween(t.Label, { TextColor3 = Theme.SubText }, 0.15)
            tween(t.Stroke, { Transparency = 1 }, 0.15)
            t.Chevron.Visible = false
        end
        Page.Visible = true
        tween(TabButton, { BackgroundTransparency = 0 }, 0.15)
        setIconColor(IconSlot, Theme.Accent)
        tween(Label, { TextColor3 = Theme.Text }, 0.15)
        tween(ActiveStroke, { Transparency = 0 }, 0.15)
        Chevron.Visible = true
        self.HeaderLabel.Text = string.upper(name)
    end)

    local Tab = setmetatable({
        Button = TabButton,
        Page = Page,
        Icon = IconSlot,
        Label = Label,
        Chevron = Chevron,
        Stroke = ActiveStroke,
    }, { __index = MyUI })

    table.insert(self.Tabs, Tab)
    return Tab
end

-- ===== Components (added to a Tab's Page) =====

local function addSubtitle(parent, text, yOffset, widthOffset)
    if not text or text == "" then return end
    new("TextLabel", {
        Text = text,
        Font = Theme.Font,
        TextSize = 12,
        TextColor3 = Theme.SubText,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, yOffset),
        Size = UDim2.new(1, -(widthOffset or 32), 0, 16),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = parent,
    })
end

function MyUI:CreateButton(config)
    config = config or {}
    local hasSub = config.SubTitle ~= nil

    local Button = new("TextButton", {
        Text = "",
        BackgroundColor3 = Theme.Secondary,
        Size = UDim2.new(1, 0, 0, hasSub and 60 or 44),
        AutoButtonColor = false,
        Parent = self.Page,
    }, { corner(8), stroke(Theme.Stroke, 1) })

    new("TextLabel", {
        Text = string.upper(config.Title or "Button"),
        Font = Theme.FontBold,
        TextSize = 15,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, hasSub and 8 or 0),
        Size = UDim2.new(1, -32, 0, hasSub and 20 or 44),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = hasSub and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
        Parent = Button,
    })
    addSubtitle(Button, config.SubTitle, 30)

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
    local hasSub = config.SubTitle ~= nil

    local Holder = new("Frame", {
        Size = UDim2.new(1, 0, 0, hasSub and 64 or 44),
        BackgroundColor3 = Theme.Secondary,
        Parent = self.Page,
    }, { corner(10), stroke(Theme.Stroke, 1) })

    new("TextLabel", {
        Text = string.upper(config.Title or "Toggle"),
        Font = Theme.FontBold,
        TextSize = 15,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, hasSub and 10 or 0),
        Size = UDim2.new(1, -90, hasSub and 0 or 1, hasSub and 20 or 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Holder,
    })
    addSubtitle(Holder, config.SubTitle, 32, 90)

    local Switch = new("Frame", {
        Size = UDim2.fromOffset(52, 26),
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -16, 0.5, 0),
        BackgroundColor3 = state and Theme.Accent or Theme.Background,
        Parent = Holder,
    }, { corner(13), stroke(Theme.Stroke, 1) })

    local Knob = new("Frame", {
        Size = UDim2.fromOffset(20, 20),
        Position = state and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Parent = Switch,
    }, { corner(10) })

    local ClickArea = new("TextButton", {
        Text = "",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = Holder,
    })

    ClickArea.MouseButton1Click:Connect(function()
        state = not state
        tween(Switch, { BackgroundColor3 = state and Theme.Accent or Theme.Background }, 0.15)
        tween(Knob, { Position = state and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10) }, 0.15)
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
    local hasSub = config.SubTitle ~= nil

    local Holder = new("Frame", {
        Size = UDim2.new(1, 0, 0, hasSub and 78 or 64),
        BackgroundColor3 = Theme.Secondary,
        Parent = self.Page,
    }, { corner(10), stroke(Theme.Stroke, 1) })

    new("TextLabel", {
        Text = string.upper(config.Title or "Slider"),
        Font = Theme.FontBold,
        TextSize = 15,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 8),
        Size = UDim2.new(1, -80, 0, 20),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Holder,
    })
    addSubtitle(Holder, config.SubTitle, 28, 80)

    local ValueLabel = new("TextLabel", {
        Text = tostring(value),
        Font = Theme.FontBold,
        TextSize = 16,
        TextColor3 = Theme.Accent,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -60, 0, 8),
        Size = UDim2.fromOffset(46, 20),
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = Holder,
    })

    local Track = new("Frame", {
        Size = UDim2.new(1, -32, 0, 5),
        Position = UDim2.new(0, 16, 1, -20),
        BackgroundColor3 = Theme.Background,
        Parent = Holder,
    }, { corner(3) })

    local Fill = new("Frame", {
        Size = UDim2.new((value - min) / math.max(max - min, 1), 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        Parent = Track,
    }, { corner(3) })

    local Knob = new("Frame", {
        Size = UDim2.fromOffset(18, 18),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new((value - min) / math.max(max - min, 1), 0, 0.5, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        ZIndex = 2,
        Parent = Track,
    }, { corner(9), stroke(Theme.Accent, 3) })

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
            tween(Knob, { Size = UDim2.fromOffset(22, 22) }, 0.1)
            setFromX(input.Position.X)
        end
    end

    Track.InputBegan:Connect(beginDrag)
    Knob.InputBegan:Connect(beginDrag)

    UserInputService.InputEnded:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            tween(Knob, { Size = UDim2.fromOffset(18, 18) }, 0.1)
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
    local hasSub = config.SubTitle ~= nil
    local baseHeight = hasSub and 78 or 64

    local Holder = new("Frame", {
        Size = UDim2.new(1, 0, 0, baseHeight),
        BackgroundColor3 = Theme.Secondary,
        ClipsDescendants = true,
        Parent = self.Page,
    }, { corner(10), stroke(Theme.Accent2, 1) })

    new("TextLabel", {
        Text = string.upper(config.Title or "Dropdown"),
        Font = Theme.FontBold,
        TextSize = 15,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 8),
        Size = UDim2.new(0.5, 0, 0, 20),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Holder,
    })
    addSubtitle(Holder, config.SubTitle, 28, 200)

    -- Compact "value + arrow" box, anchored to the right of the row
    local Box = new("TextButton", {
        Text = "",
        BackgroundColor3 = Theme.Background,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -16, 0, 13),
        Size = UDim2.fromOffset(160, 38),
        AutoButtonColor = false,
        Parent = Holder,
    }, { corner(8), stroke(Theme.Accent2, 1) })

    local SelectedLabel = new("TextLabel", {
        Text = string.upper(tostring(selected or "Select")),
        Font = Theme.FontBold,
        TextSize = 13,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 0),
        Size = UDim2.new(1, -34, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Box,
    })

    local Arrow = new("TextLabel", {
        Text = "V",
        Font = Theme.FontBold,
        TextSize = 12,
        TextColor3 = Theme.Accent2,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -26, 0, 0),
        Size = UDim2.fromOffset(20, 38),
        Parent = Box,
    })

    local OptionsFrame = new("Frame", {
        Position = UDim2.new(0, 16, 0, baseHeight),
        Size = UDim2.new(1, -32, 0, #options * 30),
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
            BackgroundColor3 = Theme.Background,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 28),
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = OptionsFrame,
        }, { corner(6) })

        OptButton.MouseEnter:Connect(function()
            tween(OptButton, { BackgroundTransparency = 0, TextColor3 = Theme.Accent2 }, 0.1)
        end)
        OptButton.MouseLeave:Connect(function()
            tween(OptButton, { BackgroundTransparency = 1, TextColor3 = Theme.SubText }, 0.1)
        end)

        OptButton.MouseButton1Click:Connect(function()
            selected = option
            SelectedLabel.Text = string.upper(tostring(option))
            if config.Callback then pcall(config.Callback, option) end
        end)
    end

    Box.MouseButton1Click:Connect(function()
        open = not open
        local targetHeight = open and (baseHeight + #options * 30 + 8) or baseHeight
        tween(Holder, { Size = UDim2.new(1, 0, 0, targetHeight) }, 0.2)
        tween(Arrow, { Rotation = open and 180 or 0 }, 0.2)
    end)

    return Holder
end

function MyUI:CreateInput(config)
    config = config or {}
    local hasSub = config.SubTitle ~= nil

    local Holder = new("Frame", {
        Size = UDim2.new(1, 0, 0, hasSub and 64 or 44),
        BackgroundColor3 = Theme.Secondary,
        Parent = self.Page,
    }, { corner(10), stroke(Theme.Stroke, 1) })

    new("TextLabel", {
        Text = string.upper(config.Title or "Input"),
        Font = Theme.FontBold,
        TextSize = 15,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, hasSub and 10 or 0),
        Size = UDim2.new(0.4, 0, hasSub and 0 or 1, hasSub and 20 or 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Holder,
    })
    addSubtitle(Holder, config.SubTitle, 32, 300)

    local Box = new("TextBox", {
        Text = config.Default or "",
        PlaceholderText = config.Placeholder or "...",
        Font = Theme.Font,
        TextSize = 13,
        TextColor3 = Theme.Text,
        BackgroundColor3 = Theme.Background,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -16, 0.5, 0),
        Size = UDim2.fromOffset(180, 30),
        ClearTextOnFocus = false,
        Parent = Holder,
    }, { corner(8) })

    Box.FocusLost:Connect(function(enterPressed)
        if config.Callback then
            pcall(config.Callback, Box.Text, enterPressed)
        end
    end)

    return Holder
end

-- ===== Section (หัวข้อย่อย/เส้นคั่น ใช้จัดกลุ่ม component ในแท็บ) =====
-- ใช้งาน: Tab:CreateSection({ Title = "การตั้งค่า" })
function MyUI:CreateSection(config)
    config = config or {}
    local Holder = new("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        Parent = self.Page,
    })
    new("TextLabel", {
        Text = string.upper(config.Title or "Section"),
        Font = Theme.FontBold,
        TextSize = 13,
        TextColor3 = Theme.Accent,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(4, 0),
        Size = UDim2.new(1, -8, 0, 18),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Holder,
    })
    new("Frame", {
        Size = UDim2.new(1, -8, 0, 1),
        Position = UDim2.fromOffset(4, 22),
        BackgroundColor3 = Theme.Stroke,
        BorderSizePixel = 0,
        Parent = Holder,
    })
    return Holder
end

-- ===== Paragraph (ข้อความยาวๆ อธิบาย ปรับความสูงอัตโนมัติตามเนื้อหา) =====
-- ใช้งาน: Tab:CreateParagraph({ Title = "หัวข้อ", Content = "เนื้อหายาวๆ..." })
function MyUI:CreateParagraph(config)
    config = config or {}
    local Holder = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Secondary,
        Parent = self.Page,
    }, { corner(10), stroke(Theme.Stroke, 1) })

    new("UIPadding", {
        PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16),
        Parent = Holder,
    })
    new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = Holder })

    new("TextLabel", {
        Text = string.upper(config.Title or "Paragraph"),
        Font = Theme.FontBold,
        TextSize = 15,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        LayoutOrder = 1,
        Parent = Holder,
    })
    new("TextLabel", {
        Text = config.Content or "",
        Font = Theme.Font,
        TextSize = 13,
        TextColor3 = Theme.SubText,
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        LayoutOrder = 2,
        Parent = Holder,
    })
    return Holder
end

-- ===== Keybind (กำหนดปุ่มลัดเอง) =====
-- ใช้งาน: Tab:CreateKeybind({ Title = "Toggle UI", Default = Enum.KeyCode.RightControl, Callback = function(key) end })
function MyUI:CreateKeybind(config)
    config = config or {}
    local currentKey = config.Default or Enum.KeyCode.Unknown
    local listening = false

    local Holder = new("Frame", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = Theme.Secondary,
        Parent = self.Page,
    }, { corner(10), stroke(Theme.Stroke, 1) })

    new("TextLabel", {
        Text = string.upper(config.Title or "Keybind"),
        Font = Theme.FontBold,
        TextSize = 15,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 0),
        Size = UDim2.new(1, -120, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Holder,
    })

    local KeyButton = new("TextButton", {
        Text = currentKey.Name,
        Font = Theme.FontBold,
        TextSize = 13,
        TextColor3 = Theme.Accent,
        BackgroundColor3 = Theme.Background,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -16, 0.5, 0),
        Size = UDim2.fromOffset(90, 30),
        AutoButtonColor = false,
        Parent = Holder,
    }, { corner(8), stroke(Theme.Accent, 1) })

    KeyButton.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        KeyButton.Text = "..."
        tween(KeyButton, { BackgroundColor3 = Theme.Accent }, 0.1)
    end)

    UserInputService.InputBegan:Connect(function(input)
        if not listening then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            currentKey = input.KeyCode
            KeyButton.Text = currentKey.Name
            listening = false
            tween(KeyButton, { BackgroundColor3 = Theme.Background }, 0.1)
            if config.Callback then pcall(config.Callback, currentKey) end
        end
    end)

    return Holder
end

-- ===== Colorpicker (เลือกสีจากพาเลตแบบย่อ/ขยาย) =====
-- ใช้งาน: Tab:CreateColorpicker({ Title = "สีธีม", Default = Color3.fromRGB(0,220,255), Callback = function(color) end })
function MyUI:CreateColorpicker(config)
    config = config or {}
    local selected = config.Default or Theme.Accent
    local palette = config.Palette or {
        Color3.fromRGB(0, 220, 255), Color3.fromRGB(170, 80, 255), Color3.fromRGB(70, 220, 130),
        Color3.fromRGB(255, 190, 60), Color3.fromRGB(255, 70, 90), Color3.fromRGB(255, 255, 255),
    }
    local open = false
    local baseHeight = 44

    local Holder = new("Frame", {
        Size = UDim2.new(1, 0, 0, baseHeight),
        BackgroundColor3 = Theme.Secondary,
        ClipsDescendants = true,
        Parent = self.Page,
    }, { corner(10), stroke(Theme.Stroke, 1) })

    new("TextLabel", {
        Text = string.upper(config.Title or "Color"),
        Font = Theme.FontBold,
        TextSize = 15,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 0),
        Size = UDim2.new(1, -80, 0, baseHeight),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Holder,
    })

    local Swatch = new("TextButton", {
        Text = "",
        BackgroundColor3 = selected,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -16, 0, 7),
        Size = UDim2.fromOffset(30, 30),
        AutoButtonColor = false,
        Parent = Holder,
    }, { corner(8), stroke(Theme.Text, 1) })

    local PaletteFrame = new("Frame", {
        Position = UDim2.new(0, 16, 0, baseHeight),
        Size = UDim2.new(1, -32, 0, 34),
        BackgroundTransparency = 1,
        Parent = Holder,
    })
    new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), Parent = PaletteFrame })

    for _, color in ipairs(palette) do
        local Swab = new("TextButton", {
            Text = "",
            BackgroundColor3 = color,
            Size = UDim2.fromOffset(26, 26),
            AutoButtonColor = false,
            Parent = PaletteFrame,
        }, { corner(6), stroke(Theme.Text, 1, 0.5) })

        Swab.MouseButton1Click:Connect(function()
            selected = color
            Swatch.BackgroundColor3 = color
            if config.Callback then pcall(config.Callback, color) end
        end)
    end

    Swatch.MouseButton1Click:Connect(function()
        open = not open
        local targetHeight = open and (baseHeight + 42) or baseHeight
        tween(Holder, { Size = UDim2.new(1, 0, 0, targetHeight) }, 0.2)
    end)

    return Holder
end

-- ===== ProgressBar (แถบสถานะ อัปเดตค่าได้ผ่าน :Set()) =====
-- ใช้งาน: local bar = Tab:CreateProgressBar({ Title = "Loading", Max = 100, Default = 0 }); bar:Set(50)
function MyUI:CreateProgressBar(config)
    config = config or {}
    local min = config.Min or 0
    local max = config.Max or 100
    local value = config.Default or min

    local Holder = new("Frame", {
        Size = UDim2.new(1, 0, 0, 54),
        BackgroundColor3 = Theme.Secondary,
        Parent = self.Page,
    }, { corner(10), stroke(Theme.Stroke, 1) })

    new("TextLabel", {
        Text = string.upper(config.Title or "Progress"),
        Font = Theme.FontBold,
        TextSize = 14,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 8),
        Size = UDim2.new(1, -70, 0, 18),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Holder,
    })

    local PercentLabel = new("TextLabel", {
        Text = string.format("%d%%", math.floor((value - min) / math.max(max - min, 1) * 100)),
        Font = Theme.FontBold,
        TextSize = 13,
        TextColor3 = Theme.Accent,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -60, 0, 8),
        Size = UDim2.fromOffset(46, 18),
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = Holder,
    })

    local Track = new("Frame", {
        Size = UDim2.new(1, -32, 0, 8),
        Position = UDim2.new(0, 16, 1, -18),
        BackgroundColor3 = Theme.Background,
        Parent = Holder,
    }, { corner(4) })

    local Fill = new("Frame", {
        Size = UDim2.new((value - min) / math.max(max - min, 1), 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        Parent = Track,
    }, { corner(4) })
    local grad = new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Accent),
            ColorSequenceKeypoint.new(1, Theme.Accent2),
        }),
    })
    grad.Parent = Fill

    local api = {}
    function api:Set(newValue)
        value = math.clamp(newValue, min, max)
        local rel = (value - min) / math.max(max - min, 1)
        tween(Fill, { Size = UDim2.new(rel, 0, 1, 0) }, 0.2)
        PercentLabel.Text = string.format("%d%%", math.floor(rel * 100))
    end
    return api
end

-- ===== Confirm (popup ถาม Yes/No ก่อนทำ action สำคัญ) =====
-- ใช้งาน: Window:CreateConfirm({ Title = "ลบข้อมูล?", Content = "ยืนยันการลบ", OnConfirm = function() end, OnCancel = function() end })
function MyUI:CreateConfirm(config)
    config = config or {}
    local ScreenGui = PlayerGui:FindFirstChild("MyUI")
    if not ScreenGui then return end

    local Overlay = new("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        ZIndex = 50,
        Parent = ScreenGui,
    })

    local Box = new("Frame", {
        Size = UDim2.fromOffset(320, 160),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundColor3 = Theme.Secondary,
        ZIndex = 51,
        Parent = Overlay,
    }, { corner(12), glowStroke(2) })

    new("TextLabel", {
        Text = string.upper(config.Title or "Confirm"),
        Font = Theme.FontBold,
        TextSize = 18,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(20, 16),
        Size = UDim2.new(1, -40, 0, 24),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 52,
        Parent = Box,
    })
    new("TextLabel", {
        Text = config.Content or "",
        Font = Theme.Font,
        TextSize = 13,
        TextColor3 = Theme.SubText,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(20, 46),
        Size = UDim2.new(1, -40, 0, 60),
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 52,
        Parent = Box,
    })

    local function makeBtn(text, color, xOffset)
        return new("TextButton", {
            Text = string.upper(text),
            Font = Theme.FontBold,
            TextSize = 13,
            TextColor3 = Theme.Text,
            BackgroundColor3 = color,
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, xOffset, 1, -16),
            Size = UDim2.fromOffset(110, 34),
            AutoButtonColor = false,
            ZIndex = 52,
            Parent = Box,
        }, { corner(8) })
    end

    local ConfirmBtn = makeBtn(config.ConfirmText or "Confirm", StatusColors.Success, -16)
    local CancelBtn = makeBtn(config.CancelText or "Cancel", Theme.Background, -136)

    ConfirmBtn.MouseButton1Click:Connect(function()
        if config.OnConfirm then pcall(config.OnConfirm) end
        Overlay:Destroy()
    end)
    CancelBtn.MouseButton1Click:Connect(function()
        if config.OnCancel then pcall(config.OnCancel) end
        Overlay:Destroy()
    end)

    return Overlay
end

-- ===== SetTheme (สลับชุดสีของ UI ทั้งหมด — มีผลกับ component ที่สร้าง "หลังจากนี้") =====
-- ใช้งาน: MyUI:SetTheme({ Accent = Color3.fromRGB(255, 70, 90), Accent2 = Color3.fromRGB(255, 190, 60) })
function MyUI:SetTheme(colors)
    colors = colors or {}
    for key, value in pairs(colors) do
        if Theme[key] ~= nil then
            Theme[key] = value
        end
    end
end

-- ===== Watermark (ป้ายลอยมุมจอ แสดงข้อความ + FPS ได้) =====
-- ใช้งาน: Window:CreateWatermark({ Text = "MyUI", ShowFPS = true })
function MyUI:CreateWatermark(config)
    config = config or {}
    local ScreenGui = PlayerGui:FindFirstChild("MyUI")
    if not ScreenGui then return end

    local Watermark = new("Frame", {
        Size = UDim2.fromOffset(0, 28),
        AutomaticSize = Enum.AutomaticSize.X,
        Position = UDim2.fromOffset(20, 76),
        BackgroundColor3 = Theme.Secondary,
        Parent = ScreenGui,
    }, { corner(6), stroke(Theme.Accent, 1) })

    new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = Watermark })

    local Label = new("TextLabel", {
        Text = config.Text or "MyUI",
        Font = Theme.FontBold,
        TextSize = 13,
        TextColor3 = Theme.Accent,
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 1, 0),
        Parent = Watermark,
    })

    if config.ShowFPS then
        local frames, elapsed = 0, 0
        RunService.RenderStepped:Connect(function(dt)
            frames += 1
            elapsed += dt
            if elapsed >= 0.5 then
                Label.Text = string.format("%s | %d FPS", config.Text or "MyUI", math.floor(frames / elapsed))
                frames, elapsed = 0, 0
            end
        end)
    end

    return Watermark
end

-- ===== Label (ข้อความสวยๆ ในหน้า Tab รองรับ Type: Info, Success, Warning, Error) =====
-- ใช้งาน: Tab:CreateLabel({ Title = "บันทึกสำเร็จ", Content = "ข้อมูลถูกบันทึกแล้ว", Type = "Success" })
-- จัดกึ่งกลาง + ขอบไล่สีโดดเด่น (เหมาะกับเครดิตผู้พัฒนา):
-- Tab:CreateLabel({ Title = "⚡ CreateBy: ---->3A1TR<---- ⚡", Align = "Center", Glow = true })
function MyUI:CreateLabel(config)
    config = config or {}
    local statusType = config.Type -- "Info" | "Success" | "Warning" | "Error" | nil
    local accentColor = config.Color or StatusColors[statusType] or Theme.Accent
    local hasContent = config.Content ~= nil and config.Content ~= ""
    local align = (config.Align == "Center") and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left

    local border = config.Glow and glowStroke(1.5) or stroke(accentColor, 1)

    local Holder = new("Frame", {
        Size = UDim2.new(1, 0, 0, hasContent and 56 or 36),
        BackgroundColor3 = Theme.Secondary,
        Parent = self.Page,
    }, { corner(8), border })

    -- แถบสีด้านซ้าย ให้ดูเป็นการ์ดแจ้งเตือน (ซ่อนไว้ถ้าจัดกึ่งกลาง เพราะจะดูเบี้ยว)
    if align == Enum.TextXAlignment.Left then
        new("Frame", {
            Size = UDim2.new(0, 3, 1, -12),
            Position = UDim2.fromOffset(0, 6),
            BackgroundColor3 = accentColor,
            Parent = Holder,
        }, { corner(2) })
    end

    new("TextLabel", {
        Text = config.Title or "Label",
        Font = Theme.FontBold,
        TextSize = 14,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, hasContent and 6 or 0),
        Size = UDim2.new(1, -32, 0, hasContent and 18 or 36),
        TextXAlignment = align,
        TextYAlignment = hasContent and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
        Parent = Holder,
    })

    if hasContent then
        new("TextLabel", {
            Text = config.Content,
            Font = Theme.Font,
            TextSize = 12,
            TextColor3 = Theme.SubText,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(16, 26),
            Size = UDim2.new(1, -32, 0, 24),
            TextWrapped = true,
            TextXAlignment = align,
            Parent = Holder,
        })
    end

    return Holder
end

-- ===== Notifications =====
-- ใช้งาน: Window:Notify({ Title = "Error", Content = "เกิดข้อผิดพลาด", Type = "Error", Duration = 4 })
function MyUI:Notify(config)
    config = config or {}
    local ScreenGui = PlayerGui:FindFirstChild("MyUI")
    if not ScreenGui then return end

    local accentColor = config.Color or StatusColors[config.Type] or Theme.Accent

    local Notif = new("Frame", {
        Size = UDim2.fromOffset(280, 64),
        Position = UDim2.new(1, -300, 1, -84),
        BackgroundColor3 = Theme.Secondary,
        Parent = ScreenGui,
    }, { corner(10), stroke(accentColor, 1) })

    new("TextLabel", {
        Text = string.upper(config.Title or "Notification"),
        Font = Theme.FontBold,
        TextSize = 14,
        TextColor3 = accentColor,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 8),
        Size = UDim2.new(1, -28, 0, 18),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Notif,
    })

    new("TextLabel", {
        Text = config.Content or "",
        Font = Theme.Font,
        TextSize = 12,
        TextColor3 = Theme.SubText,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 30),
        Size = UDim2.new(1, -28, 0, 28),
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Notif,
    })

    task.delay(config.Duration or 3, function()
        tween(Notif, { Position = UDim2.new(1, 20, 1, -84) }, 0.3)
        task.wait(0.3)
        Notif:Destroy()
    end)

    return Notif
end

return MyUI
