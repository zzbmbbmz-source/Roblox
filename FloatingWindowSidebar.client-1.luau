--[[
    FloatingWindowSidebar.client.luau

    วางไฟล์นี้ใน StarterPlayerScripts เท่านั้น (client-only ล้วน ไม่ต้องมี server)

    เลย์เอาต์: Sidebar (แท็บซ้าย) + Content (เนื้อหาขวา)
    แท็บ: Main / Player / Visual / Misc

    แท็บ Player:
    - Walk Speed slider (0-200)
    - Jump Power slider (5-150)
    - Player List แบบ dropdown ค้นหาชื่อบางส่วนได้ (พิมพ์ "Rob" เจอ "Roblox")
      เลือกชื่อแล้วเทเลพอร์ตไปหาทันที
    - ปุ่ม Reset Character / Sit
    - ปุ่ม Give ClickToTP (สร้างไอเทมเทเลพอร์ตแบบคลิกที่พื้น)
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mouse = player:GetMouse()

--=====================================================
-- THEME: SCI-FI / NEON HUD
--=====================================================
local Theme = {
	Background = Color3.fromRGB(8, 14, 22),
	Surface = Color3.fromRGB(12, 22, 32),
	SurfaceLight = Color3.fromRGB(20, 34, 46),
	Sidebar = Color3.fromRGB(16, 26, 36),
	TitleBar = Color3.fromRGB(10, 18, 28),
	Accent = Color3.fromRGB(0, 225, 255),
	Secondary = Color3.fromRGB(190, 60, 255),
	TextPrimary = Color3.fromRGB(225, 250, 255),
	TextSecondary = Color3.fromRGB(120, 180, 195),
	Danger = Color3.fromRGB(255, 70, 95),
	Success = Color3.fromRGB(70, 255, 160),
	CornerRadius = UDim.new(0, 4),
	FontTitle = Enum.Font.RobotoMono,
	FontBody = Enum.Font.RobotoMono,
}

local WINDOW_WIDTH = 480
local WINDOW_HEIGHT = 420
local SIDEBAR_WIDTH = 120

--=====================================================
-- ROOT ScreenGui
--=====================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FloatingWindowSidebarGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 50
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

--=====================================================
-- Generic Drag Helper
--=====================================================
local function makeDraggable(dragHandle: GuiObject, targetFrame: GuiObject)
	local dragging = false
	local dragInput: InputObject? = nil
	local dragStart: Vector3? = nil
	local startPos: UDim2? = nil
	local moved = false
	local DRAG_THRESHOLD = 4

	local function update(input: InputObject)
		if not dragStart or not startPos then return end
		local delta = input.Position - dragStart
		if not moved and delta.Magnitude > DRAG_THRESHOLD then
			moved = true
		end
		targetFrame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end

	dragHandle.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			moved = false
			dragStart = input.Position
			startPos = targetFrame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	dragHandle.InputChanged:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input: InputObject)
		if dragging and input == dragInput then
			update(input)
		end
	end)

	return function()
		return moved
	end
end

--=====================================================
-- Toggle Button (☰ / ✕ ลากย้ายตำแหน่งได้อิสระ)
--=====================================================
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(0, 56, 0, 56)
toggleButton.Position = UDim2.new(1, -80, 1, -100)
toggleButton.BackgroundColor3 = Theme.Surface
toggleButton.BorderSizePixel = 0
toggleButton.Text = "MENU"
toggleButton.TextColor3 = Theme.Accent
toggleButton.Font = Theme.FontTitle
toggleButton.TextSize = 13
toggleButton.TextWrapped = true
toggleButton.AutoButtonColor = false
toggleButton.Parent = screenGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggleButton

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Theme.Accent
toggleStroke.Thickness = 1.5
toggleStroke.Transparency = 0.2
toggleStroke.Parent = toggleButton

local toggleGetWasDragged = makeDraggable(toggleButton, toggleButton)

toggleButton.MouseEnter:Connect(function()
	TweenService:Create(toggleStroke, TweenInfo.new(0.15), { Transparency = 0 }):Play()
end)
toggleButton.MouseLeave:Connect(function()
	TweenService:Create(toggleStroke, TweenInfo.new(0.15), { Transparency = 0.2 }):Play()
end)

--=====================================================
-- Main Window Frame
--=====================================================
local windowFrame = Instance.new("Frame")
windowFrame.Name = "WindowFrame"
windowFrame.Size = UDim2.new(0, WINDOW_WIDTH, 0, WINDOW_HEIGHT)
windowFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
windowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
windowFrame.BackgroundColor3 = Theme.Background
windowFrame.BorderSizePixel = 0
windowFrame.Visible = false
windowFrame.ClipsDescendants = true
windowFrame.Parent = screenGui

local windowCorner = Instance.new("UICorner")
windowCorner.CornerRadius = Theme.CornerRadius
windowCorner.Parent = windowFrame

local windowStroke = Instance.new("UIStroke")
windowStroke.Color = Theme.Accent
windowStroke.Thickness = 1.5
windowStroke.Transparency = 0.3
windowStroke.Parent = windowFrame

local windowStrokeGradient = Instance.new("UIGradient")
windowStrokeGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Theme.Accent),
	ColorSequenceKeypoint.new(0.5, Theme.Secondary),
	ColorSequenceKeypoint.new(1, Theme.Accent),
})
windowStrokeGradient.Parent = windowStroke

--=====================================================
-- Title Bar (เต็มความกว้างด้านบนสุด)
--=====================================================
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Theme.TitleBar
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 2
titleBar.Parent = windowFrame

local titleBarLine = Instance.new("Frame")
titleBarLine.Size = UDim2.new(1, 0, 0, 2)
titleBarLine.Position = UDim2.new(0, 0, 1, 0)
titleBarLine.BorderSizePixel = 0
titleBarLine.BackgroundColor3 = Theme.Accent
titleBarLine.ZIndex = 3
titleBarLine.Parent = titleBar

local titleBarLineGradient = Instance.new("UIGradient")
titleBarLineGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Theme.Accent),
	ColorSequenceKeypoint.new(0.5, Theme.Secondary),
	ColorSequenceKeypoint.new(1, Theme.Accent),
})
titleBarLineGradient.Parent = titleBarLine

local accentTab = Instance.new("Frame")
accentTab.Size = UDim2.new(0, 5, 1, -12)
accentTab.Position = UDim2.new(0, 12, 0, 6)
accentTab.BackgroundColor3 = Theme.Accent
accentTab.BorderSizePixel = 0
accentTab.ZIndex = 3
accentTab.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -80, 1, 0)
titleLabel.Position = UDim2.new(0, 28, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "SYSTEM // PANEL_01"
titleLabel.TextColor3 = Theme.TextPrimary
titleLabel.Font = Theme.FontTitle
titleLabel.TextSize = 14
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 3
titleLabel.Parent = titleBar

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 26, 0, 26)
closeButton.Position = UDim2.new(1, -34, 0.5, 0)
closeButton.AnchorPoint = Vector2.new(0, 0.5)
closeButton.BackgroundColor3 = Theme.Danger
closeButton.BackgroundTransparency = 0.85
closeButton.BorderSizePixel = 0
closeButton.Text = "X"
closeButton.TextColor3 = Theme.Danger
closeButton.Font = Theme.FontTitle
closeButton.TextSize = 13
closeButton.AutoButtonColor = false
closeButton.ZIndex = 3
closeButton.Parent = titleBar

local closeButtonCorner = Instance.new("UICorner")
closeButtonCorner.CornerRadius = UDim.new(0, 6)
closeButtonCorner.Parent = closeButton

closeButton.MouseEnter:Connect(function()
	TweenService:Create(closeButton, TweenInfo.new(0.15), { BackgroundTransparency = 0.5 }):Play()
end)
closeButton.MouseLeave:Connect(function()
	TweenService:Create(closeButton, TweenInfo.new(0.15), { BackgroundTransparency = 0.85 }):Play()
end)

makeDraggable(titleBar, windowFrame)

--=====================================================
-- Body (Sidebar ซ้าย + Content ขวา)
--=====================================================
local body = Instance.new("Frame")
body.Name = "Body"
body.Size = UDim2.new(1, 0, 1, -40)
body.Position = UDim2.new(0, 0, 0, 40)
body.BackgroundTransparency = 1
body.Parent = windowFrame

local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, SIDEBAR_WIDTH, 1, 0)
sidebar.BackgroundColor3 = Theme.Sidebar
sidebar.BorderSizePixel = 0
sidebar.Parent = body

local sidebarDivider = Instance.new("Frame")
sidebarDivider.Size = UDim2.new(0, 1, 1, 0)
sidebarDivider.Position = UDim2.new(1, 0, 0, 0)
sidebarDivider.BackgroundColor3 = Theme.Accent
sidebarDivider.BackgroundTransparency = 0.3
sidebarDivider.BorderSizePixel = 0
sidebarDivider.Parent = sidebar

local sidebarPadding = Instance.new("UIPadding")
sidebarPadding.PaddingTop = UDim.new(0, 10)
sidebarPadding.PaddingLeft = UDim.new(0, 8)
sidebarPadding.PaddingRight = UDim.new(0, 8)
sidebarPadding.Parent = sidebar

local sidebarLayout = Instance.new("UIListLayout")
sidebarLayout.Padding = UDim.new(0, 6)
sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
sidebarLayout.Parent = sidebar

local contentContainer = Instance.new("Frame")
contentContainer.Name = "ContentContainer"
contentContainer.Size = UDim2.new(1, -SIDEBAR_WIDTH, 1, 0)
contentContainer.Position = UDim2.new(0, SIDEBAR_WIDTH, 0, 0)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = body

--=====================================================
-- Tabs
--=====================================================
local TAB_NAMES = { "Main", "Player", "Visual", "Misc" }
local tabButtons: { [string]: TextButton } = {}
local tabContents: { [string]: ScrollingFrame } = {}

local function selectTab(tabName: string)
	for name, btn in tabButtons do
		local active = (name == tabName)
		TweenService:Create(btn, TweenInfo.new(0.15), {
			BackgroundColor3 = active and Color3.fromRGB(0, 45, 60) or Theme.Sidebar,
			TextColor3 = active and Theme.Accent or Theme.TextSecondary,
		}):Play()
		local indicator = btn:FindFirstChild("Indicator")
		if indicator then
			indicator.Visible = active
		end
	end
	for name, frame in tabContents do
		frame.Visible = (name == tabName)
	end
end

for i, tabName in ipairs(TAB_NAMES) do
	local btn = Instance.new("TextButton")
	btn.Name = tabName .. "Tab"
	btn.Size = UDim2.new(1, 0, 0, 34)
	btn.BackgroundColor3 = Theme.Sidebar
	btn.BorderSizePixel = 0
	btn.Text = string.upper(tabName)
	btn.TextColor3 = Theme.TextSecondary
	btn.Font = Theme.FontTitle
	btn.TextSize = 12
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.AutoButtonColor = false
	btn.LayoutOrder = i
	btn.Parent = sidebar
	tabButtons[tabName] = btn

	local btnPadding = Instance.new("UIPadding")
	btnPadding.PaddingLeft = UDim.new(0, 12)
	btnPadding.Parent = btn

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = btn

	local indicator = Instance.new("Frame")
	indicator.Name = "Indicator"
	indicator.Size = UDim2.new(0, 3, 1, -10)
	indicator.Position = UDim2.new(0, 0, 0.5, 0)
	indicator.AnchorPoint = Vector2.new(0, 0.5)
	indicator.BackgroundColor3 = Theme.Accent
	indicator.BorderSizePixel = 0
	indicator.Visible = false
	indicator.Parent = btn

	btn.Activated:Connect(function()
		selectTab(tabName)
	end)

	local contentFrame = Instance.new("ScrollingFrame")
	contentFrame.Name = tabName .. "Content"
	contentFrame.Size = UDim2.new(1, 0, 1, 0)
	contentFrame.BackgroundTransparency = 1
	contentFrame.BorderSizePixel = 0
	contentFrame.ScrollBarThickness = 4
	contentFrame.ScrollBarImageColor3 = Theme.Accent
	contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	contentFrame.Visible = false
	contentFrame.Parent = contentContainer
	tabContents[tabName] = contentFrame

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 18)
	padding.PaddingRight = UDim.new(0, 18)
	padding.PaddingTop = UDim.new(0, 16)
	padding.PaddingBottom = UDim.new(0, 16)
	padding.Parent = contentFrame

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 14)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = contentFrame
end

--=====================================================
-- Section label + placeholder helpers
--=====================================================
local function makeSectionLabel(parent: Instance, text: string, order: number)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 14)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Theme.TextSecondary
	label.Font = Theme.FontTitle
	label.TextSize = 11
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.LayoutOrder = order
	label.Parent = parent
	return label
end

for _, tabName in ipairs({ "Main", "Visual", "Misc" }) do
	local content = tabContents[tabName]
	makeSectionLabel(content, string.upper(tabName), 1)

	local placeholder = Instance.new("TextLabel")
	placeholder.Size = UDim2.new(1, 0, 0, 60)
	placeholder.BackgroundTransparency = 1
	placeholder.Text = "> แท็บนี้เว้นว่างไว้ ใส่ฟังก์ชันเพิ่มได้ภายหลัง"
	placeholder.TextColor3 = Theme.TextSecondary
	placeholder.Font = Theme.FontBody
	placeholder.TextSize = 13
	placeholder.TextWrapped = true
	placeholder.TextXAlignment = Enum.TextXAlignment.Left
	placeholder.TextYAlignment = Enum.TextYAlignment.Top
	placeholder.LayoutOrder = 2
	placeholder.Parent = content
end

--=====================================================
-- Slider Helper
--=====================================================
local function makeSlider(
	parent: Instance,
	order: number,
	labelText: string,
	min: number,
	max: number,
	default: number,
	onChanged: (value: number) -> ()
)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 46)
	row.BackgroundTransparency = 1
	row.LayoutOrder = order
	row.Parent = parent

	local headerRow = Instance.new("Frame")
	headerRow.Size = UDim2.new(1, 0, 0, 16)
	headerRow.BackgroundTransparency = 1
	headerRow.Parent = row

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.7, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = labelText
	nameLabel.TextColor3 = Theme.TextPrimary
	nameLabel.Font = Theme.FontTitle
	nameLabel.TextSize = 12
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = headerRow

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(0.3, 0, 1, 0)
	valueLabel.Position = UDim2.new(0.7, 0, 0, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = tostring(default)
	valueLabel.TextColor3 = Theme.Accent
	valueLabel.Font = Theme.FontTitle
	valueLabel.TextSize = 13
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Parent = headerRow

	local track = Instance.new("Frame")
	track.Name = "Track"
	track.Size = UDim2.new(1, 0, 0, 6)
	track.Position = UDim2.new(0, 0, 0, 26)
	track.BackgroundColor3 = Theme.Surface
	track.BorderSizePixel = 0
	track.Parent = row

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(1, 0)
	trackCorner.Parent = track

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = Theme.Accent
	fill.BorderSizePixel = 0
	fill.Parent = track

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	local fillGradient = Instance.new("UIGradient")
	fillGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Theme.Accent),
		ColorSequenceKeypoint.new(1, Theme.Secondary),
	})
	fillGradient.Parent = fill

	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.Size = UDim2.new(0, 16, 0, 16)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.new(0, 0, 0.5, 0)
	knob.BackgroundColor3 = Theme.TextPrimary
	knob.BorderSizePixel = 0
	knob.ZIndex = 4
	knob.Parent = track

	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(1, 0)
	knobCorner.Parent = knob

	local knobStroke = Instance.new("UIStroke")
	knobStroke.Color = Theme.Accent
	knobStroke.Thickness = 2
	knobStroke.Parent = knob

	local function setValue(value: number, fireCallback: boolean?)
		value = math.clamp(value, min, max)
		local alpha = (value - min) / (max - min)
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		knob.Position = UDim2.new(alpha, 0, 0.5, 0)
		valueLabel.Text = tostring(math.floor(value))
		if fireCallback ~= false then
			onChanged(value)
		end
	end

	local dragging = false

	local function updateFromInputX(inputX: number)
		local trackPos = track.AbsolutePosition.X
		local trackWidth = track.AbsoluteSize.X
		local alpha = math.clamp((inputX - trackPos) / trackWidth, 0, 1)
		setValue(min + alpha * (max - min))
	end

	knob.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
		end
	end)

	track.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateFromInputX(input.Position.X)
		end
	end)

	UserInputService.InputChanged:Connect(function(input: InputObject)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromInputX(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	setValue(default, false)

	return setValue
end

--=====================================================
-- PLAYER tab
--=====================================================
do
	local playerContent = tabContents["Player"]

	local function getHumanoid(): Humanoid?
		local character = player.Character
		return character and character:FindFirstChildOfClass("Humanoid")
	end

	makeSectionLabel(playerContent, "MOVEMENT", 1)
	makeSlider(playerContent, 2, "Walk Speed", 0, 200, 16, function(value)
		local humanoid = getHumanoid()
		if humanoid then
			humanoid.WalkSpeed = value
		end
	end)
	makeSlider(playerContent, 3, "Jump Power", 5, 150, 50, function(value)
		local humanoid = getHumanoid()
		if humanoid then
			humanoid.JumpPower = value
		end
	end)

	--=====================================================
	-- Player List: dropdown แบบกดเปิด/ปิด แสดงรายชื่อผู้เล่นทั้งหมด
	-- กดที่กล่องเพื่อเปิดลิสต์ กดชื่อใครก็เทเลพอร์ตไปหาคนนั้นทันที
	--=====================================================
	makeSectionLabel(playerContent, "PLAYER LIST", 4)

	local dropdownRow = Instance.new("Frame")
	dropdownRow.Size = UDim2.new(1, 0, 0, 0)
	dropdownRow.AutomaticSize = Enum.AutomaticSize.Y
	dropdownRow.BackgroundTransparency = 1
	dropdownRow.LayoutOrder = 5
	dropdownRow.Parent = playerContent

	local dropdownLayout = Instance.new("UIListLayout")
	dropdownLayout.Padding = UDim.new(0, 6)
	dropdownLayout.SortOrder = Enum.SortOrder.LayoutOrder
	dropdownLayout.Parent = dropdownRow

	-- กล่องหัว dropdown: แสดงชื่อที่เลือกอยู่ + ลูกศร กดเพื่อเปิด/ปิดลิสต์
	local dropdownHeader = Instance.new("TextButton")
	dropdownHeader.Name = "DropdownHeader"
	dropdownHeader.Size = UDim2.new(1, 0, 0, 36)
	dropdownHeader.BackgroundColor3 = Theme.Surface
	dropdownHeader.BorderSizePixel = 0
	dropdownHeader.Text = ""
	dropdownHeader.AutoButtonColor = false
	dropdownHeader.LayoutOrder = 1
	dropdownHeader.Parent = dropdownRow

	local dropdownHeaderCorner = Instance.new("UICorner")
	dropdownHeaderCorner.CornerRadius = UDim.new(0, 6)
	dropdownHeaderCorner.Parent = dropdownHeader

	local dropdownHeaderStroke = Instance.new("UIStroke")
	dropdownHeaderStroke.Color = Theme.Accent
	dropdownHeaderStroke.Transparency = 0.5
	dropdownHeaderStroke.Thickness = 1
	dropdownHeaderStroke.Parent = dropdownHeader

	local selectedLabel = Instance.new("TextLabel")
	selectedLabel.Name = "SelectedLabel"
	selectedLabel.Size = UDim2.new(1, -40, 1, 0)
	selectedLabel.Position = UDim2.new(0, 12, 0, 0)
	selectedLabel.BackgroundTransparency = 1
	selectedLabel.Text = "เลือกผู้เล่น..."
	selectedLabel.TextColor3 = Theme.TextSecondary
	selectedLabel.Font = Theme.FontBody
	selectedLabel.TextSize = 13
	selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
	selectedLabel.TextTruncate = Enum.TextTruncate.AtEnd
	selectedLabel.Parent = dropdownHeader

	local dropdownArrow = Instance.new("TextLabel")
	dropdownArrow.Name = "Arrow"
	dropdownArrow.Size = UDim2.new(0, 24, 1, 0)
	dropdownArrow.Position = UDim2.new(1, -30, 0, 0)
	dropdownArrow.BackgroundTransparency = 1
	dropdownArrow.Text = "v"
	dropdownArrow.TextColor3 = Theme.Accent
	dropdownArrow.Font = Theme.FontTitle
	dropdownArrow.TextSize = 11
	dropdownArrow.Parent = dropdownHeader

	-- ลิสต์รายชื่อผู้เล่นทั้งหมด (แสดง/ซ่อนเมื่อกดกล่องหัว)
	local resultsList = Instance.new("Frame")
	resultsList.Name = "ResultsList"
	resultsList.Size = UDim2.new(1, 0, 0, 0)
	resultsList.AutomaticSize = Enum.AutomaticSize.Y
	resultsList.BackgroundTransparency = 1
	resultsList.Visible = false
	resultsList.LayoutOrder = 2
	resultsList.Parent = dropdownRow

	local resultsLayout = Instance.new("UIListLayout")
	resultsLayout.Padding = UDim.new(0, 4)
	resultsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	resultsLayout.Parent = resultsList

	local dropdownOpen = false

	-- ฟังก์ชันเทเลพอร์ตไปหาผู้เล่นเป้าหมาย
	local function teleportToPlayer(targetPlayer: Player)
		local myCharacter = player.Character
		local targetCharacter = targetPlayer.Character
		if not myCharacter or not targetCharacter then
			return false
		end
		local myRoot = myCharacter:FindFirstChild("HumanoidRootPart") :: BasePart?
		local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart") :: BasePart?
		if myRoot and targetRoot then
			myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, -4)
			return true
		end
		return false
	end

	local function setDropdownOpen(open: boolean)
		dropdownOpen = open
		resultsList.Visible = open
		dropdownArrow.Text = open and "^" or "v"
	end

	-- สร้างลิสต์รายชื่อผู้เล่นทั้งหมดใหม่ทุกครั้งที่เปิด (กันชื่อไม่อัปเดต)
	local function rebuildResultsList()
		for _, child in resultsList:GetChildren() do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end

		local others = {}
		for _, candidate in Players:GetPlayers() do
			if candidate ~= player then
				table.insert(others, candidate)
			end
		end

		for i, targetPlayer in others do
			local btn = Instance.new("TextButton")
			btn.Name = targetPlayer.Name
			btn.Size = UDim2.new(1, 0, 0, 32)
			btn.BackgroundColor3 = Theme.Surface
			btn.BorderSizePixel = 0
			btn.Text = "> " .. targetPlayer.Name
			btn.TextColor3 = Theme.TextPrimary
			btn.Font = Theme.FontBody
			btn.TextSize = 13
			btn.TextXAlignment = Enum.TextXAlignment.Left
			btn.AutoButtonColor = false
			btn.LayoutOrder = i
			btn.Parent = resultsList

			local btnPadding = Instance.new("UIPadding")
			btnPadding.PaddingLeft = UDim.new(0, 10)
			btnPadding.Parent = btn

			local btnCorner = Instance.new("UICorner")
			btnCorner.CornerRadius = UDim.new(0, 6)
			btnCorner.Parent = btn

			btn.MouseEnter:Connect(function()
				TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.SurfaceLight }):Play()
			end)
			btn.MouseLeave:Connect(function()
				TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.Surface }):Play()
			end)

			btn.Activated:Connect(function()
				local success = teleportToPlayer(targetPlayer)
				selectedLabel.Text = targetPlayer.Name
				selectedLabel.TextColor3 = Theme.TextPrimary
				setDropdownOpen(false)
				if not success then
					warn(`[Panel] เทเลพอร์ตไปหา {targetPlayer.Name} ไม่สำเร็จ (ไม่พบ character)`)
				end
			end)
		end

		if #others == 0 then
			local emptyLabel = Instance.new("TextLabel")
			emptyLabel.Size = UDim2.new(1, 0, 0, 28)
			emptyLabel.BackgroundTransparency = 1
			emptyLabel.Text = "ไม่มีผู้เล่นคนอื่นในเซิร์ฟเวอร์"
			emptyLabel.TextColor3 = Theme.TextSecondary
			emptyLabel.Font = Theme.FontBody
			emptyLabel.TextSize = 12
			emptyLabel.TextXAlignment = Enum.TextXAlignment.Left
			emptyLabel.Parent = resultsList
		end
	end

	dropdownHeader.Activated:Connect(function()
		if not dropdownOpen then
			rebuildResultsList()
		end
		setDropdownOpen(not dropdownOpen)
	end)

	-- ถ้ามีคนเข้า/ออกระหว่างที่ dropdown เปิดอยู่ ให้รีเฟรชลิสต์ทันที
	Players.PlayerAdded:Connect(function()
		if dropdownOpen then
			rebuildResultsList()
		end
	end)
	Players.PlayerRemoving:Connect(function()
		if dropdownOpen then
			task.defer(rebuildResultsList)
		end
	end)

	--=====================================================
	-- ปุ่มฟังก์ชันด่วน: Reset Character / Sit
	--=====================================================
	makeSectionLabel(playerContent, "QUICK ACTIONS", 6)

	local quickActionsRow = Instance.new("Frame")
	quickActionsRow.Size = UDim2.new(1, 0, 0, 36)
	quickActionsRow.BackgroundTransparency = 1
	quickActionsRow.LayoutOrder = 7
	quickActionsRow.Parent = playerContent

	local quickActionsLayout = Instance.new("UIListLayout")
	quickActionsLayout.FillDirection = Enum.FillDirection.Horizontal
	quickActionsLayout.Padding = UDim.new(0, 8)
	quickActionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	quickActionsLayout.Parent = quickActionsRow

	local function makeQuickButton(text: string, order: number, onClick: () -> ())
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0.5, -4, 1, 0)
		btn.BackgroundColor3 = Theme.Surface
		btn.BorderSizePixel = 0
		btn.Text = string.upper(text)
		btn.TextColor3 = Theme.Accent
		btn.Font = Theme.FontTitle
		btn.TextSize = 12
		btn.AutoButtonColor = false
		btn.LayoutOrder = order
		btn.Parent = quickActionsRow

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = btn

		local stroke = Instance.new("UIStroke")
		stroke.Color = Theme.Accent
		stroke.Transparency = 0.5
		stroke.Thickness = 1
		stroke.Parent = btn

		btn.MouseEnter:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.SurfaceLight }):Play()
		end)
		btn.MouseLeave:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.Surface }):Play()
		end)

		btn.Activated:Connect(onClick)
		return btn
	end

	makeQuickButton("Reset Character", 1, function()
		local humanoid = getHumanoid()
		if humanoid then
			humanoid.Health = 0
		end
	end)

	makeQuickButton("Sit", 2, function()
		local humanoid = getHumanoid()
		if humanoid then
			humanoid.Sit = true
		end
	end)

	--=====================================================
	-- ปุ่ม Give ClickToTP (ต่อยอดจากโค้ดที่ให้มา)
	--=====================================================
	makeSectionLabel(playerContent, "ITEMS", 8)

	local giveButton = Instance.new("TextButton")
	giveButton.Size = UDim2.new(1, 0, 0, 38)
	giveButton.BackgroundColor3 = Theme.Surface
	giveButton.BorderSizePixel = 0
	giveButton.Text = "GIVE CLICKTOTP"
	giveButton.TextColor3 = Theme.Accent
	giveButton.Font = Theme.FontTitle
	giveButton.TextSize = 13
	giveButton.AutoButtonColor = false
	giveButton.LayoutOrder = 9
	giveButton.Parent = playerContent

	local giveButtonCorner = Instance.new("UICorner")
	giveButtonCorner.CornerRadius = UDim.new(0, 6)
	giveButtonCorner.Parent = giveButton

	local giveButtonStroke = Instance.new("UIStroke")
	giveButtonStroke.Color = Theme.Accent
	giveButtonStroke.Transparency = 0.5
	giveButtonStroke.Thickness = 1
	giveButtonStroke.Parent = giveButton

	giveButton.MouseEnter:Connect(function()
		TweenService:Create(giveButton, TweenInfo.new(0.15), { BackgroundColor3 = Theme.SurfaceLight }):Play()
	end)
	giveButton.MouseLeave:Connect(function()
		TweenService:Create(giveButton, TweenInfo.new(0.15), { BackgroundColor3 = Theme.Surface }):Play()
	end)

	local function createClickToTPTool()
		local existingInBackpack = player.Backpack:FindFirstChild("ClickToTP")
		local existingEquipped = player.Character and player.Character:FindFirstChild("ClickToTP")
		if existingInBackpack or existingEquipped then
			return false
		end

		local tool = Instance.new("Tool")
		tool.Name = "ClickToTP"
		tool.RequiresHandle = false
		tool.CanBeDropped = false

		-- ลอจิกจากโค้ดตัวอย่างที่ให้มา: คลิกที่พื้น = เทเลพอร์ตตัวเองไปจุดนั้น
		tool.Activated:Connect(function()
			if mouse.Hit then
				local pos = mouse.Hit.Position + Vector3.new(0, 2.5, 0)
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if root then
					root.CFrame = CFrame.new(pos)
				end
			end
		end)

		tool.Parent = player.Backpack
		return true
	end

	giveButton.Activated:Connect(function()
		createClickToTPTool()
	end)
end

--=====================================================
-- เปิด/ปิด ด้วย Tween และสลับข้อความปุ่ม toggle
--=====================================================
local isOpen = false
local openTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local closeTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local OPEN_SIZE = UDim2.new(0, WINDOW_WIDTH, 0, WINDOW_HEIGHT)
local CLOSED_SIZE = UDim2.new(0, WINDOW_WIDTH, 0, 0)

local function openWindow()
	if isOpen then return end
	isOpen = true
	windowFrame.Size = CLOSED_SIZE
	windowFrame.Visible = true
	toggleButton.Text = "X"
	TweenService:Create(windowFrame, openTweenInfo, { Size = OPEN_SIZE }):Play()
end

local function closeWindow()
	if not isOpen then return end
	isOpen = false
	toggleButton.Text = "MENU"
	local tween = TweenService:Create(windowFrame, closeTweenInfo, { Size = CLOSED_SIZE })
	tween:Play()
	tween.Completed:Connect(function()
		if not isOpen then
			windowFrame.Visible = false
		end
	end)
end

toggleButton.MouseButton1Click:Connect(function()
	if toggleGetWasDragged() then return end
	if isOpen then
		closeWindow()
	else
		openWindow()
	end
end)

closeButton.Activated:Connect(closeWindow)

selectTab("Main")
