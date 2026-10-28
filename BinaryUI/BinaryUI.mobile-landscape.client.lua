-- BinaryUI Mobile Landscape
-- A touch-friendly, draggable floating hub for your own Roblox Studio experience.
-- Install as a LocalScript under StarterPlayer > StarterPlayerScripts.
-- This is a UI shell only: connect button callbacks to features in your own game.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local existing = playerGui:FindFirstChild("BinaryUI")
if existing then existing:Destroy() end

local C = {
    bg = Color3.fromRGB(13, 12, 23),
    panel = Color3.fromRGB(25, 22, 40),
    panel2 = Color3.fromRGB(36, 30, 55),
    purple = Color3.fromRGB(172, 93, 255),
    cyan = Color3.fromRGB(91, 220, 255),
    text = Color3.fromRGB(247, 243, 255),
    muted = Color3.fromRGB(172, 163, 194),
    green = Color3.fromRGB(92, 226, 165),
}

local gui = Instance.new("ScreenGui")
gui.Name = "BinaryUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 50
gui.Parent = playerGui

local function corner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = obj
end

local function stroke(obj, color, transparency, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Transparency = transparency or 0
    s.Thickness = thickness or 1
    s.Parent = obj
    return s
end

local function label(parent, text, size, pos, fontSize, color, font)
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Size = size
    t.Position = pos
    t.Text = text
    t.TextColor3 = color or C.text
    t.TextSize = fontSize or 14
    t.Font = font or Enum.Font.GothamMedium
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.TextYAlignment = Enum.TextYAlignment.Center
    t.Parent = parent
    return t
end

local function button(parent, text, size, pos, primary)
    local b = Instance.new("TextButton")
    b.Size = size
    b.Position = pos
    b.BackgroundColor3 = primary and C.purple or C.panel2
    b.BorderSizePixel = 0
    b.AutoButtonColor = true
    b.Text = text
    b.TextColor3 = C.text
    b.TextSize = 14
    b.Font = Enum.Font.GothamBold
    b.Parent = parent
    corner(b, 10)
    if not primary then stroke(b, C.purple, 0.65, 1) end
    return b
end

-- Small floating reopen button; remains available when the panel is minimized.
local bubble = button(gui, "B", UDim2.fromOffset(54, 54), UDim2.new(0, 14, 0.5, -27), true)
bubble.Name = "FloatingButton"
bubble.TextSize = 22
bubble.Visible = false
corner(bubble, 18)
stroke(bubble, C.cyan, 0.1, 1.5)

local panel = Instance.new("Frame")
panel.Name = "MainPanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(600, 330)
panel.BackgroundColor3 = C.bg
panel.BorderSizePixel = 0
panel.Parent = gui
corner(panel, 16)
stroke(panel, C.purple, 0.12, 1.5)

local scale = Instance.new("UIScale")
scale.Parent = panel

local top = Instance.new("Frame")
top.Name = "TopBar"
top.Size = UDim2.new(1, 0, 0, 54)
top.BackgroundColor3 = C.panel
top.BorderSizePixel = 0
top.Parent = panel
corner(top, 16)

local title = label(top, "BINARY  /  MOBILE HUB", UDim2.new(1, -180, 1, 0), UDim2.fromOffset(18, 0), 17, C.text, Enum.Font.GothamBold)
local subtitle = label(top, "TOUCH OPTIMIZED  •  LANDSCAPE", UDim2.new(1, -220, 0, 16), UDim2.fromOffset(19, 31), 9, C.cyan, Enum.Font.GothamBold)

local minimize = button(top, "—", UDim2.fromOffset(38, 34), UDim2.new(1, -88, 0, 10), false)
minimize.TextSize = 19
local close = button(top, "×", UDim2.fromOffset(38, 34), UDim2.new(1, -44, 0, 10), false)
close.TextSize = 22

local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Position = UDim2.fromOffset(12, 66)
sidebar.Size = UDim2.new(0, 142, 1, -78)
sidebar.BackgroundColor3 = C.panel
sidebar.BorderSizePixel = 0
sidebar.Parent = panel
corner(sidebar, 12)

local content = Instance.new("Frame")
content.Name = "Content"
content.Position = UDim2.fromOffset(166, 66)
content.Size = UDim2.new(1, -178, 1, -78)
content.BackgroundColor3 = C.panel
content.BorderSizePixel = 0
content.Parent = panel
corner(content, 12)

label(content, "QUICK CONTROLS", UDim2.new(1, -28, 0, 26), UDim2.fromOffset(14, 10), 13, C.cyan, Enum.Font.GothamBold)
label(content, "Large touch targets • clean spacing • readable labels", UDim2.new(1, -28, 0, 22), UDim2.fromOffset(14, 36), 11, C.muted)

local status = label(content, "Ready — choose a section", UDim2.new(1, -28, 0, 24), UDim2.fromOffset(14, 66), 12, C.text)

local actionNames = {"Action One", "Action Two", "Action Three", "Action Four"}
local actionButtons = {}
for i, name in ipairs(actionNames) do
    local col = (i - 1) % 2
    local row = math.floor((i - 1) / 2)
    local b = button(content, name, UDim2.new(0.5, -21, 0, 54), UDim2.new(col * 0.5, 14, 0, 104 + row * 66), false)
    actionButtons[i] = b
    b.Activated:Connect(function()
        status.Text = name .. " selected — connect your own feature callback here"
    end)
end

local sections = {"HOME", "FEATURES", "SETTINGS"}
local sectionButtons = {}
local activeSection = "HOME"
for i, name in ipairs(sections) do
    local b = button(sidebar, name, UDim2.new(1, -16, 0, 44), UDim2.fromOffset(8, 12 + (i - 1) * 54), i == 1)
    b.TextSize = 12
    sectionButtons[name] = b
    b.Activated:Connect(function()
        activeSection = name
        for section, item in pairs(sectionButtons) do
            item.BackgroundColor3 = section == name and C.purple or C.panel2
        end
        if name == "HOME" then
            status.Text = "Ready — choose a section"
            actionButtons[1].Text = "Action One"
            actionButtons[2].Text = "Action Two"
            actionButtons[3].Text = "Action Three"
            actionButtons[4].Text = "Action Four"
        elseif name == "FEATURES" then
            status.Text = "Features — add your own game systems"
            actionButtons[1].Text = "Feature A"
            actionButtons[2].Text = "Feature B"
            actionButtons[3].Text = "Feature C"
            actionButtons[4].Text = "Feature D"
        else
            status.Text = "Settings — UI scale adapts to screen size"
            actionButtons[1].Text = "Compact UI"
            actionButtons[2].Text = "Standard UI"
            actionButtons[3].Text = "Reset Panel"
            actionButtons[4].Text = "Hide Panel"
        end
    end)
end

local function updateScale()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    -- Designed for landscape; scale down on smaller screens while preserving touch sizes.
    local availableW = math.max(260, viewport.X - 24)
    local availableH = math.max(180, viewport.Y - 24)
    scale.Scale = math.min(1, availableW / 600, availableH / 330)
    if viewport.X < viewport.Y then
        subtitle.Text = "ROTATE DEVICE TO LANDSCAPE"
    else
        subtitle.Text = "TOUCH OPTIMIZED  •  LANDSCAPE"
    end
end
updateScale()
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end

-- Drag the top bar or floating bubble with touch/mouse.
local function makeDraggable(handle, target)
    local dragging = false
    local dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            dragInput = input
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
makeDraggable(top, panel)
makeDraggable(bubble, bubble)

minimize.Activated:Connect(function()
    panel.Visible = false
    bubble.Visible = true
end)
close.Activated:Connect(function()
    panel.Visible = false
    bubble.Visible = true
end)
bubble.Activated:Connect(function()
    panel.Visible = true
    bubble.Visible = false
end)

-- Keep the floating button on-screen when the viewport changes.
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(updateScale)
