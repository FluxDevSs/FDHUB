--[[ 
    Custom ESP Library
    Text ESP + Box ESP + Skeleton ESP + HP Bars v2.23
    Death safe + cleanup safe
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
-- DRAWINGS
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
-- SETTINGS FUNCTIONS
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
-- ADD PLAYER
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

    player.CharacterAdded:Connect(function(char)
        local hum = char:WaitForChild("Humanoid",5)
        if hum then
            hum.Died:Connect(function()
                local data = ESP.Objects[player]
                if not data then return end

                if data.Text then data.Text.Visible = false end
                if data.Box then data.Box.Visible = false end
                if data.HPBar then data.HPBar.Visible = false end

                if data.SkeletonLines then
                    for _,l in pairs(data.SkeletonLines) do
                        l.Visible = false
                    end
                end

            end)
        end

    end)
end

------------------------------------------------
-- ADD NPC
------------------------------------------------

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
            if data.Text then data.Text.Visible = false end
            if data.Box then data.Box.Visible = false end
            if data.HPBar then data.HPBar.Visible = false end
            if data.SkeletonLines then
                for _,l in pairs(data.SkeletonLines) do
                    l.Visible = false
                end
            end
        end
        return
    end

    for _,data in pairs(ESP.Objects) do

        local root
        local model

    if data.Type == "Player" then

        model = data.Object.Character

        if not model or not model.Parent then

            if data.Text then data.Text.Visible = false end
            if data.Box then data.Box.Visible = false end
            if data.HPBar then data.HPBar.Visible = false end

            if data.SkeletonLines then
                for _,l in pairs(data.SkeletonLines) do
                    l.Visible = false
                end
            end

            continue
        end

        root = model:FindFirstChild(ESP.Settings.PositionMode)

        elseif data.Type == "NPC" then
            model = data.Object
            if not model or not model.Parent then continue end
            root = GetRoot(model)

        else
            root = data.Object
        end

        if not root then continue end

        local screenPos,onScreen = WorldToScreen(root.Position)

        if not onScreen then
            if data.Text then data.Text.Visible = false end
            if data.Box then data.Box.Visible = false end
            if data.HPBar then data.HPBar.Visible = false end
            if data.SkeletonLines then
                for _,l in pairs(data.SkeletonLines) do
                    l.Visible = false
                end
            end
            continue
        end

        local dist = (Camera.CFrame.Position - root.Position).Magnitude

------------------------------------------------
-- TEXT
------------------------------------------------

        if data.Text then

            if ESP.Settings.NameEnabled then

                local color
                local name
                local head

                if data.Type == "Player" then
                    color = ESP.Colors.Player
                    name = data.Object.Name
                    head = model:FindFirstChild("Head")

                elseif data.Type == "NPC" then
                    color = ESP.Colors.NPC
                    name = data.Name
                    head = model:FindFirstChild("Head")

                else
                    color = ESP.Colors.Item
                    name = data.Name
                end

                local pos = root.Position

                if head then
                    pos = head.Position + Vector3.new(0,0.6,0)
                end

                local screen,on = WorldToScreen(pos)

                if on then
                    data.Text.Text = string.format("%s [%.0fm]",name,dist)
                    data.Text.Color = color
                    data.Text.Position = screen
                    data.Text.Visible = true
                else
                    data.Text.Visible = false
                end

            else
                data.Text.Visible = false
            end
        end

------------------------------------------------
-- BOX (Head-to-foot screen projection)
------------------------------------------------

        if data.Box then

            local useBox =
                (data.Type == "Player" and ESP.Settings.PlayerBoxEnabled)
                or (data.Type == "NPC" and ESP.Settings.NPCBoxEnabled)

            if useBox and model then

                local hrp = model:FindFirstChild("HumanoidRootPart")
                local head = model:FindFirstChild("Head")

                if hrp and head then

                    -- Top = above head, Bottom = below feet
                    local topPos    = head.Position + Vector3.new(0, head.Size.Y, 0)
                    local bottomPos = hrp.Position  - Vector3.new(0, 3, 0)

                    local topScreen,    onTop    = WorldToScreen(topPos)
                    local bottomScreen, onBottom = WorldToScreen(bottomPos)

                    if onTop and onBottom then

                        local boxH = math.abs(bottomScreen.Y - topScreen.Y)
                        local boxW = boxH * 0.5  -- width is half height (character aspect ratio)

                        local boxX = screenPos.X - boxW / 2
                        local boxY = topScreen.Y

                        data.Box.Position = Vector2.new(boxX, boxY)
                        data.Box.Size     = Vector2.new(boxW, boxH)
                        data.Box.Color    = ESP.Colors.Box
                        data.Box.Visible  = true

                    else
                        data.Box.Visible = false
                    end

                else
                    data.Box.Visible = false
                end

            else
                data.Box.Visible = false
            end

        end

------------------------------------------------
-- HP BAR
------------------------------------------------

        if ESP.Settings.HPEnabled and data.HPBar and model then

            local humanoid = model:FindFirstChildOfClass("Humanoid")

            if humanoid and data.Box.Visible then

                local percent = math.clamp(humanoid.Health / humanoid.MaxHealth,0,1)

                local boxPos = data.Box.Position
                local boxSize = data.Box.Size

                local height = boxSize.Y * percent

                data.HPBar.Size = Vector2.new(ESP.Settings.HPWidth,height)

                data.HPBar.Position = Vector2.new(
                    boxPos.X - ESP.Settings.HPWidth - 2,
                    boxPos.Y + (boxSize.Y - height)
                )

                data.HPBar.Color = ESP.Colors.HP
                data.HPBar.Visible = true

            else
                data.HPBar.Visible = false
            end

        end

------------------------------------------------
-- SKELETON
------------------------------------------------

        if ESP.Settings.SkeletonEnabled and data.SkeletonLines and model then

            for _,line in pairs(data.SkeletonLines) do
                line.Visible = false
            end

            local parts = {
                Head = model:FindFirstChild("Head"),
                Torso = model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso"),
                Root = model:FindFirstChild("HumanoidRootPart"),
                LA = model:FindFirstChild("LeftUpperArm") or model:FindFirstChild("Left Arm"),
                RA = model:FindFirstChild("RightUpperArm") or model:FindFirstChild("Right Arm"),
                LL = model:FindFirstChild("LeftUpperLeg") or model:FindFirstChild("Left Leg"),
                RL = model:FindFirstChild("RightUpperLeg") or model:FindFirstChild("Right Leg")
            }

            local pairsList = {
                {"Head","Torso"},
                {"Torso","Root"},
                {"Torso","LA"},
                {"Torso","RA"},
                {"Root","LL"},
                {"Root","RL"}
            }

            local index = 1

            for _,pair in ipairs(pairsList) do

                local p1 = parts[pair[1]]
                local p2 = parts[pair[2]]
                local line = data.SkeletonLines[index]

                if p1 and p2 and line then

                    local s1,on1 = Camera:WorldToViewportPoint(p1.Position)
                    local s2,on2 = Camera:WorldToViewportPoint(p2.Position)

                    if on1 and on2 and s1.Z > 0 and s2.Z > 0 then
                        line.From = Vector2.new(s1.X,s1.Y)
                        line.To = Vector2.new(s2.X,s2.Y)
                        line.Color = ESP.Colors.Skeleton
                        line.Visible = true
                    end

                end

                index += 1
            end

        end

    end

end)

return ESP





