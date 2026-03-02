--[[ 
    Custom ESP Library
    FINAL FIXED VERSION
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
    MaxDistance = 5000
}

ESP.Colors = {
    Player = Color3.fromRGB(255, 255, 255),
    Item = Color3.fromRGB(0, 255, 150)
}

ESP.Objects = {}

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

-- ================= CORE =================
function ESP:AddPlayer(player)
    if player == LocalPlayer then return end
    if ESP.Objects[player] then return end

    ESP.Objects[player] = {
        Type = "Player",
        Object = player,
        Text = NewText()
    }
end

function ESP:AddPart(part, name)
    if ESP.Objects[part] then return end

    ESP.Objects[part] = {
        Type = "Part",
        Object = part,
        Name = name or part.Name,
        Text = NewText()
    }
end

function ESP:Remove(object)
    local data = ESP.Objects[object]
    if not data then return end

    data.Text.Visible = false
    data.Text:Remove()
    ESP.Objects[object] = nil
end

function ESP:SetEnabled(state)
    ESP.Settings.Enabled = state

    if not state then
        for _, data in pairs(ESP.Objects) do
            data.Text.Visible = false
        end
    end
end

-- ================= RENDER LOOP =================
RunService.RenderStepped:Connect(function()
    -- HARD STOP
    if ESP.Settings.Enabled ~= true then
        return
    end

    for _, data in pairs(ESP.Objects) do
        local root

        if data.Type == "Player" then
            local char = data.Object.Character
            root = char and char:FindFirstChild("HumanoidRootPart")
        else
            root = data.Object
        end

        if not root then
            data.Text.Visible = false
            continue
        end

        local pos, onScreen = WorldToScreen(root.Position)
        local dist = (Camera.CFrame.Position - root.Position).Magnitude

        if onScreen and dist <= ESP.Settings.MaxDistance then
            data.Text.Text = (data.Type == "Player")
                and string.format("%s [%.0fm]", data.Object.Name, dist)
                or string.format("%s [%.0fm]", data.Name, dist)

            data.Text.Position = pos
            data.Text.Color = (data.Type == "Player")
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
    ESP:Remove(p)
end)

return ESP
