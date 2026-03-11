local Aimbot = {} -- v1.9

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

-- Replace the entire BULLET AIMBOT HOOK section with this:

------------------------------------------------
-- BULLET AIMBOT HOOK (Direct Remote Hook)
------------------------------------------------

local FireProjectile = game.ReplicatedStorage.Remotes.FireProjectile
local VisualProjectile = game.ReplicatedStorage.Remotes.VisualProjectile
local ProjectileInflict = game.ReplicatedStorage.Remotes.ProjectileInflict

local function getTargetDirection()
    local target = GetClosestPlayerInFOVThroughWalls()
    if not target then return nil end

    local targetPos
    local character = target.Parent or target

    if character:FindFirstChild("HumanoidRootPart") then
        targetPos = character.HumanoidRootPart.Position
    elseif character:FindFirstChild("Head") then
        targetPos = character.Head.Position
    elseif target:IsA("BasePart") then
        targetPos = target.Position
    end

    if not targetPos then return nil, nil end

    local camPos = workspace.CurrentCamera.CFrame.Position
    local direction = (targetPos - camPos).Unit
    return direction, targetPos
end

-- Hook FireProjectile (InvokeServer - first shot)
local oldInvoke = FireProjectile.InvokeServer
FireProjectile.InvokeServer = newcclosure(function(self, direction, seed, timestamp)
    if not Aimbot.Settings.BulletAimbot then
        return oldInvoke(self, direction, seed, timestamp)
    end

    local newDir, _ = getTargetDirection()
    if newDir then
        direction = newDir
    end

    return oldInvoke(self, direction, seed, timestamp)
end)

-- Hook VisualProjectile (FireServer - subsequent shots e.g. shotgun pellets)
local oldVisualFire = VisualProjectile.FireServer
VisualProjectile.FireServer = newcclosure(function(self, direction, seed)
    if not Aimbot.Settings.BulletAimbot then
        return oldVisualFire(self, direction, seed)
    end

    local newDir, _ = getTargetDirection()
    if newDir then
        direction = newDir
    end

    return oldVisualFire(self, direction, seed)
end)

-- Hook ProjectileInflict to make sure damage registers on target
local oldInflict = ProjectileInflict.FireServer
ProjectileInflict.FireServer = newcclosure(function(self, hitPart, hitCFrame, seed, timestamp)
    if not Aimbot.Settings.BulletAimbot then
        return oldInflict(self, hitPart, hitCFrame, seed, timestamp)
    end

    local target = GetClosestPlayerInFOVThroughWalls()
    if target then
        local character = target.Parent or target
        local hrp = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
        if hrp then
            hitPart = hrp
            hitCFrame = hrp.CFrame:ToObjectSpace(hrp.CFrame)
        end
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
    if not BulletModule then
        warn("[NOX] Silent Aim unavailable — no compatible bullet module found in this game")
        return
    end
    self.Settings.BulletAimbot = state
end

function Aimbot:GetTarget()
    return GetClosestPlayerInFOV()
end

return Aimbot

