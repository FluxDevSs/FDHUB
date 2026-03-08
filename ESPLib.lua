--[[ 
    Custom ESP Library
    Text ESP + Box ESP + Skeleton ESP + HP Bars v2.2
    Clean rewrite
]]

local ESP = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

------------------------------------------------
-- SETTINGS
------------------------------------------------

ESP.Settings = {
    Enabled = true,

    TextSize = 16,
    Font = 2,

    PlayerBoxEnabled = false,
    NPCBoxEnabled = false,
    BoxThickness = 1.5,

    NameEnabled = false,

    SkeletonEnabled = false,
    SkeletonThickness = 1,

    HPEnabled = false,
    HPWidth = 4,

    MaxDistance = 5000,
    PositionMode = "HumanoidRootPart",

    OffsetY = 0,
    BoxPadding = 3,
    BoxSmoothing = 0.18
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
-- DRAWING FACTORY
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
-- UTILS
------------------------------------------------

local function WorldToScreen(pos)
    local v,onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(v.X,v.Y),onScreen,v.Z
end

local function GetRoot(model)
    return model:FindFirstChild("HumanoidRootPart")
        or model.PrimaryPart
        or model:FindFirstChildWhichIsA("BasePart")
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

function ESP:SetEnabled(v)
    ESP.Settings.Enabled = v
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
        SkeletonLines = skeletonLines
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
        SkeletonLines = skeletonLines
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
-- PLAYER AUTO REGISTER
------------------------------------------------

for _,player in ipairs(Players:GetPlayers()) do
    ESP:AddPlayer(player)
end

Players.PlayerAdded:Connect(function(player)
    ESP:AddPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
    ESP:Remove(player)
end)

------------------------------------------------
-- RENDER LOOP
------------------------------------------------

RunService.RenderStepped:Connect(function()

    if not ESP.Settings.Enabled then
        for _,data in pairs(ESP.Objects) do

            if data.Box then data.Box.Visible = false end
            if data.Text then data.Text.Visible = false end
            if data.HP then data.HP.Visible = false end

            if data.Skeleton then
                for _,l in pairs(data.Skeleton) do
                    if l then l.Visible = false end
                end
            end

        end
        return
    end


    for obj,data in pairs(ESP.Objects) do

        local root = data.Root
        local hum = data.Hum

        ------------------------------------------------
        -- CLEANUP IF BROKEN
        ------------------------------------------------

        if not root or not hum or not root.Parent or hum.Health <= 0 then

            if data.Box then data.Box:Remove() end
            if data.Text then data.Text:Remove() end
            if data.HP then data.HP:Remove() end

            if data.Skeleton then
                for _,l in pairs(data.Skeleton) do
                    if l then l:Remove() end
                end
            end

            ESP.Objects[obj] = nil
            continue
        end


        ------------------------------------------------
        -- SCREEN POSITION
        ------------------------------------------------

        local pos,visible = Camera:WorldToViewportPoint(root.Position)

        if not visible then

            if data.Box then data.Box.Visible = false end
            if data.Text then data.Text.Visible = false end
            if data.HP then data.HP.Visible = false end

            if data.Skeleton then
                for _,l in pairs(data.Skeleton) do
                    if l then l.Visible = false end
                end
            end

            continue
        end


        ------------------------------------------------
        -- DISTANCE
        ------------------------------------------------

        local distance = (Camera.CFrame.Position - root.Position).Magnitude

        if distance > ESP.Settings.MaxDistance then
            continue
        end


        ------------------------------------------------
        -- BOX SIZE
        ------------------------------------------------

        local scale = 1/(distance*0.01)
        local w = 35*scale
        local h = 55*scale

        local x = pos.X - w/2
        local y = pos.Y - h/2


        ------------------------------------------------
        -- PLAYER / NPC BOX SEPARATION
        ------------------------------------------------

        local showBox = false

        if data.Type == "Player" and ESP.Settings.PlayerBoxEnabled then
            showBox = true
        end

        if data.Type == "NPC" and ESP.Settings.NPCBoxEnabled then
            showBox = true
        end


        if data.Box then

            if showBox then
                data.Box.Size = Vector2.new(w,h)
                data.Box.Position = Vector2.new(x,y)
                data.Box.Visible = true
            else
                data.Box.Visible = false
            end

        end


        ------------------------------------------------
        -- NAME
        ------------------------------------------------

        if data.Text then

            if ESP.Settings.NameEnabled then
                data.Text.Text = data.Name.." ["..math.floor(distance).."m]"
                data.Text.Position = Vector2.new(pos.X,y-14)
                data.Text.Visible = true
            else
                data.Text.Visible = false
            end

        end


        ------------------------------------------------
        -- HP BAR
        ------------------------------------------------

        if data.HP then

            if ESP.Settings.HPEnabled then

                local percent = hum.Health / hum.MaxHealth
                local hpHeight = h * percent

                data.HP.From = Vector2.new(x-5,y+h)
                data.HP.To = Vector2.new(x-5,y+h-hpHeight)

                data.HP.Color = Color3.fromRGB(
                    255*(1-percent),
                    255*percent,
                    0
                )

                data.HP.Visible = true

            else
                data.HP.Visible = false
            end

        end


        ------------------------------------------------
        -- SKELETON
        ------------------------------------------------

        if data.Skeleton then

            if ESP.Settings.SkeletonEnabled then
                drawSkeleton(data.Skeleton,root.Parent)
            else
                for _,l in pairs(data.Skeleton) do
                    if l then l.Visible = false end
                end
            end

        end

    end

end)

return ESP

