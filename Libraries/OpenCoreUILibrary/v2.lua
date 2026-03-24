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
	InputBox.TextSize = 14
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
		subtitle.Size = UDim2.new(0, 300, 0, 18)
		subtitle.TextXAlignment = Enum.TextXAlignment.Left
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
				section.Size = UDim2.new(1, 0, 0, 0)
				section.AutomaticSize = Enum.AutomaticSize.Y
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
				elements.Size = UDim2.new(1, 0, 0, 0)
				elements.AutomaticSize = Enum.AutomaticSize.Y
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

					local paragraphTitle = Instance.new("TextLabel")
					paragraphTitle.BackgroundTransparency = 1
					paragraphTitle.Font = GetFont(Window.Font, "Bold")
					paragraphTitle.Text = paragraphConfig.Title
					paragraphTitle.TextColor3 = Theme.Text
					paragraphTitle.TextSize = 13
					paragraphTitle.Size = UDim2.new(1, 0, 0, 18)
					paragraphTitle.TextXAlignment = Enum.TextXAlignment.Left
					paragraphTitle.Parent = paragraphFrame

					local paragraphText = Instance.new("TextLabel")
					paragraphText.BackgroundTransparency = 1
					paragraphText.Font = GetFont(Window.Font, "Regular")
					paragraphText.Text = paragraphConfig.Content
					paragraphText.TextColor3 = Theme.SubText
					paragraphText.TextSize = 12
					paragraphText.Position = UDim2.new(0, 0, 0, 22)
					paragraphText.Size = UDim2.new(1, 0, 0, 0)
					paragraphText.AutomaticSize = Enum.AutomaticSize.Y
					paragraphText.TextWrapped = true
					paragraphText.TextXAlignment = Enum.TextXAlignment.Left
					paragraphText.TextYAlignment = Enum.TextYAlignment.Top
					paragraphText.Parent = paragraphFrame

					return {
						SetTitle = function(self, text)
							paragraphTitle.Text = text
						end,
						SetContent = function(self, text)
							paragraphText.Text = text
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
							pcall(btnConfig.Callback)
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
							local targetSize = UDim2.new(1, 0, 0, 36 + (#optionsContainer:GetChildren() - 1) * 30)
							Tween(dropFrame, {Size = targetSize}, 0.2)
						end
					end

					header.MouseButton1Click:Connect(function()
						opened = not opened
						local targetSize = opened and UDim2.new(1, 0, 0, 36 + (#optionsContainer:GetChildren() - 1) * 30) or UDim2.new(1, 0, 0, 35)

						Tween(dropFrame, {Size = targetSize}, 0.2)
						Tween(arrow, {Rotation = opened and 180 or 0}, 0.2)
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

				-- Colour Picker (Pending Ui ReLook)
				function Section:AddColorPicker(colorConfig)
					colorConfig = colorConfig or {}
					colorConfig.Name = colorConfig.Name or "Color Picker"
					colorConfig.Default = colorConfig.Default or Color3.fromRGB(255, 255, 255)
					colorConfig.Flag = colorConfig.Flag or nil
					colorConfig.Callback = colorConfig.Callback or function() end

					local selectedColor = colorConfig.Default
					local h, s, v = RGBtoHSV(math.floor(selectedColor.R * 255), math.floor(selectedColor.G * 255), math.floor(selectedColor.B * 255))
					local r, g, b = math.floor(selectedColor.R * 255), math.floor(selectedColor.G * 255), math.floor(selectedColor.B * 255)
					local expanded = false

					local colorFrame = Instance.new("Frame")
					colorFrame.BackgroundColor3 = Theme.Surface
					colorFrame.BorderSizePixel = 0
					colorFrame.Size = UDim2.new(1, 0, 0, 35)
					colorFrame.ClipsDescendants = true
					colorFrame.Parent = elements

					AddCorner(colorFrame, 4)
					AddStroke(colorFrame, Theme.Border, 1, 0)

					-- Header
					local header = Instance.new("TextButton")
					header.BackgroundTransparency = 1
					header.Size = UDim2.new(1, 0, 0, 35)
					header.Text = ""
					header.Parent = colorFrame

					local label = Instance.new("TextLabel")
					label.BackgroundTransparency = 1
					label.Font = GetFont(Window.Font, "Medium")
					label.Text = colorConfig.Name
					label.TextColor3 = Theme.Text
					label.TextSize = 13
					label.Position = UDim2.new(0, 12, 0, 0)
					label.Size = UDim2.new(1, -60, 1, 0)
					label.TextXAlignment = Enum.TextXAlignment.Left
					label.Parent = header

					local colorPreview = Instance.new("Frame")
					colorPreview.AnchorPoint = Vector2.new(1, 0.5)
					colorPreview.BackgroundColor3 = selectedColor
					colorPreview.BorderSizePixel = 0
					colorPreview.Position = UDim2.new(1, -12, 0.5, 0)
					colorPreview.Size = UDim2.new(0, 35, 0, 20)
					colorPreview.Parent = header

					AddCorner(colorPreview, 4)
					AddStroke(colorPreview, Theme.Border, 1, 0)

					local panel = Instance.new("Frame")
					panel.BackgroundTransparency = 1
					panel.Position = UDim2.new(0, 0, 0, 40)
					panel.Size = UDim2.new(1, 0, 0, 200)
					panel.Parent = colorFrame

					local panelPadding = Instance.new("UIPadding")
					panelPadding.PaddingLeft = UDim.new(0, 12)
					panelPadding.PaddingRight = UDim.new(0, 12)
					panelPadding.PaddingBottom = UDim.new(0, 12)
					panelPadding.Parent = panel

					-- Large Color Preview
					local largePreview = Instance.new("Frame")
					largePreview.BackgroundColor3 = selectedColor
					largePreview.BorderSizePixel = 0
					largePreview.Size = UDim2.new(1, 0, 0, 60)
					largePreview.Parent = panel

					AddCorner(largePreview, 6)
					AddStroke(largePreview, Theme.Border, 1, 0)

					-- RGB/HSV Display
					local rgbLabel = Instance.new("TextLabel")
					rgbLabel.BackgroundTransparency = 1
					rgbLabel.Font = GetFont(Window.Font, "Regular")
					rgbLabel.Text = string.format("RGB: %d, %d, %d", r, g, b)
					rgbLabel.TextColor3 = Theme.SubText
					rgbLabel.TextSize = 11
					rgbLabel.Position = UDim2.new(0, 0, 0, 66)
					rgbLabel.Size = UDim2.new(0.5, 0, 0, 15)
					rgbLabel.TextXAlignment = Enum.TextXAlignment.Left
					rgbLabel.Parent = panel

					local hsvLabel = Instance.new("TextLabel")
					hsvLabel.BackgroundTransparency = 1
					hsvLabel.Font = GetFont(Window.Font, "Regular")
					hsvLabel.Text = string.format("HSV: %d, %d, %d", h, s, v)
					hsvLabel.TextColor3 = Theme.SubText
					hsvLabel.TextSize = 11
					hsvLabel.Position = UDim2.new(0.5, 0, 0, 66)
					hsvLabel.Size = UDim2.new(0.5, 0, 0, 15)
					hsvLabel.TextXAlignment = Enum.TextXAlignment.Right
					hsvLabel.Parent = panel

					-- HSV Sliders
					local function createHSVSlider(name, defaultVal, maxVal, yPos)
						local sliderLabel = Instance.new("TextLabel")
						sliderLabel.BackgroundTransparency = 1
						sliderLabel.Font = GetFont(Window.Font, "Regular")
						sliderLabel.Text = name
						sliderLabel.TextColor3 = Theme.SubText
						sliderLabel.TextSize = 11
						sliderLabel.Position = UDim2.new(0, 0, 0, yPos)
						sliderLabel.Size = UDim2.new(0, 20, 0, 18)
						sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
						sliderLabel.Parent = panel

						local sliderValue = Instance.new("TextLabel")
						sliderValue.BackgroundTransparency = 1
						sliderValue.Font = GetFont(Window.Font, "Bold")
						sliderValue.Text = tostring(math.floor(defaultVal))
						sliderValue.TextColor3 = Theme.Text
						sliderValue.TextSize = 11
						sliderValue.Position = UDim2.new(1, -35, 0, yPos)
						sliderValue.Size = UDim2.new(0, 35, 0, 18)
						sliderValue.TextXAlignment = Enum.TextXAlignment.Right
						sliderValue.Parent = panel

						local sliderBar = Instance.new("TextButton")
						sliderBar.BorderSizePixel = 0
						sliderBar.Position = UDim2.new(0, 28, 0, yPos + 4)
						sliderBar.Size = UDim2.new(1, -70, 0, 10)
						sliderBar.Text = ""
						sliderBar.Parent = panel

						AddCorner(sliderBar, 5)

						-- Gradient for Hue slider - use bright background
						if name == "H" then
							sliderBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
							local gradient = Instance.new("UIGradient")
							gradient.Color = ColorSequence.new{
								ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
								ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
								ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
								ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
								ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
								ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
								ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
							}
							gradient.Parent = sliderBar
						else
							sliderBar.BackgroundColor3 = Theme.Card
							local sliderFill = Instance.new("Frame")
							sliderFill.BackgroundColor3 = Theme.SliderFill
							sliderFill.BorderSizePixel = 0
							sliderFill.Size = UDim2.new(defaultVal / maxVal, 0, 1, 0)
							sliderFill.Parent = sliderBar

							AddCorner(sliderFill, 5)
							return sliderBar, sliderFill, sliderValue
						end

						return sliderBar, nil, sliderValue
					end

					local hBar, _, hValue = createHSVSlider("H", h, 360, 86)
					local sBar, sFill, sValue = createHSVSlider("S", s, 100, 106)
					local vBar, vFill, vValue = createHSVSlider("V", v, 100, 126)

					-- Color Palette
					local paletteFrame = Instance.new("Frame")
					paletteFrame.BackgroundTransparency = 1
					paletteFrame.Position = UDim2.new(0, 0, 0, 146)
					paletteFrame.Size = UDim2.new(1, 0, 0, 40)
					paletteFrame.Parent = panel

					local paletteLayout = Instance.new("UIListLayout")
					paletteLayout.FillDirection = Enum.FillDirection.Horizontal
					paletteLayout.Padding = UDim.new(0, 6)
					paletteLayout.Parent = paletteFrame

					local presetColors = {
						Color3.fromRGB(244, 67, 54),   -- Red
						Color3.fromRGB(255, 152, 0),   -- Orange
						Color3.fromRGB(255, 193, 7),   -- Yellow
						Color3.fromRGB(0, 188, 212),   -- Cyan
						Color3.fromRGB(76, 175, 80),   -- Green
						Color3.fromRGB(156, 39, 176),  -- Purple
						Color3.fromRGB(255, 255, 255), -- White
						Color3.fromRGB(0, 0, 0)        -- Black
					}

					for _, color in ipairs(presetColors) do
						local swatch = Instance.new("TextButton")
						swatch.BackgroundColor3 = color
						swatch.BorderSizePixel = 0
						swatch.Size = UDim2.new(0, 35, 0, 35)
						swatch.Text = ""
						swatch.Parent = paletteFrame

						AddCorner(swatch, 6)
						AddStroke(swatch, Theme.Border, 1, 0)

						swatch.MouseButton1Click:Connect(function()
							selectedColor = color
							r, g, b = math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255)
							h, s, v = RGBtoHSV(r, g, b)

							colorPreview.BackgroundColor3 = selectedColor
							largePreview.BackgroundColor3 = selectedColor
							hValue.Text = tostring(math.floor(h))
							sValue.Text = tostring(math.floor(s))
							vValue.Text = tostring(math.floor(v))
							if sFill then sFill.Size = UDim2.new(s / 100, 0, 1, 0) end
							if vFill then vFill.Size = UDim2.new(v / 100, 0, 1, 0) end

							rgbLabel.Text = string.format("RGB: %d, %d, %d", r, g, b)
							hsvLabel.Text = string.format("HSV: %d, %d, %d", h, s, v)

							if colorConfig.Flag then
								OpenCore.Flags[colorConfig.Flag] = selectedColor
							end
							task.spawn(function()
								pcall(colorConfig.Callback, {
									Color = selectedColor,
									RGB = {R = r, G = g, B = b},
									HSV = {H = h, S = s, V = v},
									HEX = ColorToHex(selectedColor)
								})
							end)
						end)
					end

					local function updateColor()
						r, g, b = HSVtoRGB(h, s, v)
						selectedColor = Color3.fromRGB(r, g, b)
						colorPreview.BackgroundColor3 = selectedColor
						largePreview.BackgroundColor3 = selectedColor

						rgbLabel.Text = string.format("RGB: %d, %d, %d", r, g, b)
						hsvLabel.Text = string.format("HSV: %d, %d, %d", h, s, v)

						if colorConfig.Flag then
							OpenCore.Flags[colorConfig.Flag] = selectedColor
						end
						task.spawn(function()
							pcall(colorConfig.Callback, {
								Color = selectedColor,
								RGB = {R = r, G = g, B = b},
								HSV = {H = h, S = s, V = v},
								HEX = ColorToHex(selectedColor)
							})
						end)
					end

					local function createSliderLogic(bar, fill, valueLabel, channel, maxVal)
						local dragging = false

						local function update(input)
							local pos = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
							local val = pos * maxVal

							if channel == "h" then h = val
							elseif channel == "s" then s = val
							elseif channel == "v" then v = val end

							valueLabel.Text = tostring(math.floor(val))
							if fill then
								Tween(fill, {Size = UDim2.new(pos, 0, 1, 0)}, 0.05)
							end
							updateColor()
						end

						bar.InputBegan:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 then
								dragging = true
								update(input)
							end
						end)

						bar.InputEnded:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 then
								dragging = false
							end
						end)

						UserInputService.InputChanged:Connect(function(input)
							if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
								update(input)
							end
						end)
					end

					createSliderLogic(hBar, nil, hValue, "h", 360)
					createSliderLogic(sBar, sFill, sValue, "s", 100)
					createSliderLogic(vBar, vFill, vValue, "v", 100)

					-- Toggle expansion
					header.MouseButton1Click:Connect(function()
						expanded = not expanded
						local targetSize = expanded and UDim2.new(1, 0, 0, 250) or UDim2.new(1, 0, 0, 35)
						Tween(colorFrame, {Size = targetSize}, 0.3)
						colorPreview.Visible = not expanded
					end)

					return {
						Set = function(self, color)
							selectedColor = color
							r, g, b = math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255)
							h, s, v = RGBtoHSV(r, g, b)

							colorPreview.BackgroundColor3 = selectedColor
							largePreview.BackgroundColor3 = selectedColor
							hValue.Text = tostring(math.floor(h))
							sValue.Text = tostring(math.floor(s))
							vValue.Text = tostring(math.floor(v))
							if sFill then sFill.Size = UDim2.new(s / 100, 0, 1, 0) end
							if vFill then vFill.Size = UDim2.new(v / 100, 0, 1, 0) end

							rgbLabel.Text = string.format("RGB: %d, %d, %d", r, g, b)
							hsvLabel.Text = string.format("HSV: %d, %d, %d", h, s, v)

							if colorConfig.Flag then
								OpenCore.Flags[colorConfig.Flag] = selectedColor
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
					textBox.TextSize = 12
					textBox.TextXAlignment = Enum.TextXAlignment.Left
					textBox.ClearTextOnFocus = false
					textBox.Parent = inputFrame

					AddCorner(textBox, 3)

					local textPadding = Instance.new("UIPadding")
					textPadding.PaddingLeft = UDim.new(0, 8)
					textPadding.PaddingRight = UDim.new(0, 8)
					textPadding.Parent = textBox

					textBox.FocusLost:Connect(function()
						if inputConfig.Flag then
							OpenCore.Flags[inputConfig.Flag] = textBox.Text
						end
						task.spawn(function()
							pcall(inputConfig.Callback, textBox.Text)
						end)
					end)

					return {
						Set = function(self, value)
							textBox.Text = value
							if inputConfig.Flag then
								OpenCore.Flags[inputConfig.Flag] = value
							end
						end
					}
				end

				-- Label
				function Section:AddLabel(labelConfig)
					labelConfig = labelConfig or {}

					local labelFrame = Instance.new("Frame")
					labelFrame.BackgroundTransparency = 1
					labelFrame.Size = UDim2.new(1, 0, 0, 20)
					labelFrame.Parent = elements

					local label = Instance.new("TextLabel")
					label.BackgroundTransparency = 1
					label.Text = labelConfig.Text or "Label"
					label.Font = labelConfig.Font or Enum.Font.Gotham
					label.TextSize = labelConfig.TextSize or 12
					label.TextColor3 = labelConfig.TextColor or Theme.SubText
					label.TextXAlignment = labelConfig.TextXAlignment or Enum.TextXAlignment.Left
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
						
						local name = keyCode.Name
						
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
						elseif name:match("^Numpad") then
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

-- Improved Color Wheel Picker with Transparency & Brightness
function OpenCore:AddColorWheel(sectionConfig)
	sectionConfig = sectionConfig or {}
	sectionConfig.Name = sectionConfig.Name or "Color Picker"
	sectionConfig.Default = sectionConfig.Default or Color3.fromRGB(255, 0, 0)
	sectionConfig.Flag = sectionConfig.Flag or nil
	sectionConfig.Callback = sectionConfig.Callback or function() end

	local colorFrame = Instance.new("Frame")
	colorFrame.BackgroundColor3 = Theme.Surface
	colorFrame.BorderSizePixel = 0
	colorFrame.Size = UDim2.new(1, 0, 0, 35)
	colorFrame.ClipsDescendants = false
	colorFrame.Parent = elements
	AddCorner(colorFrame, 4)
	AddStroke(colorFrame, Theme.Border, 1, 0)

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = GetFont(Window.Font, "Medium")
	label.Text = sectionConfig.Name
	label.TextColor3 = Theme.Text
	label.TextSize = 13
	label.Position = UDim2.new(0, 12, 0, 0)
	label.Size = UDim2.new(1, -60, 1, 0)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = colorFrame

	local colorPreview = Instance.new("Frame")
	colorPreview.AnchorPoint = Vector2.new(1, 0.5)
	colorPreview.BackgroundColor3 = sectionConfig.Default
	colorPreview.BorderSizePixel = 0
	colorPreview.Position = UDim2.new(1, -12, 0.5, 0)
	colorPreview.Size = UDim2.new(0, 35, 0, 20)
	colorPreview.Parent = colorFrame
	AddCorner(colorPreview, 4)
	AddStroke(colorPreview, Theme.Border, 1, 0)

	local currentColor = sectionConfig.Default
	local currentTransparency = 0
	local hue, saturation, value = 0, 1, 1

	local function createColorPickerTooltip()
		local tooltip = Instance.new("Frame")
		tooltip.BackgroundColor3 = Theme.Card
		tooltip.BorderSizePixel = 0
		tooltip.Size = UDim2.new(0, 250, 0, 300)
		tooltip.Parent = colorFrame.Parent.Parent
		AddCorner(tooltip, 6)

		local wheelCanvas = Instance.new("Frame")
		wheelCanvas.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		wheelCanvas.BorderSizePixel = 0
		wheelCanvas.Position = UDim2.new(0, 15, 0, 15)
		wheelCanvas.Size = UDim2.new(0, 220, 0, 220)
		wheelCanvas.Parent = tooltip
		AddCorner(wheelCanvas, 110)

		local brightnessLabel = Instance.new("TextLabel")
		brightnessLabel.BackgroundTransparency = 1
		brightnessLabel.Font = GetFont(Window.Font, "Regular")
		brightnessLabel.Text = "Brightness"
		brightnessLabel.TextColor3 = Theme.SubText
		brightnessLabel.TextSize = 11
		brightnessLabel.Position = UDim2.new(0, 15, 0, 240)
		brightnessLabel.Size = UDim2.new(0.5, 0, 0, 15)
		brightnessLabel.Parent = tooltip

		local brightnessSlider = Instance.new("TextButton")
		brightnessSlider.BackgroundColor3 = Theme.Surface
		brightnessSlider.BorderSizePixel = 0
		brightnessSlider.Position = UDim2.new(0, 15, 0, 258)
		brightnessSlider.Size = UDim2.new(0.5, -20, 0, 12)
		brightnessSlider.AutoButtonColor = false
		brightnessSlider.Font = Enum.Font.SourceSans
		brightnessSlider.Text = ""
		brightnessSlider.Parent = tooltip
		AddCorner(brightnessSlider, 3)

		local brightnessGradient = Instance.new("UIGradient")
		brightnessGradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
		}
		brightnessGradient.Parent = brightnessSlider

		local brightnessFill = Instance.new("Frame")
		brightnessFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		brightnessFill.BorderSizePixel = 0
		brightnessFill.Size = UDim2.new(1, 0, 1, 0)
		brightnessFill.Parent = brightnessSlider
		AddCorner(brightnessFill, 3)

		local transparencyLabel = Instance.new("TextLabel")
		transparencyLabel.BackgroundTransparency = 1
		transparencyLabel.Font = GetFont(Window.Font, "Regular")
		transparencyLabel.Text = "Transparency"
		transparencyLabel.TextColor3 = Theme.SubText
		transparencyLabel.TextSize = 11
		transparencyLabel.Position = UDim2.new(0.5, 5, 0, 240)
		transparencyLabel.Size = UDim2.new(0.5, -20, 0, 15)
		transparencyLabel.Parent = tooltip

		local transparencySlider = Instance.new("TextButton")
		transparencySlider.BackgroundColor3 = Theme.Surface
		transparencySlider.BorderSizePixel = 0
		transparencySlider.Position = UDim2.new(0.5, 5, 0, 258)
		transparencySlider.Size = UDim2.new(0.5, -20, 0, 12)
		transparencySlider.AutoButtonColor = false
		transparencySlider.Font = Enum.Font.SourceSans
		transparencySlider.Text = ""
		transparencySlider.Parent = tooltip
		AddCorner(transparencySlider, 3)

		local transparencyGradient = Instance.new("UIGradient")
		transparencyGradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 100, 100))
		}
		transparencyGradient.Parent = transparencySlider

		local transparencyFill = Instance.new("Frame")
		transparencyFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		transparencyFill.BorderSizePixel = 0
		transparencyFill.Size = UDim2.new(1, 0, 1, 0)
		transparencyFill.Parent = transparencySlider
		AddCorner(transparencyFill, 3)

		local previewBox = Instance.new("Frame")
		previewBox.BackgroundColor3 = currentColor
		previewBox.BorderSizePixel = 0
		previewBox.Position = UDim2.new(0, 15, 0, 280)
		previewBox.Size = UDim2.new(1, -30, 0, 15)
		previewBox.Parent = tooltip
		AddCorner(previewBox, 4)

		local function updateColor()
			currentColor = Color3.fromHSV(hue, saturation, value)
			colorPreview.BackgroundColor3 = currentColor
			previewBox.BackgroundColor3 = currentColor
			if sectionConfig.Flag then
				OpenCore.Flags[sectionConfig.Flag] = {Color = currentColor, Transparency = currentTransparency}
			end
			task.spawn(function()
				pcall(sectionConfig.Callback, {Color = currentColor, Transparency = currentTransparency})
			end)
		end

		local function onWheelClick(input)
			local relativePos = input.Position - wheelCanvas.AbsolutePosition
			local center = wheelCanvas.AbsoluteSize / 2
			local delta = relativePos - center
			local radius = delta.Magnitude
			local maxRadius = wheelCanvas.AbsoluteSize.X / 2
			if radius <= maxRadius then
				saturation = math.min(1, radius / maxRadius)
				hue = (math.atan2(delta.Y, delta.X) + math.pi) / (2 * math.pi)
				updateColor()
			end
		end

		local function onBrightnessSliderClick(input)
			local relativeX = input.Position.X - brightnessSlider.AbsolutePosition.X
			value = math.clamp(relativeX / brightnessSlider.AbsoluteSize.X, 0, 1)
			brightnessFill.Size = UDim2.new(value, 0, 1, 0)
			updateColor()
		end

		local function onTransparencySliderClick(input)
			local relativeX = input.Position.X - transparencySlider.AbsolutePosition.X
			currentTransparency = math.clamp(relativeX / transparencySlider.AbsoluteSize.X, 0, 1)
			transparencyFill.Size = UDim2.new(currentTransparency, 0, 1, 0)
			updateColor()
		end

		wheelCanvas.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				onWheelClick(input)
				local conn = UserInputService.InputChanged:Connect(function(moveInput)
					if moveInput.UserInputType == Enum.UserInputType.MouseMovement then
						onWheelClick(moveInput)
					end
				end)
				UserInputService.InputEnded:Connect(function(endInput)
					if endInput.UserInputType == Enum.UserInputType.MouseButton1 then
						conn:Disconnect()
					end
				end)
			end
		end)

		brightnessSlider.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				onBrightnessSliderClick(input)
				local conn = UserInputService.InputChanged:Connect(function(moveInput)
					if moveInput.UserInputType == Enum.UserInputType.MouseMovement then
						onBrightnessSliderClick(moveInput)
					end
				end)
				UserInputService.InputEnded:Connect(function(endInput)
					if endInput.UserInputType == Enum.UserInputType.MouseButton1 then
						conn:Disconnect()
					end
				end)
			end
		end)

		transparencySlider.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				onTransparencySliderClick(input)
				local conn = UserInputService.InputChanged:Connect(function(moveInput)
					if moveInput.UserInputType == Enum.UserInputType.MouseMovement then
						onTransparencySliderClick(moveInput)
					end
				end)
				UserInputService.InputEnded:Connect(function(endInput)
					if endInput.UserInputType == Enum.UserInputType.MouseButton1 then
						conn:Disconnect()
					end
				end)
			end
		end)

		return tooltip
	end

	colorPreview.MouseButton1Click:Connect(function()
		if colorFrame.Parent:FindFirstChild("ColorPickerTooltip") then
			colorFrame.Parent:FindFirstChild("ColorPickerTooltip"):Destroy()
		else
			local tooltip = createColorPickerTooltip()
			tooltip.Name = "ColorPickerTooltip"
		end
	end)

	return {
		Set = function(self, color)
			currentColor = color
			colorPreview.BackgroundColor3 = currentColor
			if sectionConfig.Flag then
				OpenCore.Flags[sectionConfig.Flag] = {Color = currentColor, Transparency = currentTransparency}
			end
		end
	}
end

return OpenCore
