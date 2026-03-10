--[[ 
    Custom ESP Library
    Text ESP + Box ESP + Skeleton ESP + HP Bars v2.26
    Death safe + cleanup safe + Velocity compatible
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

    PositionMode = "HumanoidRootPart",

    OffsetY = 0,
    BoxPadding = 3,
    BoxSmoothing = 0.18,

    MaxDistance = {
        Player    = 1000,
        NPC       = 500,
        item      = 500,
        weapon    = 500,
        corpse    = 500,
        container = 500,
    },

    VisibilityCheck = false,
    HoldingEnabled = false,
}

ESP.Colors = {
    Container = Color3.fromRGB(255,165,0),
    Player = Color3.fromRGB(255,255,255),
    PlayerVisible = Color3.fromRGB(0,255,80),
    NPC = Color3.fromRGB(255,120,120),
    NPCVisible = Color3.fromRGB(0,255,80),
    Item = Color3.fromRGB(0,255,150),
    Weapon = Color3.fromRGB(255,200,0),
    Corpse = Color3.fromRGB(180,0,255),
    Box = Color3.fromRGB(255,255,255),
    Skeleton = Color3.fromRGB(255,255,255),
    HP = Color3.fromRGB(255,0,0)
}

ESP.Objects = {}
ESP.Connections = {}

-- Check Drawing API is available
local DrawingAvailable = (Drawing ~= nil)
if not DrawingAvailable then
    warn("[NOX ESP] Drawing API not available on this executor — ESP disabled")
end

------------------------------------------------
-- DRAWINGS
------------------------------------------------

local function NewText()
    if not DrawingAvailable then return { Visible = false, Remove = function() end } end
    local t = Drawing.new("Text")
    t.Visible = false
    t.Center = true
    t.Outline = true
    t.Font = ESP.Settings.Font
    t.Size = ESP.Settings.TextSize
    return t
end

local function NewCornerBox()
    if not DrawingAvailable then
        return {}
    end
    local lines = {}
    for i = 1, 8 do
        local l = Drawing.new("Line")
        l.Visible = false
        l.Thickness = ESP.Settings.BoxThickness
        l.Color = ESP.Colors.Box
        lines[i] = l
    end
    return lines
end

local function SetCornerBoxVisible(lines, v)
    for _, l in ipairs(lines) do
        if l and l.Visible ~= nil then l.Visible = v end
    end
end

local function RemoveCornerBox(lines)
    for _, l in ipairs(lines) do
        if l and type(l.Remove) == "function" then l:Remove() end
    end
end

local function DrawCornerBox(lines, x, y, w, h, color)
    if not DrawingAvailable or #lines == 0 then return end
    local cx = math.floor(math.min(w, h) * 0.22)
    local x2, y2 = x + w, y + h
    local t = ESP.Settings.BoxThickness

    for _, l in ipairs(lines) do
        l.Color = color
        l.Thickness = t
    end

    lines[1].From = Vector2.new(x, y);         lines[1].To = Vector2.new(x + cx, y)
    lines[2].From = Vector2.new(x, y);         lines[2].To = Vector2.new(x, y + cx)
    lines[3].From = Vector2.new(x2, y);        lines[3].To = Vector2.new(x2 - cx, y)
    lines[4].From = Vector2.new(x2, y);        lines[4].To = Vector2.new(x2, y + cx)
    lines[5].From = Vector2.new(x, y2);        lines[5].To = Vector2.new(x + cx, y2)
    lines[6].From = Vector2.new(x, y2);        lines[6].To = Vector2.new(x, y2 - cx)
    lines[7].From = Vector2.new(x2, y2);       lines[7].To = Vector2.new(x2 - cx, y2)
    lines[8].From = Vector2.new(x2, y2);       lines[8].To = Vector2.new(x2, y2 - cx)

    SetCornerBoxVisible(lines, true)
end

local function NewLine()
    if not DrawingAvailable then return { Visible = false, Remove = function() end } end
    local l = Drawing.new("Line")
    l.Visible = false
    l.Thickness = ESP.Settings.SkeletonThickness
    return l
end

local function NewHPBar()
    if not DrawingAvailable then return { Visible = false, Remove = function() end } end
    local b = Drawing.new("Square")
    b.Visible = false
    b.Filled = true
    return b
end

------------------------------------------------
-- UTILS
------------------------------------------------

local function WorldToScreen(pos)
    local v, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(v.X, v.Y), onScreen, v.Z
end

local function GetRoot(model)
    return model:FindFirstChild("HumanoidRootPart")
        or model.PrimaryPart
        or model:FindFirstChildWhichIsA("BasePart")
end

local function IsVisible(fromPos, targetModel)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

    local filter = {targetModel}
    if LocalPlayer.Character then
        table.insert(filter, LocalPlayer.Character)
    end
    raycastParams.FilterDescendantsInstances = filter

    local head = targetModel:FindFirstChild("Head")
    local targetPos = head and head.Position or (targetModel.PrimaryPart and targetModel.PrimaryPart.Position)
    if not targetPos then return false end

    local direction = targetPos - fromPos
    local result = workspace:Raycast(fromPos, direction, raycastParams)

    return result == nil or result.Instance:IsDescendantOf(targetModel)
end

------------------------------------------------
-- CLEANUP
------------------------------------------------

local function cleanup(object)
    local data = ESP.Objects[object]
    if not data then return end

    if data.Text and type(data.Text.Remove) == "function" then data.Text:Remove() end
    if data.HoldingText and type(data.HoldingText.Remove) == "function" then data.HoldingText:Remove() end
    if data.Box then
        if type(data.Box) == "table" then
            RemoveCornerBox(data.Box)
        elseif type(data.Box.Remove) == "function" then
            data.Box:Remove()
        end
    end
    if data.HPBar and type(data.HPBar.Remove) == "function" then data.HPBar:Remove() end

    if data.SkeletonLines then
        for _, l in pairs(data.SkeletonLines) do
            if type(l.Remove) == "function" then l:Remove() end
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

function ESP:SetEnabled(v)       ESP.Settings.Enabled = v end
function ESP:SetSkeletonEnabled(v) ESP.Settings.SkeletonEnabled = v end
function ESP:SetHPEnabled(v)     ESP.Settings.HPEnabled = v end
function ESP:SetNameEnabled(v)   ESP.Settings.NameEnabled = v end
function ESP:SetVisibilityCheck(v) ESP.Settings.VisibilityCheck = v end
function ESP:SetHoldingEnabled(v) ESP.Settings.HoldingEnabled = v end

------------------------------------------------
-- ADD PLAYER
------------------------------------------------

function ESP:AddPlayer(player)
    if player == LocalPlayer then return end
    if ESP.Objects[player] then return end

    local skeletonLines = {}
    for i = 1, 10 do
        skeletonLines[i] = NewLine()
    end

    local holdingText = NewText()
    if holdingText.Size ~= nil then holdingText.Size = 14 end

    ESP.Objects[player] = {
        Type = "Player",
        Object = player,
        Text = NewText(),
        HoldingText = holdingText,
        Box = NewCornerBox(),
        HPBar = NewHPBar(),
        SkeletonLines = skeletonLines
    }

    player.CharacterAdded:Connect(function(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then
            hum.Died:Connect(function()
                local data = ESP.Objects[player]
                if not data then return end

                if data.Text then data.Text.Visible = false end
                if data.HoldingText then data.HoldingText.Visible = false end
                if data.Box then
                    if type(data.Box) == "table" then SetCornerBoxVisible(data.Box, false)
                    else data.Box.Visible = false end
                end
                if data.HPBar then data.HPBar.Visible = false end
                if data.SkeletonLines then
                    for _, l in pairs(data.SkeletonLines) do l.Visible = false end
                end
            end)
        end
    end)
end

------------------------------------------------
-- ADD NPC
------------------------------------------------

function ESP:AddNPC(model, name)
    if not model or not model:IsA("Model") then return end
    if ESP.Objects[model] then return end

    local skeletonLines = {}
    for i = 1, 10 do
        skeletonLines[i] = NewLine()
    end

    ESP.Objects[model] = {
        Type = "NPC",
        Object = model,
        Name = name or model.Name,
        Text = NewText(),
        Box = NewCornerBox(),
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

function ESP:AddPart(part, name, espCategory)
    if not part or not part:IsA("BasePart") then return end
    if ESP.Objects[part] then return end

    ESP.Objects[part] = {
        Type = "Part",
        Object = part,
        Name = name or part.Name,
        EspCategory = espCategory or "item",
        EspColor = ESP.Colors[espCategory] or ESP.Colors.Item,
        Text = NewText(),
        Box = nil
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
-- TRACK FOLDER
------------------------------------------------

function ESP:TrackFolder(key, folder, category, Lookups)
    if not ESP._trackedFolders then ESP._trackedFolders = {} end

    if ESP._trackedFolders[key] then
        ESP._trackedFolders[key]:Disconnect()
        ESP._trackedFolders[key] = nil
    end

    local function modelMatches(model)
        if not model:IsA("Model") then return false end
        local name = model.Name
        local nameLower = name:lower()

        local function inLookup(lookup)
            if lookup[name] then return true end
            for k in pairs(lookup) do
                if k:lower() == nameLower then return true end
            end
            return false
        end

        if category == "item" then
            return inLookup(Lookups.ItemLookup)
        elseif category == "weapon" then
            return inLookup(Lookups.GunLookup)
        elseif category == "corpse" then
            if inLookup(Lookups.ItemLookup) or inLookup(Lookups.GunLookup) then return false end
            if Lookups.ContainerLookup and inLookup(Lookups.ContainerLookup) then return false end
            return model:FindFirstChildOfClass("Humanoid") ~= nil
                or model:FindFirstChild("HumanoidRootPart") ~= nil
        elseif category == "container" then
            return inLookup(Lookups.ContainerLookup)
        end
        return false
    end

    local function getAnchorPart(model)
        if model.PrimaryPart then return model.PrimaryPart end
        return model:FindFirstChildWhichIsA("BasePart")
    end

    local function tryAddModel(model)
        if not modelMatches(model) then return end
        local part = getAnchorPart(model)
        if not part then return end
        if ESP.Objects[model] then return end

        ESP.Objects[model] = {
            Type = "Part",
            Object = part,
            Name = model.Name,
            EspCategory = category,
            EspColor = ESP.Colors[category] or ESP.Colors.Item,
            Text = NewText(),
            Box = nil
        }

        ESP.Connections[model] = model.AncestryChanged:Connect(function()
            if not model:IsDescendantOf(workspace) then
                cleanup(model)
            end
        end)
    end

    for _, obj in ipairs(folder:GetChildren()) do
        tryAddModel(obj)
    end

    ESP._trackedFolders[key] = folder.ChildAdded:Connect(function(obj)
        tryAddModel(obj)
    end)
end

------------------------------------------------
-- TRACK DESCENDANTS (NPCs)
------------------------------------------------

function ESP:TrackDescendants(key, container)
    if not ESP._trackedDescendants then ESP._trackedDescendants = {} end

    if ESP._trackedDescendants[key] then
        ESP._trackedDescendants[key]:Disconnect()
        ESP._trackedDescendants[key] = nil
    end

    local function isNPC(obj)
        if not obj:IsA("Model") then return false end
        return obj:FindFirstChildOfClass("Humanoid") ~= nil
    end

    local function tryAddNPC(obj)
        if isNPC(obj) then
            ESP:AddNPC(obj, obj.Name)
        end
    end

    for _, obj in ipairs(container:GetDescendants()) do
        tryAddNPC(obj)
    end

    ESP._trackedDescendants[key] = container.DescendantAdded:Connect(function(obj)
        tryAddNPC(obj)
    end)
end

------------------------------------------------
-- UNTRACK
------------------------------------------------

function ESP:Untrack(key)
    if ESP._trackedFolders and ESP._trackedFolders[key] then
        ESP._trackedFolders[key]:Disconnect()
        ESP._trackedFolders[key] = nil
    end

    if ESP._trackedDescendants and ESP._trackedDescendants[key] then
        ESP._trackedDescendants[key]:Disconnect()
        ESP._trackedDescendants[key] = nil
    end

    local categoryMap = { items = "item", weapons = "weapon", corpses = "corpse", containers = "container" }
    local targetCategory = categoryMap[key] or key

    local toRemove = {}
    for obj, data in pairs(ESP.Objects) do
        if data.EspCategory == targetCategory
        or (key == "npcs" and data.Type == "NPC") then
            table.insert(toRemove, obj)
        end
    end

    for _, obj in ipairs(toRemove) do
        cleanup(obj)
    end
end

------------------------------------------------
-- PLAYER AUTO REGISTER
------------------------------------------------

for _, player in ipairs(Players:GetPlayers()) do
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
    if not DrawingAvailable then return end

    if not ESP.Settings.Enabled then
        for _, data in pairs(ESP.Objects) do
            if data.Text then data.Text.Visible = false end
            if data.HoldingText then data.HoldingText.Visible = false end
            if data.Box then
                if type(data.Box) == "table" then SetCornerBoxVisible(data.Box, false)
                else data.Box.Visible = false end
            end
            if data.HPBar then data.HPBar.Visible = false end
            if data.SkeletonLines then
                for _, l in pairs(data.SkeletonLines) do l.Visible = false end
            end
        end
        return
    end

    for _, data in pairs(ESP.Objects) do

        local root
        local model

        if data.Type == "Player" then
            model = data.Object.Character

            if not model or not model.Parent then
                if data.Text then data.Text.Visible = false end
                if data.HoldingText then data.HoldingText.Visible = false end
                if data.Box then
                    if type(data.Box) == "table" then SetCornerBoxVisible(data.Box, false)
                    else data.Box.Visible = false end
                end
                if data.HPBar then data.HPBar.Visible = false end
                if data.SkeletonLines then
                    for _, l in pairs(data.SkeletonLines) do l.Visible = false end
                end
                continue
            end

            root = model:FindFirstChild(ESP.Settings.PositionMode)

        elseif data.Type == "NPC" then
            model = data.Object
            if not model or not model.Parent then continue end
            root = GetRoot(model)

        else
            if not data.Object or not data.Object.Parent then
                if data.Text then data.Text.Visible = false end
                continue
            end
            root = data.Object
        end

        if not root then continue end

        local screenPos, onScreen = WorldToScreen(root.Position)

        if not onScreen then
            if data.Text then data.Text.Visible = false end
            if data.HoldingText then data.HoldingText.Visible = false end
            if data.Box then
                if type(data.Box) == "table" then SetCornerBoxVisible(data.Box, false)
                else data.Box.Visible = false end
            end
            if data.HPBar then data.HPBar.Visible = false end
            if data.SkeletonLines then
                for _, l in pairs(data.SkeletonLines) do l.Visible = false end
            end
            continue
        end

        local dist = (Camera.CFrame.Position - root.Position).Magnitude

        do
            local maxDist
            if data.Type == "Player" then
                maxDist = ESP.Settings.MaxDistance.Player
            elseif data.Type == "NPC" then
                maxDist = ESP.Settings.MaxDistance.NPC
            elseif data.Type == "Part" and data.EspCategory then
                maxDist = ESP.Settings.MaxDistance[data.EspCategory]
            end

            if maxDist and dist > maxDist then
                if data.Text then data.Text.Visible = false end
                if data.Box then
                    if type(data.Box) == "table" then SetCornerBoxVisible(data.Box, false)
                    else data.Box.Visible = false end
                end
                if data.HPBar then data.HPBar.Visible = false end
                if data.SkeletonLines then
                    for _, l in pairs(data.SkeletonLines) do l.Visible = false end
                end
                continue
            end
        end

        if data.Text then
            if data.Type == "Part" then
                local catKey = data.EspCategory and (data.EspCategory:sub(1,1):upper() .. data.EspCategory:sub(2)) or "Item"
                local color = ESP.Colors[catKey] or ESP.Colors.Item
                local screen, on = WorldToScreen(root.Position)

                if on then
                    data.Text.Text     = string.format("%s [%.0fm]", data.Name, dist)
                    data.Text.Color    = color
                    data.Text.Position = Vector2.new(screen.X, screen.Y - data.Text.Size - 2)
                    data.Text.Visible  = true
                else
                    data.Text.Visible = false
                end

            elseif data.Type == "NPC" then
                local color = ESP.Colors.NPC
                local head  = model and model:FindFirstChild("Head")
                local pos   = head and (head.Position + Vector3.new(0, 0.6, 0)) or root.Position
                local screen, on = WorldToScreen(pos)

                if on then
                    data.Text.Text = string.format("%s [%.0fm]", data.Name, dist)
                    data.Text.Color = color

                    if data.BoxBounds then
                        data.Text.Position = Vector2.new(
                            data.BoxBounds.X + data.BoxBounds.W / 2,
                            data.BoxBounds.Y - data.Text.Size - 2
                        )
                    else
                        data.Text.Position = Vector2.new(screen.X, screen.Y - data.Text.Size - 2)
                    end

                    data.Text.Visible = true
                else
                    data.Text.Visible = false
                end

            elseif data.Type == "Player" then
                local head = model:FindFirstChild("Head")
                local pos  = head and (head.Position + Vector3.new(0, 0.6, 0)) or root.Position
                local screen, on = WorldToScreen(pos)

                if on then
                    local anchorX, anchorY
                    if data.BoxBounds then
                        anchorX = data.BoxBounds.X + data.BoxBounds.W / 2
                        anchorY = data.BoxBounds.Y - data.Text.Size - 2
                    else
                        anchorX = screen.X
                        anchorY = screen.Y - data.Text.Size - 2
                    end

                    if ESP.Settings.NameEnabled then
                        data.Text.Text     = string.format("%s [%.0fm]", data.Object.Name, dist)
                        data.Text.Color    = ESP.Colors.Player
                        data.Text.Position = Vector2.new(anchorX, anchorY)
                        data.Text.Visible  = true
                    else
                        data.Text.Visible = false
                    end

                    if ESP.Settings.HoldingEnabled then
                        local holdingVal = data.Object:FindFirstChild("Holding")
                            or (model and model:FindFirstChild("Holding"))
                        local holdingStr = holdingVal and tostring(holdingVal.Value) or ""
                        if holdingStr == "" then holdingStr = "[no Holding]" end

                        if holdingStr ~= "" then
                            local holdY
                            if data.BoxBounds then
                                holdY = data.BoxBounds.Y + data.BoxBounds.H + 2
                            else
                                holdY = anchorY + data.Text.Size + 2
                            end
                            data.HoldingText.Text     = holdingStr
                            data.HoldingText.Color    = Color3.fromRGB(255, 220, 100)
                            data.HoldingText.Position = Vector2.new(anchorX, holdY)
                            data.HoldingText.Visible  = true
                        else
                            data.HoldingText.Visible = false
                        end
                    else
                        data.HoldingText.Visible = false
                    end
                else
                    data.Text.Visible = false
                    data.HoldingText.Visible = false
                end
            end
        end

        data.BoxBounds = nil

        if data.Box and type(data.Box) == "table" and #data.Box > 0 then
            local useBox =
                (data.Type == "Player" and ESP.Settings.PlayerBoxEnabled)
                or (data.Type == "NPC" and ESP.Settings.NPCBoxEnabled)

            if useBox and model then
                local hrp  = model:FindFirstChild("HumanoidRootPart")
                local head = model:FindFirstChild("Head")
                local foot = model:FindFirstChild("LeftFoot")
                          or model:FindFirstChild("RightFoot")
                          or model:FindFirstChild("Left Leg")
                          or model:FindFirstChild("Right Leg")

                if hrp and head then
                    local topPos    = head.Position + Vector3.new(0, head.Size.Y + 0.2, 0)
                    local bottomPos = foot
                        and (foot.Position - Vector3.new(0, foot.Size.Y / 2, 0))
                        or  (hrp.Position  - Vector3.new(0, 3.2, 0))

                    local topScreen, onTop       = WorldToScreen(topPos)
                    local bottomScreen, onBottom = WorldToScreen(bottomPos)

                    if onTop and onBottom then
                        local boxH  = math.abs(bottomScreen.Y - topScreen.Y)
                        local boxW  = boxH * 0.5
                        local pad   = boxH * 0.05
                        local boxX  = screenPos.X - boxW / 2 - pad
                        local boxY  = topScreen.Y - pad
                        local boxW2 = boxW + pad * 2
                        local boxH2 = boxH + pad * 2

                        local boxColor = (data.Type == "Player") and ESP.Colors.Player or ESP.Colors.NPC
                        DrawCornerBox(data.Box, boxX, boxY, boxW2, boxH2, boxColor)

                        data.BoxBounds = { X = boxX, Y = boxY, W = boxW2, H = boxH2 }
                    else
                        SetCornerBoxVisible(data.Box, false)
                    end
                else
                    SetCornerBoxVisible(data.Box, false)
                end
            else
                SetCornerBoxVisible(data.Box, false)
            end
        end

        if ESP.Settings.HPEnabled and data.HPBar and model then
            local humanoid = model:FindFirstChildOfClass("Humanoid")

            if humanoid and data.BoxBounds then
                local percent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                local height  = data.BoxBounds.H * percent

                data.HPBar.Size     = Vector2.new(ESP.Settings.HPWidth, height)
                data.HPBar.Position = Vector2.new(
                    data.BoxBounds.X - ESP.Settings.HPWidth - 2,
                    data.BoxBounds.Y + (data.BoxBounds.H - height)
                )
                data.HPBar.Color   = ESP.Colors.HP
                data.HPBar.Visible = true
            else
                data.HPBar.Visible = false
            end
        end

        if ESP.Settings.SkeletonEnabled and data.SkeletonLines and model then
            for _, line in pairs(data.SkeletonLines) do line.Visible = false end

            local parts = {
                Head  = model:FindFirstChild("Head"),
                Torso = model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso"),
                Root  = model:FindFirstChild("HumanoidRootPart"),
                LA    = model:FindFirstChild("LeftUpperArm")  or model:FindFirstChild("Left Arm"),
                RA    = model:FindFirstChild("RightUpperArm") or model:FindFirstChild("Right Arm"),
                LL    = model:FindFirstChild("LeftUpperLeg")  or model:FindFirstChild("Left Leg"),
                RL    = model:FindFirstChild("RightUpperLeg") or model:FindFirstChild("Right Leg")
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
            for _, pair in ipairs(pairsList) do
                local p1   = parts[pair[1]]
                local p2   = parts[pair[2]]
                local line = data.SkeletonLines[index]

                if p1 and p2 and line then
                    local s1, on1 = Camera:WorldToViewportPoint(p1.Position)
                    local s2, on2 = Camera:WorldToViewportPoint(p2.Position)

                    if on1 and on2 and s1.Z > 0 and s2.Z > 0 then
                        line.From    = Vector2.new(s1.X, s1.Y)
                        line.To      = Vector2.new(s2.X, s2.Y)
                        line.Color   = ESP.Colors.Skeleton
                        line.Visible = true
                    end
                end

                index += 1
            end
        end

    end
end)

return ESP
