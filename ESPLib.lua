--[[ 
    Custom ESP Library
    Text ESP + Box ESP + Skeleton ESP + HP Bars
    Auto cleanup built-in
]]

local ESP = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

ESP.Settings = {
    Enabled = true,

    -- Text
    TextSize = 13,
    Font = 2,

    -- Box
    BoxEnabled = false,
    BoxThickness = 1.5,

    -- Skeleton
    SkeletonEnabled = false,
    SkeletonThickness = 1,

    -- HP bar
    HPEnabled = false,
    HPWidth = 4,

    -- General
    MaxDistance = 5000,
    PositionMode = "HumanoidRootPart",
    OffsetY = 0
}

ESP.Colors = {
    Player = Color3.fromRGB(255, 255, 255),
    Item   = Color3.fromRGB(0, 255, 150),
    Box    = Color3.fromRGB(255, 255, 255),
    Skeleton = Color3.fromRGB(255, 255, 255),
    HP = Color3.fromRGB(255,0,0)
}

ESP.Objects = {}
ESP.Connections = {}

-- UTIL
local function NewText()
    local t = Drawing.new("Text")
    t.Visible = false
    t.Center = true
    t.Outline = true
    t.Font = ESP.Settings.Font
    t.Size = ESP.Settings.TextSize
    return t
end

local function NewBox()
    local b = Drawing.new("Square")
    b.Visible = false
    b.Filled = false
    b.Thickness = ESP.Settings.BoxThickness
    return b
end

local function NewLine()
    local l = Drawing.new("Line")
    l.Visible = false
    l.Thickness = ESP.Settings.SkeletonThickness
    return l
end

local function NewHPBar()
    local bar = Drawing.new("Square")
    bar.Visible = false
    bar.Filled = true
    return bar
end

local function WorldToScreen(pos)
    local v, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(v.X, v.Y), onScreen, v.Z
end

local function cleanup(object)
    local data = ESP.Objects[object]
    if not data then return end

    if data.Text then data.Text:Remove() end
    if data.Box then data.Box:Remove() end
    if data.HPBar then data.HPBar:Remove() end
    if data.SkeletonLines then
        for _, l in pairs(data.SkeletonLines) do
            l:Remove()
        end
    end

    if ESP.Connections[object] then
        ESP.Connections[object]:Disconnect()
        ESP.Connections[object] = nil
    end

    ESP.Objects[object] = nil
end

-- PUBLIC SETTERS
function ESP:SetEnabled(v)
    ESP.Settings.Enabled = v
    if not v then
        for _, d in pairs(ESP.Objects) do
            d.Text.Visible = false
            if d.Box then d.Box.Visible = false end
            if d.HPBar then d.HPBar.Visible = false end
            if d.SkeletonLines then
                for _, l in pairs(d.SkeletonLines) do l.Visible = false end
            end
        end
    end
end

function ESP:SetPositionMode(v)
    if v == "Head" or v == "HumanoidRootPart" then
        ESP.Settings.PositionMode = v
    end
end

function ESP:SetYOffset(v)
    if typeof(v) == "number" then
        ESP.Settings.OffsetY = v
    end
end

function ESP:SetBoxEnabled(v) ESP.Settings.BoxEnabled = v end
function ESP:SetSkeletonEnabled(v) ESP.Settings.SkeletonEnabled = v end
function ESP:SetHPEnabled(v) ESP.Settings.HPEnabled = v end

-- ADD OBJECTS
function ESP:AddPlayer(player)
    if player == LocalPlayer then return end
    if ESP.Objects[player] then return end

    local skeletonLines = {}
    for i = 1,6 do -- torso+arms+legs
        skeletonLines[i] = NewLine()
    end

    ESP.Objects[player] = {
        Type = "Player",
        Object = player,
        Text = NewText(),
        Box = NewBox(),
        HPBar = NewHPBar(),
        SkeletonLines = skeletonLines
    }
end

function ESP:AddPart(part, name)
    if not part or not part:IsA("BasePart") then return end
    if ESP.Objects[part] then return end

    ESP.Objects[part] = {
        Type = "Part",
        Object = part,
        Name = name or part.Name,
        Text = NewText(),
        Box = NewBox()
    }

    ESP.Connections[part] = part.AncestryChanged:Connect(function(_, parent)
        if not parent or not part:IsDescendantOf(workspace) then
            cleanup(part)
        end
    end)
end

function ESP:Remove(object)
    cleanup(object)
end

-- RENDER LOOP
RunService.RenderStepped:Connect(function()
    if not ESP.Settings.Enabled then return end

    for _, data in pairs(ESP.Objects) do
        local worldPos
        local root

        if data.Type == "Player" then
            local char = data.Object.Character
            root = char and char:FindFirstChild(ESP.Settings.PositionMode)
            if not root then
                data.Text.Visible = false
                data.Box.Visible = false
                data.HPBar.Visible = false
                if data.SkeletonLines then
                    for _, l in pairs(data.SkeletonLines) do l.Visible = false end
                end
                continue
            end
            worldPos = root.Position + Vector3.new(0, ESP.Settings.OffsetY, 0)
        else
            root = data.Object
            if not root:IsDescendantOf(workspace) then
                cleanup(root)
                continue
            end
            worldPos = root.Position + Vector3.new(0, ESP.Settings.OffsetY, 0)
        end

        local screenPos, onScreen, depth = WorldToScreen(worldPos)
        local dist = (Camera.CFrame.Position - worldPos).Magnitude

        if not onScreen or dist > ESP.Settings.MaxDistance then
            data.Text.Visible = false
            if data.Box then data.Box.Visible = false end
            if data.HPBar then data.HPBar.Visible = false end
            if data.SkeletonLines then
                for _, l in pairs(data.SkeletonLines) do l.Visible = false end
            end
            continue
        end

        -- TEXT
        data.Text.Text = (data.Type == "Player") and
            string.format("%s [%.0fm]", data.Object.Name, dist) or
            string.format("%s [%.0fm]", data.Name, dist)
        data.Text.Position = screenPos
        data.Text.Color = ESP.Colors.Player
        data.Text.Visible = true

        -- BOX
        if ESP.Settings.BoxEnabled then
            local scale = math.clamp(1/depth*1000,20,300)
            data.Box.Size = Vector2.new(scale*0.6, scale)
            data.Box.Position = screenPos - (data.Box.Size/2)
            data.Box.Color = ESP.Colors.Box
            data.Box.Visible = true
        else
            data.Box.Visible = false
        end

        -- HP BAR
        if ESP.Settings.HPEnabled and data.Type == "Player" then
            local hum = data.Object.Character and data.Object.Character:FindFirstChildWhichIsA("Humanoid")
            if hum then
                local healthPerc = math.clamp(hum.Health/hum.MaxHealth,0,1)
                local barHeight = data.Box.Size.Y * healthPerc
                data.HPBar.Size = Vector2.new(ESP.Settings.HPWidth, data.Box.Size.Y)
                data.HPBar.Position = data.Box.Position - Vector2.new(ESP.Settings.HPWidth+2,0)
                data.HPBar.Color = ESP.Colors.HP
                data.HPBar.Visible = true
            else
                data.HPBar.Visible = false
            end
        else
            if data.HPBar then data.HPBar.Visible = false end
        end

        -- SKELETON ESP
        if ESP.Settings.SkeletonEnabled and data.Type == "Player" then
            local char = data.Object.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local head = char:FindFirstChild("Head")
                local larm = char:FindFirstChild("LeftUpperArm")
                local rarm = char:FindFirstChild("RightUpperArm")
                local lleg = char:FindFirstChild("LeftUpperLeg")
                local rleg = char:FindFirstChild("RightUpperLeg")

                local points = {hrp, head, larm, rarm, lleg, rleg}
                for i, l in ipairs(data.SkeletonLines) do
                    if points[i] and points[i+1] then
                        local p1, on1 = WorldToScreen(points[i].Position)
                        local p2, on2 = WorldToScreen(points[i+1].Position)
                        if on1 and on2 then
                            l.From = p1
                            l.To = p2
                            l.Color = ESP.Colors.Skeleton
                            l.Visible = true
                        else
                            l.Visible = false
                        end
                    else
                        l.Visible = false
                    end
                end
            end
        else
            if data.SkeletonLines then
                for _, l in pairs(data.SkeletonLines) do l.Visible = false end
            end
        end
    end
end)

-- PLAYER AUTO
for _, p in ipairs(Players:GetPlayers()) do
    ESP:AddPlayer(p)
end

Players.PlayerAdded:Connect(function(p)
    ESP:AddPlayer(p)
end)

Players.PlayerRemoving:Connect(function(p)
    cleanup(p)
end)

return ESP
