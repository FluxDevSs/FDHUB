--[[
    Custom ESP Library
    Players: Fixed-size screen-space Box + Text + HP + Skeleton
    Items: Text ONLY (no boxes, ever)
    Auto cleanup
]]

local ESP = {}

-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ================= SETTINGS =================
ESP.Settings = {
    Enabled = true,

    -- Text
    TextSize = 13,
    Font = 2,

    -- Box (PLAYERS ONLY)
    BoxEnabled = false,
    BoxThickness = 1.5,
    FixedBoxSize = Vector2.new(40, 70),
    BoxSmoothing = 0.18,

    -- Skeleton
    SkeletonEnabled = false,
    SkeletonThickness = 1,

    -- HP bar
    HPEnabled = false,
    HPWidth = 4,

    -- General
    MaxDistance = 5000,
}

ESP.Colors = {
    Player = Color3.fromRGB(255, 255, 255),
    Item = Color3.fromRGB(0, 255, 150),
    Box = Color3.fromRGB(255, 255, 255),
    Skeleton = Color3.fromRGB(255, 255, 255),
}

ESP.Objects = {}
ESP.Connections = {}

-- ================= DRAWING HELPERS =================
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
    local b = Drawing.new("Square")
    b.Visible = false
    b.Filled = true
    return b
end

-- ================= UTIL =================
local function WorldToScreen(pos)
    local v, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(v.X, v.Y), onScreen, v.Z
end

local function safeW2S(part)
    if not part then return nil end
    local v, onScreen = Camera:WorldToViewportPoint(part.Position)
    if not onScreen or v.Z <= 0 then return nil end
    return Vector2.new(v.X, v.Y)
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

-- ================= PUBLIC API =================
function ESP:SetEnabled(v) ESP.Settings.Enabled = v end
function ESP:SetBoxEnabled(v) ESP.Settings.BoxEnabled = v end
function ESP:SetSkeletonEnabled(v) ESP.Settings.SkeletonEnabled = v end
function ESP:SetHPEnabled(v) ESP.Settings.HPEnabled = v end

-- ================= ADD OBJECTS =================
function ESP:AddPlayer(player)
    if player == LocalPlayer then return end
    if ESP.Objects[player] then return end

    local skeletonLines = {}
    for i = 1, 10 do
        skeletonLines[i] = NewLine()
    end

    ESP.Objects[player] = {
        Type = "Player",
        Object = player,
        Text = NewText(),
        Box = NewBox(),
        HPBar = NewHPBar(),
        SkeletonLines = skeletonLines,
        LastBox = { Pos = nil },
    }
end

-- ITEMS = TEXT ONLY
function ESP:AddPart(part, name)
    if not part or not part:IsA("BasePart") then return end
    if ESP.Objects[part] then return end

    ESP.Objects[part] = {
        Type = "Item",
        Object = part,
        Name = name or part.Name,
        Text = NewText(),
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

-- ================= RENDER LOOP =================
RunService.RenderStepped:Connect(function()
    if not ESP.Settings.Enabled then return end

    for _, data in pairs(ESP.Objects) do
        local worldPos

        -- ===== PLAYER =====
        if data.Type == "Player" then
            local char = data.Object.Character
            local head = char and char:FindFirstChild("Head")
            if not head then
                if data.Text then data.Text.Visible = false end
                if data.Box then data.Box.Visible = false end
                if data.HPBar then data.HPBar.Visible = false end
                for _, l in pairs(data.SkeletonLines) do l.Visible = false end
                continue
            end
            worldPos = head.Position

        -- ===== ITEM =====
        else
            if not data.Object:IsDescendantOf(workspace) then
                cleanup(data.Object)
                continue
            end
            worldPos = data.Object.Position
        end

        local screenPos, onScreen, _ = WorldToScreen(worldPos)
        local dist = (Camera.CFrame.Position - worldPos).Magnitude

        if not onScreen or dist > ESP.Settings.MaxDistance then
            if data.Text then data.Text.Visible = false end
            if data.Type == "Player" then
                data.Box.Visible = false
                data.HPBar.Visible = false
                for _, l in pairs(data.SkeletonLines) do l.Visible = false end
            end
            continue
        end

        -- ================= TEXT =================
        if data.Type == "Player" then
            data.Text.Text = string.format("%s [%.0fm]", data.Object.Name, dist)
            data.Text.Color = ESP.Colors.Player
        else
            data.Text.Text = string.format("%s [%.0fm]", data.Name, dist)
            data.Text.Color = ESP.Colors.Item
        end

        data.Text.Position = Vector2.new(screenPos.X, screenPos.Y)
        data.Text.Visible = true

        -- ================= PLAYER BOX (FIXED SIZE) =================
        if data.Type == "Player" and ESP.Settings.BoxEnabled then
            local size = ESP.Settings.FixedBoxSize

            local targetPos = Vector2.new(
                screenPos.X - size.X / 2,
                screenPos.Y - size.Y * 0.35
            )

            if data.LastBox.Pos then
                data.LastBox.Pos = data.LastBox.Pos:Lerp(targetPos, ESP.Settings.BoxSmoothing)
            else
                data.LastBox.Pos = targetPos
            end

            data.Box.Size = size
            data.Box.Position = data.LastBox.Pos
            data.Box.Color = ESP.Colors.Box
            data.Box.Visible = true

            data.Text.Position = Vector2.new(screenPos.X, targetPos.Y - 14)
        else
            if data.Box then data.Box.Visible = false end
        end

        -- ================= HP BAR =================
        if data.Type == "Player" and ESP.Settings.HPEnabled and data.Box.Visible then
            local hum = data.Object.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                local fullH = data.Box.Size.Y
                local hpH = fullH * hp

                data.HPBar.Size = Vector2.new(ESP.Settings.HPWidth, hpH)
                data.HPBar.Position = Vector2.new(
                    data.Box.Position.X - ESP.Settings.HPWidth - 3,
                    data.Box.Position.Y + (fullH - hpH)
                )

                data.HPBar.Color = Color3.fromRGB(255 * (1 - hp), 255 * hp, 0)
                data.HPBar.Visible = true
            else
                data.HPBar.Visible = false
            end
        else
            if data.HPBar then data.HPBar.Visible = false end
        end

        -- ================= SKELETON =================
        if data.Type == "Player" and ESP.Settings.SkeletonEnabled then
            local char = data.Object.Character
            local joints = {
                {char.Head, char.UpperTorso},
                {char.UpperTorso, char.LowerTorso},
                {char.UpperTorso, char.LeftUpperArm},
                {char.LeftUpperArm, char.LeftLowerArm},
                {char.UpperTorso, char.RightUpperArm},
                {char.RightUpperArm, char.RightLowerArm},
                {char.LowerTorso, char.LeftUpperLeg},
                {char.LeftUpperLeg, char.LeftLowerLeg},
                {char.LowerTorso, char.RightUpperLeg},
                {char.RightUpperLeg, char.RightLowerLeg},
            }

            for i, joint in ipairs(joints) do
                local a = safeW2S(joint[1])
                local b = safeW2S(joint[2])
                local line = data.SkeletonLines[i]

                if a and b then
                    line.From = a
                    line.To = b
                    line.Color = ESP.Colors.Skeleton
                    line.Visible = true
                else
                    line.Visible = false
                end
            end
        else
            if data.SkeletonLines then
                for _, l in pairs(data.SkeletonLines) do l.Visible = false end
            end
        end
    end
end)

-- ================= PLAYER AUTO =================
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
