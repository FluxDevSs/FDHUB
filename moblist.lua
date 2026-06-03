-- UILibrary.lua
-- Full Roblox Luau UI Library
-- Put this inside a ModuleScript named "UILibrary"

local UILibrary = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local DEFAULT_THEME = {
	Background = Color3.fromRGB(22, 22, 28),
	BackgroundDark = Color3.fromRGB(16, 16, 21),
	BackgroundLight = Color3.fromRGB(31, 31, 39),

	Accent = Color3.fromRGB(120, 90, 255),
	AccentDark = Color3.fromRGB(90, 65, 210),

	Text = Color3.fromRGB(245, 245, 255),
	TextMuted = Color3.fromRGB(160, 160, 175),

	Stroke = Color3.fromRGB(55, 55, 70),
	Success = Color3.fromRGB(80, 220, 130),
	Error = Color3.fromRGB(255, 90, 90),
}

local function mergeTheme(customTheme)
	local theme = {}

	for key, value in pairs(DEFAULT_THEME) do
		theme[key] = value
	end

	if typeof(customTheme) == "table" then
		for key, value in pairs(customTheme) do
			theme[key] = value
		end
	end

	return theme
end

local function create(className, properties, children)
	local instance = Instance.new(className)

	for property, value in pairs(properties or {}) do
		instance[property] = value
	end

	for _, child in ipairs(children or {}) do
		child.Parent = instance
	end

	return instance
end

local function corner(radius)
	return create("UICorner", {
		CornerRadius = UDim.new(0, radius or 8)
	})
end

local function stroke(color, thickness, transparency)
	return create("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		Transparency = transparency or 0
	})
end

local function padding(left, right, top, bottom)
	return create("UIPadding", {
		PaddingLeft = UDim.new(0, left or 0),
		PaddingRight = UDim.new(0, right or 0),
		PaddingTop = UDim.new(0, top or 0),
		PaddingBottom = UDim.new(0, bottom or 0)
	})
end

local function tween(object, tweenInfo, properties)
	local createdTween = TweenService:Create(object, tweenInfo, properties)
	createdTween:Play()
	return createdTween
end

local function makeDraggable(frame, handle)
	local dragging = false
	local dragStart = nil
	local startPosition = nil

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPosition = frame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end

		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local delta = input.Position - dragStart

		frame.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
	end)
end

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Section = {}
Section.__index = Section

function UILibrary.new(config)
	config = config or {}

	local self = setmetatable({}, Window)

	self.Title = config.Title or "UI Library"
	self.Subtitle = config.Subtitle or "Roblox UI"
	self.Theme = mergeTheme(config.Theme)
	self.Width = config.Width or 620
	self.Height = config.Height or 430
	self.Tabs = {}
	self.ActiveTab = nil
	self.Minimized = false
	self.ToggleKey = config.ToggleKey or Enum.KeyCode.RightShift

	local playerGui = LocalPlayer:WaitForChild("PlayerGui")

	local oldGui = playerGui:FindFirstChild("UILibraryScreenGui")
	if oldGui then
		oldGui:Destroy()
	end

	self.ScreenGui = create("ScreenGui", {
		Name = "UILibraryScreenGui",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = playerGui
	})

	self.Main = create("Frame", {
		Name = "Main",
		Size = UDim2.fromOffset(self.Width, self.Height),
		Position = UDim2.new(0.5, -self.Width / 2, 0.5, -self.Height / 2),
		BackgroundColor3 = self.Theme.Background,
		BorderSizePixel = 0,
		Parent = self.ScreenGui
	}, {
		corner(12),
		stroke(self.Theme.Stroke, 1, 0)
	})

	self.Topbar = create("Frame", {
		Name = "Topbar",
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = self.Theme.BackgroundDark,
		BorderSizePixel = 0,
		Parent = self.Main
	}, {
		corner(12)
	})

	self.TopbarFix = create("Frame", {
		Name = "TopbarFix",
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.new(0, 0, 1, -14),
		BackgroundColor3 = self.Theme.BackgroundDark,
		BorderSizePixel = 0,
		Parent = self.Topbar
	})

	self.TitleLabel = create("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, -120, 0, 24),
		Position = UDim2.fromOffset(16, 5),
		BackgroundTransparency = 1,
		Text = self.Title,
		TextColor3 = self.Theme.Text,
		TextSize = 16,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = self.Topbar
	})

	self.SubtitleLabel = create("TextLabel", {
		Name = "Subtitle",
		Size = UDim2.new(1, -120, 0, 18),
		Position = UDim2.fromOffset(16, 25),
		BackgroundTransparency = 1,
		Text = self.Subtitle,
		TextColor3 = self.Theme.TextMuted,
		TextSize = 12,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = self.Topbar
	})

	self.CloseButton = create("TextButton", {
		Name = "CloseButton",
		Size = UDim2.fromOffset(30, 30),
		Position = UDim2.new(1, -38, 0, 8),
		BackgroundColor3 = self.Theme.BackgroundLight,
		BorderSizePixel = 0,
		Text = "×",
		TextColor3 = self.Theme.Text,
		TextSize = 18,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = false,
		Parent = self.Topbar
	}, {
		corner(8)
	})

	self.MinimizeButton = create("TextButton", {
		Name = "MinimizeButton",
		Size = UDim2.fromOffset(30, 30),
		Position = UDim2.new(1, -74, 0, 8),
		BackgroundColor3 = self.Theme.BackgroundLight,
		BorderSizePixel = 0,
		Text = "-",
		TextColor3 = self.Theme.Text,
		TextSize = 18,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = false,
		Parent = self.Topbar
	}, {
		corner(8)
	})

	self.Sidebar = create("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, 160, 1, -46),
		Position = UDim2.fromOffset(0, 46),
		BackgroundColor3 = self.Theme.BackgroundDark,
		BorderSizePixel = 0,
		Parent = self.Main
	})

	self.SidebarLayout = create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		Parent = self.Sidebar
	})

	self.SidebarPadding = padding(10, 10, 10, 10)
	self.SidebarPadding.Parent = self.Sidebar

	self.Content = create("Frame", {
		Name = "Content",
		Size = UDim2.new(1, -160, 1, -46),
		Position = UDim2.fromOffset(160, 46),
		BackgroundColor3 = self.Theme.Background,
		BorderSizePixel = 0,
		Parent = self.Main
	})

	self.NotificationHolder = create("Frame", {
		Name = "NotificationHolder",
		Size = UDim2.fromOffset(320, 500),
		Position = UDim2.new(1, -340, 0, 20),
		BackgroundTransparency = 1,
		Parent = self.ScreenGui
	})

	self.NotificationLayout = create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		VerticalAlignment = Enum.VerticalAlignment.Top,
		Parent = self.NotificationHolder
	})

	makeDraggable(self.Main, self.Topbar)

	self.CloseButton.MouseButton1Click:Connect(function()
		self.ScreenGui:Destroy()
	end)

	self.MinimizeButton.MouseButton1Click:Connect(function()
		self:SetMinimized(not self.Minimized)
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == self.ToggleKey then
			self.ScreenGui.Enabled = not self.ScreenGui.Enabled
		end
	end)

	return self
end

function Window:SetMinimized(state)
	self.Minimized = state

	if state then
		self.MinimizeButton.Text = "+"
		tween(self.Main, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(self.Width, 46)
		})
		self.Sidebar.Visible = false
		self.Content.Visible = false
	else
		self.MinimizeButton.Text = "-"
		self.Sidebar.Visible = true
		self.Content.Visible = true
		tween(self.Main, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(self.Width, self.Height)
		})
	end
end

function Window:Notify(config)
	config = config or {}

	local title = config.Title or "Notification"
	local text = config.Text or ""
	local duration = config.Duration or 3

	local notification = create("Frame", {
		Name = "Notification",
		Size = UDim2.fromOffset(320, 82),
		BackgroundColor3 = self.Theme.Background,
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		Parent = self.NotificationHolder
	}, {
		corner(10),
		stroke(self.Theme.Stroke, 1, 0)
	})

	local accent = create("Frame", {
		Name = "Accent",
		Size = UDim2.new(0, 4, 1, -16),
		Position = UDim2.fromOffset(8, 8),
		BackgroundColor3 = self.Theme.Accent,
		BorderSizePixel = 0,
		Parent = notification
	}, {
		corner(4)
	})

	local titleLabel = create("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, -34, 0, 24),
		Position = UDim2.fromOffset(22, 9),
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = self.Theme.Text,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = notification
	})

	local textLabel = create("TextLabel", {
		Name = "Text",
		Size = UDim2.new(1, -34, 0, 38),
		Position = UDim2.fromOffset(22, 34),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = self.Theme.TextMuted,
		TextSize = 12,
		Font = Enum.Font.Gotham,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = notification
	})

	tween(notification, TweenInfo.new(0.2), {
		BackgroundTransparency = 0
	})

	task.delay(duration, function()
		if notification and notification.Parent then
			tween(notification, TweenInfo.new(0.2), {
				BackgroundTransparency = 1
			})

			task.wait(0.22)

			if notification then
				notification:Destroy()
			end
		end
	end)
end

function Window:CreateTab(name)
	local tab = setmetatable({}, Tab)

	tab.Window = self
	tab.Name = name
	tab.Sections = {}

	tab.Button = create("TextButton", {
		Name = name .. "Button",
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = self.Theme.BackgroundLight,
		BorderSizePixel = 0,
		Text = name,
		TextColor3 = self.Theme.TextMuted,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutoButtonColor = false,
		Parent = self.Sidebar
	}, {
		corner(8),
		padding(12, 12, 0, 0)
	})

	tab.Page = create("ScrollingFrame", {
		Name = name .. "Page",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = self.Theme.Accent,
		CanvasSize = UDim2.fromOffset(0, 0),
		Visible = false,
		Parent = self.Content
	})

	tab.PageLayout = create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 10),
		Parent = tab.Page
	})

	tab.PagePadding = padding(12, 12, 12, 12)
	tab.PagePadding.Parent = tab.Page

	tab.PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		tab.Page.CanvasSize = UDim2.fromOffset(0, tab.PageLayout.AbsoluteContentSize.Y + 24)
	end)

	tab.Button.MouseButton1Click:Connect(function()
		self:SelectTab(tab)
	end)

	table.insert(self.Tabs, tab)

	if not self.ActiveTab then
		self:SelectTab(tab)
	end

	return tab
end

function Window:SelectTab(tab)
	for _, otherTab in ipairs(self.Tabs) do
		otherTab.Page.Visible = false
		otherTab.Button.TextColor3 = self.Theme.TextMuted
		otherTab.Button.BackgroundColor3 = self.Theme.BackgroundLight
	end

	self.ActiveTab = tab
	tab.Page.Visible = true
	tab.Button.TextColor3 = self.Theme.Text
	tab.Button.BackgroundColor3 = self.Theme.Accent
end

function Tab:CreateSection(name)
	local section = setmetatable({}, Section)

	section.Tab = self
	section.Window = self.Window
	section.Name = name

	section.Frame = create("Frame", {
		Name = name .. "Section",
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = self.Window.Theme.BackgroundLight,
		BorderSizePixel = 0,
		Parent = self.Page
	}, {
		corner(10),
		stroke(self.Window.Theme.Stroke, 1, 0)
	})

	section.Title = create("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, -20, 0, 32),
		Position = UDim2.fromOffset(10, 4),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = self.Window.Theme.Text,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = section.Frame
	})

	section.Content = create("Frame", {
		Name = "Content",
		Size = UDim2.new(1, -20, 0, 0),
		Position = UDim2.fromOffset(10, 38),
		BackgroundTransparency = 1,
		Parent = section.Frame
	})

	section.Layout = create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		Parent = section.Content
	})

	section.Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		section.Content.Size = UDim2.new(1, -20, 0, section.Layout.AbsoluteContentSize.Y)
		section.Frame.Size = UDim2.new(1, 0, 0, section.Layout.AbsoluteContentSize.Y + 50)
	end)

	table.insert(self.Sections, section)

	return section
end

function Section:AddButton(config)
	config = config or {}

	local text = config.Text or "Button"
	local callback = config.Callback or function() end

	local button = create("TextButton", {
		Name = text .. "Button",
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = self.Window.Theme.BackgroundDark,
		BorderSizePixel = 0,
		Text = text,
		TextColor3 = self.Window.Theme.Text,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = false,
		Parent = self.Content
	}, {
		corner(8),
		stroke(self.Window.Theme.Stroke, 1, 0)
	})

	button.MouseEnter:Connect(function()
		tween(button, TweenInfo.new(0.15), {
			BackgroundColor3 = self.Window.Theme.AccentDark
		})
	end)

	button.MouseLeave:Connect(function()
		tween(button, TweenInfo.new(0.15), {
			BackgroundColor3 = self.Window.Theme.BackgroundDark
		})
	end)

	button.MouseButton1Click:Connect(function()
		tween(button, TweenInfo.new(0.08), {
			Size = UDim2.new(1, -4, 0, 34)
		})

		task.delay(0.08, function()
			if button and button.Parent then
				tween(button, TweenInfo.new(0.08), {
					Size = UDim2.new(1, 0, 0, 36)
				})
			end
		end)

		local ok, err = pcall(callback)

		if not ok then
			warn("[UILibrary Button Error]", err)
		end
	end)

	return button
end

function Section:AddToggle(config)
	config = config or {}

	local text = config.Text or "Toggle"
	local default = config.Default or false
	local callback = config.Callback or function() end

	local state = default

	local holder = create("Frame", {
		Name = text .. "Toggle",
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = self.Window.Theme.BackgroundDark,
		BorderSizePixel = 0,
		Parent = self.Content
	}, {
		corner(8),
		stroke(self.Window.Theme.Stroke, 1, 0)
	})

	local label = create("TextLabel", {
		Name = "Label",
		Size = UDim2.new(1, -70, 1, 0),
		Position = UDim2.fromOffset(12, 0),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = self.Window.Theme.Text,
		TextSize = 13,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = holder
	})

	local toggleButton = create("TextButton", {
		Name = "ToggleButton",
		Size = UDim2.fromOffset(46, 22),
		Position = UDim2.new(1, -58, 0.5, -11),
		BackgroundColor3 = state and self.Window.Theme.Accent or self.Window.Theme.BackgroundLight,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = holder
	}, {
		corner(12)
	})

	local knob = create("Frame", {
		Name = "Knob",
		Size = UDim2.fromOffset(18, 18),
		Position = state and UDim2.fromOffset(25, 2) or UDim2.fromOffset(3, 2),
		BackgroundColor3 = self.Window.Theme.Text,
		BorderSizePixel = 0,
		Parent = toggleButton
	}, {
		corner(10)
	})

	local function setToggle(value)
		state = value

		tween(toggleButton, TweenInfo.new(0.15), {
			BackgroundColor3 = state and self.Window.Theme.Accent or self.Window.Theme.BackgroundLight
		})

		tween(knob, TweenInfo.new(0.15), {
			Position = state and UDim2.fromOffset(25, 2) or UDim2.fromOffset(3, 2)
		})

		local ok, err = pcall(function()
			callback(state)
		end)

		if not ok then
			warn("[UILibrary Toggle Error]", err)
		end
	end

	toggleButton.MouseButton1Click:Connect(function()
		setToggle(not state)
	end)

	holder.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			setToggle(not state)
		end
	end)

	return {
		Set = setToggle,
		Get = function()
			return state
		end,
		Instance = holder
	}
end

function Section:AddSlider(config)
	config = config or {}

	local text = config.Text or "Slider"
	local min = config.Min or 0
	local max = config.Max or 100
	local default = config.Default or min
	local rounding = config.Rounding or 0
	local callback = config.Callback or function() end

	local value = math.clamp(default, min, max)
	local dragging = false

	local holder = create("Frame", {
		Name = text .. "Slider",
		Size = UDim2.new(1, 0, 0, 58),
		BackgroundColor3 = self.Window.Theme.BackgroundDark,
		BorderSizePixel = 0,
		Parent = self.Content
	}, {
		corner(8),
		stroke(self.Window.Theme.Stroke, 1, 0)
	})

	local label = create("TextLabel", {
		Name = "Label",
		Size = UDim2.new(1, -90, 0, 26),
		Position = UDim2.fromOffset(12, 4),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = self.Window.Theme.Text,
		TextSize = 13,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = holder
	})

	local valueLabel = create("TextLabel", {
		Name = "Value",
		Size = UDim2.fromOffset(70, 26),
		Position = UDim2.new(1, -82, 0, 4),
		BackgroundTransparency = 1,
		Text = tostring(value),
		TextColor3 = self.Window.Theme.TextMuted,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = holder
	})

	local bar = create("Frame", {
		Name = "Bar",
		Size = UDim2.new(1, -24, 0, 8),
		Position = UDim2.fromOffset(12, 38),
		BackgroundColor3 = self.Window.Theme.BackgroundLight,
		BorderSizePixel = 0,
		Parent = holder
	}, {
		corner(8)
	})

	local fill = create("Frame", {
		Name = "Fill",
		Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
		BackgroundColor3 = self.Window.Theme.Accent,
		BorderSizePixel = 0,
		Parent = bar
	}, {
		corner(8)
	})

	local function roundNumber(number)
		local multiplier = 10 ^ rounding
		return math.floor(number * multiplier + 0.5) / multiplier
	end

	local function setSliderFromX(x)
		local percent = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		value = roundNumber(min + ((max - min) * percent))

		valueLabel.Text = tostring(value)

		tween(fill, TweenInfo.new(0.08), {
			Size = UDim2.new(percent, 0, 1, 0)
		})

		local ok, err = pcall(function()
			callback(value)
		end)

		if not ok then
			warn("[UILibrary Slider Error]", err)
		end
	end

	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setSliderFromX(input.Position.X)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			setSliderFromX(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	return {
		Set = function(newValue)
			value = math.clamp(newValue, min, max)
			local percent = (value - min) / (max - min)
			valueLabel.Text = tostring(value)
			fill.Size = UDim2.new(percent, 0, 1, 0)
			callback(value)
		end,
		Get = function()
			return value
		end,
		Instance = holder
	}
end

function Section:AddTextbox(config)
	config = config or {}

	local text = config.Text or "Textbox"
	local placeholder = config.Placeholder or "Type here..."
	local default = config.Default or ""
	local clearOnFocus = config.ClearOnFocus or false
	local callback = config.Callback or function() end

	local holder = create("Frame", {
		Name = text .. "Textbox",
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = self.Window.Theme.BackgroundDark,
		BorderSizePixel = 0,
		Parent = self.Content
	}, {
		corner(8),
		stroke(self.Window.Theme.Stroke, 1, 0)
	})

	local label = create("TextLabel", {
		Name = "Label",
		Size = UDim2.new(0.42, -16, 1, 0),
		Position = UDim2.fromOffset(12, 0),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = self.Window.Theme.Text,
		TextSize = 13,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = holder
	})

	local box = create("TextBox", {
		Name = "Input",
		Size = UDim2.new(0.58, -18, 0, 30),
		Position = UDim2.new(0.42, 6, 0.5, -15),
		BackgroundColor3 = self.Window.Theme.BackgroundLight,
		BorderSizePixel = 0,
		Text = default,
		PlaceholderText = placeholder,
		TextColor3 = self.Window.Theme.Text,
		PlaceholderColor3 = self.Window.Theme.TextMuted,
		TextSize = 13,
		Font = Enum.Font.Gotham,
		ClearTextOnFocus = clearOnFocus,
		Parent = holder
	}, {
		corner(7),
		padding(8, 8, 0, 0)
	})

	box.FocusLost:Connect(function(enterPressed)
		local ok, err = pcall(function()
			callback(box.Text, enterPressed)
		end)

		if not ok then
			warn("[UILibrary Textbox Error]", err)
		end
	end)

	return {
		Set = function(newText)
			box.Text = tostring(newText)
		end,
		Get = function()
			return box.Text
		end,
		Instance = holder,
		TextBox = box
	}
end

function Section:AddDropdown(config)
	config = config or {}

	local text = config.Text or "Dropdown"
	local options = config.Options or {}
	local default = config.Default
	local callback = config.Callback or function() end

	local selected = default or options[1]
	local open = false

	local holder = create("Frame", {
		Name = text .. "Dropdown",
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundColor3 = self.Window.Theme.BackgroundDark,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = self.Content
	}, {
		corner(8),
		stroke(self.Window.Theme.Stroke, 1, 0)
	})

	local button = create("TextButton", {
		Name = "Button",
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Parent = holder
	})

	local label = create("TextLabel", {
		Name = "Label",
		Size = UDim2.new(0.42, -16, 0, 44),
		Position = UDim2.fromOffset(12, 0),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = self.Window.Theme.Text,
		TextSize = 13,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = holder
	})

	local selectedLabel = create("TextLabel", {
		Name = "Selected",
		Size = UDim2.new(0.58, -44, 0, 44),
		Position = UDim2.new(0.42, 6, 0, 0),
		BackgroundTransparency = 1,
		Text = tostring(selected or "None"),
		TextColor3 = self.Window.Theme.TextMuted,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = holder
	})

	local arrow = create("TextLabel", {
		Name = "Arrow",
		Size = UDim2.fromOffset(24, 44),
		Position = UDim2.new(1, -34, 0, 0),
		BackgroundTransparency = 1,
		Text = "▼",
		TextColor3 = self.Window.Theme.TextMuted,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		Parent = holder
	})

	local list = create("Frame", {
		Name = "List",
		Size = UDim2.new(1, -20, 0, 0),
		Position = UDim2.fromOffset(10, 48),
		BackgroundTransparency = 1,
		Parent = holder
	})

	local listLayout = create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		Parent = list
	})

	local function resize()
		local listHeight = listLayout.AbsoluteContentSize.Y

		if open then
			holder.Size = UDim2.new(1, 0, 0, 58 + listHeight)
			list.Size = UDim2.new(1, -20, 0, listHeight)
			arrow.Text = "▲"
		else
			holder.Size = UDim2.new(1, 0, 0, 44)
			arrow.Text = "▼"
		end
	end

	local function refreshOptions(newOptions)
		options = newOptions or options

		for _, child in ipairs(list:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end

		for _, option in ipairs(options) do
			local optionButton = create("TextButton", {
				Name = tostring(option),
				Size = UDim2.new(1, 0, 0, 30),
				BackgroundColor3 = self.Window.Theme.BackgroundLight,
				BorderSizePixel = 0,
				Text = tostring(option),
				TextColor3 = self.Window.Theme.Text,
				TextSize = 13,
				Font = Enum.Font.Gotham,
				AutoButtonColor = false,
				Parent = list
			}, {
				corner(7)
			})

			optionButton.MouseButton1Click:Connect(function()
				selected = option
				selectedLabel.Text = tostring(option)
				open = false
				resize()

				local ok, err = pcall(function()
					callback(option)
				end)

				if not ok then
					warn("[UILibrary Dropdown Error]", err)
				end
			end)
		end

		task.defer(resize)
	end

	button.MouseButton1Click:Connect(function()
		open = not open
		resize()
	end)

	refreshOptions(options)

	return {
		Set = function(option)
			selected = option
			selectedLabel.Text = tostring(option)
			callback(option)
		end,
		Get = function()
			return selected
		end,
		Refresh = refreshOptions,
		Instance = holder
	}
end

function Section:AddKeybind(config)
	config = config or {}

	local text = config.Text or "Keybind"
	local default = config.Default or Enum.KeyCode.F
	local callback = config.Callback or function() end

	local currentKey = default
	local listening = false

	local holder = create("Frame", {
		Name = text .. "Keybind",
		Size = UDim2.new(1, 0, 0, 42),
		BackgroundColor3 = self.Window.Theme.BackgroundDark,
		BorderSizePixel = 0,
		Parent = self.Content
	}, {
		corner(8),
		stroke(self.Window.Theme.Stroke, 1, 0)
	})

	local label = create("TextLabel", {
		Name = "Label",
		Size = UDim2.new(1, -130, 1, 0),
		Position = UDim2.fromOffset(12, 0),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = self.Window.Theme.Text,
		TextSize = 13,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = holder
	})

	local keyButton = create("TextButton", {
		Name = "KeyButton",
		Size = UDim2.fromOffset(100, 28),
		Position = UDim2.new(1, -112, 0.5, -14),
		BackgroundColor3 = self.Window.Theme.BackgroundLight,
		BorderSizePixel = 0,
		Text = currentKey.Name,
		TextColor3 = self.Window.Theme.Text,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = false,
		Parent = holder
	}, {
		corner(7)
	})

	keyButton.MouseButton1Click:Connect(function()
		listening = true
		keyButton.Text = "..."
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if listening then
			if input.KeyCode ~= Enum.KeyCode.Unknown then
				currentKey = input.KeyCode
				keyButton.Text = currentKey.Name
				listening = false
			end

			return
		end

		if input.KeyCode == currentKey then
			local ok, err = pcall(callback)

			if not ok then
				warn("[UILibrary Keybind Error]", err)
			end
		end
	end)

	return {
		Set = function(newKey)
			currentKey = newKey
			keyButton.Text = currentKey.Name
		end,
		Get = function()
			return currentKey
		end,
		Instance = holder
	}
end

return UILibrary
