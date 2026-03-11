local Aimbot = {} -- v2.1

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

UserInputService.InputBegan:Connect(function(input,gp)
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

    local screenCenter = Vector2.new(
        Camera.ViewportSize.X / 2,
        Camera.ViewportSize.Y / 2
    )

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if Aimbot.Settings.TeamCheck and player.Team == LocalPlayer.Team then
                continue
            end
            if Aimbot.Settings.AliveCheck and not IsAlive(player) then
                continue
            end

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

    local screenCenter = Vector2.new(
        Camera.ViewportSize.X / 2,
        Camera.ViewportSize.Y / 2
    )

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if Aimbot.Settings.TeamCheck and player.Team == LocalPlayer.Team then
                continue
            end
            if Aimbot.Settings.AliveCheck and not IsAlive(player) then
                continue
            end

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
    local screenCenter = Vector2.new(
        Camera.ViewportSize.X / 2,
        Camera.ViewportSize.Y / 2
    )

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
-- BULLET AIMBOT HOOK (Direct Remote Hook)
------------------------------------------------

local FireProjectile = game.ReplicatedStorage.Remotes.FireProjectile
local VisualProjectile = game.ReplicatedStorage.Remotes.VisualProjectile
local ProjectileInflict = game.ReplicatedStorage.Remotes.ProjectileInflict

local function getTargetInfo()
    local target = GetClosestPlayerInFOVThroughWalls()
    if not target then return nil, nil, nil end

    local character = target.Parent or target
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local head = character:FindFirstChild("Head")

    local hitPart = hrp or head or (target:IsA("BasePart") and target or nil)
    if not hitPart then return nil, nil, nil end

    local camPos = workspace.CurrentCamera.CFrame.Position
    local hitPos = hitPart.Position

    -- Direction from camera toward target
    local direction = (hitPos - camPos).Unit

    -- Hit position on the surface of the part facing the camera
    local surfacePos = hitPos + (camPos - hitPos).Unit * (hitPart.Size.Magnitude / 2)

    -- Replicate exactly what the game does:
    -- v193 = v155.CFrame:ToObjectSpace(CFrame.new(v158))
    local hitCFrame = hitPart.CFrame:ToObjectSpace(CFrame.new(surfacePos))

    return direction, hitPart, hitCFrame
end

-- Hook FireProjectile (InvokeServer - first shot)
local oldInvoke = FireProjectile.InvokeServer
FireProjectile.InvokeServer = newcclosure(function(self, direction, seed, timestamp)
    if not Aimbot.Settings.BulletAimbot then
        return oldInvoke(self, direction, seed, timestamp)
    end

    local newDir, _, _ = getTargetInfo()
    if newDir then
        direction = newDir
    end

    return oldInvoke(self, direction, seed, timestamp)
end)

-- Hook VisualProjectile (FireServer - pellets/subsequent shots)
local oldVisualFire = VisualProjectile.FireServer
VisualProjectile.FireServer = newcclosure(function(self, direction, seed)
    if not Aimbot.Settings.BulletAimbot then
        return oldVisualFire(self, direction, seed)
    end

    local newDir, _, _ = getTargetInfo()
    if newDir then
        direction = newDir
    end

    return oldVisualFire(self, direction, seed)
end)

-- Hook ProjectileInflict - this is what actually deals damage on the server
-- Game code: v6:FireServer(v155, v193, v123, tick())
-- v155 = hit part, v193 = v155.CFrame:ToObjectSpace(CFrame.new(hitPosition))
local oldInflict = ProjectileInflict.FireServer
ProjectileInflict.FireServer = newcclosure(function(self, hitPart, hitCFrame, seed, timestamp)
    if not Aimbot.Settings.BulletAimbot then
        return oldInflict(self, hitPart, hitCFrame, seed, timestamp)
    end

    local _, newHitPart, newHitCFrame = getTargetInfo()
    if newHitPart and newHitCFrame then
        hitPart = newHitPart
        hitCFrame = newHitCFrame
    end

    return oldInflict(self, hitPart, hitCFrame, seed, timestamp)
end)

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
