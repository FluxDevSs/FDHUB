--[[ 
    Custom ESP Library
    Text ESP + Box ESP + Skeleton ESP + HP Bars v1.7
    Fully bug fixed
]]

local ESP = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

ESP.Settings = {
    Enabled = true,

    TextSize = 16,
    Font = 2,

    BoxEnabled = false,
    BoxThickness = 1.5,

    NameEnabled = false,

    SkeletonEnabled = false,
    SkeletonThickness = 1,

    HPEnabled = false,
    HPWidth = 4,

    MaxDistance = 5000,
    PositionMode = "HumanoidRootPart",
    OffsetY = 0,

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
-- DRAWING
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
    local b = Drawing.new("Square")
    b.Visible = false
    b.Filled = true
    return b
end

------------------------------------------------
-- UTIL
------------------------------------------------

local function WorldToScreen(pos)
    local v,on = Camera:WorldToViewportPoint(pos)
    return Vector2.new(v.X,v.Y),on,v.Z
end

local function safeW2S(part)
    if not part then return end
    local v,on = Camera:WorldToViewportPoint(part.Position)
    if not on or v.Z <= 0 then return end
    return Vector2.new(v.X,v.Y)
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

function ESP:SetEnabled(v) ESP.Settings.Enabled = v end
function ESP:SetBoxEnabled(v) ESP.Settings.BoxEnabled = v end
function ESP:SetSkeletonEnabled(v) ESP.Settings.SkeletonEnabled = v end
function ESP:SetHPEnabled(v) ESP.Settings.HPEnabled = v end
function ESP:SetNameEnabled(v) ESP.Settings.NameEnabled = v end

------------------------------------------------
-- ADD PLAYER
------------------------------------------------

function ESP:AddPlayer(player)

    if player == LocalPlayer then return end
    if ESP.Objects[player] then return end

    local skeleton = {}

    for i=1,10 do
        skeleton[i] = NewLine()
    end

    ESP.Objects[player] = {
        Type = "Player",
        Object = player,
        Text = NewText(),
        Box = NewBox(),
        HPBar = NewHPBar(),
        SkeletonLines = skeleton,
        LastBox = nil
    }
end

------------------------------------------------
-- ADD PART
------------------------------------------------

function ESP:AddPart(part,name)

    if not part or not part:IsA("BasePart") then return end
    if ESP.Objects[part] then return end

    ESP.Objects[part] = {
        Type = "Part",
        Object = part,
        Name = name or part.Name,
        Text = NewText(),
        Box = NewBox(),
        LastBox = nil
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
-- PLAYER AUTO
------------------------------------------------

local function addPlayers()

    for _,p in ipairs(Players:GetPlayers()) do
        ESP:AddPlayer(p)
    end

end

Players.PlayerAdded:Connect(function(p)
    ESP:AddPlayer(p)
end)

Players.PlayerRemoving:Connect(function(p)
    cleanup(p)
end)

addPlayers()

------------------------------------------------
-- HIDE FUNCTION
------------------------------------------------

local function hide(data)

    if data.Text then data.Text.Visible = false end
    if data.Box then data.Box.Visible = false end
    if data.HPBar then data.HPBar.Visible = false end

    if data.SkeletonLines then
        for _,l in pairs(data.SkeletonLines) do
            l.Visible = false
        end
    end

end

------------------------------------------------
-- RENDER
------------------------------------------------

RunService.RenderStepped:Connect(function()

    if not ESP.Settings.Enabled then

        for _,d in pairs(ESP.Objects) do
            hide(d)
        end

        return
    end

    for object,data in pairs(ESP.Objects) do

        local root
        local worldPos

        if data.Type == "Player" then

            local char = object.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            if not char or not hum or hum.Health <= 0 then
                hide(data)
                continue
            end

            root = char:FindFirstChild(ESP.Settings.PositionMode)
            if not root then
                hide(data)
                continue
            end

            worldPos = root.Position

        else

            root = object

            if not root:IsDescendantOf(workspace) then
                cleanup(object)
                continue
            end

            worldPos = root.Position

        end

        local screen,on,depth = WorldToScreen(worldPos)

        local dist = (Camera.CFrame.Position - worldPos).Magnitude

        if not on or dist > ESP.Settings.MaxDistance then
            hide(data)
            data.LastBox = nil
            continue
        end

        ------------------------------------------------
        -- TEXT
        ------------------------------------------------

        if data.Type == "Player" then

            if ESP.Settings.NameEnabled then

                data.Text.Text = string.format("%s [%.0fm]",object.Name,dist)
                data.Text.Color = ESP.Colors.Player

                if data.LastBox then
                    data.Text.Position = Vector2.new(
                        data.LastBox.Pos.X + data.LastBox.Size.X/2,
                        data.LastBox.Pos.Y + data.LastBox.Size.Y + 2
                    )
                else
                    data.Text.Position = screen
                end

                data.Text.Visible = true

            else
                data.Text.Visible = false
            end

        else

            data.Text.Text = string.format("%s [%.0fm]",data.Name,dist)
            data.Text.Position = screen
            data.Text.Color = ESP.Colors.Item
            data.Text.Visible = true

        end

        ------------------------------------------------
        -- BOX
        ------------------------------------------------

        if data.Type == "Player" then

            local char = object.Character

            local minX,minY = math.huge,math.huge
            local maxX,maxY = -math.huge,-math.huge

            local visible = 0

            for _,corner in ipairs(GetBoundingBox(char)) do

                local v,onScreen = Camera:WorldToViewportPoint(corner)

                if onScreen and v.Z > 0 then

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

                data.LastBox = {Pos=pos,Size=size}

                if ESP.Settings.BoxEnabled then
                    data.Box.Position = pos
                    data.Box.Size = size
                    data.Box.Color = ESP.Colors.Box
                    data.Box.Visible = true
                else
                    data.Box.Visible = false
                end

            else
                data.Box.Visible = false
                data.LastBox = nil
            end
        end

        ------------------------------------------------
        -- HP BAR
        ------------------------------------------------

        if ESP.Settings.HPEnabled and data.LastBox then

            local hum = object.Character and object.Character:FindFirstChildOfClass("Humanoid")

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

            else
                data.HPBar.Visible = false
            end
        else
            if data.HPBar then
                data.HPBar.Visible = false
            end
        end

        ------------------------------------------------
        -- SKELETON
        ------------------------------------------------

        if ESP.Settings.SkeletonEnabled and data.Type == "Player" then

            local char = object.Character

            if not char then
                hide(data)
                continue
            end

            local joints

            if char:FindFirstChild("UpperTorso") then

                joints = {
                    {"Head","UpperTorso"},
                    {"UpperTorso","LowerTorso"},
                    {"UpperTorso","LeftUpperArm"},
                    {"LeftUpperArm","LeftLowerArm"},
                    {"UpperTorso","RightUpperArm"},
                    {"RightUpperArm","RightLowerArm"},
                    {"LowerTorso","LeftUpperLeg"},
                    {"LeftUpperLeg","LeftLowerLeg"},
                    {"LowerTorso","RightUpperLeg"},
                    {"RightUpperLeg","RightLowerLeg"}
                }

            else

                joints = {
                    {"Head","Torso"},
                    {"Torso","Left Arm"},
                    {"Left Arm","Left Leg"},
                    {"Torso","Right Arm"},
                    {"Right Arm","Right Leg"}
                }

            end

            for i,pair in ipairs(joints) do

                local a = char:FindFirstChild(pair[1])
                local b = char:FindFirstChild(pair[2])

                local line = data.SkeletonLines[i]

                if a and b then

                    local p1 = safeW2S(a)
                    local p2 = safeW2S(b)

                    if p1 and p2 then
                        line.From = p1
                        line.To = p2
                        line.Color = ESP.Colors.Skeleton
                        line.Visible = true
                    else
                        line.Visible = false
                    end
                else
                    line.Visible = false
                end
            end
        end

    end

end)

return ESP
