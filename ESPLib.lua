--[[ 
    Custom ESP Library
    Inspired by Exunys ESP structure
    Written from scratch
]]

local ESP = {}
ESP.__index = ESP

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Settings
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

-- Utility
local function NewDrawing(type, props)
    local obj = Drawing.new(type)
    for i,v in pairs(props) do
        obj[i] = v
    end
    return obj
end

local function WorldToScreen(pos)
    local vec, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(vec.X, vec.Y), onScreen, vec.Z
end

-- Base ESP object
function ESP:_create(object, name, color)
    local text = NewDrawing("Text", {
        Visible = false,
        Center = true,
        Outline = true,
        Font = self.Settings.Font,
        Size = self.Settings.TextSize,
        Color = color
    })

    self.Objects[object] = {
        Object = object,
        Name = name,
        Color = color,
        Text = text
    }
end

-- Public API
function ESP:AddPlayer(player)
    if player == LocalPlayer then return end
    self:_create(player, player.Name, self.Colors.Player)
end

function ESP:AddPart(part, name)
    self:_create(part, name or part.Name, self.Colors.Item)
end

function ESP:Remove(object)
    local data = self.Objects[object]
    if data then
        data.Text:Remove()
        self.Objects[object] = nil
    end
end

function ESP:Clear()
    for _, data in pairs(self.Objects) do
        data.Text:Remove()
    end
    table.clear(self.Objects)
end

-- Update loop
RunService.RenderStepped:Connect(function()
    if not ESP.Settings.Enabled then
        for _, data in pairs(ESP.Objects) do
            data.Text.Visible = false
        end
        return
    end

    for object, data in pairs(ESP.Objects) do
        local root

        if object:IsA("Player") then
            local char = object.Character
            root = char and char:FindFirstChild("HumanoidRootPart")
        elseif object:IsA("BasePart") then
            root = object
        end

        if not root then
            data.Text.Visible = false
            continue
        end

        local screenPos, onScreen, depth = WorldToScreen(root.Position)
        local distance = (Camera.CFrame.Position - root.Position).Magnitude

        if onScreen and distance <= ESP.Settings.MaxDistance then
            data.Text.Position = screenPos
            data.Text.Text = string.format(
                "%s [%.0fm]",
                data.Name,
                distance
            )
            data.Text.Color = data.Color
            data.Text.Visible = true
        else
            data.Text.Visible = false
        end
    end
end)

-- Auto player handling
Players.PlayerAdded:Connect(function(player)
    ESP:AddPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
    ESP:Remove(player)
end)

-- Init existing players
for _, player in ipairs(Players:GetPlayers()) do
    ESP:AddPlayer(player)
end

return ESP