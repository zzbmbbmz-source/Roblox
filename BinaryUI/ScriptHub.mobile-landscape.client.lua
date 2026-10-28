-- BinaryUI Script Hub — Mobile Landscape
-- Install as a LocalScript in StarterPlayer > StarterPlayerScripts
-- UI shell for scripts/features in your own Roblox experience or authorized tools.
-- Add your own permitted callbacks in the SCRIPT_ACTIONS table below.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local previous = playerGui:FindFirstChild("BinaryScriptHub")
if previous then previous:Destroy() end

local THEME = {
    bg = Color3.fromRGB(12, 10, 21),
    panel = Color3.fromRGB(23, 19, 38),
    card = Color3.fromRGB(34, 28, 53),
    purple = Color3.fromRGB(173, 93, 255),
    cyan = Color3.fromRGB(88, 222, 255),
    white = Color3.fromRGB(247, 243, 255),
    muted = Color3.fromRGB(174, 164, 196),
    green = Color3.fromRGB(94, 229, 168),
}

-- Replace these placeholder callbacks with features you own/are authorized to run.
local SCRIPT_ACTIONS = {
    ["Example Tool"] = function() return "Connect your own tool here." end,
    ["Movement UI"] = function() return "Connect your own movement feature here." end,
    ["Training Tools"] = function() return "Connect your own training feature here." end,
    ["Visual Settings"] = function() return "Connect your own visual settings here." end,
}

local gui = Instance.new("ScreenGui")
gui.Name = "BinaryScriptHub"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.Parent = playerGui

local function round(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = obj
end

local function outline(obj, color, transparency, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Transparency = transparency or 0
    s.Thickness = thickness or 1
    s.Parent = obj
end

local function makeLabel(parent, text, size, pos, fontSize, color, font)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = size
    label.Position = pos
    label.Text = text
    label.TextColor3 = color or THEME.white
    label.TextSize = fontSize or 14
    label.Font = font or Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = parent
    return label
end

local function makeButton(parent, text, size, pos, accent)
    local b = Instance.new("TextButton")
    b.Size = size
    b.Position = pos
    b.BackgroundColor3 = accent and THEME.purple or THEME.card
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = THEME.white
    b.TextSize = 13
    b.Font = Enum.Font.GothamBold
    b.AutoButtonColor = true
    b.Parent = parent
    round(b, 10)
    if not accent then outline(b, THEME.purple, 0.68, 1) end
    return b
end

local panel = Instance.new("Frame")
panel.Name = "HubPanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(660, 370)
panel.BackgroundColor3 = THEME.bg
panel.BorderSizePixel = 0
panel.Parent = gui
round(panel, 16)
outline(panel, THEME.purple, 0.12, 1.5)

local scale = Instance.new("UIScale")
scale.Parent = panel

local top = Instance.new("Frame")
top.Size = UDim2.new(1, 0, 0, 56)
top.BackgroundColor3 = THEME.panel
top.BorderSizePixel = 0
top.Parent = panel
round(top, 16)

makeLabel(top, "BINARY", UDim2.fromOffset(125, 28), UDim2.fromOffset(18, 5), 20, THEME.white, Enum.Font.GothamBlack)
makeLabel(top, "SCRIPT HUB  /  MOBILE", UDim2.fromOffset(250, 18), UDim2.fromOffset(20, 32), 10, THEME.cyan, Enum.Font.GothamBold)

local minimize = makeButton(top, "—", UDim2.fromOffset(40, 36), UDim2.new(1, -91, 0, 10), false)
minimize.TextSize = 19
local close = makeButton(top, "×", UDim2.fromOffset(40, 36), UDim2.new(1, -45, 0, 10), false)
close.TextSize = 22

local sidebar = Instance.new("Frame")
sidebar.Position = UDim2.fromOffset(12, 68)
sidebar.Size = UDim2.new(0, 150, 1, -80)
sidebar.BackgroundColor3 = THEME.panel
sidebar.BorderSizePixel = 0
sidebar.Parent = panel
round(sidebar, 12)

makeLabel(sidebar, "CATEGORIES", UDim2.new(1, -20, 0, 25), UDim2.fromOffset(12, 8), 10, THEME.muted, Enum.Font.GothamBold)

local content = Instance.new("Frame")
content.Position = UDim2.fromOffset(174, 68)
content.Size = UDim2.new(1, -186, 1, -80)
content.BackgroundColor3 = THEME.panel
content.BorderSizePixel = 0
content.Parent = panel
round(content, 12)

local categoryTitle = makeLabel(content, "FEATURE LIBRARY", UDim2.new(1, -24, 0, 26), UDim2.fromOffset(14, 8), 14, THEME.cyan, Enum.Font.GothamBold)
local description = makeLabel(content, "Choose a card to view or run your configured feature.", UDim2.new(1, -24, 0, 22), UDim2.fromOffset(14, 32), 11, THEME.muted)
local status = makeLabel(content, "●  HUB READY", UDim2.new(1, -24, 0, 20), UDim2.new(0, 14, 1, -28), 10, THEME.green, Enum.Font.GothamBold)

local cardHolder = Instance.new("ScrollingFrame")
cardHolder.Name = "CardScrollArea"
cardHolder.BackgroundTransparency = 1
cardHolder.BorderSizePixel = 0
cardHolder.Position = UDim2.fromOffset(12, 64)
cardHolder.Size = UDim2.new(1, -24, 1, -102)
cardHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
cardHolder.AutomaticCanvasSize = Enum.AutomaticSize.Y
cardHolder.ScrollingDirection = Enum.ScrollingDirection.Y
cardHolder.ScrollBarThickness = 4
cardHolder.ScrollBarImageColor3 = THEME.purple
cardHolder.ClipsDescendants = true
cardHolder.Parent = content

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0.5, -7, 0, 102)
grid.CellPadding = UDim2.fromOffset(10, 10)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = cardHolder

local function addCard(name, desc, order)
    local card = Instance.new("Frame")
    card.BackgroundColor3 = THEME.card
    card.BorderSizePixel = 0
    card.LayoutOrder = order
    card.Parent = cardHolder
    round(card, 12)
    outline(card, THEME.purple, 0.72, 1)

    makeLabel(card, name, UDim2.new(1, -18, 0, 25), UDim2.fromOffset(10, 7), 13, THEME.white, Enum.Font.GothamBold)
    local detail = makeLabel(card, desc, UDim2.new(1, -18, 0, 25), UDim2.fromOffset(10, 31), 10, THEME.muted)
    detail.TextWrapped = true

    local run = makeButton(card, "OPEN / RUN", UDim2.new(1, -20, 0, 30), UDim2.new(0, 10, 1, -38), true)
    run.TextSize = 11
    run.Activated:Connect(function()
        local callback = SCRIPT_ACTIONS[name]
        if callback then
            local ok, result = pcall(callback)
            status.Text = ok and ("✓  " .. tostring(result)) or ("!  Feature error: " .. tostring(result))
            status.TextColor3 = ok and THEME.green or Color3.fromRGB(255, 115, 135)
        else
            status.Text = "No action configured for " .. name
            status.TextColor3 = THEME.muted
        end
    end)
end

local categories = {
    {name = "HOME", title = "FEATURE LIBRARY", desc = "Your scripts and tools, in one place."},
    {name = "TOOLS", title = "TOOLS", desc = "Utility scripts you have configured."},
    {name = "MOVEMENT", title = "MOVEMENT", desc = "Movement features for your own experience."},
    {name = "VISUALS", title = "VISUALS", desc = "Visual and interface settings."},
    {name = "SETTINGS", title = "HUB SETTINGS", desc = "UI options and hub information."},
}
local categoryButtons = {}
local selected = "HOME"
local bubble -- forward declaration for Settings callbacks

local function showCategory(name)
    selected = name
    local entry
    for _, item in ipairs(categories) do
        if item.name == name then entry = item break end
    end
    if not entry then return end
    categoryTitle.Text = entry.title
    description.Text = entry.desc
    status.Text = "●  " .. entry.title .. " SELECTED"
    status.TextColor3 = THEME.green

    for key, button in pairs(categoryButtons) do
        button.BackgroundColor3 = key == name and THEME.purple or THEME.card
    end
    for _, child in ipairs(cardHolder:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    if name == "SETTINGS" then
        addCard("Compact UI", "Scale the hub to fit the screen.", 1)
        addCard("Reset Panel", "Return the panel to the center.", 2)
        addCard("Hide Panel", "Minimize to the floating B button.", 3)
    elseif name == "MOVEMENT" then
        addCard("Movement UI", "Placeholder for your own movement tools.", 1)
        addCard("Training Tools", "Tools for an authorized training place.", 2)
    elseif name == "VISUALS" then
        addCard("Visual Settings", "Placeholder for permitted visual options.", 1)
        addCard("Example Tool", "Example feature card.", 2)
    elseif name == "TOOLS" then
        addCard("Example Tool", "A sample configurable utility.", 1)
        addCard("Training Tools", "Practice tools for your own game.", 2)
    else
        addCard("Example Tool", "Replace this card with your script details.", 1)
        addCard("Movement UI", "Add a short description for your feature.", 2)
        addCard("Training Tools", "Keep touch controls large and clear.", 3)
        addCard("Visual Settings", "Connect this card to your own settings.", 4)
    end

    if name == "SETTINGS" then
        for _, card in ipairs(cardHolder:GetChildren()) do
            if card:IsA("Frame") then
                local run = card:FindFirstChildWhichIsA("TextButton")
                if run then
                    local cardName = card:FindFirstChildWhichIsA("TextLabel")
                    if cardName and cardName.Text == "Compact UI" then
                        run.Activated:Connect(function() scale.Scale = math.max(0.65, scale.Scale - 0.08); status.Text = "UI scale reduced" end)
                    elseif cardName and cardName.Text == "Reset Panel" then
                        run.Activated:Connect(function() panel.Position = UDim2.fromScale(0.5, 0.5); status.Text = "Panel centered" end)
                    elseif cardName and cardName.Text == "Hide Panel" then
                        run.Activated:Connect(function() panel.Visible = false; bubble.Visible = true end)
                    end
                end
            end
        end
    end
end

for i, item in ipairs(categories) do
    local b = makeButton(sidebar, item.name, UDim2.new(1, -16, 0, 43), UDim2.fromOffset(8, 39 + (i - 1) * 49), i == 1)
    b.TextSize = 11
    categoryButtons[item.name] = b
    b.Activated:Connect(function() showCategory(item.name) end)
end

bubble = makeButton(gui, "B", UDim2.fromOffset(56, 56), UDim2.new(0, 12, 0.5, -28), true)
bubble.Name = "FloatingOpenButton"
bubble.TextSize = 23
bubble.Visible = false
round(bubble, 18)
outline(bubble, THEME.cyan, 0.08, 1.5)

local function updateScale()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local v = camera.ViewportSize
    scale.Scale = math.min(1, math.max(0.55, (v.X - 24) / 660), math.max(0.55, (v.Y - 24) / 370))
end
updateScale()
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(updateScale)

local function draggable(handle, target)
    local moving, startInput, startPos = false, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            moving = true
            startInput = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then moving = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if moving and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - startInput
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
draggable(top, panel)
draggable(bubble, bubble)

minimize.Activated:Connect(function() panel.Visible = false; bubble.Visible = true end)
close.Activated:Connect(function() panel.Visible = false; bubble.Visible = true end)
bubble.Activated:Connect(function() panel.Visible = true; bubble.Visible = false end)

showCategory("HOME")
