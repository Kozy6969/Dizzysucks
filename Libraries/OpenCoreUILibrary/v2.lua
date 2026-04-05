local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Mouse = Players.LocalPlayer:GetMouse()

-- Try CoreGui first then playergui
local function GetGuiParent()
	local success, result = pcall(function()
		return game:GetService("CoreGui")
	end)

	if success and result then
		local test = Instance.new("Folder")
		local canUse = pcall(function()
			test.Parent = result
			test:Destroy()
		end)

		if canUse then
			return result
		end
	end

	return Players.LocalPlayer:WaitForChild("PlayerGui")
end

-- Icons
local Icons = {
	Close = "rbxassetid://11293981586",
	Minimize = "rbxassetid://11293980042",
	ChevronDown = "rbxassetid://12974428978",
}

local OpenCore = {
	Flags = {},
	CurrentTheme = "Dark",
	Themes = {
		Dark = {
			Primary = Color3.fromRGB(255, 255, 255),
			Secondary = Color3.fromRGB(200, 200, 200),
			Accent = Color3.fromRGB(180, 180, 180),

			Background = Color3.fromRGB(15, 15, 15),
			Surface = Color3.fromRGB(20, 20, 20),
			Card = Color3.fromRGB(25, 25, 25),

			Text = Color3.fromRGB(255, 255, 255),
			SubText = Color3.fromRGB(160, 160, 160),
			Muted = Color3.fromRGB(100, 100, 100),

			Success = Color3.fromRGB(120, 120, 120),

			Border = Color3.fromRGB(40, 40, 40),
			Hover = Color3.fromRGB(35, 35, 35),
			SliderFill = Color3.fromRGB(255, 255, 255),

			ToggleFill = Color3.fromRGB(25, 25, 25)
		},
		Light = {
			Primary = Color3.fromRGB(30, 30, 30),
			Secondary = Color3.fromRGB(60, 60, 60),
			Accent = Color3.fromRGB(80, 80, 80),

			Background = Color3.fromRGB(245, 245, 245),
			Surface = Color3.fromRGB(255, 255, 255),
			Card = Color3.fromRGB(248, 248, 248),

			Text = Color3.fromRGB(20, 20, 20),
			SubText = Color3.fromRGB(100, 100, 100),
			Muted = Color3.fromRGB(150, 150, 150),

			Success = Color3.fromRGB(59, 130, 246),

			Border = Color3.fromRGB(220, 220, 220),
			Hover = Color3.fromRGB(235, 235, 235),
			SliderFill = Color3.fromRGB(59, 130, 246),

			ToggleFill = Color3.fromRGB(202, 202, 202)
		},
	}
}

local Theme = OpenCore.Themes[OpenCore.CurrentTheme]

local function Tween(obj, props, duration)
	duration = duration or 0.2
	TweenService:Create(obj, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function MakeDraggable(frame, handle)
	local dragging = false
	local dragInput, dragStart, startPos

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
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

	handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
end

local function AddCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 4)
	corner.Parent = parent
	return corner
end

local function AddStroke(parent, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Theme.Border
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0
	stroke.Parent = parent
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return stroke
end

local function RGBtoHSV(r, g, b)
	r, g, b = r / 255, g / 255, b / 255
	local max, min = math.max(r, g, b), math.min(r, g, b)
	local h, s, v
	v = max

	local d = max - min
	if max == 0 then s = 0 else s = d / max end

	if max == min then
		h = 0
	else
		if max == r then
			h = (g - b) / d
			if g < b then h = h + 6 end
		elseif max == g then
			h = (g - b) / d + 2
		elseif max == b then
			h = (r - g) / d + 4
		end
		h = h / 6
	end

	return math.floor(h * 360), math.floor(s * 100), math.floor(v * 100)
end

local function HSVtoRGB(h, s, v)
	h, s, v = h / 360, s / 100, v / 100
	local r, g, b

	local i = math.floor(h * 6)
	local f = h * 6 - i
	local p = v * (1 - s)
	local q = v * (1 - f * s)
	local t = v * (1 - (1 - f) * s)

	i = i % 6

	if i == 0 then r, g, b = v, t, p
	elseif i == 1 then r, g, b = q, v, p
	elseif i == 2 then r, g, b = p, v, t
	elseif i == 3 then r, g, b = p, q, v
	elseif i == 4 then r, g, b = t, p, v
	elseif i == 5 then r, g, b = v, p, q
	end

	return math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)
end

local function ColorToHex(color)
	return string.format("#%02X%02X%02X", 
		math.floor(color.R * 255),
		math.floor(color.G * 255),
		math.floor(color.B * 255)
	)
end

-- KeySystem
local KeySystemShown = false

local function CreateKeySystem(config, callback, theme)
	if KeySystemShown then
		callback(true) -- Already verified, skip
		return
	end

	local GuiParent = GetGuiParent()

	local KeySystemGui = Instance.new("ScreenGui")
	KeySystemGui.Name = "KeySystem"
	KeySystemGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	KeySystemGui.Parent = GuiParent

	local Overlay = Instance.new("Frame")
	Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Overlay.BackgroundTransparency = 0.5
	Overlay.BorderSizePixel = 0
	Overlay.Size = UDim2.new(1.5, 0, 1.5, 0)
	Overlay.Parent = KeySystemGui

	local MainFrame = Instance.new("Frame")
	MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	MainFrame.BackgroundColor3 = theme.Background
	MainFrame.BorderSizePixel = 0
	MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	MainFrame.Size = UDim2.new(0, 0, 0, 0)
	MainFrame.ClipsDescendants = true
	MainFrame.Parent = KeySystemGui

	AddCorner(MainFrame, 8)
	AddStroke(MainFrame, theme.Border, 1, 0)

	local TopBar = Instance.new("Frame")
	TopBar.BackgroundColor3 = theme.Surface
	TopBar.BorderSizePixel = 0
	TopBar.Size = UDim2.new(1, 0, 0, 50)
	TopBar.Parent = MainFrame

	AddCorner(TopBar, 8)

	local TopBarFix = Instance.new("Frame")
	TopBarFix.BackgroundColor3 = theme.Surface
	TopBarFix.BorderSizePixel = 0
	TopBarFix.Position = UDim2.new(0, 0, 1, -8)
	TopBarFix.Size = UDim2.new(1, 0, 0, 8)
	TopBarFix.Parent = TopBar

	local TopBarBorder = Instance.new("Frame")
	TopBarBorder.BackgroundColor3 = theme.Border
	TopBarBorder.BorderSizePixel = 0
	TopBarBorder.Position = UDim2.new(0, 0, 1, -1)
	TopBarBorder.Size = UDim2.new(1, 0, 0, 1)
	TopBarBorder.Parent = TopBar

	local Title = Instance.new("TextLabel")
	Title.BackgroundTransparency = 1
	Title.Position = UDim2.new(0, 20, 0, 0)
	Title.Size = UDim2.new(1, -40, 1, 0)
	Title.Font = Enum.Font.GothamBold
	Title.Text = config.WindowTitle or "Key System"
	Title.TextColor3 = theme.Text
	Title.TextSize = 16
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.Parent = TopBar

	local SubTitle = Instance.new("TextLabel")
	SubTitle.BackgroundTransparency = 1
	SubTitle.Position = UDim2.new(0, 20, 0, 60)
	SubTitle.Size = UDim2.new(1, -40, 0, 26)
	SubTitle.Font = Enum.Font.GothamBold
	SubTitle.Text = "Key System"
	SubTitle.TextColor3 = theme.Text
	SubTitle.TextSize = 18
	SubTitle.TextXAlignment = Enum.TextXAlignment.Left
	SubTitle.Parent = MainFrame

	local Description = Instance.new("TextLabel")
	Description.BackgroundTransparency = 1
	Description.Position = UDim2.new(0, 20, 0, 90)
	Description.Size = UDim2.new(1, -40, 0, 45)
	Description.Font = Enum.Font.Gotham
	Description.Text = config.KeyDescription or "Please enter your key to continue"
	Description.TextColor3 = theme.SubText
	Description.TextSize = 13
	Description.TextWrapped = true
	Description.TextXAlignment = Enum.TextXAlignment.Left
	Description.TextYAlignment = Enum.TextYAlignment.Top
	Description.Parent = MainFrame

	local InputFrame = Instance.new("Frame")
	InputFrame.BackgroundColor3 = theme.Card
	InputFrame.BorderSizePixel = 0
	InputFrame.Position = UDim2.new(0, 20, 0, 145)
	InputFrame.Size = UDim2.new(1, -40, 0, 42)
	InputFrame.Parent = MainFrame

	AddCorner(InputFrame, 6)
	AddStroke(InputFrame, theme.Border, 1, 0)

	local InputBox = Instance.new("TextBox")
	InputBox.BackgroundTransparency = 1
	InputBox.Position = UDim2.new(0, 12, 0, 0)
	InputBox.Size = UDim2.new(1, -24, 1, 0)
	InputBox.Font = Enum.Font.Gotham
	InputBox.PlaceholderText = "Enter key..."
	InputBox.PlaceholderColor3 = theme.Muted
	InputBox.Text = ""
	InputBox.TextColor3 = theme.Text
	InputBox.TextSize = 16
	InputBox.TextXAlignment = Enum.TextXAlignment.Left
	InputBox.ClearTextOnFocus = false
	InputBox.Parent = InputFrame

	local MessageFrame = Instance.new("Frame")
	MessageFrame.BackgroundTransparency = 1
	MessageFrame.Position = UDim2.new(0, 20, 0, 195)
	MessageFrame.Size = UDim2.new(1, -40, 0, 30)
	MessageFrame.ClipsDescendants = false
	MessageFrame.Parent = MainFrame

	local ErrorMessage = Instance.new("TextLabel")
	ErrorMessage.BackgroundTransparency = 1
	ErrorMessage.Position = UDim2.new(0, 0, 0, -50)
	ErrorMessage.Size = UDim2.new(1, 0, 1, 0)
	ErrorMessage.Font = Enum.Font.GothamBold
	ErrorMessage.Text = ""
	ErrorMessage.TextColor3 = Color3.fromRGB(244, 67, 54)
	ErrorMessage.TextSize = 12
	ErrorMessage.TextXAlignment = Enum.TextXAlignment.Center
	ErrorMessage.Parent = MessageFrame

	local function showMessage(text, isSuccess)
		ErrorMessage.Text = text
		ErrorMessage.TextColor3 = isSuccess and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(244, 67, 54)
		ErrorMessage.Position = UDim2.new(0, 0, 0, -5)

		local tween = TweenService:Create(ErrorMessage, 
			TweenInfo.new(0.4, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
			{Position = UDim2.new(0, 0, 0, 0)}
		)
		tween:Play()

		task.spawn(function()
			wait(3)
			TweenService:Create(ErrorMessage,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{Position = UDim2.new(0, 0, 0, -5)}
			):Play()
		end)
	end

	local ButtonContainer = Instance.new("Frame")
	ButtonContainer.BackgroundTransparency = 1
	ButtonContainer.Position = UDim2.new(0, 20, 0, 230)
	ButtonContainer.Size = UDim2.new(1, -40, 0, 38)
	ButtonContainer.Parent = MainFrame

	local ButtonLayout = Instance.new("UIListLayout")
	ButtonLayout.FillDirection = Enum.FillDirection.Horizontal
	ButtonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	ButtonLayout.Padding = UDim.new(0, 10)
	ButtonLayout.Parent = ButtonContainer

	local function CreateButton(text, isPrimary)
		local Button = Instance.new("TextButton")
		Button.BackgroundColor3 = isPrimary and theme.Success or theme.Card
		Button.BorderSizePixel = 0
		Button.Size = UDim2.new(0, 100, 0, 38)
		Button.Font = Enum.Font.GothamMedium
		Button.Text = text
		Button.TextColor3 = theme.Text
		Button.TextSize = 13
		Button.TextScaled = true
		Button.AutoButtonColor = false
		Button.Parent = ButtonContainer

		AddCorner(Button, 6)

		Button.MouseEnter:Connect(function()
			Tween(Button, {BackgroundColor3 = isPrimary and theme.Accent or theme.Hover}, 0.15)
		end)

		Button.MouseLeave:Connect(function()
			Tween(Button, {BackgroundColor3 = isPrimary and theme.Success or theme.Card}, 0.15)
		end)

		return Button
	end

	local GetKeyButton = CreateButton("Get Key", false)
	local SubmitButton = CreateButton("Submit", true)

	GetKeyButton.MouseButton1Click:Connect(function()
		setclipboard(config.KeyLink or "https://example.com/getkey")
		showMessage("Key link copied to clipboard!", true)
	end)

	local function verifyKey(enteredKey)
		if enteredKey == config.KeySystem or enteredKey == config.Key then
			showMessage("Key verified! Loading...", true)
			KeySystemShown = true
			wait(0.8)
			Tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.3)
			wait(0.3)
			KeySystemGui:Destroy()
			callback(true)
		else
			showMessage("Invalid key. Please try again.", false)
			InputBox.Text = ""
		end
	end

	SubmitButton.MouseButton1Click:Connect(function()
		verifyKey(InputBox.Text)
	end)

	InputBox.FocusLost:Connect(function(enterPressed)
		if enterPressed and InputBox.Text ~= "" then
			verifyKey(InputBox.Text)
		end
	end)

	local KeySystemAPI = {}
	function KeySystemAPI:EnterKey(key)
		InputBox.Text = key
		verifyKey(key)
	end

	Tween(MainFrame, {Size = UDim2.new(0, 400, 0, 290)}, 0.3)
	wait(0.3)
	InputBox:CaptureFocus()

	return KeySystemAPI
end
-- Font fallback helper (global so it's accessible everywhere)
local function GetFont(baseFont, fontType)
	local fonts = {
		Bold = baseFont == Enum.Font.Gotham and Enum.Font.GothamBold or (baseFont == Enum.Font.SourceSans and Enum.Font.SourceSansBold or Enum.Font.GothamBold),
		Medium = baseFont == Enum.Font.Gotham and Enum.Font.GothamMedium or (baseFont == Enum.Font.SourceSans and Enum.Font.SourceSans or Enum.Font.GothamMedium),
		Regular = baseFont == Enum.Font.Gotham and Enum.Font.Gotham or (baseFont == Enum.Font.SourceSans and Enum.Font.SourceSans or Enum.Font.Gotham)
	}
	return fonts[fontType] or baseFont
end

-- Create Window
function OpenCore:CreateWindow(config)
	config = config or {}
	config.Title = config.Title or "OpenCore"
	config.Subtitle = config.Subtitle or "Modern UI Library"
	config.Size = config.Size or UDim2.new(0, 700, 0, 550)
	config.Theme = config.Theme or "Dark"
	config.Font = config.Font or Enum.Font.Gotham

	-- Set theme
	OpenCore.CurrentTheme = config.Theme
	Theme = OpenCore.Themes[OpenCore.CurrentTheme]

	local Window = {
		Tabs = {},
		CurrentTab = nil,
		Theme = Theme,
		_initialized = false,
		Font = config.Font
	}

	function Window:CreateTab(...)
		while not self._initialized do
			task.wait(0.1)
		end
		return self.CreateTab(...)
	end

	local function InitializeWindow()
		local GuiParent = GetGuiParent()

		-- Cleanup
		if GuiParent:FindFirstChild("OpenCore") then
			GuiParent:FindFirstChild("OpenCore"):Destroy()
		end

		local gui = Instance.new("ScreenGui")
		gui.Name = "OpenCore"
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.Parent = GuiParent

		local main = Instance.new("Frame")
		main.Name = "Main"
		main.AnchorPoint = Vector2.new(0.5, 0)
		main.BackgroundColor3 = Theme.Background
		main.BorderSizePixel = 0
		main.Position = UDim2.new(0.5, 0, 0.5, -config.Size.Y.Offset/2)
		main.Size = config.Size
		main.ClipsDescendants = true
		main.Parent = gui

		AddCorner(main, 6)
		AddStroke(main, Theme.Border, 1, 0)

		-- Top Bar
		local topBar = Instance.new("Frame")
		topBar.Name = "TopBar"
		topBar.BackgroundColor3 = Theme.Surface
		topBar.BorderSizePixel = 0
		topBar.Size = UDim2.new(1, 0, 0, 50)
		topBar.Parent = main

		AddCorner(topBar, 6)

		local topBarFix = Instance.new("Frame")
		topBarFix.BackgroundColor3 = Theme.Surface
		topBarFix.BorderSizePixel = 0
		topBarFix.Position = UDim2.new(0, 0, 1, -6)
		topBarFix.Size = UDim2.new(1, 0, 0, 6)
		topBarFix.Parent = topBar

		local bottomLine = Instance.new("Frame")
		bottomLine.BackgroundColor3 = Theme.Border
		bottomLine.BorderSizePixel = 0
		bottomLine.Position = UDim2.new(0, 0, 1, -1)
		bottomLine.Size = UDim2.new(1, 0, 0, 1)
		bottomLine.Parent = topBar

		-- Title
		local title = Instance.new("TextLabel")
		title.BackgroundTransparency = 1
		title.Font = GetFont(config.Font, "Bold")
		title.Text = config.Title
		title.TextColor3 = Theme.Text
		title.TextSize = 16
		title.Position = UDim2.new(0, 15, 0, 8)
		title.Size = UDim2.new(0, 300, 0, 20)
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Parent = topBar

		-- Subtitle
		local subtitle = Instance.new("TextLabel")
		subtitle.BackgroundTransparency = 1
		subtitle.Font = GetFont(config.Font, "Regular")
		subtitle.Text = config.Subtitle
		subtitle.TextColor3 = Theme.SubText
		subtitle.TextSize = 12
		subtitle.Position = UDim2.new(0, 15, 0, 28)
		subtitle.Size = UDim2.new(1, -30, 0, 0)
		subtitle.AutomaticSize = Enum.AutomaticSize.Y
		subtitle.TextWrapped = true
		subtitle.TextXAlignment = Enum.TextXAlignment.Left
		subtitle.TextYAlignment = Enum.TextYAlignment.Top
		subtitle.Parent = topBar

		-- Close
		local closeBtn = Instance.new("TextButton")
		closeBtn.AnchorPoint = Vector2.new(1, 0.5)
		closeBtn.BackgroundColor3 = Theme.Card
		closeBtn.BorderSizePixel = 0
		closeBtn.Position = UDim2.new(1, -10, 0.5, 0)
		closeBtn.Size = UDim2.new(0, 30, 0, 30)
		closeBtn.Text = ""
		closeBtn.Parent = topBar

		AddCorner(closeBtn, 4)

		local closeIcon = Instance.new("ImageLabel")
		closeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		closeIcon.BackgroundTransparency = 1
		closeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
		closeIcon.Size = UDim2.new(0, 16, 0, 16)
		closeIcon.Image = Icons.Close
		closeIcon.ImageColor3 = Theme.SubText
		closeIcon.Parent = closeBtn

		closeBtn.MouseEnter:Connect(function()
			Tween(closeBtn, {BackgroundColor3 = Color3.fromRGB(239, 68, 68)}, 0.2)
			Tween(closeIcon, {ImageColor3 = Color3.fromRGB(255, 255, 255)}, 0.2)
		end)

		closeBtn.MouseLeave:Connect(function()
			Tween(closeBtn, {BackgroundColor3 = Theme.Card}, 0.2)
			Tween(closeIcon, {ImageColor3 = Theme.SubText}, 0.2)
		end)

		closeBtn.MouseButton1Click:Connect(function()
			gui:Destroy()
		end)

		-- Minimize
		local minimizeBtn = Instance.new("TextButton")
		minimizeBtn.AnchorPoint = Vector2.new(1, 0.5)
		minimizeBtn.BackgroundColor3 = Theme.Card
		minimizeBtn.BorderSizePixel = 0
		minimizeBtn.Position = UDim2.new(1, -45, 0.5, 0)
		minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
		minimizeBtn.Text = ""
		minimizeBtn.Parent = topBar

		AddCorner(minimizeBtn, 4)

		local minimizeIcon = Instance.new("ImageLabel")
		minimizeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		minimizeIcon.BackgroundTransparency = 1
		minimizeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
		minimizeIcon.Size = UDim2.new(0, 16, 0, 16)
		minimizeIcon.Image = Icons.Minimize
		minimizeIcon.ImageColor3 = Theme.SubText
		minimizeIcon.Parent = minimizeBtn

		local minimized = false
		minimizeBtn.MouseEnter:Connect(function()
			Tween(minimizeBtn, {BackgroundColor3 = Theme.Hover}, 0.2)
			Tween(minimizeIcon, {ImageColor3 = Theme.Text}, 0.2)
		end)

		minimizeBtn.MouseLeave:Connect(function()
			Tween(minimizeBtn, {BackgroundColor3 = Theme.Card}, 0.2)
			Tween(minimizeIcon, {ImageColor3 = Theme.SubText}, 0.2)
		end)

		-- Sidebar
		local sidebar = Instance.new("ScrollingFrame")
		sidebar.Name = "Sidebar"
		sidebar.BackgroundColor3 = Theme.Surface
		sidebar.BorderSizePixel = 0
		sidebar.Position = UDim2.new(0, 0, 0, 50)
		sidebar.Size = UDim2.new(0, 170, 1, -50)
		sidebar.ScrollBarThickness = 4
		sidebar.ScrollBarImageColor3 = Theme.SubText
		sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
		sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
		sidebar.Parent = main

		local sidebarList = Instance.new("UIListLayout")
		sidebarList.SortOrder = Enum.SortOrder.LayoutOrder
		sidebarList.Padding = UDim.new(0, 6)
		sidebarList.Parent = sidebar

		local sidebarPadding = Instance.new("UIPadding")
		sidebarPadding.PaddingTop = UDim.new(0, 10)
		sidebarPadding.PaddingLeft = UDim.new(0, 10)
		sidebarPadding.PaddingRight = UDim.new(0, 10)
		sidebarPadding.PaddingBottom = UDim.new(0, 10)
		sidebarPadding.Parent = sidebar

		local content = Instance.new("Frame")
		content.Name = "Content"
		content.BackgroundTransparency = 1
		content.BorderSizePixel = 0
		content.Position = UDim2.new(0, 170, 0, 50)
		content.Size = UDim2.new(1, -170, 1, -50)
		content.Parent = main

		minimizeBtn.MouseButton1Click:Connect(function()
			minimized = not minimized

			if minimized then
				local originalPos = main.Position
				main.AnchorPoint = Vector2.new(0.5, 0)
				main.Position = originalPos
				Tween(main, {Size = UDim2.new(config.Size.X.Scale, config.Size.X.Offset, 0, 50)}, 0.3)
				wait(0.15)
				sidebar.Visible = false
				content.Visible = false
			else
				sidebar.Visible = true
				content.Visible = true
				Tween(main, {Size = config.Size}, 0.3)
			end
		end)

		MakeDraggable(main, topBar)

		-- CreateTab
		function Window:CreateTab(tabConfig)
			tabConfig = tabConfig or {}
			tabConfig.Name = tabConfig.Name or "Tab"
			tabConfig.Icon = tabConfig.Icon or "11326672785"

			local Tab = {
				Sections = {}
			}

			local tabBtn = Instance.new("TextButton")
			tabBtn.Name = tabConfig.Name
			tabBtn.BackgroundColor3 = Theme.Card
			tabBtn.BorderSizePixel = 0
			tabBtn.Size = UDim2.new(1, 0, 0, 38)
			tabBtn.Text = ""
			tabBtn.Parent = sidebar

			AddCorner(tabBtn, 4)

			local iconFrame = Instance.new("Frame")
			iconFrame.BackgroundTransparency = 1
			iconFrame.Position = UDim2.new(0, 10, 0.5, 0)
			iconFrame.AnchorPoint = Vector2.new(0, 0.5)
			iconFrame.Size = UDim2.new(0, 18, 0, 18)
			iconFrame.Parent = tabBtn

			local icon
			if tonumber(tabConfig.Icon) then
				icon = Instance.new("ImageLabel")
				icon.Image = "rbxassetid://" .. tabConfig.Icon
				icon.ImageColor3 = Theme.SubText
			else
				icon = Instance.new("TextLabel")
				icon.Text = tabConfig.Icon
				icon.TextColor3 = Theme.SubText
				icon.Font = Enum.Font.GothamBold
				icon.TextSize = 14
			end

			icon.BackgroundTransparency = 1
			icon.Size = UDim2.new(1, 0, 1, 0)
			icon.Parent = iconFrame

			local tabLabel = Instance.new("TextLabel")
			tabLabel.BackgroundTransparency = 1
			tabLabel.Font = GetFont(Window.Font, "Medium")
			tabLabel.Text = tabConfig.Name
			tabLabel.TextColor3 = Theme.SubText
			tabLabel.TextSize = 13
			tabLabel.Position = UDim2.new(0, 35, 0, 0)
			tabLabel.Size = UDim2.new(1, -35, 1, 0)
			tabLabel.TextXAlignment = Enum.TextXAlignment.Left
			tabLabel.Parent = tabBtn

			local indicator = Instance.new("Frame")
			indicator.BackgroundColor3 = Theme.Success
			indicator.BorderSizePixel = 0
			indicator.Size = UDim2.new(0, 2, 0, 0)
			indicator.Position = UDim2.new(0, 0, 0.5, 0)
			indicator.AnchorPoint = Vector2.new(0, 0.5)
			indicator.Parent = tabBtn

			local tabContent = Instance.new("ScrollingFrame")
			tabContent.Name = tabConfig.Name .. "Content"
			tabContent.BackgroundTransparency = 1
			tabContent.BorderSizePixel = 0
			tabContent.Size = UDim2.new(1, 0, 1, 0)
			tabContent.ScrollBarThickness = 4
			tabContent.ScrollBarImageColor3 = Theme.SubText
			tabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
			tabContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
			tabContent.Visible = false
			tabContent.Parent = content

			local contentList = Instance.new("UIListLayout")
			contentList.SortOrder = Enum.SortOrder.LayoutOrder
			contentList.Padding = UDim.new(0, 12)
			contentList.Parent = tabContent

			local contentPadding = Instance.new("UIPadding")
			contentPadding.PaddingTop = UDim.new(0, 15)
			contentPadding.PaddingLeft = UDim.new(0, 15)
			contentPadding.PaddingRight = UDim.new(0, 15)
			contentPadding.PaddingBottom = UDim.new(0, 15)
			contentPadding.Parent = tabContent

			Tab.Button = tabBtn
			Tab.Content = tabContent
			Tab.Icon = icon
			Tab.Label = tabLabel
			Tab.Indicator = indicator

			-- Tab selection
			tabBtn.MouseButton1Click:Connect(function()
				for _, tab in pairs(Window.Tabs) do
					tab.Content.Visible = false
					Tween(tab.Button, {BackgroundColor3 = Theme.Card}, 0.2)
					Tween(tab.Label, {TextColor3 = Theme.SubText}, 0.2)
					if tab.Icon.ClassName == "ImageLabel" then
						Tween(tab.Icon, {ImageColor3 = Theme.SubText}, 0.2)
					else
						Tween(tab.Icon, {TextColor3 = Theme.SubText}, 0.2)
					end
					Tween(tab.Indicator, {Size = UDim2.new(0, 2, 0, 0)}, 0.2)
				end

				tabContent.Visible = true
				Window.CurrentTab = Tab
				Tween(tabBtn, {BackgroundColor3 = Theme.Hover}, 0.2)
				Tween(tabLabel, {TextColor3 = Theme.Text}, 0.2)
				if icon.ClassName == "ImageLabel" then
					Tween(icon, {ImageColor3 = Theme.Text}, 0.2)
				else
					Tween(icon, {TextColor3 = Theme.Text}, 0.2)
				end
				Tween(indicator, {Size = UDim2.new(0, 2, 1, 0)}, 0.2)
			end)

			tabBtn.MouseEnter:Connect(function()
				if Window.CurrentTab ~= Tab then
					Tween(tabBtn, {BackgroundColor3 = Theme.Hover}, 0.15)
				end
			end)

			tabBtn.MouseLeave:Connect(function()
				if Window.CurrentTab ~= Tab then
					Tween(tabBtn, {BackgroundColor3 = Theme.Card}, 0.15)
				end
			end)

			table.insert(Window.Tabs, Tab)

			-- Auto-select first tab
			if #Window.Tabs == 1 then
				task.wait()
				tabContent.Visible = true
				Window.CurrentTab = Tab
				tabBtn.BackgroundColor3 = Theme.Hover
				tabLabel.TextColor3 = Theme.Text
				if icon.ClassName == "ImageLabel" then
					icon.ImageColor3 = Theme.Text
				else
					icon.TextColor3 = Theme.Text
				end
				indicator.Size = UDim2.new(0, 2, 1, 0)
			end

			-- CreateSection
			function Tab:CreateSection(name)
				local Section = {}

				local section = Instance.new("Frame")
				section.Name = name
				section.BackgroundColor3 = Theme.Card
				section.BorderSizePixel = 0
				section.Size = UDim2.new(1, 0, 0, 100)
				section.Parent = tabContent

				AddCorner(section, 4)
				AddStroke(section, Theme.Border, 1, 0)

				local header = Instance.new("Frame")
				header.BackgroundTransparency = 1
				header.Size = UDim2.new(1, 0, 0, 40)
				header.Parent = section

				local sectionTitle = Instance.new("TextLabel")
				sectionTitle.BackgroundTransparency = 1
				sectionTitle.Font = GetFont(Window.Font, "Bold")
				sectionTitle.Text = name
				sectionTitle.TextColor3 = Theme.Text
				sectionTitle.TextSize = 14
				sectionTitle.Position = UDim2.new(0, 15, 0, 0)
				sectionTitle.Size = UDim2.new(1, -30, 1, 0)
				sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
				sectionTitle.Parent = header

				local divider = Instance.new("Frame")
				divider.BackgroundColor3 = Theme.Border
				divider.BorderSizePixel = 0
				divider.Position = UDim2.new(0, 15, 1, 0)
				divider.Size = UDim2.new(1, -30, 0, 1)
				divider.Parent = header

				local elements = Instance.new("Frame")
				elements.BackgroundTransparency = 1
				elements.Position = UDim2.new(0, 0, 0, 40)
				elements.Size = UDim2.new(1, 0, 1, -40)
				elements.Parent = section

				local elementsList = Instance.new("UIListLayout")
				elementsList.SortOrder = Enum.SortOrder.LayoutOrder
				elementsList.Padding = UDim.new(0, 8)
				elementsList.Parent = elements

				local elementsPadding = Instance.new("UIPadding")
				elementsPadding.PaddingTop = UDim.new(0, 8)
				elementsPadding.PaddingLeft = UDim.new(0, 15)
				elementsPadding.PaddingRight = UDim.new(0, 15)
				elementsPadding.PaddingBottom = UDim.new(0, 15)
				elementsPadding.Parent = elements

				local function updateSectionSize()
					local totalHeight = 40 + 8 + 15 -- header + top padding + bottom padding
					for _, child in ipairs(elements:GetChildren()) do
						if child:IsA("GuiObject") then
							totalHeight = totalHeight + child.AbsoluteSize.Y + 8
						end
					end
					local currentHeight = section.Size.Y.Offset
					local duration = totalHeight > currentHeight and 0.05 or 0.2
					Tween(section, {Size = UDim2.new(1, 0, 0, totalHeight)}, duration)
				end

				elementsList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
					updateSectionSize()
				end)

				task.spawn(function()
					task.wait(0.1)
					updateSectionSize()
				end)

				-- Paragraph (Taken the idea from Orion)
				function Section:AddParagraph(paragraphConfig)
					paragraphConfig = paragraphConfig or {}
					paragraphConfig.Title = paragraphConfig.Title or "Paragraph"
					paragraphConfig.Content = paragraphConfig.Content or "No content"
					local paragraphFrame = Instance.new("Frame")
					paragraphFrame.BackgroundColor3 = Theme.Surface
					paragraphFrame.BorderSizePixel = 0
					paragraphFrame.Size = UDim2.new(1, 0, 0, 0)
					paragraphFrame.AutomaticSize = Enum.AutomaticSize.Y
					paragraphFrame.Parent = elements

					AddCorner(paragraphFrame, 4)
					AddStroke(paragraphFrame, Theme.Border, 1, 0)

					local paragraphPadding = Instance.new("UIPadding")
					paragraphPadding.PaddingTop = UDim.new(0, 12)
					paragraphPadding.PaddingLeft = UDim.new(0, 12)
					paragraphPadding.PaddingRight = UDim.new(0, 12)
					paragraphPadding.PaddingBottom = UDim.new(0, 12)
					paragraphPadding.Parent = paragraphFrame

					local paragraphLayout = Instance.new("UIListLayout")
					paragraphLayout.SortOrder = Enum.SortOrder.LayoutOrder
					paragraphLayout.Padding = UDim.new(0, 6)
					paragraphLayout.Parent = paragraphFrame

					local paragraphTitle = Instance.new("TextLabel")
					paragraphTitle.BackgroundTransparency = 1
					paragraphTitle.Font = GetFont(Window.Font, "Bold")
					paragraphTitle.Text = paragraphConfig.Title
					paragraphTitle.TextColor3 = Theme.Text
					paragraphTitle.TextSize = 13
					paragraphTitle.Size = UDim2.new(1, 0, 0, 0)
					paragraphTitle.AutomaticSize = Enum.AutomaticSize.Y
					paragraphTitle.TextXAlignment = Enum.TextXAlignment.Left
					paragraphTitle.TextWrapped = true
					paragraphTitle.Parent = paragraphFrame

					local paragraphText = Instance.new("TextLabel")
					paragraphText.BackgroundTransparency = 1
					paragraphText.Font = GetFont(Window.Font, "Regular")
					paragraphText.Text = paragraphConfig.Content
					paragraphText.TextColor3 = Theme.SubText
					paragraphText.TextSize = 12
					paragraphText.Size = UDim2.new(1, 0, 0, 20)
					paragraphText.TextWrapped = true
					paragraphText.TextXAlignment = Enum.TextXAlignment.Left
					paragraphText.TextYAlignment = Enum.TextYAlignment.Top
					paragraphText.Parent = paragraphFrame

					-- Expand size until text fits
					task.spawn(function()
						task.wait(0.05)
						while not paragraphText.TextFits do
							paragraphText.Size = UDim2.new(1, 0, 0, paragraphText.Size.Y.Offset + 5)
							task.wait(0.01)
						end
					end)

					return {
						SetTitle = function(self, text)
							paragraphTitle.Text = text
						end,
						SetContent = function(self, text)
							paragraphText.Text = text
							paragraphText.Size = UDim2.new(1, 0, 0, 20)
							task.spawn(function()
								task.wait(0.05)
								while not paragraphText.TextFits do
									paragraphText.Size = UDim2.new(1, 0, 0, paragraphText.Size.Y.Offset + 5)
									task.wait(0.01)
								end
							end)
						end
					}
				end

				-- Button
				function Section:AddButton(btnConfig)
					btnConfig = btnConfig or {}
					btnConfig.Name = btnConfig.Name or "Button"
					btnConfig.Callback = btnConfig.Callback or function() end

					local btn = Instance.new("TextButton")
					btn.BackgroundColor3 = Theme.Surface
					btn.BorderSizePixel = 0
					btn.Size = UDim2.new(1, 0, 0, 35)
					btn.Font = GetFont(Window.Font, "Medium")
					btn.Text = btnConfig.Name
					btn.TextColor3 = Theme.Text
					btn.TextSize = 13
					btn.Parent = elements

					AddCorner(btn, 4)
					AddStroke(btn, Theme.Border, 1, 0)

					btn.MouseEnter:Connect(function()
						Tween(btn, {BackgroundColor3 = Theme.Hover}, 0.15)
					end)

					btn.MouseLeave:Connect(function()
						Tween(btn, {BackgroundColor3 = Theme.Surface}, 0.15)
					end)

					btn.MouseButton1Click:Connect(function()
						Tween(btn, {Size = UDim2.new(1, 0, 0, 32)}, 0.08)
						wait(0.08)
						Tween(btn, {Size = UDim2.new(1, 0, 0, 35)}, 0.08)
						task.spawn(function()
							local success, err = pcall(btnConfig.Callback)

					if not success then
    		warn("Button failed with the error:", err)
		end
						end)
					end)
				end

				-- Toggle
				function Section:AddToggle(toggleConfig)
					toggleConfig = toggleConfig or {}
					toggleConfig.Name = toggleConfig.Name or "Toggle"
					toggleConfig.Default = toggleConfig.Default or false
					toggleConfig.Flag = toggleConfig.Flag or nil
					toggleConfig.Callback = toggleConfig.Callback or function() end

					local toggled = toggleConfig.Default

					local toggleFrame = Instance.new("TextButton")
					toggleFrame.BackgroundColor3 = Theme.Surface
					toggleFrame.BorderSizePixel = 0
					toggleFrame.Size = UDim2.new(1, 0, 0, 35)
					toggleFrame.Text = ""
					toggleFrame.Parent = elements

					AddCorner(toggleFrame, 4)
					AddStroke(toggleFrame, Theme.Border, 1, 0)

					local label = Instance.new("TextLabel")
					label.BackgroundTransparency = 1
					label.Font = GetFont(Window.Font, "Medium")
					label.Text = toggleConfig.Name
					label.TextColor3 = Theme.Text
					label.TextSize = 13
					label.Position = UDim2.new(0, 12, 0, 0)
					label.Size = UDim2.new(1, -60, 1, 0)
					label.TextXAlignment = Enum.TextXAlignment.Left
					label.Parent = toggleFrame

					local toggle = Instance.new("Frame")
					toggle.AnchorPoint = Vector2.new(1, 0.5)
					toggle.BackgroundColor3 = toggled and Theme.Success or Theme.ToggleFill
					toggle.BorderSizePixel = 0
					toggle.Position = UDim2.new(1, -12, 0.5, 0)
					toggle.Size = UDim2.new(0, 40, 0, 20)
					toggle.Parent = toggleFrame

					AddCorner(toggle, 10)

					local indicator = Instance.new("Frame")
					indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					indicator.BorderSizePixel = 0
					indicator.Position = toggled and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
					indicator.AnchorPoint = Vector2.new(0, 0.5)
					indicator.Size = UDim2.new(0, 16, 0, 16)
					indicator.Parent = toggle

					AddCorner(indicator, 8)

					local function updateToggle(state)
						toggled = state
						if toggleConfig.Flag then
							OpenCore.Flags[toggleConfig.Flag] = toggled
						end

						Tween(toggle, {BackgroundColor3 = toggled and Theme.Success or Theme.Card}, 0.2)
						Tween(indicator, {Position = toggled and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)}, 0.2)

						task.spawn(function()
							pcall(toggleConfig.Callback, toggled)
						end)
					end

					toggleFrame.MouseButton1Click:Connect(function()
						updateToggle(not toggled)
					end)

					if toggleConfig.Default then
						updateToggle(true)
					end

					return {
						Set = function(self, value)
							updateToggle(value)
						end
					}
				end

				-- Slider
				function Section:AddSlider(sliderConfig)
					sliderConfig = sliderConfig or {}
					sliderConfig.Name = sliderConfig.Name or "Slider"
					sliderConfig.Min = sliderConfig.Min or 0
					sliderConfig.Max = sliderConfig.Max or 100
					sliderConfig.Default = sliderConfig.Default or 50
					sliderConfig.Increment = sliderConfig.Increment or 1
					sliderConfig.Flag = sliderConfig.Flag or nil
					sliderConfig.Callback = sliderConfig.Callback or function() end

					local value = sliderConfig.Default

					local sliderFrame = Instance.new("Frame")
					sliderFrame.BackgroundColor3 = Theme.Surface
					sliderFrame.BorderSizePixel = 0
					sliderFrame.Size = UDim2.new(1, 0, 0, 50)
					sliderFrame.Parent = elements

					AddCorner(sliderFrame, 4)
					AddStroke(sliderFrame, Theme.Border, 1, 0)

					local label = Instance.new("TextLabel")
					label.BackgroundTransparency = 1
					label.Font = GetFont(Window.Font, "Medium")
					label.Text = sliderConfig.Name
					label.TextColor3 = Theme.Text
					label.TextSize = 13
					label.Position = UDim2.new(0, 12, 0, 6)
					label.Size = UDim2.new(0.6, 0, 0, 18)
					label.TextXAlignment = Enum.TextXAlignment.Left
					label.Parent = sliderFrame
					label.ZIndex = 2

					local valueBox = Instance.new("TextBox")
					valueBox.BackgroundTransparency = 1
					valueBox.Font = GetFont(Window.Font, "Bold")
					valueBox.Text = tostring(value)
					valueBox.TextColor3 = Theme.SubText
					valueBox.TextSize = 13
					valueBox.Position = UDim2.new(0.6, 0, 0, 6)
					valueBox.Size = UDim2.new(0.4, -12, 0, 18)
					valueBox.TextXAlignment = Enum.TextXAlignment.Right
					valueBox.ClearTextOnFocus = false
					valueBox.Parent = sliderFrame
					valueBox.ZIndex = 2

					local sliderBar = Instance.new("TextButton")
					sliderBar.BackgroundColor3 = Theme.Surface
					sliderBar.BorderSizePixel = 0
					sliderBar.Position = UDim2.new(0, 0, 0, 0)
					sliderBar.Size = UDim2.new(1, 0, 1, 0)
					sliderBar.Text = ""
					sliderBar.ZIndex = 1
					sliderBar.Parent = sliderFrame

					AddCorner(sliderBar, 4)

					local sliderBarVisual = Instance.new("Frame")
					sliderBarVisual.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
					sliderBarVisual.BorderSizePixel = 0
					sliderBarVisual.Position = UDim2.new(0, 12, 1, -16)
					sliderBarVisual.Size = UDim2.new(1, -24, 0, 4)
					sliderBarVisual.ZIndex = 2
					sliderBarVisual.Parent = sliderFrame

					AddCorner(sliderBarVisual, 2)

					local sliderFill = Instance.new("Frame")
					sliderFill.BackgroundColor3 = Theme.SliderFill
					sliderFill.BorderSizePixel = 0
					sliderFill.Size = UDim2.new((value - sliderConfig.Min) / (sliderConfig.Max - sliderConfig.Min), 0, 1, 0)
					sliderFill.ZIndex = 3
					sliderFill.Parent = sliderBarVisual

					AddCorner(sliderFill, 2)

					local dragging = false

					local function updateSlider(input)
						local pos = (input.Position.X - sliderBarVisual.AbsolutePosition.X) / sliderBarVisual.AbsoluteSize.X
						pos = math.clamp(pos, 0, 1)

						value = math.floor((sliderConfig.Min + (sliderConfig.Max - sliderConfig.Min) * pos) / sliderConfig.Increment + 0.5) * sliderConfig.Increment
						value = math.clamp(value, sliderConfig.Min, sliderConfig.Max)

						if sliderConfig.Flag then
							OpenCore.Flags[sliderConfig.Flag] = value
						end

						valueBox.Text = tostring(value)
						Tween(sliderFill, {Size = UDim2.new((value - sliderConfig.Min) / (sliderConfig.Max - sliderConfig.Min), 0, 1, 0)}, 0.05)

						task.spawn(function()
							pcall(sliderConfig.Callback, value)
						end)
					end

					sliderBar.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							dragging = true
							updateSlider(input)
						end
					end)

					sliderBar.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							dragging = false
						end
					end)

					UserInputService.InputChanged:Connect(function(input)
						if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
							updateSlider(input)
						end
					end)

					valueBox.FocusLost:Connect(function()
						local newValue = tonumber(valueBox.Text)
						if newValue then
							value = math.clamp(newValue, sliderConfig.Min, sliderConfig.Max)
							valueBox.Text = tostring(value)
							sliderFill.Size = UDim2.new((value - sliderConfig.Min) / (sliderConfig.Max - sliderConfig.Min), 0, 1, 0)
							if sliderConfig.Flag then
								OpenCore.Flags[sliderConfig.Flag] = value
							end
							task.spawn(function()
								pcall(sliderConfig.Callback, value)
							end)
						else
							valueBox.Text = tostring(value)
						end
					end)

					return {
						Set = function(self, val)
							value = math.clamp(val, sliderConfig.Min, sliderConfig.Max)
							valueBox.Text = tostring(value)
							sliderFill.Size = UDim2.new((value - sliderConfig.Min) / (sliderConfig.Max - sliderConfig.Min), 0, 1, 0)
							if sliderConfig.Flag then
								OpenCore.Flags[sliderConfig.Flag] = value
							end
						end
					}
				end

				-- Dropdown
				function Section:AddDropdown(dropConfig)
					dropConfig = dropConfig or {}
					dropConfig.Name = dropConfig.Name or "Dropdown"
					dropConfig.Options = dropConfig.Options or {}
					dropConfig.Default = dropConfig.Default or dropConfig.Options[1] or "None"
					dropConfig.Flag = dropConfig.Flag or nil
					dropConfig.Callback = dropConfig.Callback or function() end

					local selected = dropConfig.Default
					local opened = false

					local dropFrame = Instance.new("Frame")
					dropFrame.BackgroundColor3 = Theme.Surface
					dropFrame.BorderSizePixel = 0
					dropFrame.Size = UDim2.new(1, 0, 0, 35)
					dropFrame.ClipsDescendants = true
					dropFrame.Parent = elements

					AddCorner(dropFrame, 4)
					AddStroke(dropFrame, Theme.Border, 1, 0)

					local header = Instance.new("TextButton")
					header.BackgroundTransparency = 1
					header.Size = UDim2.new(1, 0, 0, 35)
					header.Text = ""
					header.Parent = dropFrame

					local label = Instance.new("TextLabel")
					label.BackgroundTransparency = 1
					label.Font = GetFont(Window.Font, "Medium")
					label.Text = dropConfig.Name
					label.TextColor3 = Theme.Text
					label.TextSize = 13
					label.Position = UDim2.new(0, 12, 0, 0)
					label.Size = UDim2.new(0.4, 0, 1, 0)
					label.TextXAlignment = Enum.TextXAlignment.Left
					label.Parent = header

					local valueLabel = Instance.new("TextLabel")
					valueLabel.BackgroundTransparency = 1
					valueLabel.Font = GetFont(Window.Font, "Regular")
					valueLabel.Text = selected
					valueLabel.TextColor3 = Theme.SubText
					valueLabel.TextSize = 12
					valueLabel.Position = UDim2.new(0.4, 0, 0, 0)
					valueLabel.Size = UDim2.new(0.6, -35, 1, 0)
					valueLabel.TextXAlignment = Enum.TextXAlignment.Right
					valueLabel.Parent = header

					local arrow = Instance.new("ImageLabel")
					arrow.BackgroundTransparency = 1
					arrow.Image = Icons.ChevronDown
					arrow.ImageColor3 = Theme.SubText
					arrow.AnchorPoint = Vector2.new(1, 0.5)
					arrow.Position = UDim2.new(1, -12, 0.5, 0)
					arrow.Size = UDim2.new(0, 14, 0, 14)
					arrow.Parent = header

					local optionsContainer = Instance.new("Frame")
					optionsContainer.BackgroundColor3 = Theme.Card
					optionsContainer.BorderSizePixel = 0
					optionsContainer.Position = UDim2.new(0, 1, 0, 36)
					optionsContainer.Size = UDim2.new(1, -2, 0, 0)
					optionsContainer.Parent = dropFrame

					local optionsList = Instance.new("UIListLayout")
					optionsList.SortOrder = Enum.SortOrder.LayoutOrder
					optionsList.Padding = UDim.new(0, 0)
					optionsList.Parent = optionsContainer

					local function createOption(optionName)
						local option = Instance.new("TextButton")
						option.BackgroundColor3 = Theme.Card
						option.BorderSizePixel = 0
						option.Size = UDim2.new(1, 0, 0, 30)
						option.Font = GetFont(Window.Font, "Regular")
						option.Text = "  " .. optionName
						option.TextColor3 = Theme.SubText
						option.TextSize = 12
						option.TextXAlignment = Enum.TextXAlignment.Left
						option.Parent = optionsContainer

						option.MouseEnter:Connect(function()
							Tween(option, {BackgroundColor3 = Theme.Hover}, 0.1)
						end)

						option.MouseLeave:Connect(function()
							Tween(option, {BackgroundColor3 = Theme.Card}, 0.1)
						end)

						option.MouseButton1Click:Connect(function()
							selected = optionName
							valueLabel.Text = selected
							if dropConfig.Flag then
								OpenCore.Flags[dropConfig.Flag] = selected
							end

							opened = false
							Tween(dropFrame, {Size = UDim2.new(1, 0, 0, 35)}, 0.2)
							Tween(arrow, {Rotation = 0}, 0.2)

							task.spawn(function()
								pcall(dropConfig.Callback, selected)
							end)
						end)

						return option
					end

					for _, option in ipairs(dropConfig.Options) do
						createOption(option)
					end

					local function updateDropdownSize()
						if opened then
							local optionCount = 0
							for _, child in ipairs(optionsContainer:GetChildren()) do
								if child:IsA("TextButton") then
									optionCount = optionCount + 1
								end
							end
							local targetSize = UDim2.new(1, 0, 0, 36 + optionCount * 30)
							Tween(dropFrame, {Size = targetSize}, 0.2)
						end
					end

					header.MouseButton1Click:Connect(function()
						opened = not opened
						local optionCount = 0
						for _, child in ipairs(optionsContainer:GetChildren()) do
							if child:IsA("TextButton") then
								optionCount = optionCount + 1
							end
						end
						
						if opened then
							Tween(dropFrame, {Size = UDim2.new(1, 0, 0, 36 + optionCount * 30)}, 0.2)
						else
							Tween(dropFrame, {Size = UDim2.new(1, 0, 0, 35)}, 0.2)
						end
						
						Tween(arrow, {Rotation = opened and 180 or 0}, 0.2)
						task.wait(0.2)
						updateSectionSize()
					end)

					return {
						Set = function(self, value)
							selected = value
							valueLabel.Text = selected
							if dropConfig.Flag then
								OpenCore.Flags[dropConfig.Flag] = selected
							end
						end,
						AddOption = function(self, optionName)
							table.insert(dropConfig.Options, optionName)
							createOption(optionName)
							updateDropdownSize()
						end,
						RemoveOption = function(self, optionName)
							for i, v in ipairs(dropConfig.Options) do
								if v == optionName then
									table.remove(dropConfig.Options, i)
									break
								end
							end
							for _, child in pairs(optionsContainer:GetChildren()) do
								if child:IsA("TextButton") and child.Text == "  " .. optionName then
									child:Destroy()
									break
								end
							end
							updateDropdownSize()
						end,
						Clear = function(self)
							dropConfig.Options = {}
							for _, child in pairs(optionsContainer:GetChildren()) do
								if child:IsA("TextButton") then
									child:Destroy()
								end
							end
							selected = "None"
							valueLabel.Text = selected
							updateDropdownSize()
						end,
						Refresh = function(self, options)
							for _, child in ipairs(optionsContainer:GetChildren()) do
								if child:IsA("TextButton") then
									child:Destroy()
								end
							end
							dropConfig.Options = options
							for _, option in ipairs(options) do
								createOption(option)
							end
						end
					}
				end

				-- Multi-Select Dropdown
function Section:AddMultiDropdown(multi_config)
	multi_config = multi_config or {}
	multi_config.Name = multi_config.Name or "Multi-Select"
	multi_config.Options = multi_config.Options or {}
	multi_config.Default = multi_config.Default or {}
	multi_config.MaxSelected = multi_config.MaxSelected or nil
	multi_config.MinSelected = multi_config.MinSelected or 1
	multi_config.Flag = multi_config.Flag or nil
	multi_config.Callback = multi_config.Callback or function() end
	multi_config.WatchInstance = multi_config.WatchInstance or nil

	local theme = OpenCore.Themes[OpenCore.CurrentTheme] or {}
	theme.Primary  = theme.Primary  or Color3.fromRGB(0, 170, 255)
	theme.Danger   = theme.Danger   or Color3.fromRGB(255, 50, 50)
	theme.Success  = theme.Success  or Color3.fromRGB(0, 255, 0)
	theme.Card     = theme.Card     or Color3.fromRGB(50, 50, 50)
	theme.Surface  = theme.Surface  or Color3.fromRGB(30, 30, 30)
	theme.Border   = theme.Border   or Color3.fromRGB(60, 60, 60)
	theme.Hover    = theme.Hover    or theme.Card
	theme.Text     = theme.Text     or Color3.fromRGB(255, 255, 255)
	theme.SubText  = theme.SubText  or Color3.fromRGB(180, 180, 180)

	local selected_indices = {}
	for _, item in ipairs(multi_config.Default) do
		for i, opt in ipairs(multi_config.Options) do
			if opt == item then
				selected_indices[i] = true
				break
			end
		end
	end
	local opened = false
	local watch_connections = {}

	local drop_frame = Instance.new("Frame")
	drop_frame.BackgroundColor3 = theme.Surface
	drop_frame.BorderSizePixel = 0
	drop_frame.Size = UDim2.new(1, 0, 0, 35)
	drop_frame.ClipsDescendants = true
	drop_frame.Parent = elements
	AddCorner(drop_frame, 4)
	AddStroke(drop_frame, theme.Border, 1, 0)

	local header = Instance.new("TextButton")
	header.BackgroundTransparency = 1
	header.Size = UDim2.new(1, 0, 0, 35)
	header.Text = ""
	header.Parent = drop_frame

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = GetFont(Window.Font, "Medium")
	label.Text = multi_config.Name
	label.TextColor3 = theme.Text
	label.TextSize = 13
	label.Position = UDim2.new(0, 12, 0, 0)
	label.Size = UDim2.new(0.4, 0, 1, 0)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = header

	local value_label = Instance.new("TextLabel")
	value_label.BackgroundTransparency = 1
	value_label.Font = GetFont(Window.Font, "Regular")
	value_label.TextColor3 = theme.SubText
	value_label.TextSize = 12
	value_label.Position = UDim2.new(0.4, 0, 0, 0)
	value_label.Size = UDim2.new(0.6, -35, 1, 0)
	value_label.TextXAlignment = Enum.TextXAlignment.Right
	value_label.TextTruncate = Enum.TextTruncate.AtEnd
	value_label.Parent = header

	local arrow = Instance.new("ImageLabel")
	arrow.BackgroundTransparency = 1
	arrow.Image = Icons.ChevronDown
	arrow.ImageColor3 = theme.SubText
	arrow.AnchorPoint = Vector2.new(1, 0.5)
	arrow.Position = UDim2.new(1, -12, 0.5, 0)
	arrow.Size = UDim2.new(0, 14, 0, 14)
	arrow.Parent = header

	local options_container = Instance.new("Frame")
	options_container.BackgroundColor3 = theme.Card
	options_container.BorderSizePixel = 0
	options_container.Position = UDim2.new(0, 1, 0, 36)
	options_container.Size = UDim2.new(1, -2, 0, 0)
	options_container.Parent = drop_frame

	local options_list = Instance.new("UIListLayout")
	options_list.SortOrder = Enum.SortOrder.LayoutOrder
	options_list.Padding = UDim.new(0, 0)
	options_list.Parent = options_container

	local function update_value_label()
		local names = {}
		for i in pairs(selected_indices) do
			table.insert(names, multi_config.Options[i])
		end
		value_label.Text = #names > 0 and table.concat(names, ", ") or "None"
	end
	update_value_label()

	local function is_selected_index(idx)
		return selected_indices[idx] == true
	end

	local function selected_count()
		local n = 0
		for _ in pairs(selected_indices) do n = n + 1 end
		return n
	end

	local function get_selected_names()
		local names = {}
		for i in pairs(selected_indices) do
			table.insert(names, multi_config.Options[i])
		end
		return names
	end

	local option_buttons = {}

	local function update_dropdown_size()
		if not opened then return end
		Tween(drop_frame, {Size = UDim2.new(1, 0, 0, 36 + options_list.AbsoluteContentSize.Y)}, 0.2)
	end
local function add_option_button(real_index, option_name, order)
    local option = Instance.new("TextButton")
    option.BackgroundColor3 = theme.Card
    option.BorderSizePixel = 0
    option.Size = UDim2.new(1, 0, 0, 30)
    option.Font = GetFont(Window.Font, "Regular")
    option.Text = "  " .. option_name
    option.TextColor3 = theme.SubText
    option.TextSize = 12
    option.TextXAlignment = Enum.TextXAlignment.Left
    option.LayoutOrder = order + 3
    option.Parent = options_container

    local circle = Instance.new("Frame")
    circle.BackgroundColor3 = theme.Success
    circle.BorderSizePixel = 0
    circle.AnchorPoint = Vector2.new(1, 0.5)
    circle.Position = UDim2.new(1, -12, 0.5, 0)
    circle.Size = UDim2.new(0, 8, 0, 8)
    circle.BackgroundTransparency = is_selected_index(real_index) and 0 or 1
    circle.Parent = option
    AddCorner(circle, 4)

    option.MouseButton1Click:Connect(function()
        if is_selected_index(real_index) then
            if selected_count() > multi_config.MinSelected then
                selected_indices[real_index] = nil
                Tween(circle, {BackgroundTransparency = 1}, 0.2)
            end
        else
            if not multi_config.MaxSelected or selected_count() < multi_config.MaxSelected then
                selected_indices[real_index] = true
                Tween(circle, {BackgroundTransparency = 0}, 0.2)
            end
        end
        update_value_label()
    end)

    option_buttons[real_index] = option
end
	local function refresh_options(filtered_pairs)
    for _, btn in pairs(option_buttons) do
        if btn and btn.Parent then
            btn:Destroy()
        end
    end
    option_buttons = {}

    for order, pair in ipairs(filtered_pairs) do
        add_option_button(pair.index, pair.name, order)
    end
end

	local function build_pairs(options, filter_text)
		local result = {}
		filter_text = filter_text and filter_text:lower() or ""
		for i, name in ipairs(options) do
			if name:lower():find(filter_text, 1, true) then
				table.insert(result, {index = i, name = name})
			end
		end
		return result
	end

local sync_pending = false

local function sync_from_instance(instance)
    if sync_pending then return end
    sync_pending = true

    task.defer(function()
        local new_options = {}
        for _, obj in ipairs(instance:GetDescendants()) do
            table.insert(new_options, obj:GetFullName())
        end

        local new_selected = {}
        for idx in pairs(selected_indices) do
            local old_name = multi_config.Options[idx]
            for i, new_name in ipairs(new_options) do
                if new_name == old_name then
                    new_selected[i] = true
                    break
                end
            end
        end

        multi_config.Options = new_options
        selected_indices = new_selected
        update_value_label()
        refresh_options(build_pairs(multi_config.Options, search_box and search_box.Text or ""))
        update_dropdown_size()

        sync_pending = false
    end)
end

local function setup_watch(instance)
    for _, conn in ipairs(watch_connections) do
        conn:Disconnect()
    end
    watch_connections = {}
    if not instance then return end

    sync_from_instance(instance)

    table.insert(watch_connections, instance.DescendantAdded:Connect(function(obj)
        local full_name = obj:GetFullName()
        local new_index = #multi_config.Options + 1
        table.insert(multi_config.Options, full_name)
        add_option_button(new_index, full_name, new_index)
        update_dropdown_size()
    end))

    table.insert(watch_connections, instance.DescendantRemoving:Connect(function(obj)
        local full_name = obj:GetFullName()
        for i, v in ipairs(multi_config.Options) do
            if v == full_name then
                if option_buttons[i] and option_buttons[i].Parent then
                    option_buttons[i]:Destroy()
                    option_buttons[i] = nil
                end
                selected_indices[i] = nil
                table.remove(multi_config.Options, i)
                local shifted_buttons = {}
                local shifted_selected = {}
                for idx, val in pairs(selected_indices) do
                    if idx > i then
                        shifted_selected[idx - 1] = val
                    else
                        shifted_selected[idx] = val
                    end
                end
                for idx, btn in pairs(option_buttons) do
                    if idx > i then
                        shifted_buttons[idx - 1] = btn
                        btn.LayoutOrder = (idx - 1) + 3
                    else
                        shifted_buttons[idx] = btn
                    end
                end
                option_buttons = shifted_buttons
                selected_indices = shifted_selected
                update_value_label()
                update_dropdown_size()
                break
            end
        end
    end))
end

	local search_box = Instance.new("TextBox")
	search_box.BackgroundColor3 = theme.Surface
	search_box.BorderSizePixel = 0
	search_box.Size = UDim2.new(1, -4, 0, 28)
	search_box.Position = UDim2.new(0, 2, 0, 0)
	search_box.PlaceholderText = "Search..."
	search_box.Font = GetFont(Window.Font, "Regular")
	search_box.TextSize = 12
	search_box.TextColor3 = theme.Text
	search_box.TextXAlignment = Enum.TextXAlignment.Left
	search_box.ClearTextOnFocus = false
	search_box.Text = ""
	search_box.LayoutOrder = 1
	search_box.Parent = options_container
	AddCorner(search_box, 4)

	local confirm_button = Instance.new("TextButton")
	confirm_button.BackgroundColor3 = theme.Primary
	confirm_button.BorderSizePixel = 0
	confirm_button.Size = UDim2.new(1, 0, 0, 30)
	confirm_button.Font = GetFont(Window.Font, "Medium")
	confirm_button.Text = "Confirm"
	confirm_button.TextColor3 = Color3.new(1, 1, 1)
	confirm_button.TextSize = 13
	confirm_button.LayoutOrder = 2
	confirm_button.Parent = options_container
	AddCorner(confirm_button, 4)

	local clear_button = Instance.new("TextButton")
	clear_button.BackgroundColor3 = theme.Danger
	clear_button.BorderSizePixel = 0
	clear_button.Size = UDim2.new(1, 0, 0, 30)
	clear_button.Font = GetFont(Window.Font, "Medium")
	clear_button.Text = "Clear"
	clear_button.TextColor3 = Color3.new(1, 1, 1)
	clear_button.TextSize = 13
	clear_button.LayoutOrder = 3
	clear_button.Parent = options_container
	AddCorner(clear_button, 4)

	options_list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		options_container.Size = UDim2.new(1, -2, 0, options_list.AbsoluteContentSize.Y)
		if opened then
			Tween(drop_frame, {Size = UDim2.new(1, 0, 0, 36 + options_list.AbsoluteContentSize.Y)}, 0.2)
			task.wait(0.2)
			updateSectionSize()
		end
	end)

	refresh_options(build_pairs(multi_config.Options))

	task.wait(0.05)

	if multi_config.WatchInstance then
		setup_watch(multi_config.WatchInstance)
	end

	search_box:GetPropertyChangedSignal("Text"):Connect(function()
		refresh_options(build_pairs(multi_config.Options, search_box.Text))
		update_dropdown_size()
	end)

	header.MouseButton1Click:Connect(function()
		opened = not opened
		if opened then
			update_dropdown_size()
		else
			Tween(drop_frame, {Size = UDim2.new(1, 0, 0, 35)}, 0.2)
		end
		Tween(arrow, {Rotation = opened and 180 or 0}, 0.2)
		task.wait(0.2)
		updateSectionSize()
	end)

	confirm_button.MouseButton1Click:Connect(function()
		local names = get_selected_names()
		if multi_config.Flag then
			OpenCore.Flags[multi_config.Flag] = names
		end
		task.spawn(function()
			pcall(multi_config.Callback, names)
		end)
		opened = false
		Tween(drop_frame, {Size = UDim2.new(1, 0, 0, 35)}, 0.2)
		Tween(arrow, {Rotation = 0}, 0.2)
		task.wait(0.2)
		updateSectionSize()
	end)

	clear_button.MouseButton1Click:Connect(function()
		selected_indices = {}
		for _, item in ipairs(multi_config.Default) do
			for i, opt in ipairs(multi_config.Options) do
				if opt == item then
					selected_indices[i] = true
					break
				end
			end
		end
		update_value_label()
		if multi_config.Flag then
			OpenCore.Flags[multi_config.Flag] = get_selected_names()
		end
		refresh_options(build_pairs(multi_config.Options, search_box.Text))
		update_dropdown_size()
	end)

	return {
		Set = function(self, values)
			selected_indices = {}
			for _, item in ipairs(values) do
				for i, opt in ipairs(multi_config.Options) do
					if opt == item then
						selected_indices[i] = true
						break
					end
				end
			end
			update_value_label()
			refresh_options(build_pairs(multi_config.Options, search_box.Text))
		end,
		Get = function(self)
			return get_selected_names()
		end,
		AddOption = function(self, option_name)
			table.insert(multi_config.Options, option_name)
			refresh_options(build_pairs(multi_config.Options, search_box.Text))
			update_dropdown_size()
		end,
		RemoveOption = function(self, option_name)
			for i, v in ipairs(multi_config.Options) do
				if v == option_name then
					selected_indices[i] = nil
					table.remove(multi_config.Options, i)
					local shifted = {}
					for idx, val in pairs(selected_indices) do
						if idx > i then
							shifted[idx - 1] = val
						else
							shifted[idx] = val
						end
					end
					selected_indices = shifted
					break
				end
			end
			update_value_label()
			refresh_options(build_pairs(multi_config.Options, search_box.Text))
			update_dropdown_size()
		end,
		Clear = function(self)
			selected_indices = {}
			update_value_label()
			refresh_options(build_pairs(multi_config.Options, search_box.Text))
			update_dropdown_size()
		end,
		Refresh = function(self, options)
			selected_indices = {}
			multi_config.Options = options
			refresh_options(build_pairs(options, search_box.Text))
			update_dropdown_size()
		end,
		SetWatch = function(self, instance)
			setup_watch(instance)
		end,
		StopWatch = function(self)
			for _, conn in ipairs(watch_connections) do
				conn:Disconnect()
			end
			watch_connections = {}
		end
	}
end

                -- Color Wheel
                function Section:AddColorWheel(sectionConfig)
                    sectionConfig = sectionConfig or {}
                    sectionConfig.Name = sectionConfig.Name or "Color Picker"
                    sectionConfig.Default = sectionConfig.Default or Color3.fromRGB(255, 0, 0)
                    sectionConfig.Flag = sectionConfig.Flag or nil
                    sectionConfig.Callback = sectionConfig.Callback or function() end

                    local isExpanded = false

                    local colorFrame = Instance.new("Frame")
                    colorFrame.BackgroundColor3 = Theme.Surface
                    colorFrame.BorderSizePixel = 0
                    colorFrame.Size = UDim2.new(1, 0, 0, 35)
                    colorFrame.ClipsDescendants = true
                    colorFrame.Parent = elements
                    AddCorner(colorFrame, 4)
                    AddStroke(colorFrame, Theme.Border, 1, 0)

                    local header = Instance.new("TextButton")
                    header.BackgroundTransparency = 1
                    header.Size = UDim2.new(1, 0, 0, 35)
                    header.Text = ""
                    header.Parent = colorFrame

                    local label = Instance.new("TextLabel")
                    label.BackgroundTransparency = 1
                    label.Font = GetFont(Window.Font, "Medium")
                    label.Text = sectionConfig.Name
                    label.TextColor3 = Theme.Text
                    label.TextSize = 13
                    label.Position = UDim2.new(0, 12, 0, 0)
                    label.Size = UDim2.new(1, -90, 0, 35)
                    label.TextXAlignment = Enum.TextXAlignment.Left
                    label.Parent = header

                    local colorPreview = Instance.new("Frame")
                    colorPreview.AnchorPoint = Vector2.new(1, 0.5)
                    colorPreview.BackgroundTransparency = 1
                    colorPreview.BorderSizePixel = 0
                    colorPreview.Position = UDim2.new(1, -40, 0.5, 0)
                    colorPreview.Size = UDim2.new(0, 35, 0, 20)
                    colorPreview.ClipsDescendants = true
                    colorPreview.Parent = header
                    AddCorner(colorPreview, 4)
                    AddStroke(colorPreview, Theme.Border, 1, 0)

                    local previewCheckered = Instance.new("Frame")
                    previewCheckered.BackgroundTransparency = 1
                    previewCheckered.BorderSizePixel = 0
                    previewCheckered.Size = UDim2.new(1, 0, 1, 0)
                    previewCheckered.Parent = colorPreview

                    -- Create checkered pattern for preview
                    for x = 0, 1 do
                        for y = 0, 1 do
                            local checker = Instance.new("Frame")
                            checker.BackgroundColor3 = (x + y) % 2 == 0 and Color3.fromRGB(200, 200, 200) or Color3.fromRGB(100, 100, 100)
                            checker.BorderSizePixel = 0
                            checker.Size = UDim2.new(0.5, 0, 0.5, 0)
                            checker.Position = UDim2.new(x * 0.5, 0, y * 0.5, 0)
                            checker.Parent = previewCheckered
                        end
                    end

                    local previewColor = Instance.new("Frame")
                    previewColor.BackgroundColor3 = sectionConfig.Default
                    previewColor.BackgroundTransparency = 0
                    previewColor.BorderSizePixel = 0
                    previewColor.Size = UDim2.new(1, 0, 1, 0)
                    previewColor.Parent = colorPreview

                    local arrow = Instance.new("ImageLabel")
                    arrow.AnchorPoint = Vector2.new(1, 0.5)
                    arrow.BackgroundTransparency = 1
                    arrow.Position = UDim2.new(1, -12, 0.5, 0)
                    arrow.Size = UDim2.new(0, 16, 0, 16)
                    arrow.Image = Icons.ChevronDown
                    arrow.ImageColor3 = Theme.SubText
                    arrow.Rotation = 180
                    arrow.Parent = header

                    local currentColor = sectionConfig.Default
                    local currentTransparency = 0
                    
                    -- Initialize HSV from default color
                    local h, s, v = currentColor:ToHSV()
                    local currentHue = h
                    local currentSaturation = s
                    local currentValue = v

                    -- Wheel holder (left side) - increased size for preset squares
                    local wheelHolder = Instance.new("Frame")
                    wheelHolder.BackgroundTransparency = 1
                    wheelHolder.Size = UDim2.new(0.5, -6, 0, 240)
                    wheelHolder.Position = UDim2.new(0, 5, 0, 45)
                    wheelHolder.Parent = colorFrame

                    -- Color wheel image (made smaller to fit preset squares)
                    local wheel = Instance.new("ImageButton")
                    wheel.BackgroundTransparency = 1
                    wheel.BorderSizePixel = 0
                    wheel.Size = UDim2.new(0.75, 0, 0.75, 0)
                    wheel.AnchorPoint = Vector2.new(0.5, 0.5)
                    wheel.Position = UDim2.new(0.5, 0, 0.5, 0)
                    wheel.Image = "rbxassetid://11515288750"
                    wheel.AutoButtonColor = false
                    wheel.Parent = wheelHolder

                    local wheelAspect = Instance.new("UIAspectRatioConstraint")
                    wheelAspect.Parent = wheel

                    -- Selector
                    local selector = Instance.new("ImageLabel")
                    selector.BackgroundTransparency = 1
                    selector.BorderSizePixel = 0
                    selector.AnchorPoint = Vector2.new(0.5, 0.5)
                    selector.Position = UDim2.new(0.5, 0, 0.5, 0)
                    selector.Size = UDim2.new(0.125, 0, 0.125, 0)
                    selector.Image = "rbxassetid://11515686713"
                    selector.Parent = wheel

                    local selectorAspect = Instance.new("UIAspectRatioConstraint")
                    selectorAspect.Parent = selector

                    -- Input fields (right side)
                    local inputsHolder = Instance.new("Frame")
                    inputsHolder.BackgroundTransparency = 1
                    inputsHolder.Size = UDim2.new(0.5, -6, 0, 240)
                    inputsHolder.Position = UDim2.new(0.5, 6, 0, 45)
                    inputsHolder.Parent = colorFrame

                    local function createColorInput(labelText, yPos)
                        local inputFrame = Instance.new("Frame")
                        inputFrame.BackgroundTransparency = 1
                        inputFrame.Size = UDim2.new(1, 0, 0, 24)
                        inputFrame.Position = UDim2.new(0, 0, 0, yPos)
                        inputFrame.Parent = inputsHolder

                        local inputLabel = Instance.new("TextLabel")
                        inputLabel.BackgroundTransparency = 1
                        inputLabel.Text = labelText
                        inputLabel.TextColor3 = Theme.SubText
                        inputLabel.TextSize = 11
                        inputLabel.Font = GetFont(Window.Font, "Medium")
                        inputLabel.Size = UDim2.new(0, 25, 1, 0)
                        inputLabel.TextXAlignment = Enum.TextXAlignment.Left
                        inputLabel.Parent = inputFrame

                        local input = Instance.new("TextBox")
                        input.BackgroundColor3 = Theme.Card
                        input.BorderSizePixel = 0
                        input.Position = UDim2.new(0, 30, 0, 0)
                        input.Size = UDim2.new(1, -30, 1, 0)
                        input.TextColor3 = Theme.Text
                        input.PlaceholderColor3 = Theme.Muted
                        input.Font = GetFont(Window.Font, "Regular")
                        input.TextSize = 11
                        input.Text = ""
                        input.Parent = inputFrame
                        AddCorner(input, 3)

                        return input
                    end

                    local rInput = createColorInput("R:", 0)
                    local gInput = createColorInput("G:", 28)
                    local bInput = createColorInput("B:", 56)
                    local hInput = createColorInput("H:", 90)
                    local sInput = createColorInput("S:", 118)
                    local vInput = createColorInput("V:", 146)
                    local hexInput = createColorInput("Hex:", 174)

                    local updatingInputs = false

                    -- Value slider label
                    local valueLabel = Instance.new("TextLabel")
                    valueLabel.BackgroundTransparency = 1
                    valueLabel.Text = "Brightness"
                    valueLabel.TextColor3 = Theme.SubText
                    valueLabel.TextSize = 11
                    valueLabel.Font = GetFont(Window.Font, "Regular")
                    valueLabel.Position = UDim2.new(0, 12, 0, 280)
                    valueLabel.Size = UDim2.new(1, -24, 0, 12)
                    valueLabel.TextXAlignment = Enum.TextXAlignment.Left
                    valueLabel.Parent = colorFrame

                    -- Value slider
                    local valueSlider = Instance.new("TextButton")
                    valueSlider.BackgroundColor3 = Theme.Surface
                    valueSlider.BorderSizePixel = 0
                    valueSlider.Position = UDim2.new(0, 12, 0, 295)
                    valueSlider.Size = UDim2.new(1, -24, 0, 14)
                    valueSlider.AutoButtonColor = false
                    valueSlider.Text = ""
                    valueSlider.Parent = colorFrame
                    AddCorner(valueSlider, 3)

                    local valueSliderGradient = Instance.new("UIGradient")
                    valueSliderGradient.Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
                    }
                    valueSliderGradient.Parent = valueSlider

                    local sliderBar = Instance.new("Frame")
                    sliderBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                    sliderBar.BorderSizePixel = 0
                    sliderBar.Size = UDim2.new(0, 3, 1, 0)
                    sliderBar.Position = UDim2.new(1, -3, 0, 0)
                    sliderBar.Parent = valueSlider
                    AddCorner(sliderBar, 2)

                    -- Transparency slider label
                    local transparencyLabel = Instance.new("TextLabel")
                    transparencyLabel.BackgroundTransparency = 1
                    transparencyLabel.Text = "Transparency"
                    transparencyLabel.TextColor3 = Theme.SubText
                    transparencyLabel.TextSize = 11
                    transparencyLabel.Font = GetFont(Window.Font, "Regular")
                    transparencyLabel.Position = UDim2.new(0, 12, 0, 312)
                    transparencyLabel.Size = UDim2.new(1, -24, 0, 12)
                    transparencyLabel.TextXAlignment = Enum.TextXAlignment.Left
                    transparencyLabel.Parent = colorFrame

                    -- Transparency slider
                    local transparencySlider = Instance.new("TextButton")
                    transparencySlider.BackgroundColor3 = Theme.Surface
                    transparencySlider.BorderSizePixel = 0
                    transparencySlider.Position = UDim2.new(0, 12, 0, 327)
                    transparencySlider.Size = UDim2.new(1, -24, 0, 14)
                    transparencySlider.AutoButtonColor = false
                    transparencySlider.Text = ""
                    transparencySlider.Parent = colorFrame
                    AddCorner(transparencySlider, 3)

                    local transparencyGradient = Instance.new("UIGradient")
                    transparencyGradient.Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 100, 100))
                    }
                    transparencyGradient.Parent = transparencySlider

                    local transparencyBar = Instance.new("Frame")
                    transparencyBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    transparencyBar.BorderSizePixel = 0
                    transparencyBar.Size = UDim2.new(0, 3, 1, 0)
                    transparencyBar.Position = UDim2.new(0, 0, 0, 0)
                    transparencyBar.Parent = transparencySlider
                    AddCorner(transparencyBar, 2)

                    -- Color preview with checkered background
                    local colorSampleContainer = Instance.new("Frame")
                    colorSampleContainer.BackgroundTransparency = 1
                    colorSampleContainer.BorderSizePixel = 0
                    colorSampleContainer.Position = UDim2.new(0, 12, 0, 350)
                    colorSampleContainer.Size = UDim2.new(1, -24, 0, 30)
                    colorSampleContainer.ClipsDescendants = true
                    colorSampleContainer.Parent = colorFrame

                    local containerCorner = Instance.new("UICorner")
                    containerCorner.CornerRadius = UDim.new(0, 4)
                    containerCorner.Parent = colorSampleContainer

                    local checkeredBg = Instance.new("Frame")
                    checkeredBg.BackgroundTransparency = 1
                    checkeredBg.BorderSizePixel = 0
                    checkeredBg.Size = UDim2.new(1, 0, 1, 0)
                    checkeredBg.Parent = colorSampleContainer

                    -- Create checkered pattern for color sample
                    local checkerSize = 5
                    for x = 0, math.ceil(colorSampleContainer.AbsoluteSize.X / checkerSize) do
                        for y = 0, math.ceil(colorSampleContainer.AbsoluteSize.Y / checkerSize) do
                            local checker = Instance.new("Frame")
                            checker.BackgroundColor3 = (x + y) % 2 == 0 and Color3.fromRGB(200, 200, 200) or Color3.fromRGB(100, 100, 100)
                            checker.BorderSizePixel = 0
                            checker.Size = UDim2.new(0, checkerSize, 0, checkerSize)
                            checker.Position = UDim2.new(0, x * checkerSize, 0, y * checkerSize)
                            checker.Parent = checkeredBg
                        end
                    end

                    local colorSample = Instance.new("Frame")
                    colorSample.BackgroundColor3 = currentColor
                    colorSample.BackgroundTransparency = currentTransparency
                    colorSample.BorderSizePixel = 0
                    colorSample.Size = UDim2.new(1, 0, 1, 0)
                    colorSample.Parent = colorSampleContainer

                    local function updateColor()
                        previewColor.BackgroundColor3 = currentColor
                        previewColor.BackgroundTransparency = currentTransparency
                        colorSample.BackgroundColor3 = currentColor
                        colorSample.BackgroundTransparency = currentTransparency
                        
                        if not updatingInputs then
                            updatingInputs = true
                            
                            -- Update RGB
                            rInput.Text = tostring(math.floor(currentColor.R * 255))
                            gInput.Text = tostring(math.floor(currentColor.G * 255))
                            bInput.Text = tostring(math.floor(currentColor.B * 255))
                            
                            -- Update HSV
                            local h, s, v = currentColor:ToHSV()
                            hInput.Text = tostring(math.floor(h * 360))
                            sInput.Text = tostring(math.floor(s * 100))
                            vInput.Text = tostring(math.floor(v * 100))
                            
                            -- Update Hex
                            hexInput.Text = string.format("#%02X%02X%02X", 
                                math.floor(currentColor.R * 255),
                                math.floor(currentColor.G * 255),
                                math.floor(currentColor.B * 255)
                            )
                            
                            updatingInputs = false
                        end
                        
                        if sectionConfig.Flag then
                            OpenCore.Flags[sectionConfig.Flag] = {Color = currentColor, Transparency = currentTransparency}
                        end
                        task.spawn(function()
                            pcall(sectionConfig.Callback, {Color = currentColor, Transparency = currentTransparency})
                        end)
                    end

                    -- Color preset squares at 45 degree angles
                    -- 0° (up) = Purple (270°), 45° = Blue, 90° = Cyan, 135° = Green, 180° = Yellow-Green, 225° = Orange-Yellow, 270° = Red, 315° = Pink
                    local presetAngles = {0, 45, 90, 135, 180, 225, 270, 315}
                    local presetSquares = {}
                    
                    for _, angle in ipairs(presetAngles) do
                        local square = Instance.new("TextButton")
                        -- Offset hue by 90° to match wheel orientation (0° up = purple/270°)
                        local hue = ((angle + 90) % 360) / 360
                        square.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
                        square.BorderSizePixel = 0
                        square.Size = UDim2.new(0, 14, 0, 14)
                        square.Text = ""
                        square.AutoButtonColor = false
                        square.Parent = wheelHolder
                        
                        local radians = math.rad(angle)
                        local distance = 1.35 -- outside the smaller circle
                        local x = math.sin(radians) * distance * 75
                        local y = math.cos(radians) * distance * 75
                        
                        square.AnchorPoint = Vector2.new(0.5, 0.5)
                        square.Position = UDim2.new(0.5, x, 0.5, y)
                        
                        AddCorner(square, 2)
                        
                        square.MouseButton1Click:Connect(function()
                            currentHue = hue
                            currentSaturation = 1
                            currentValue = 1
                            currentColor = Color3.fromHSV(currentHue, currentSaturation, currentValue)
                            
                            -- Update selector position (scaled to smaller wheel)
                            selector.Position = UDim2.new(0.5, math.sin(radians) * 75, 0.5, math.cos(radians) * 75)
                            
                            -- Update slider to max brightness
                            sliderBar.Position = UDim2.new(1, -3, 0, 0)
                            
                            updateColor()
                        end)
                        
                        square.MouseEnter:Connect(function()
                            Tween(square, {BackgroundColor3 = Color3.fromHSV(hue, 1, 0.8)}, 0.1)
                        end)
                        
                        square.MouseLeave:Connect(function()
                            Tween(square, {BackgroundColor3 = Color3.fromHSV(hue, 1, 1)}, 0.1)
                        end)
                        
                        table.insert(presetSquares, square)
                    end

                    local function toPolar(vec)
                        return vec.Magnitude, math.atan2(vec.Y, vec.X)
                    end

                    local function updateRing()
                        local relativeVector = Vector2.new(Mouse.X, Mouse.Y) - wheel.AbsolutePosition - wheel.AbsoluteSize / 2
                        local wheelRadius = wheel.AbsoluteSize.X / 2
                        local radius, angle = toPolar(relativeVector * Vector2.new(1, -1))
                        
                        if radius > wheelRadius then
                            relativeVector = relativeVector.Unit * wheelRadius
                            radius = wheelRadius
                        end
                        
                        selector.Position = UDim2.new(0.5, relativeVector.X, 0.5, relativeVector.Y)
                        
                        currentHue = (math.deg(angle) + 180) / 360
                        currentSaturation = math.clamp(radius / wheelRadius, 0, 1)
                        
                        currentColor = Color3.fromHSV(currentHue, currentSaturation, currentValue)
                        updateColor()
                    end

                    local function updateSlider()
                        local sliderAbsPos = valueSlider.AbsolutePosition
                        local sliderAbsSize = valueSlider.AbsoluteSize
                        
                        local clampedMousePos = math.clamp(Mouse.X - sliderAbsPos.X, 0, sliderAbsSize.X)
                        currentValue = clampedMousePos / sliderAbsSize.X
                        
                        sliderBar.Position = UDim2.new(0, clampedMousePos - sliderBar.AbsoluteSize.X / 2, 0, 0)
                        
                        currentColor = Color3.fromHSV(currentHue, currentSaturation, currentValue)
                        updateColor()
                    end

                    local function updateTransparency()
                        local sliderAbsPos = transparencySlider.AbsolutePosition
                        local sliderAbsSize = transparencySlider.AbsoluteSize
                        
                        local clampedMousePos = math.clamp(Mouse.X - sliderAbsPos.X, 0, sliderAbsSize.X)
                        currentTransparency = clampedMousePos / sliderAbsSize.X
                        
                        transparencyBar.Position = UDim2.new(0, clampedMousePos - transparencyBar.AbsoluteSize.X / 2, 0, 0)
                        updateColor()
                    end

                    wheel.MouseButton1Down:Connect(function()
                        updateRing()
                        local conn = Mouse.Move:Connect(function()
                            updateRing()
                        end)
                        local endConn
                        endConn = UserInputService.InputEnded:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                conn:Disconnect()
                                endConn:Disconnect()
                            end
                        end)
                    end)

                    valueSlider.MouseButton1Down:Connect(function()
                        updateSlider()
                        local conn = Mouse.Move:Connect(function()
                            updateSlider()
                        end)
                        local endConn
                        endConn = UserInputService.InputEnded:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                conn:Disconnect()
                                endConn:Disconnect()
                            end
                        end)
                    end)

                    transparencySlider.MouseButton1Down:Connect(function()
                        updateTransparency()
                        local conn = Mouse.Move:Connect(function()
                            updateTransparency()
                        end)
                        local endConn
                        endConn = UserInputService.InputEnded:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                conn:Disconnect()
                                endConn:Disconnect()
                            end
                        end)
                    end)

                    -- RGB Input handlers
                    rInput.FocusLost:Connect(function()
                        if not updatingInputs then
                            local r = math.clamp(tonumber(rInput.Text) or 0, 0, 255)
                            currentColor = Color3.fromRGB(r, currentColor.G * 255, currentColor.B * 255)
                            updateColor()
                        end
                    end)

                    gInput.FocusLost:Connect(function()
                        if not updatingInputs then
                            local g = math.clamp(tonumber(gInput.Text) or 0, 0, 255)
                            currentColor = Color3.fromRGB(currentColor.R * 255, g, currentColor.B * 255)
                            updateColor()
                        end
                    end)

                    bInput.FocusLost:Connect(function()
                        if not updatingInputs then
                            local b = math.clamp(tonumber(bInput.Text) or 0, 0, 255)
                            currentColor = Color3.fromRGB(currentColor.R * 255, currentColor.G * 255, b)
                            updateColor()
                        end
                    end)

                    -- HSV Input handlers
                    hInput.FocusLost:Connect(function()
                        if not updatingInputs then
                            local h, s, v = currentColor:ToHSV()
                            h = math.clamp(tonumber(hInput.Text) or 0, 0, 360) / 360
                            currentColor = Color3.fromHSV(h, s, v)
                            updateColor()
                        end
                    end)

                    sInput.FocusLost:Connect(function()
                        if not updatingInputs then
                            local h, s, v = currentColor:ToHSV()
                            s = math.clamp(tonumber(sInput.Text) or 0, 0, 100) / 100
                            currentColor = Color3.fromHSV(h, s, v)
                            updateColor()
                        end
                    end)

                    vInput.FocusLost:Connect(function()
                        if not updatingInputs then
                            local h, s, v = currentColor:ToHSV()
                            v = math.clamp(tonumber(vInput.Text) or 0, 0, 100) / 100
                            currentColor = Color3.fromHSV(h, s, v)
                            updateColor()
                        end
                    end)

                    -- Hex Input handler
                    hexInput.FocusLost:Connect(function()
                        if not updatingInputs then
                            local hex = hexInput.Text:gsub("#", "")
                            if #hex == 6 then
                                local r = tonumber(hex:sub(1, 2), 16) or 0
                                local g = tonumber(hex:sub(3, 4), 16) or 0
                                local b = tonumber(hex:sub(5, 6), 16) or 0
                                currentColor = Color3.fromRGB(r, g, b)
                                updateColor()
                            end
                        end
                    end)

                    -- Initialize inputs
                    updateColor()

                    header.MouseButton1Click:Connect(function()
                        isExpanded = not isExpanded
                        if isExpanded then
                            Tween(colorFrame, {Size = UDim2.new(1, 0, 0, 390)}, 0.2)
                            Tween(arrow, {Rotation = 0}, 0.2)
                        else
                            Tween(colorFrame, {Size = UDim2.new(1, 0, 0, 35)}, 0.2)
                            Tween(arrow, {Rotation = 180}, 0.2)
                        end
                        task.wait(0.2)
                        updateSectionSize()
                    end)

                    return {
                        Set = function(self, color)
                            currentColor = color
                            previewColor.BackgroundColor3 = currentColor
                            if sectionConfig.Flag then
                                OpenCore.Flags[sectionConfig.Flag] = {Color = currentColor, Transparency = currentTransparency}
                            end
                        end
                    }
                end


				-- Input
				function Section:AddInput(inputConfig)
					inputConfig = inputConfig or {}
					inputConfig.Name = inputConfig.Name or "Input"
					inputConfig.Default = inputConfig.Default or ""
					inputConfig.Placeholder = inputConfig.Placeholder or "Enter text..."
					inputConfig.Flag = inputConfig.Flag or nil
					inputConfig.Callback = inputConfig.Callback or function() end

					local inputFrame = Instance.new("Frame")
					inputFrame.BackgroundColor3 = Theme.Surface
					inputFrame.BorderSizePixel = 0
					inputFrame.Size = UDim2.new(1, 0, 0, 50)
					inputFrame.Parent = elements

					AddCorner(inputFrame, 4)
					AddStroke(inputFrame, Theme.Border, 1, 0)

					local label = Instance.new("TextLabel")
					label.BackgroundTransparency = 1
					label.Font = GetFont(Window.Font, "Medium")
					label.Text = inputConfig.Name
					label.TextColor3 = Theme.Text
					label.TextSize = 13
					label.Position = UDim2.new(0, 12, 0, 6)
					label.Size = UDim2.new(1, -24, 0, 18)
					label.TextXAlignment = Enum.TextXAlignment.Left
					label.Parent = inputFrame

					local textBox = Instance.new("TextBox")
					textBox.BackgroundColor3 = Theme.Card
					textBox.BorderSizePixel = 0
					textBox.Position = UDim2.new(0, 12, 0, 28)
					textBox.Size = UDim2.new(1, -24, 0, 18)
					textBox.Font = GetFont(Window.Font, "Regular")
					textBox.PlaceholderText = inputConfig.Placeholder
					textBox.PlaceholderColor3 = Theme.Muted
					textBox.Text = inputConfig.Default
					textBox.TextColor3 = Theme.Text
					textBox.TextSize = 14
					textBox.TextXAlignment = Enum.TextXAlignment.Left
					textBox.ClearTextOnFocus = false
					textBox.Parent = inputFrame

					AddCorner(textBox, 3)

					local textPadding = Instance.new("UIPadding")
					textPadding.PaddingLeft = UDim.new(0, 8)
					textPadding.PaddingRight = UDim.new(0, 8)
					textPadding.Parent = textBox

					textBox.FocusLost:Connect(function(enterPressed)
							if enterPressed then
						if inputConfig.Flag then
							OpenCore.Flags[inputConfig.Flag] = textBox.Text
						end
						task.spawn(function()
							pcall(inputConfig.Callback, textBox.Text)
						end)
							repeat
								textBox.Text = "" wait() until textBox.Text == ""
							end
					end)

					return {
						Set = function(self, value)
							textBox.Text = value
							if inputConfig.Flag then
								OpenCore.Flags[inputConfig.Flag] = value
								repeat
								textBox.Text = "" wait() until textBox.Text == ""
							else
								repeat
								textBox.Text = "" wait() until textBox.Text == ""
							end
						end
					}
				end

				-- Label
				function Section:AddLabel(labelConfig)
					if typeof(labelConfig) == "string" then
						labelConfig = {Text = labelConfig}
					end
					labelConfig = labelConfig or {}

					local labelFrame = Instance.new("Frame")
					labelFrame.BackgroundTransparency = 1
					labelFrame.Size = UDim2.new(1, 0, 0, 20)
					labelFrame.Parent = elements

					local label = Instance.new("TextLabel")
					label.BackgroundTransparency = 1
					label.Text = labelConfig.Text or "Label"
					label.Font = GetFont(Window.Font, "Regular")
					label.TextSize = 12
					label.TextColor3 = Theme.SubText
					label.TextXAlignment = Enum.TextXAlignment.Left
					label.TextWrapped = true
					label.Size = UDim2.new(1, 0, 1, 0)
					label.Parent = labelFrame

					return {
						Set = function(self, text)
							label.Text = text
						end,
						SetColor = function(self, color)
							label.TextColor3 = color
						end,
						Font = function(self, font)
							label.Font = font
						end,
						TextSize = function(self, value)
							label.TextSize = tonumber(value)
						end,
						TextXAlignment = function(self, result)
							label.TextXAlignment = result
						end
					}
				end

				-- KeyBind
				function Section:KeyBind(keyBindConfig)
					keyBindConfig = keyBindConfig or {}
					keyBindConfig.Name = keyBindConfig.Name or "KeyBind"
					keyBindConfig.Default = keyBindConfig.Default or Enum.KeyCode.E
					keyBindConfig.Flag = keyBindConfig.Flag or nil
					keyBindConfig.Callback = keyBindConfig.Callback or function() end
					keyBindConfig.OnKeyPressed = keyBindConfig.OnKeyPressed or function() end
					keyBindConfig.Clicks = keyBindConfig.Clicks or false -- Enable mouse clicks
				
					local selectedKey = keyBindConfig.Default
					local listening = false
					local connection = nil
				
					local blacklistedKeys = {
						[Enum.KeyCode.Unknown] = true,
						[Enum.KeyCode.W] = true,
						[Enum.KeyCode.A] = true,
						[Enum.KeyCode.S] = true,
						[Enum.KeyCode.D] = true,
						[Enum.KeyCode.Space] = true,
					}
				
					local keyBindFrame = Instance.new("Frame")
					keyBindFrame.BackgroundColor3 = Theme.Surface
					keyBindFrame.BorderSizePixel = 0
					keyBindFrame.Size = UDim2.new(1, 0, 0, 35)
					keyBindFrame.Parent = elements
				
					AddCorner(keyBindFrame, 4)
					AddStroke(keyBindFrame, Theme.Border, 1, 0)
				
					local label = Instance.new("TextLabel")
					label.BackgroundTransparency = 1
					label.Font = GetFont(Window.Font, "Medium")
					label.Text = keyBindConfig.Name
					label.TextColor3 = Theme.Text
					label.TextSize = 13
					label.Position = UDim2.new(0, 12, 0, 0)
					label.Size = UDim2.new(1, -110, 1, 0)
					label.TextXAlignment = Enum.TextXAlignment.Left
					label.Parent = keyBindFrame
				
					local keyButton = Instance.new("TextButton")
					keyButton.AnchorPoint = Vector2.new(1, 0.5)
					keyButton.BackgroundColor3 = Theme.Card
					keyButton.BorderSizePixel = 0
					keyButton.Position = UDim2.new(1, -12, 0.5, 0)
					keyButton.Size = UDim2.new(0, 90, 0, 26)
					keyButton.Font = GetFont(Window.Font, "Bold")
					keyButton.Text = selectedKey.Name or "None"
					keyButton.TextColor3 = Theme.Text
					keyButton.TextSize = 12
					keyButton.Parent = keyBindFrame
				
					AddCorner(keyButton, 4)
					AddStroke(keyButton, Theme.Border, 1, 0)
				
					local function formatKeyName(keyCode)
						if not keyCode or keyCode == "None" then
							return "None"
						end
						
						if typeof(keyCode) == "EnumItem" and tostring(keyCode.EnumType) == "UserInputType" then
							local name = keyCode.Name
							if name == "MouseButton1" then return "LMB"
							elseif name == "MouseButton2" then return "RMB"
							elseif name == "MouseButton3" then return "MMB"
							end
							return name
						end
						
						local name = keyCode.Name or tostring(keyCode)
						if not name then return "None" end
						
						if name == "LeftShift" or name == "RightShift" then
							return "Shift"
						elseif name == "LeftControl" or name == "RightControl" then
							return "Ctrl"
						elseif name == "LeftAlt" or name == "RightAlt" then
							return "Alt"
						elseif name == "Return" then
							return "Enter"
						elseif name == "Backspace" then
							return "Back"
						elseif name and name:match("^Numpad") then
							return name:gsub("Numpad", "Num")
						end
						
						return name
					end
				
					local function stopListening()
						listening = false
						keyButton.Text = formatKeyName(selectedKey)
						Tween(keyButton, {BackgroundColor3 = Theme.Card}, 0.2)
						Tween(keyButton, {TextColor3 = Theme.Text}, 0.2)
						
						if connection then
							connection:Disconnect()
							connection = nil
						end
					end
				
					local function startListening()
						if listening then
							stopListening()
							return
						end
						
						listening = true
						keyButton.Text = "..."
						Tween(keyButton, {BackgroundColor3 = Theme.Success}, 0.2)
						Tween(keyButton, {TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.2)
						
						connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
							if not listening then return end
							
							if input.UserInputType == Enum.UserInputType.Keyboard then
								local keyCode = input.KeyCode
								
								if keyCode == Enum.KeyCode.Escape then
									selectedKey = "None"
									keyButton.Text = "None"
									
									if keyBindConfig.Flag then
										OpenCore.Flags[keyBindConfig.Flag] = "None"
									end
									
									task.spawn(function()
										pcall(keyBindConfig.Callback, "None")
									end)
									
									stopListening()
									return
								end
								
								if blacklistedKeys[keyCode] then
									keyButton.Text = "Invalid!"
									task.wait(0.5)
									stopListening()
									return
								end
								
								selectedKey = keyCode
								
								if keyBindConfig.Flag then
									OpenCore.Flags[keyBindConfig.Flag] = selectedKey
								end
								
								task.spawn(function()
									pcall(keyBindConfig.Callback, selectedKey)
								end)
								
								stopListening()
							
							elseif keyBindConfig.Clicks then
								if input.UserInputType == Enum.UserInputType.MouseButton1 or
								   input.UserInputType == Enum.UserInputType.MouseButton2 or
								   input.UserInputType == Enum.UserInputType.MouseButton3 then
									
									selectedKey = input.UserInputType
									
									if keyBindConfig.Flag then
										OpenCore.Flags[keyBindConfig.Flag] = selectedKey
									end
									
									task.spawn(function()
										pcall(keyBindConfig.Callback, selectedKey)
									end)
									
									stopListening()
								end
							end
						end)
						
						task.spawn(function()
							task.wait(5)
							if listening then
								stopListening()
							end
						end)
					end
				
					keyButton.MouseButton1Click:Connect(startListening)
				
					keyButton.MouseEnter:Connect(function()
						if not listening then
							Tween(keyButton, {BackgroundColor3 = Theme.Hover}, 0.15)
						end
					end)
				
					keyButton.MouseLeave:Connect(function()
						if not listening then
							Tween(keyButton, {BackgroundColor3 = Theme.Card}, 0.15)
						end
					end)
				
					local hotkeyConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
						if gameProcessed then return end
						if selectedKey == "None" then return end
						
						if input.UserInputType == Enum.UserInputType.Keyboard then
							if typeof(selectedKey) == "EnumItem" and selectedKey.EnumType == Enum.KeyCode then
								if input.KeyCode == selectedKey then
									task.spawn(function()
										pcall(keyBindConfig.OnKeyPressed)
									end)
								end
							end
						
						elseif keyBindConfig.Clicks then
							if typeof(selectedKey) == "EnumItem" and tostring(selectedKey.EnumType) == "UserInputType" then
								if input.UserInputType == selectedKey then
									task.spawn(function()
										pcall(keyBindConfig.OnKeyPressed)
									end)
								end
							end
						end
					end)
				
					keyButton.Text = formatKeyName(selectedKey)
				
					return {
						Set = function(self, keyCode)
							selectedKey = keyCode
							keyButton.Text = formatKeyName(selectedKey)
							if keyBindConfig.Flag then
								OpenCore.Flags[keyBindConfig.Flag] = selectedKey
							end
						end,
						Get = function(self)
							return selectedKey
						end,
						Disconnect = function(self)
							if hotkeyConnection then
								hotkeyConnection:Disconnect()
							end
							if connection then
								connection:Disconnect()
							end
						end
					}
				end

				-- Alias for KeyBind
				function Section:AddKeybind(keyBindConfig)
					return self:KeyBind(keyBindConfig)
				end

				return Section
			end

			return Tab
		end

		Window._initialized = true
	end

	-- KEY SYSTEM CHECK
	if config.KeySystem then
		local KeySystemAPI = CreateKeySystem({
			WindowTitle = config.Title,
			KeyDescription = config.KeyDescription or "Please enter your key to continue",
			KeySystem = config.KeySystem,
			Key = config.KeySystem,
			KeyLink = config.KeyLink or "https://example.com/getkey"
		}, function(success)
			if success then
				InitializeWindow() -- Create window after key verified
			end
		end, Theme) -- Pass theme to KeySystem

		-- Store EnterKey function on OpenCore
		OpenCore.EnterKey = function(key)
			if KeySystemAPI and KeySystemAPI.EnterKey then
				KeySystemAPI:EnterKey(key)
			end
		end
	else
		-- No key system, initialize immediately
		InitializeWindow()
	end

	return Window
end

-- Set Theme at Runtime (Really Buggy)
function OpenCore:SetTheme(themeName)
	if not self.Themes[themeName] then
		warn("Theme '" .. themeName .. "' does not exist!")
		return false
	end

	self.CurrentTheme = themeName
	Theme = self.Themes[themeName]

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local openCoreGui = playerGui:FindFirstChild("OpenCore")

	if not openCoreGui then return false end

	-- Helper function to check if element matches a color
	local function colorMatches(color, targets)
		for _, target in ipairs(targets) do
			if math.abs(color.R - target.R) < 0.01 and 
				math.abs(color.G - target.G) < 0.01 and 
				math.abs(color.B - target.B) < 0.01 then
				return true
			end
		end
		return false
	end

	-- Dark theme colors
	local darkColors = {
		Background = Color3.fromRGB(15, 15, 15),
		Surface = Color3.fromRGB(20, 20, 20),
		Card = Color3.fromRGB(25, 25, 25)
	}

	-- Graphene theme colors
	local grapheneColors = {
		Background = Color3.fromRGB(12, 12, 12),
		Surface = Color3.fromRGB(28, 28, 28),
		Card = Color3.fromRGB(18, 18, 18)
	}

	-- Light theme colors
	local lightColors = {
		Background = Color3.fromRGB(245, 245, 245),
		Surface = Color3.fromRGB(255, 255, 255),
		Card = Color3.fromRGB(248, 248, 248)
	}

	-- Get all descendants
	for _, element in ipairs(openCoreGui:GetDescendants()) do
		if element:IsA("GuiObject") then
			if element.BackgroundTransparency < 1 then
				if colorMatches(element.BackgroundColor3, {darkColors.Background, grapheneColors.Background, lightColors.Background}) then
					Tween(element, {BackgroundColor3 = Theme.Background}, 0.2)
				elseif colorMatches(element.BackgroundColor3, {darkColors.Surface, grapheneColors.Surface, lightColors.Surface}) then
					Tween(element, {BackgroundColor3 = Theme.Surface}, 0.2)
				elseif colorMatches(element.BackgroundColor3, {darkColors.Card, grapheneColors.Card, lightColors.Card}) then
					Tween(element, {BackgroundColor3 = Theme.Card}, 0.2)
				elseif element.BackgroundColor3 == Color3.fromRGB(40, 40, 40) then
				elseif element.Name == "Frame" and element.Parent and element.Parent:IsA("TextButton") then
					local isToggleOn = element.Size == UDim2.new(0, 40, 0, 20)
					if isToggleOn then
						local shouldBeOn = element.BackgroundColor3.R > 0.3
						if shouldBeOn then
							Tween(element, {BackgroundColor3 = Theme.Success}, 0.2)
						end
					end
				end
			end

			-- Update text colors
			if element:IsA("TextLabel") or element:IsA("TextButton") then
				if element.Font == Enum.Font.GothamBold or element.Font == Enum.Font.GothamMedium then
					Tween(element, {TextColor3 = Theme.Text}, 0.2)
				elseif element:IsA("TextLabel") then
					Tween(element, {TextColor3 = Theme.SubText}, 0.2)
				end
			end

			-- Update text boxes
			if element:IsA("TextBox") then
				Tween(element, {TextColor3 = Theme.Text, PlaceholderColor3 = Theme.Muted}, 0.2)
				if element.BackgroundTransparency < 1 then
					Tween(element, {BackgroundColor3 = Theme.Card}, 0.2)
				end
			end

			-- Update image colors
			if element:IsA("ImageLabel") or element:IsA("ImageButton") then
				if element.ImageColor3 ~= Color3.fromRGB(255, 255, 255) then
					Tween(element, {ImageColor3 = Theme.SubText}, 0.2)
				end
			end

			-- Update strokes
			if element:IsA("UIStroke") then
				Tween(element, {Color = Theme.Border}, 0.2)
			end

			-- Update scrollbars
			if element:IsA("ScrollingFrame") then
				element.ScrollBarImageColor3 = Theme.SubText
			end
		end
	end

	print("Theme changed to: " .. themeName)
	return true
end

-- CreateTheme
function OpenCore:CreateTheme(themeName, themeData)
	if self.Themes[themeName] then
		warn("Theme '" .. themeName .. "' already exists! Overwriting...")
	end

	local requiredProps = {
		"Primary", "Secondary", "Accent",
		"Background", "Surface", "Card",
		"Text", "SubText", "Muted",
		"Success", "Border", "Hover", "SliderFill", 
		"ToggleFill"
	}

	for _, prop in ipairs(requiredProps) do
		if not themeData[prop] then
			warn("Theme '" .. themeName .. "' is missing property: " .. prop)
			return false
		end
	end

	self.Themes[themeName] = themeData
	print("Theme '" .. themeName .. "' created successfully!")
	return true
end


return OpenCore
