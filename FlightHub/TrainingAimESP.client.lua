-- FlightHub training add-on: Aim Assist + Silent Target Resolver + NPC ESP
-- Use ONLY in a Roblox Studio experience you own or are authorized to test.
-- Setup: place this LocalScript in StarterPlayer > StarterPlayerScripts.
-- Tag practice NPC models with CollectionService tag "TrainingTarget", or put them in workspace.TrainingTargets.
-- SilentTargetResolver is a BindableFunction for YOUR OWN weapon code to query the selected practice target.
-- It does not hook or modify other games' remotes or weapon systems.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local old = playerGui:FindFirstChild("TrainingAimESP")
if old then old:Destroy() end

local PURPLE = Color3.fromRGB(166, 91, 255)
local DARK = Color3.fromRGB(20, 17, 31)
local PANEL = Color3.fromRGB(31, 25, 47)
local WHITE = Color3.fromRGB(244, 238, 255)
local MUTED = Color3.fromRGB(164, 151, 188)
local GREEN = Color3.fromRGB(91, 226, 166)

local gui = Instance.new("ScreenGui")
gui.Name = "TrainingAimESP"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local function round(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = obj
end

local window = Instance.new("Frame")
window.Name = "TrainingPanel"
window.Size = UDim2.fromOffset(286, 286)
window.Position = UDim2.new(0, 18, 0.5, -143)
window.BackgroundColor3 = DARK
window.BorderSizePixel = 0
window.Parent = gui
round(window, 12)
local outline = Instance.new("UIStroke")
outline.Color = PURPLE
outline.Transparency = 0.15
outline.Parent = window

local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, -20, 0, 42)
header.Position = UDim2.fromOffset(12, 4)
header.BackgroundTransparency = 1
header.Text = "TRAINING AIM  /  ESP"
header.TextColor3 = WHITE
header.TextSize = 15
header.Font = Enum.Font.GothamBold
header.TextXAlignment = Enum.TextXAlignment.Left
header.Parent = window

local function makeButton(text, y)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -24, 0, 38)
    b.Position = UDim2.fromOffset(12, y)
    b.BackgroundColor3 = PANEL
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = WHITE
    b.TextSize = 12
    b.Font = Enum.Font.GothamBold
    b.AutoButtonColor = true
    b.Parent = window
    round(b, 8)
    return b
end

local aimButton = makeButton("AIM ASSIST: OFF", 52)
local silentButton = makeButton("SILENT TARGET RESOLVER: OFF", 98)
local espButton = makeButton("NPC ESP: OFF", 144)
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -24, 0, 48)
status.Position = UDim2.fromOffset(12, 193)
status.BackgroundTransparency = 1
status.Text = "Practice targets only\nTag NPCs: TrainingTarget"
status.TextColor3 = MUTED
status.TextSize = 11
status.Font = Enum.Font.Gotham
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = window

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(26, 26)
close.Position = UDim2.new(1, -34, 0, 9)
close.BackgroundColor3 = PANEL
close.Text = "×"
close.TextColor3 = WHITE
close.TextSize = 18
close.Font = Enum.Font.GothamBold
close.Parent = window
round(close, 7)
close.Activated:Connect(function() window.Visible = false end)

local reopen = Instance.new("TextButton")
reopen.Size = UDim2.fromOffset(44, 44)
reopen.Position = UDim2.new(0, 12, 0.5, -22)
reopen.BackgroundColor3 = PANEL
reopen.Text = "✦"
reopen.TextColor3 = WHITE
reopen.TextSize = 20
reopen.Font = Enum.Font.GothamBold
reopen.Visible = false
reopen.Parent = gui
round(reopen, 10)
reopen.Activated:Connect(function()
    window.Visible = true
    reopen.Visible = false
end)
close.Activated:Connect(function()
    window.Visible = false
    reopen.Visible = true
end)

local aimEnabled, silentEnabled, espEnabled = false, false, false
local highlights = {}
local billboards = {}
local selectedTarget = nil

-- This resolver is intentionally local and only for the developer's own weapon scripts.
local resolver = Instance.new("BindableFunction")
resolver.Name = "SilentTargetResolver"
resolver.Parent = gui
resolver.OnInvoke = function()
    if silentEnabled and selectedTarget and selectedTarget.Parent then
        return selectedTarget
    end
    return nil
end

local function getTargets()
    local found = {}
    local folder = workspace:FindFirstChild("TrainingTargets")
    if folder then
        for _, item in ipairs(folder:GetChildren()) do
            if item:IsA("Model") and item:FindFirstChildOfClass("Humanoid") and item:FindFirstChild("HumanoidRootPart") then
                table.insert(found, item)
            end
        end
    end
    for _, item in ipairs(CollectionService:GetTagged("TrainingTarget")) do
        if item:IsA("Model") and item:FindFirstChildOfClass("Humanoid") and item:FindFirstChild("HumanoidRootPart") then
            if not table.find(found, item) then table.insert(found, item) end
        end
    end
    return found
end

local function targetPart(model)
    return model and (model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart"))
end

local function chooseTarget()
    camera = workspace.CurrentCamera
    if not camera then return nil end
    local best, bestScore = nil, math.huge
    local viewport = camera.ViewportSize
    local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
    for _, model in ipairs(getTargets()) do
        local humanoid = model:FindFirstChildOfClass("Humanoid")
        local part = targetPart(model)
        if humanoid and humanoid.Health > 0 and part then
            local point, onScreen = camera:WorldToViewportPoint(part.Position)
            if onScreen and point.Z > 0 then
                local score = (Vector2.new(point.X, point.Y) - center).Magnitude
                if score < bestScore then best, bestScore = model, score end
            end
        end
    end
    return best
end

local function clearESP(model)
    if highlights[model] then highlights[model]:Destroy(); highlights[model] = nil end
    if billboards[model] then billboards[model]:Destroy(); billboards[model] = nil end
end

local function updateESP()
    local targets = getTargets()
    local alive = {}
    for _, model in ipairs(targets) do
        alive[model] = true
        if not highlights[model] then
            local h = Instance.new("Highlight")
            h.Name = "TrainingTargetHighlight"
            h.FillColor = PURPLE
            h.OutlineColor = WHITE
            h.FillTransparency = 0.72
            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            h.Adornee = model
            h.Parent = gui
            highlights[model] = h

            local head = targetPart(model)
            if head then
                local bb = Instance.new("BillboardGui")
                bb.Name = "TrainingTargetLabel"
                bb.Adornee = head
                bb.Size = UDim2.fromOffset(150, 34)
                bb.StudsOffset = Vector3.new(0, 2.3, 0)
                bb.AlwaysOnTop = true
                bb.Parent = gui
                local text = Instance.new("TextLabel")
                text.Size = UDim2.fromScale(1, 1)
                text.BackgroundTransparency = 1
                text.TextColor3 = WHITE
                text.TextStrokeTransparency = 0.25
                text.TextSize = 12
                text.Font = Enum.Font.GothamBold
                text.Parent = bb
                billboards[model] = bb
            end
        end
        local bb = billboards[model]
        local head = targetPart(model)
        local root = model:FindFirstChild("HumanoidRootPart")
        if bb and head and root then
            local character = player.Character
            local myRoot = character and character:FindFirstChild("HumanoidRootPart")
            local distance = myRoot and math.floor((root.Position - myRoot.Position).Magnitude) or 0
            local hum = model:FindFirstChildOfClass("Humanoid")
            bb.Adornee = head
            bb.TextLabel.Text = model.Name .. "  •  " .. distance .. " studs" .. (hum and ("  •  HP " .. math.floor(hum.Health)) or "")
        end
    end
    for model in pairs(highlights) do
        if not alive[model] then clearESP(model) end
    end
end

aimButton.Activated:Connect(function()
    aimEnabled = not aimEnabled
    aimButton.Text = "AIM ASSIST: " .. (aimEnabled and "ON" or "OFF")
    aimButton.BackgroundColor3 = aimEnabled and Color3.fromRGB(55, 130, 103) or PANEL
end)
silentButton.Activated:Connect(function()
    silentEnabled = not silentEnabled
    silentButton.Text = "SILENT TARGET RESOLVER: " .. (silentEnabled and "ON" or "OFF")
    silentButton.BackgroundColor3 = silentEnabled and Color3.fromRGB(55, 130, 103) or PANEL
end)
espButton.Activated:Connect(function()
    espEnabled = not espEnabled
    espButton.Text = "NPC ESP: " .. (espEnabled and "ON" or "OFF")
    espButton.BackgroundColor3 = espEnabled and Color3.fromRGB(55, 130, 103) or PANEL
    if not espEnabled then
        for model in pairs(highlights) do clearESP(model) end
    end
end)

local renderConnection = RunService.RenderStepped:Connect(function()
    selectedTarget = (aimEnabled or silentEnabled) and chooseTarget() or nil
    if aimEnabled and selectedTarget then
        local part = targetPart(selectedTarget)
        if part and camera then
            local desired = CFrame.lookAt(camera.CFrame.Position, part.Position)
            camera.CFrame = camera.CFrame:Lerp(desired, 0.12)
        end
    end
    if espEnabled then updateESP() end
    status.TextColor3 = selectedTarget and GREEN or MUTED
    status.Text = selectedTarget and ("Target: " .. selectedTarget.Name .. "\nSilent resolver is local-only") or "Practice targets only\nTag NPCs: TrainingTarget"
end)

script.Destroying:Connect(function()
    if renderConnection then renderConnection:Disconnect() end
    for model in pairs(highlights) do clearESP(model) end
end)
