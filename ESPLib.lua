--[[ 
    Custom ESP Library
    Text ESP + Box ESP + Skeleton ESP + HP Bars v2.1
    Auto cleanup built-in 
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

    BoxSmoothing = 0.18,
    BoxPadding = 3
}

ESP.Colors = {
    Player = Color3.fromRGB(255,255,255),
    NPC = Color3.fromRGB(255,120,120),
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

    if not onScreen or v.Z <= 0 then
        return
    end

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

function ESP:SetNameEnabled(v)
    ESP.Settings.NameEnabled = v
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

function ESP:AddNPC(model,name)

    if not model or not model:IsA("Model") then return end
    if ESP.Objects[model] then return end

    local skeletonLines = {}

    for i=1,10 do
        skeletonLines[i] = NewLine()
    end

    ESP.Objects[model] = {
        Type = "NPC",
        Object = model,
        Name = name or model.Name,
        Text = NewText(),
        Box = NewBox(),
        HPBar = NewHPBar(),
        SkeletonLines = skeletonLines,
        LastBox = {Pos=nil,Size=nil}
    }

    ESP.Connections[model] = model.AncestryChanged:Connect(function()

        if not model:IsDescendantOf(workspace) then
            cleanup(model)
        end

    end)

end

function ESP:AddPart(part,name)

    if not part or not part:IsA("BasePart") then return end
    if ESP.Objects[part] then return end

    ESP.Objects[part] = {
        Type = "Part",
        Object = part,
        Name = name or part.Name,
        Text = NewText(),
        Box = NewBox(),
        LastBox = {Pos=nil,Size=nil}
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

    if not ESP.Settings.Enabled then

        for _,data in pairs(ESP.Objects) do

            if data.Text then data.Text.Visible = false end
            if data.Box then data.Box.Visible = false end
            if data.HPBar then data.HPBar.Visible = false end

            if data.SkeletonLines then
                for _,line in pairs(data.SkeletonLines) do
                    line.Visible = false
                end
            end

        end

        return
    end

    for _,data in pairs(ESP.Objects) do

        local root
        local worldPos
        local char

        if data.Type == "Player" then

            char = data.Object.Character
            root = char and char:FindFirstChild(ESP.Settings.PositionMode)

            if not root then
                continue
            end

            worldPos = root.Position

        elseif data.Type == "NPC" then

            char = data.Object
            root = char:FindFirstChild("HumanoidRootPart")
                or char.PrimaryPart
                or char:FindFirstChildWhichIsA("BasePart")

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

        local screenPos,onScreen = WorldToScreen(worldPos)

        if not onScreen then
            data.Text.Visible = false
            data.Box.Visible = false
            if data.HPBar then data.HPBar.Visible = false end
            continue
        end

        local dist = (Camera.CFrame.Position - worldPos).Magnitude

        if data.Type == "Player" then

            if ESP.Settings.NameEnabled then

                data.Text.Text = string.format("%s [%.0fm]", data.Object.Name, dist)
                data.Text.Color = ESP.Colors.Player
                data.Text.Position = screenPos
                data.Text.Visible = true

            else
                data.Text.Visible = false
            end

        elseif data.Type == "NPC" then

            data.Text.Text = string.format("%s [%.0fm]", data.Name, dist)
            data.Text.Color = ESP.Colors.NPC
            data.Text.Position = screenPos
            data.Text.Visible = true

        else

            data.Text.Text = string.format("%s [%.0fm]", data.Name, dist)
            data.Text.Color = ESP.Colors.Item
            data.Text.Position = screenPos
            data.Text.Visible = true

        end

        if (data.Type == "Player" or data.Type == "NPC") and ESP.Settings.BoxEnabled then

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

                data.Box.Position = Vector2.new(minX,minY)
                data.Box.Size = Vector2.new(maxX-minX,maxY-minY)
                data.Box.Color = ESP.Colors.Box
                data.Box.Visible = true

            else
                data.Box.Visible = false
            end

        else
            data.Box.Visible = false
        end

    end

end)

return ESP
