-- Language: Luau | File: FlightHub/FlightHub.client.lua | Runtime: Roblox Studio LocalScript
-- Target: A Roblox experience you own or are authorized to edit.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local existing = playerGui:FindFirstChild("FlightHub")
if existing then existing:Destroy() end

local PURPLE = Color3.fromRGB(166, 91, 255)
local PURPLE_DARK = Color3.fromRGB(91, 43, 157)
local PANEL = Color3.fromRGB(20, 17, 31)
local PANEL_2 = Color3.fromRGB(31, 25, 47)
local TEXT = Color3.fromRGB(244, 238, 255)
local MUTED = Color3.fromRGB(164, 151, 188)
local GREEN = Color3.fromRGB(91, 226, 166)

local gui = Instance.new("ScreenGui")
gui.Name = "FlightHub"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local function create(className, props, parent)
    local object = Instance.new(className)
    for key, value in pairs(props) do object[key] = value end
    object.Parent = parent
    return object
end

local function round(parent, radius)
    create("UICorner", {CornerRadius = UDim.new(0, radius)}, parent)
end

local function stroke(parent, color, thickness, transparency)
    return create("UIStroke", {
        Color = color,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local main = create("Frame", {
    Name = "Window",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.fromOffset(330, 350),
    BackgroundColor3 = PANEL,
    BorderSizePixel = 0,
}, gui)
round(main, 14)
stroke(main, PURPLE, 1.25, 0.2)

create("UISizeConstraint", {
    MinSize = Vector2.new(290, 330),
    MaxSize = Vector2.new(390, 430),
}, main)

local scale = create("UIScale", {Scale = 1}, main)
local function fitToViewport()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    scale.Scale = math.min(1, viewport.X / 370, viewport.Y / 460)
end
fitToViewport()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(fitToViewport)
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitToViewport)
end

local header = create("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 62),
    BackgroundColor3 = PANEL_2,
    BorderSizePixel = 0,
}, main)
round(header, 14)
create("Frame", {
    Position = UDim2.new(0, 0, 1, -14),
    Size = UDim2.new(1, 0, 0, 14),
    BackgroundColor3 = PANEL_2,
    BorderSizePixel = 0,
}, header)

local logo = create("TextLabel", {
    Position = UDim2.fromOffset(16, 9),
    Size = UDim2.fromOffset(34, 34),
    BackgroundColor3 = PURPLE_DARK,
    Text = "✦",
    TextColor3 = TEXT,
    TextSize = 23,
    Font = Enum.Font.GothamBold,
}, header)
round(logo, 10)

create("TextLabel", {
    Position = UDim2.fromOffset(59, 10),
    Size = UDim2.new(1, -110, 0, 22),
    BackgroundTransparency = 1,
    Text = "FLIGHT HUB",
    TextColor3 = TEXT,
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left,
    Font = Enum.Font.GothamBold,
}, header)

create("TextLabel", {
    Position = UDim2.fromOffset(60, 32),
    Size = UDim2.new(1, -110, 0, 16),
    BackgroundTransparency = 1,
    Text = "PURPLE NEON  •  CONTROL PANEL",
    TextColor3 = MUTED,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
    Font = Enum.Font.GothamMedium,
}, header)

local minimize = create("TextButton", {
    Name = "Minimize",
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -12, 0, 15),
    Size = UDim2.fromOffset(30, 30),
    BackgroundColor3 = Color3.fromRGB(51, 39, 72),
    Text = "—",
    TextColor3 = TEXT,
    TextSize = 18,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = true,
}, header)
round(minimize, 8)

local tabs = create("Frame", {
    Position = UDim2.fromOffset(12, 74),
    Size = UDim2.new(1, -24, 0, 38),
    BackgroundTransparency = 1,
}, main)
create("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, tabs)

local content = create("Frame", {
    Name = "Content",
    Position = UDim2.fromOffset(12, 122),
    Size = UDim2.new(1, -24, 1, -134),
    BackgroundTransparency = 1,
}, main)

local pages = {}
local tabButtons = {}
local activeTab = "Flight"

local function makePage(name)
    local page = create("Frame", {
        Name = name,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Visible = false,
    }, content)
    pages[name] = page
    return page
end

local function makeTab(name, order)
    local button = create("TextButton", {
        Name = name .. "Tab",
        Size = UDim2.new(1/3, -4, 1, 0),
        BackgroundColor3 = name == activeTab and PURPLE_DARK or PANEL_2,
        Text = name,
        TextColor3 = name == activeTab and TEXT or MUTED,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        LayoutOrder = order,
        AutoButtonColor = false,
    }, tabs)
    round(button, 9)
    tabButtons[name] = button
    button.Activated:Connect(function()
        activeTab = name
        for tabName, page in pairs(pages) do
            page.Visible = tabName == name
            local tab = tabButtons[tabName]
            tab.BackgroundColor3 = tabName == name and PURPLE_DARK or PANEL_2
            tab.TextColor3 = tabName == name and TEXT or MUTED
        end
    end)
end

local flightPage = makePage("Flight")
local speedPage = makePage("Speed")
local settingsPage = makePage("Settings")
makeTab("Flight", 1)
makeTab("Speed", 2)
makeTab("Settings", 3)
flightPage.Visible = true

local function label(parent, text, position, size, textSize, color)
    return create("TextLabel", {
        Position = position,
        Size = size,
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = color or TEXT,
        TextSize = textSize or 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
    }, parent)
end

local function button(parent, text, position, size, color)
    local b = create("TextButton", {
        Position = position,
        Size = size,
        BackgroundColor3 = color or PANEL_2,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = TEXT,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = true,
    }, parent)
    round(b, 9)
    return b
end

label(flightPage, "MOVEMENT MODULE", UDim2.fromOffset(4, 0), UDim2.new(1, -8, 0, 22), 11, MUTED)

local flightToggle = button(flightPage, "✦   ENABLE FLIGHT", UDim2.fromOffset(0, 29), UDim2.new(1, 0, 0, 43), PURPLE_DARK)
local status = label(flightPage, "●  OFFLINE", UDim2.fromOffset(4, 80), UDim2.new(1, -8, 0, 22), 12, MUTED)

local vertical = 0
local upButton = button(flightPage, "▲   ASCEND", UDim2.fromOffset(0, 111), UDim2.new(0.5, -5, 0, 39))
local downButton = button(flightPage, "▼   DESCEND", UDim2.new(0.5, 5, 0, 39), UDim2.new(0.5, -5, 0, 39))

label(flightPage, "Move with your normal Roblox controls.", UDim2.fromOffset(4, 160), UDim2.new(1, -8, 0, 34), 11, MUTED)

local speed = 60
label(speedPage, "FLIGHT SPEED", UDim2.fromOffset(4, 2), UDim2.new(1, -8, 0, 22), 11, MUTED)
local speedValue = label(speedPage, "60 studs/s", UDim2.fromOffset(4, 29), UDim2.new(1, -8, 0, 26), 20, TEXT)

local slider = create("Frame", {
    Position = UDim2.fromOffset(4, 68),
    Size = UDim2.new(1, -8, 0, 8),
    BackgroundColor3 = Color3.fromRGB(58, 48, 73),
    BorderSizePixel = 0,
}, speedPage)
round(slider, 5)

local fill = create("Frame", {
    Size = UDim2.new((speed - 20) / 180, 0, 1, 0),
    BackgroundColor3 = PURPLE,
    BorderSizePixel = 0,
}, slider)
round(fill, 5)

local knob = create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new((speed - 20) / 180, 0, 0.5, 0),
    Size = UDim2.fromOffset(18, 18),
    BackgroundColor3 = TEXT,
    BorderSizePixel = 0,
}, slider)
round(knob, 9)
stroke(knob, PURPLE, 2, 0)

local draggingSlider = false
local function setSpeedFromX(x)
    local ratio = math.clamp((x - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
    speed = math.floor((20 + ratio * 180) / 5 + 0.5) * 5
    local alpha = (speed - 20) / 180
    fill.Size = UDim2.new(alpha, 0, 1, 0)
    knob.Position = UDim2.new(alpha, 0, 0.5, 0)
    speedValue.Text = tostring(speed) .. " studs/s"
end

slider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingSlider = true
        setSpeedFromX(input.Position.X)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        setSpeedFromX(input.Position.X)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingSlider = false
    end
end)

local function makeStepButton(text, xScale, direction)
    local b = button(speedPage, text, UDim2.new(xScale, xScale == 0 and 4 or -4, 0, 103), UDim2.new(0.5, -8, 0, 36))
    b.Activated:Connect(function()
        speed = math.clamp(speed + direction * 10, 20, 200)
        local alpha = (speed - 20) / 180
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, 0, 0.5, 0)
        speedValue.Text = tostring(speed) .. " studs/s"
    end)
    return b
end
makeStepButton("−  10", 0, -1)
makeStepButton("+  10", 1, 1)
label(speedPage, "Range: 20–200 studs/s", UDim2.fromOffset(4, 151), UDim2.new(1, -8, 0, 22), 11, MUTED)

label(settingsPage, "INTERFACE", UDim2.fromOffset(4, 2), UDim2.new(1, -8, 0, 22), 11, MUTED)
local hideButton = button(settingsPage, "Hide Flight Hub", UDim2.fromOffset(0, 32), UDim2.new(1, 0, 0, 40))
label(settingsPage, "Drag the header to move this panel.", UDim2.fromOffset(4, 83), UDim2.new(1, -8, 0, 35), 11, MUTED)
label(settingsPage, "Built for experiences you own or are authorized to edit.", UDim2.fromOffset(4, 125), UDim2.new(1, -8, 0, 44), 10, MUTED)

local flying = false
local attachment
local velocity
local alignOrientation
local flightConnection
local currentHumanoid
local currentRoot

local function stopFlight()
    flying = false
    if flightConnection then flightConnection:Disconnect(); flightConnection = nil end
    if velocity then velocity:Destroy(); velocity = nil end
    if alignOrientation then alignOrientation:Destroy(); alignOrientation = nil end
    if attachment then attachment:Destroy(); attachment = nil end
    if currentHumanoid and currentHumanoid.Parent then
        currentHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
    currentHumanoid, currentRoot = nil, nil
    flightToggle.Text = "✦   ENABLE FLIGHT"
    flightToggle.BackgroundColor3 = PURPLE_DARK
    status.Text = "●  OFFLINE"
    status.TextColor3 = MUTED
    vertical = 0
end

local function startFlight()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root or humanoid.Health <= 0 then
        status.Text = "Character not ready"
        return
    end

    stopFlight()
    flying = true
    currentHumanoid, currentRoot = humanoid, root
    humanoid:ChangeState(Enum.HumanoidStateType.Physics)

    attachment = Instance.new("Attachment")
    attachment.Name = "FlightHubAttachment"
    attachment.Parent = root

    velocity = Instance.new("LinearVelocity")
    velocity.Name = "FlightHubVelocity"
    velocity.Attachment0 = attachment
    velocity.RelativeTo = Enum.ActuatorRelativeTo.World
    velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    velocity.VectorVelocity = Vector3.zero
    velocity.MaxForce = root.AssemblyMass * 10000
    velocity.Parent = root

    alignOrientation = Instance.new("AlignOrientation")
    alignOrientation.Name = "FlightHubOrientation"
    alignOrientation.Attachment0 = attachment
    alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
    alignOrientation.MaxTorque = root.AssemblyMass * 10000
    alignOrientation.Responsiveness = 15
    alignOrientation.Parent = root

    flightToggle.Text = "■   DISABLE FLIGHT"
    flightToggle.BackgroundColor3 = Color3.fromRGB(55, 130, 103)
    status.Text = "●  FLIGHT ACTIVE"
    status.TextColor3 = GREEN

    flightConnection = RunService.Heartbeat:Connect(function()
        if not flying or not currentRoot or not currentRoot.Parent or not currentHumanoid or currentHumanoid.Health <= 0 then
            stopFlight()
            return
        end

        local camera = workspace.CurrentCamera
        if not camera then return end

        local move = currentHumanoid.MoveDirection
        velocity.VectorVelocity = move * speed + Vector3.new(0, vertical * speed, 0)

        local look = camera.CFrame.LookVector
        local flatLook = Vector3.new(look.X, 0, look.Z)
        if flatLook.Magnitude > 0.001 then
            alignOrientation.CFrame = CFrame.lookAt(Vector3.zero, flatLook.Unit)
        end
    end)
end

flightToggle.Activated:Connect(function()
    if flying then stopFlight() else startFlight() end
end)

local function bindVertical(buttonObject, direction)
    buttonObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            vertical = direction
        end
    end)
    buttonObject.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if vertical == direction then vertical = 0 end
        end
    end)
end
bindVertical(upButton, 1)
bindVertical(downButton, -1)

local expandedSize = main.Size
local minimized = false
minimize.Activated:Connect(function()
    minimized = not minimized
    tabs.Visible = not minimized
    content.Visible = not minimized
    main.Size = minimized and UDim2.fromOffset(330, 62) or expandedSize
    minimize.Text = minimized and "+" or "—"
end)

hideButton.Activated:Connect(function()
    gui.Enabled = false
end)

local reopen = create("TextButton", {
    Name = "ReopenButton",
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(0, 12, 0.5, 0),
    Size = UDim2.fromOffset(46, 46),
    BackgroundColor3 = PURPLE_DARK,
    Text = "✦",
    TextColor3 = TEXT,
    TextSize = 23,
    Font = Enum.Font.GothamBold,
    Visible = false,
}, gui)
round(reopen, 14)
stroke(reopen, PURPLE, 1, 0.2)
reopen.Activated:Connect(function()
    gui.Enabled = true
    reopen.Visible = false
end)

gui:GetPropertyChangedSignal("Enabled"):Connect(function()
    reopen.Visible = not gui.Enabled
end)

local draggingWindow = false
local dragStart, startPosition
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingWindow = true
        dragStart = input.Position
        startPosition = main.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if draggingWindow and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingWindow = false
    end
end)

player.CharacterAdded:Connect(function()
    stopFlight()
end)

TweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
    BackgroundTransparency = 0,
}):Play()
