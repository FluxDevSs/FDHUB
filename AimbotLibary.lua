local Aimbot = {} -- v3.5

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local holdingRightClick = false

Aimbot.Settings = {
    Enabled = false,
    FOVVisible = false,
    AimPart = "Head",
    FOVRadius = 200,
    Smoothness = 0,
    TeamCheck = false,
    AliveCheck = true,
    BulletAimbot = false,
}

Aimbot.FOVCircle = Drawing.new("Circle")
Aimbot.FOVCircle.Visible = false
Aimbot.FOVCircle.Thickness = 1
Aimbot.FOVCircle.Filled = false
Aimbot.FOVCircle.NumSides = 64
Aimbot.FOVCircle.Radius = Aimbot.Settings.FOVRadius
Aimbot.FOVCircle.Color = Color3.fromRGB(255,255,255)
Aimbot.FOVCircle.Transparency = 1

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        holdingRightClick = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        holdingRightClick = false
    end
end)

local function IsAlive(player)
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function GetClosestPlayerInFOV()
    local closestPart = nil
    local shortestDistance = math.huge
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if Aimbot.Settings.TeamCheck and player.Team == LocalPlayer.Team then continue end
            if Aimbot.Settings.AliveCheck and not IsAlive(player) then continue end

            local part = player.Character:FindFirstChild(Aimbot.Settings.AimPart)
            if not part then continue end

            local screenPos, visible = Camera:WorldToViewportPoint(part.Position)
            if not visible then continue end

            local distance = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
            if distance <= Aimbot.Settings.FOVRadius and distance < shortestDistance then
                shortestDistance = distance
                closestPart = part
            end
        end
    end

    return closestPart
end

local function GetClosestPlayerInFOVThroughWalls()
    local closestPart = nil
    local shortestDistance = math.huge
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if Aimbot.Settings.TeamCheck and player.Team == LocalPlayer.Team then continue end
            if Aimbot.Settings.AliveCheck and not IsAlive(player) then continue end

            local part = player.Character:FindFirstChild(Aimbot.Settings.AimPart)
            if not part then continue end

            local screenPos, _ = Camera:WorldToViewportPoint(part.Position)
            local distance = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
            if distance <= Aimbot.Settings.FOVRadius and distance < shortestDistance then
                shortestDistance = distance
                closestPart = part
            end
        end
    end

    return closestPart
end

RunService.RenderStepped:Connect(function()
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    Aimbot.FOVCircle.Position = screenCenter
    Aimbot.FOVCircle.Radius = Aimbot.Settings.FOVRadius
    Aimbot.FOVCircle.Visible = Aimbot.Settings.FOVVisible

    if not Aimbot.Settings.Enabled then return end
    if not holdingRightClick then return end

    local target = GetClosestPlayerInFOV()
    if target then
        local camPos = Camera.CFrame.Position
        local aimCFrame = CFrame.new(camPos, target.Position)
        if Aimbot.Settings.Smoothness > 0 then
            Camera.CFrame = Camera.CFrame:Lerp(aimCFrame, Aimbot.Settings.Smoothness)
        else
            Camera.CFrame = aimCFrame
        end
    end
end)

------------------------------------------------
-- BULLET AIMBOT
-- Based on decompiled FPS.Bullet module:
-- v6:FireServer(v155, v155.CFrame:ToObjectSpace(CFrame.new(v158)), v123, tick())
-- v155 = hit part, v158 = world hit position, v123 = seed
------------------------------------------------

local ProjectileInflict = game.ReplicatedStorage.Remotes.ProjectileInflict
local cachedTarget = nil

RunService.Heartbeat:Connect(function()
    if Aimbot.Settings.BulletAimbot then
        cachedTarget = GetClosestPlayerInFOVThroughWalls()
    else
        cachedTarget = nil
    end
end)

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    if not rawequal(self, ProjectileInflict) then
        return oldNamecall(self, ...)
    end

    local method = getnamecallmethod()
    if method ~= "FireServer" then
        return oldNamecall(self, ...)
    end

    if not Aimbot.Settings.BulletAimbot or not cachedTarget then
        return oldNamecall(self, ...)
    end

    local character = cachedTarget.Parent or cachedTarget
    if not character then
        return oldNamecall(self, ...)
    end

    -- Match exactly what the game does for humanoid hits:
    -- it picks the raycast hit part (e.g. HeadTopHitBox) then does
    -- hitPart.CFrame:ToObjectSpace(CFrame.new(worldHitPosition))
    -- We spoof worldHitPosition as the center of the hitPart
    local hitPart = character:FindFirstChild("HeadTopHitBox")
        or character:FindFirstChild("Head")
        or character:FindFirstChild("HumanoidRootPart")

    if not hitPart then
        return oldNamecall(self, ...)
    end

    -- Replicate: v155.CFrame:ToObjectSpace(CFrame.new(v158))
    -- where v158 = hitPart.Position (center of the target part)
    local hitCFrame = hitPart.CFrame:ToObjectSpace(CFrame.new(hitPart.Position))

    local args = {...}
    -- arg[1] = hit part, arg[2] = object space hit CFrame, arg[3] = seed, arg[4] = timestamp
    return oldNamecall(self, hitPart, hitCFrame, args[3], args[4])
end))

------------------------------------------------
-- API
------------------------------------------------

function Aimbot:SetFOV(radius)
    self.Settings.FOVRadius = radius
end

function Aimbot:SetFOVVisible(state)
    self.Settings.FOVVisible = state
end

function Aimbot:SetSmoothness(value)
    self.Settings.Smoothness = math.clamp(value, 0, 1)
end

function Aimbot:SetAimPart(part)
    self.Settings.AimPart = part
end

function Aimbot:SetEnabled(state)
    self.Settings.Enabled = state
end

function Aimbot:SetBulletAimbot(state)
    self.Settings.BulletAimbot = state
end

function Aimbot:GetTarget()
    return GetClosestPlayerInFOV()
end

return Aimbot
