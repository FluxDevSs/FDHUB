--[[ 
    Custom ESP Library
    Auto-removes ESP when objects leave workspace
]]

local ESP = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ================= SETTINGS =================
ESP.Settings = {
    Enabled = true,

    TextSize = 13,
    Font = 2,
    MaxDistance = 5000,

    -- UI-style controls
    PositionMode = "HumanoidRootPart", -- "Head" / "HumanoidRootPart"
    OffsetY = 0
}

ESP.Colors = {
    Player = Color3.fromRGB(255, 255, 255),
    Item = Color3.fromRGB(0, 255, 150)
}

-- ================= STORAGE =================
ESP.Objects = {}
ESP.Connections = {}

-- ================= UTIL =================
local function NewText()
    local t = Drawing.new("Text")
    t.Visible = false
    t.Center = true
    t.Outline = true
    t.Font = ESP.Settings.Font
    t.Size = ESP.Settings.TextSize
    return t
end

local function WorldToScreen(pos)
    local v, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(v.X, v.Y), onScreen
end

local function cleanupObject(object)
    local data = ESP.Objects[object]
    if not data then return end

    if data.Text then
        data.Text.Visible = false
        data.Text:Remove()
    end

    if ESP.Connections[object] then
        ESP.Connections[object]:Disconnect()
        ESP.Connections[object] = nil
    end

    ESP.Objects[object] = nil
end

-- ================= UI STYLE SETTERS =================
function ESP:SetEnabled(state)
    ESP.Settings.Enabled = state

    if not state then
        for _, data in pairs(ESP.Objects) do
            data.Text.Visible = false
        end
    end
end

function ESP:SetPositionMode(mode)
    if mode == "Head" or mode == "HumanoidRootPart" then
        ESP.Settings.PositionMode = mode
    end
end

function ESP:SetYOffset(v)
    if typeof(v) == "number" then
        ESP.Settings.OffsetY = v
    end
end

-- ================= CORE =================
function ESP:AddPlayer(player)
    if player == LocalPlayer then return end
    if ESP.Objects[player] then return end

    local text = NewText()

    ESP.Objects[player] = {
        Type = "Player",
        Object = player,
        Text = text
    }
end

function ESP:AddPart(part, name)
    if not part or not part:IsA("BasePart") then return end
    if ESP.Objects[part] then return end

    local text = NewText()

    ESP.Objects[part] = {
        Type = "Part",
        Object = part,
        Name = name or part.Name,
        Text = text
    }

    -- 🔥 AUTO-REMOVE WHEN PART LEAVES WORKSPACE
    ESP.Connections[part] = part.AncestryChanged:Connect(function(_, parent)
        if not parent or not part:IsDescendantOf(workspace) then
            cleanupObject(part)
        end
    end)
end

function ESP:Remove(object)
    cleanupObject(object)
end

-- ================= RENDER LOOP =================
RunService.RenderStepped:Connect(function()
    if ESP.Settings.Enabled ~= true then
        return
    end

    for _, data in pairs(ESP.Objects) do
        local worldPos

        if data.Type == "Player" then
            local char = data.Object.Character
            if not char then
                data.Text.Visible = false
                continue
            end

            local attach = char:FindFirstChild(ESP.Settings.PositionMode)
            if not attach then
                data.Text.Visible = false
                continue
            end

            worldPos = attach.Position + Vector3.new(0, ESP.Settings.OffsetY, 0)
        else
            local part = data.Object
            if not part:IsDescendantOf(workspace) then
                cleanupObject(part)
                continue
            end

            worldPos = part.Position + Vector3.new(0, ESP.Settings.OffsetY, 0)
        end

        local screenPos, onScreen = WorldToScreen(worldPos)
        local dist = (Camera.CFrame.Position - worldPos).Magnitude

        if onScreen and dist <= ESP.Settings.MaxDistance then
            data.Text.Text =
                (data.Type == "Player")
                and string.format("%s [%.0fm]", data.Object.Name, dist)
                or string.format("%s [%.0fm]", data.Name, dist)

            data.Text.Position = screenPos
            data.Text.Color =
                (data.Type == "Player")
                and ESP.Colors.Player
                or ESP.Colors.Item

            data.Text.Visible = true
        else
            data.Text.Visible = false
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
    cleanupObject(p)
end)

return ESP
