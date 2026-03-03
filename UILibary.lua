--// Simple UI Library
--// By ChatGPT
--// Lightweight & clean

local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local Library = {}
Library.Theme = {
    Background = Color3.fromRGB(25, 25, 25),
    Topbar = Color3.fromRGB(30, 30, 30),
    Accent = Color3.fromRGB(0, 170, 255),
    Text = Color3.fromRGB(255, 255, 255)
}

--// Create ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UILibrary"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

--// Window
function Library:CreateWindow(title)
    local Window = {}

    local Main = Instance.new("Frame")
    Main.Size = UDim2.fromOffset(520, 380)
    Main.Position = UDim2.fromScale(0.5, 0.5)
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.BackgroundColor3 = self.Theme.Background
    Main.BorderSizePixel = 0
    Main.Parent = ScreenGui

    local Topbar = Instance.new("Frame")
    Topbar.Size = UDim2.new(1, 0, 0, 40)
    Topbar.BackgroundColor3 = self.Theme.Topbar
    Topbar.BorderSizePixel = 0
    Topbar.Parent = Main

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -10, 1, 0)
    Title.Position = UDim2.fromOffset(10, 0)
    Title.BackgroundTransparency = 1
    Title.Text = title or "Window"
    Title.TextColor3 = self.Theme.Text
    Title.TextXAlignment = Left
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 14
    Title.Parent = Topbar

    -- Dragging
    do
        local dragging, dragStart, startPos
        Topbar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = Main.Position
            end
        end)
        UIS.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        UIS.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                Main.Position = startPos + UDim2.fromOffset(delta.X, delta.Y)
            end
        end)
    end

    -- Tabs
    local TabButtons = Instance.new("Frame")
    TabButtons.Size = UDim2.new(0, 120, 1, -40)
    TabButtons.Position = UDim2.fromOffset(0, 40)
    TabButtons.BackgroundColor3 = self.Theme.Topbar
    TabButtons.BorderSizePixel = 0
    TabButtons.Parent = Main

    local TabsLayout = Instance.new("UIListLayout", TabButtons)
    TabsLayout.Padding = UDim.new(0, 5)

    local Pages = Instance.new("Frame")
    Pages.Size = UDim2.new(1, -120, 1, -40)
    Pages.Position = UDim2.fromOffset(120, 40)
    Pages.BackgroundTransparency = 1
    Pages.Parent = Main

    function Window:CreateTab(name)
        local Tab = {}

        local Button = Instance.new("TextButton")
        Button.Size = UDim2.new(1, -10, 0, 32)
        Button.Position = UDim2.fromOffset(5, 0)
        Button.BackgroundColor3 = Library.Theme.Background
        Button.Text = name
        Button.Font = Enum.Font.Gotham
        Button.TextSize = 13
        Button.TextColor3 = Library.Theme.Text
        Button.BorderSizePixel = 0
        Button.Parent = TabButtons

        local Page = Instance.new("ScrollingFrame")
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.CanvasSize = UDim2.fromOffset(0, 0)
        Page.ScrollBarImageTransparency = 1
        Page.Visible = false
        Page.Parent = Pages

        local Layout = Instance.new("UIListLayout", Page)
        Layout.Padding = UDim.new(0, 6)

        Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.fromOffset(0, Layout.AbsoluteContentSize.Y + 10)
        end)

        Button.MouseButton1Click:Connect(function()
            for _, v in ipairs(Pages:GetChildren()) do
                if v:IsA("ScrollingFrame") then
                    v.Visible = false
                end
            end
            Page.Visible = true
        end)

        --// Elements
        function Tab:Button(text, callback)
            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(1, -10, 0, 32)
            Btn.Position = UDim2.fromOffset(5, 0)
            Btn.BackgroundColor3 = Library.Theme.Topbar
            Btn.Text = text
            Btn.Font = Enum.Font.Gotham
            Btn.TextSize = 13
            Btn.TextColor3 = Library.Theme.Text
            Btn.BorderSizePixel = 0
            Btn.Parent = Page

            Btn.MouseButton1Click:Connect(function()
                if callback then
                    callback()
                end
            end)
        end

        function Tab:Toggle(text, default, callback)
            local state = default or false

            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(1, -10, 0, 32)
            Btn.Position = UDim2.fromOffset(5, 0)
            Btn.BackgroundColor3 = Library.Theme.Topbar
            Btn.Text = text .. " : " .. (state and "ON" or "OFF")
            Btn.Font = Enum.Font.Gotham
            Btn.TextSize = 13
            Btn.TextColor3 = Library.Theme.Text
            Btn.BorderSizePixel = 0
            Btn.Parent = Page

            Btn.MouseButton1Click:Connect(function()
                state = not state
                Btn.Text = text .. " : " .. (state and "ON" or "OFF")
                if callback then
                    callback(state)
                end
            end)
        end

        function Tab:Label(text)
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -10, 0, 28)
            Label.Position = UDim2.fromOffset(5, 0)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 13
            Label.TextColor3 = Library.Theme.Text
            Label.TextWrapped = true
            Label.TextXAlignment = Left
            Label.Parent = Page
        end

        return Tab
    end

    return Window
end

return Library