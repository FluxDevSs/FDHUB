--[[ 
    Simple Aimbot Library
    Camera-based (legit style)
    Reusable & configurable
]]

local Aimbot = {}

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

--// Locals
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

--// Settings
Aimbot.Settings = {
    Enabled = true,
    Toggle = false, -- true = toggle, false = hold
    AimKey = Enum.UserInputType.MouseButton2,

    TeamCheck = true,
    AliveCheck = true,

    AimPart = "Head", -- Head / HumanoidRootPart
    Smoothness = 0.15, -- 0 = instant, 1 = slow
    MaxDistance = 1000,
    FOV = 250, -- pixels
}

--// State
local Aiming = false

--// Utility
local function IsAlive(player)
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function WorldToScreen(pos)
    local vec, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(vec.X, vec.Y), onScreen
end

--// Get closest target to mouse
local function GetClosestTarget()
    local closest, shortest = nil, math.huge
    local mousePos = Vector2.new(Mouse.X, Mouse.Y)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if Aimbot.Settings.TeamCheck and player.Team == LocalPlayer.Team then
                continue
            end

            if Aimbot.Settings.AliveCheck and not IsAlive(player) then
                continue
            end

            local char = player.Character
            local part = char and char:FindFirstChild(Aimbot.Settings.AimPart)
            if not part then continue end

            local screenPos, onScreen = WorldToScreen(part.Position)
            if not onScreen then continue end

            local distance = (screenPos - mousePos).Magnitude
            local worldDist = (Camera.CFrame.Position - part.Position).Magnitude

            if distance < shortest 
                and distance <= Aimbot.Settings.FOV
                and worldDist <= Aimbot.Settings.MaxDistance then
                shortest = distance
                closest = part
            end
        end
    end

    return closest
end

--// Input handling
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Aimbot.Settings.AimKey then
        if Aimbot.Settings.Toggle then
            Aiming = not Aiming
        else
            Aiming = true
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Aimbot.Settings.AimKey and not Aimbot.Settings.Toggle then
        Aiming = false
    end
end)

--// Main loop
RunService.RenderStepped:Connect(function()
    if not Aimbot.Settings.Enabled or not Aiming then return end

    local target = GetClosestTarget()
    if not target then return end

    local camPos = Camera.CFrame.Position
    local newCFrame = CFrame.new(camPos, target.Position)

    Camera.CFrame = Camera.CFrame:Lerp(newCFrame, Aimbot.Settings.Smoothness)
end)

--// API
function Aimbot:SetEnabled(state)
    self.Settings.Enabled = state
end

function Aimbot:SetSmoothness(value)
    self.Settings.Smoothness = math.clamp(value, 0, 1)
end

function Aimbot:SetAimPart(partName)
    self.Settings.AimPart = partName
end

return Aimbot
