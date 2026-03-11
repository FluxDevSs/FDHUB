local Aimbot = {} -- v2.4

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
    local ok, target = pcall(GetClosestPlayerInFOVThroughWalls)
    if not ok or not target then return nil, nil, nil end

    local character = target.Parent or target
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local head = character:FindFirstChild("Head")

    local hitPart = hrp or head or (target:IsA("BasePart") and target or nil)
    if not hitPart then return nil, nil, nil end

    local camPos = workspace.CurrentCamera.CFrame.Position
    local hitPos = hitPart.Position

    local direction = (hitPos - camPos).Unit
    local surfacePos = hitPos + (camPos - hitPos).Unit * (hitPart.Size.Magnitude / 2)

    local ok2, hitCFrame = pcall(function()
        return hitPart.CFrame:ToObjectSpace(CFrame.new(surfacePos))
    end)
    if not ok2 then return direction, hitPart, CFrame.new() end

    return direction, hitPart, hitCFrame
end

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()

    -- Early exit if not one of our remotes - prevents crash
    if self ~= FireProjectile and self ~= VisualProjectile and self ~= ProjectileInflict then
        return oldNamecall(self, ...)
    end

    -- Early exit if bullet aimbot is off
    if not Aimbot.Settings.BulletAimbot then
        return oldNamecall(self, ...)
    end

    local args = {...}

    if self == FireProjectile and method == "InvokeServer" then
        local newDir, _, _ = getTargetInfo()
        if newDir then
            args[1] = newDir
        end
        return oldNamecall(self, table.unpack(args))
    end

    if self == VisualProjectile and method == "FireServer" then
        local newDir, _, _ = getTargetInfo()
        if newDir then
            args[1] = newDir
        end
        return oldNamecall(self, table.unpack(args))
    end

    if self == ProjectileInflict and method == "FireServer" then
        local _, newHitPart, newHitCFrame = getTargetInfo()
        if newHitPart and newHitCFrame then
            return oldNamecall(self, newHitPart, newHitCFrame, args[3], args[4])
        end
    end

    return oldNamecall(self, ...)
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



