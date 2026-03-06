--[[ 
    Custom ESP Library
    Text ESP + Box ESP + Skeleton ESP + HP Bars v2
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

    -- Name
    NameEnabled = false,

    -- Skeleton
    SkeletonEnabled = false,
    SkeletonThickness = 1,

    -- HP bar
    HPEnabled = false,
    HPWidth = 4,

    -- General
    MaxDistance = 5000,
    PositionMode = "HumanoidRootPart",
    OffsetY = 0,

    -- Box dynamics
    BoxSmoothing = 0.18,
    BoxPadding = 3
}

ESP.Colors = {
    Player = Color3.fromRGB(255,255,255),
    Item = Color3.fromRGB(0,255,150),
    Box = Color3.fromRGB(255,255,255),
    Skeleton = Color3.fromRGB(255,255,255),
    HP = Color3.fromRGB(255,0,0)
}

ESP.Objects = {}
ESP.Connections = {}

------------------------------------------------
-- DRAWING UTILS
------------------------------------------------

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

------------------------------------------------
-- UTIL
------------------------------------------------

local function WorldToScreen(pos)
    local v,onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(v.X,v.Y),onScreen,v.Z
end

local function GetBoundingBox(model)
    local cf,size = model:GetBoundingBox()
    local corners = {}

    for x=-1,1,2 do
        for y=-1,1,2 do
            for z=-1,1,2 do
                table.insert(
                    corners,
                    (cf * CFrame.new(
                        size.X/2 * x,
                        size.Y/2 * y,
                        size.Z/2 * z
                    )).Position
                )
            end
        end
    end

    return corners
end

local function safeW2S(part)
    if not part then return end
    local v,onScreen = Camera:WorldToViewportPoint(part.Position)
    if not onScreen or v.Z <= 0 then return end
    return Vector2.new(v.X,v.Y)
end

------------------------------------------------
-- CLEANUP
------------------------------------------------

local function cleanup(object)
    local data = ESP.Objects[object]
    if not data then return end

    if data.Text then data.Text:Remove() end
    if data.Box then data.Box:Remove() end
    if data.HPBar then data.HPBar:Remove() end

    if data.SkeletonLines then
        for _,l in pairs(data.SkeletonLines) do
            l:Remove()
        end
    end

    if ESP.Connections[object] then
        ESP.Connections[object]:Disconnect()
        ESP.Connections[object] = nil
    end

    ESP.Objects[object] = nil
end

------------------------------------------------
-- SETTINGS
------------------------------------------------

function ESP:SetEnabled(v)
    ESP.Settings.Enabled = v
end

function ESP:SetBoxEnabled(v)
    ESP.Settings.BoxEnabled = v
end

function ESP:SetSkeletonEnabled(v)
    ESP.Settings.SkeletonEnabled = v
end

function ESP:SetHPEnabled(v)
    ESP.Settings.HPEnabled = v
end

------------------------------------------------
-- ADD OBJECTS
------------------------------------------------

function ESP:AddPlayer(player)
    if player == LocalPlayer then return end
    if ESP.Objects[player] then return end

    local skeletonLines = {}
    for i=1,10 do
        skeletonLines[i] = NewLine()
    end

    ESP.Objects[player] = {
        Type = "Player",
        Object = player,
        Text = NewText(),
        Box = NewBox(),
        HPBar = NewHPBar(),
        SkeletonLines = skeletonLines,
        LastBox = {Pos=nil,Size=nil}
    }
end

function ESP:AddPart(part,name)
    if not part or not part:IsA("BasePart") then return end
    if ESP.Objects[part] then return end

    ESP.Objects[part] = {
        Type = "Part",
        Object = part,
        Name = name or part.Name,
        Text = NewText(),
        Box = NewBox()
    }

    ESP.Connections[part] = part.AncestryChanged:Connect(function()
        if not part:IsDescendantOf(workspace) then
            cleanup(part)
        end
    end)
end

function ESP:Remove(object)
    cleanup(object)
end

------------------------------------------------
-- AUTO PLAYER HANDLING
------------------------------------------------

local function addAllPlayers()
    for _,player in ipairs(Players:GetPlayers()) do
        ESP:AddPlayer(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    ESP:AddPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
    ESP:Remove(player)
end)

addAllPlayers()

------------------------------------------------
-- RENDER LOOP
------------------------------------------------

RunService.RenderStepped:Connect(function()

    if not ESP.Settings.Enabled then return end

    for _,data in pairs(ESP.Objects) do

        local root
        local worldPos

        if data.Type == "Player" then
            local char = data.Object.Character
            root = char and char:FindFirstChild(ESP.Settings.PositionMode)

            if not root then
                continue
            end

            worldPos = root.Position

        else

            root = data.Object
            if not root:IsDescendantOf(workspace) then
                cleanup(root)
                continue
            end

            worldPos = root.Position
        end

        local screenPos,onScreen,depth = WorldToScreen(worldPos)

        if not onScreen then
            data.Text.Visible = false
            if data.Box then data.Box.Visible = false end
            if data.HPBar then data.HPBar.Visible = false end
            continue
        end

        ------------------------------------------------
        -- TEXT
        ------------------------------------------------

        -- NAME ESP
        if ESP.Settings.NameEnabled then

            data.Text.Text = (data.Type == "Player") and
                string.format("%s [%.0fm]", data.Object.Name, dist) or
                string.format("%s [%.0fm]", data.Name, dist)

            data.Text.Color = ESP.Colors.Player

            if data.LastBox and data.LastBox.Pos then
                data.Text.Position = Vector2.new(
                    data.LastBox.Pos.X + (data.LastBox.Size.X / 2),
                    data.LastBox.Pos.Y + data.LastBox.Size.Y + 2
                )
            else
                data.Text.Position = screenPos
            end

            data.Text.Visible = true

        else
            data.Text.Visible = false
        end

        ------------------------------------------------
        -- BOX CALCULATION
        ------------------------------------------------

        if data.Type == "Player" then

            local char = data.Object.Character
            if char then

                local minX,minY = math.huge,math.huge
                local maxX,maxY = -math.huge,-math.huge
                local visible = 0

                for _,corner in ipairs(GetBoundingBox(char)) do

                    local v,on = Camera:WorldToViewportPoint(corner)

                    if on and v.Z > 0 then
                        visible += 1

                        minX = math.min(minX,v.X)
                        minY = math.min(minY,v.Y)
                        maxX = math.max(maxX,v.X)
                        maxY = math.max(maxY,v.Y)
                    end
                end

                if visible >= 4 then

                    minX -= ESP.Settings.BoxPadding
                    minY -= ESP.Settings.BoxPadding
                    maxX += ESP.Settings.BoxPadding
                    maxY += ESP.Settings.BoxPadding

                    local pos = Vector2.new(minX,minY)
                    local size = Vector2.new(maxX-minX,maxY-minY)

                    data.LastBox.Pos = pos
                    data.LastBox.Size = size

                    if ESP.Settings.BoxEnabled then
                        data.Box.Position = pos
                        data.Box.Size = size
                        data.Box.Color = ESP.Colors.Box
                        data.Box.Visible = true
                    else
                        data.Box.Visible = false
                    end

                end
            end
        end

        ------------------------------------------------
        -- HP BAR
        ------------------------------------------------

        if ESP.Settings.HPEnabled and data.LastBox.Pos then

            local hum = data.Object.Character and data.Object.Character:FindFirstChildOfClass("Humanoid")

            if hum then

                local hp = math.clamp(hum.Health/hum.MaxHealth,0,1)

                local h = data.LastBox.Size.Y
                local hpH = h * hp

                data.HPBar.Size = Vector2.new(ESP.Settings.HPWidth,hpH)
                data.HPBar.Position = Vector2.new(
                    data.LastBox.Pos.X - ESP.Settings.HPWidth - 3,
                    data.LastBox.Pos.Y + (h - hpH)
                )

                data.HPBar.Color = Color3.fromRGB(
                    255*(1-hp),
                    255*hp,
                    0
                )

                data.HPBar.Visible = true
            end
        end

        ------------------------------------------------
        -- SKELETON
        ------------------------------------------------

        if ESP.Settings.SkeletonEnabled and data.Type == "Player" then

            local char = data.Object.Character
            if char then

                local joints = {
                    {char.Head,char.UpperTorso},
                    {char.UpperTorso,char.LowerTorso},

                    {char.UpperTorso,char.LeftUpperArm},
                    {char.LeftUpperArm,char.LeftLowerArm},

                    {char.UpperTorso,char.RightUpperArm},
                    {char.RightUpperArm,char.RightLowerArm},

                    {char.LowerTorso,char.LeftUpperLeg},
                    {char.LeftUpperLeg,char.LeftLowerLeg},

                    {char.LowerTorso,char.RightUpperLeg},
                    {char.RightUpperLeg,char.RightLowerLeg}
                }

                for i,joint in ipairs(joints) do

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
            end
        end

    end
end)

return ESP

