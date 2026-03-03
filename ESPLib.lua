local ESP = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

ESP.Settings = {
    Enabled = true,
    TextSize = 13,
    Font = 2,
    BoxEnabled = false,
    BoxThickness = 1.5,
    SkeletonEnabled = false,
    SkeletonThickness = 1,
    HPEnabled = false,
    HPWidth = 4,
    MaxDistance = 5000,
    PositionMode = "HumanoidRootPart",
    OffsetY = 0,
    BoxSmoothing = 0.18,
    BoxPadding = 3,
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
    return Vector2.new(v.X,v.Y), onScreen, v.Z
end

local function GetBoundingBox(model)
    local cf,size = model:GetBoundingBox()
    local corners = {}
    for x=-1,1,2 do
        for y=-1,1,2 do
            for z=-1,1,2 do
                table.insert(corners,(cf * CFrame.new(size.X/2*x,size.Y/2*y,size.Z/2*z)).Position)
            end
        end
    end
    return corners
end

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

local function safeW2S(part)
    if not part then return nil end
    local v,onScreen = Camera:WorldToViewportPoint(part.Position)
    if not onScreen or v.Z <= 0 then return nil end
    return Vector2.new(v.X,v.Y)
end

function ESP:SetEnabled(v)
    ESP.Settings.Enabled = v
    if not v then
        for _,d in pairs(ESP.Objects) do
            d.Text.Visible = false
            if d.Box then d.Box.Visible = false end
            if d.HPBar then d.HPBar.Visible = false end
            if d.SkeletonLines then
                for _,l in pairs(d.SkeletonLines) do l.Visible = false end
            end
        end
    end
end

function ESP:SetPositionMode(v)
    if v=="Head" or v=="HumanoidRootPart" then
        ESP.Settings.PositionMode = v
    end
end

function ESP:SetYOffset(v)
    if typeof(v)=="number" then
        ESP.Settings.OffsetY = v
    end
end

function ESP:SetBoxEnabled(v) ESP.Settings.BoxEnabled = v end
function ESP:SetSkeletonEnabled(v) ESP.Settings.SkeletonEnabled = v end
function ESP:SetHPEnabled(v) ESP.Settings.HPEnabled = v end

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

    ESP.Connections[part] = part.AncestryChanged:Connect(function(_,parent)
        if not parent or not part:IsDescendantOf(workspace) then
            cleanup(part)
        end
    end)
end

function ESP:Remove(object)
    cleanup(object)
end

RunService.RenderStepped:Connect(function()
    if not ESP.Settings.Enabled then return end

    for _,data in pairs(ESP.Objects) do
        local worldPos
        local root

        if data.Type=="Player" then
            local char = data.Object.Character
            root = char and char:FindFirstChild(ESP.Settings.PositionMode)
            if not root then
                data.Text.Visible=false
                if data.Box then data.Box.Visible=false end
                if data.HPBar then data.HPBar.Visible=false end
                if data.SkeletonLines then
                    for _,l in pairs(data.SkeletonLines) do l.Visible=false end
                end
                continue
            end
            worldPos = root.Position + Vector3.new(0,ESP.Settings.OffsetY,0)
        else
            root = data.Object
            if not root:IsDescendantOf(workspace) then
                cleanup(root)
                continue
            end
            worldPos = root.Position + Vector3.new(0,ESP.Settings.OffsetY,0)
        end

        local screenPos,onScreen,depth = WorldToScreen(worldPos)
        local dist = (Camera.CFrame.Position - worldPos).Magnitude

        if not onScreen or dist > ESP.Settings.MaxDistance then
            data.Text.Visible=false
            if data.Box then data.Box.Visible=false end
            if data.HPBar then data.HPBar.Visible=false end
            if data.SkeletonLines then
                for _,l in pairs(data.SkeletonLines) do l.Visible=false end
            end
            continue
        end

        data.Text.Text = (data.Type=="Player")
            and string.format("%s [%.0fm]",data.Object.Name,dist)
            or string.format("%s [%.0fm]",data.Name,dist)
        data.Text.Position = screenPos
        data.Text.Color = ESP.Colors.Player
        data.Text.Visible = true

        if ESP.Settings.BoxEnabled and data.Type=="Player" then
            local char = data.Object.Character
            if char then
                local minX,minY = math.huge,math.huge
                local maxX,maxY = -math.huge,-math.huge
                local visible = false

                for _,corner in ipairs(GetBoundingBox(char)) do
                    local v,onScreen = Camera:WorldToViewportPoint(corner)
                    if onScreen and v.Z > 0 then
                        visible = true
                        minX = math.min(minX,v.X)
                        minY = math.min(minY,v.Y)
                        maxX = math.max(maxX,v.X)
                        maxY = math.max(maxY,v.Y)
                    end
                end

                if visible then
                    minX -= ESP.Settings.BoxPadding
                    minY -= ESP.Settings.BoxPadding
                    maxX += ESP.Settings.BoxPadding
                    maxY += ESP.Settings.BoxPadding

                    local targetPos = Vector2.new(minX,minY)
                    local targetSize = Vector2.new(maxX-minX,maxY-minY)

                    if data.LastBox.Pos then
                        data.LastBox.Pos = data.LastBox.Pos:Lerp(targetPos,ESP.Settings.BoxSmoothing)
                        data.LastBox.Size = data.LastBox.Size:Lerp(targetSize,ESP.Settings.BoxSmoothing)
                    else
                        data.LastBox.Pos = targetPos
                        data.LastBox.Size = targetSize
                    end

                    data.Box.Position = data.LastBox.Pos
                    data.Box.Size = data.LastBox.Size
                    data.Box.Color = ESP.Colors.Box
                    data.Box.Visible = true
                else
                    data.Box.Visible = false
                end
            else
                data.Box.Visible = false
            end
        else
            if data.Box then data.Box.Visible=false end
        end
    end
end)

Players.PlayerRemoving:Connect(function(p)
    cleanup(p)
end)

return ESP
