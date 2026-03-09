local Aimbot = {}

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

-- Normal FOV check, requires target to be visible on screen
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

            local distance = (Vector2.new(screenPos.X,screenPos.Y) - screenCenter).Magnitude

            if distance <= Aimbot.Settings.FOVRadius and distance < shortestDistance then
                shortestDistance = distance
                closestPart = part
            end
        end
    end

    return closestPart
end

-- Through walls FOV check, ignores visibility
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

-- Bullet aimbot hook
local BulletModule
for _, v in pairs(getloadedmodules()) do
    if v.Name == "Bullet" then
        local ok, result = pcall(require, v)
        if ok and type(result) == "table" and result.CreateBullet then
            BulletModule = result
            break
        end
    end
end

if BulletModule and BulletModule.CreateBullet then
    local isFiring = false
    local original
    original = hookfunction(BulletModule.CreateBullet, newcclosure(function(self, p66, p67, p68, p69, a, p70, b, p71)
        if not Aimbot.Settings.BulletAimbot then
            return original(self, p66, p67, p68, p69, a, p70, b, p71)
        end
        if isFiring then
            return original(self, p66, p67, p68, p69, a, p70, b, p71)
        end
        isFiring = true
        local target = GetClosestPlayerInFOVThroughWalls()
        if target and p69 then
            local aimPos = target.Position
            pcall(function()
                p69.CFrame = CFrame.new(p69.Position, aimPos)
            end)
        end
        local result = table.pack(original(self, p66, p67, p68, p69, a, p70, b, p71))
        isFiring = false
        return table.unpack(result)
    end))
else
    warn("BulletModule not found — bullet aimbot unavailable")
end

function Aimbot:SetFOV(radius)
    self.Settings.FOVRadius = radius
end

function Aimbot:SetFOVVisible(state)
    self.Settings.FOVVisible = state
end

function Aimbot:SetSmoothness(value)
    self.Settings.Smoothness = math.clamp(value,0,1)
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

return Aimbot
