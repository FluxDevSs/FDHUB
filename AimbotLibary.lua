local Aimbot = {} -- v1.3

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
-- BULLET AIMBOT HOOK
-- Searches loaded modules broadly for any bullet/projectile creation function
------------------------------------------------

local BulletModule = nil
local BulletFuncName = nil

-- Names to try when searching loaded modules (case-insensitive check below)
local MODULE_NAME_PATTERNS = {
    "bullet", "projectile", "proj", "gun", "shoot", "fire", "ballistic"
}

-- Function key names that suggest bullet creation
local FUNC_NAME_PATTERNS = {
    "CreateBullet", "FireBullet", "Shoot", "Fire", "NewBullet",
    "SpawnBullet", "CreateProjectile", "FireProjectile"
}

local function nameMatchesAny(name, patterns)
    local lower = name:lower()
    for _, pat in ipairs(patterns) do
        if lower:find(pat:lower(), 1, true) then
            return true
        end
    end
    return false
end

local function findBulletFunction(tbl)
    for _, funcName in ipairs(FUNC_NAME_PATTERNS) do
        local ok, val = pcall(function() return tbl[funcName] end)
        if ok and type(val) == "function" then
            return funcName
        end
    end
    return nil
end

-- Search all loaded modules
for _, v in pairs(getloadedmodules()) do
    if not nameMatchesAny(v.Name, MODULE_NAME_PATTERNS) then continue end

    local ok, result = pcall(require, v)
    if not ok or type(result) ~= "table" then continue end

    local funcName = findBulletFunction(result)
    if funcName then
        BulletModule = result
        BulletFuncName = funcName
        break
    end
end

-- If still not found, do a broader scan of ALL loaded modules for bullet-like functions
if not BulletModule then
    for _, v in pairs(getloadedmodules()) do
        local ok, result = pcall(require, v)
        if not ok or type(result) ~= "table" then continue end

        local funcName = findBulletFunction(result)
        if funcName then
            BulletModule = result
            BulletFuncName = funcName
            break
        end
    end
end

if BulletModule and BulletFuncName then
    local isFiring = false
    local original

    original = hookfunction(BulletModule[BulletFuncName], newcclosure(function(...)
        if not Aimbot.Settings.BulletAimbot then
            return original(...)
        end

        if isFiring then
            return original(...)
        end

        isFiring = true

        local args = {...}
        local target = GetClosestPlayerInFOVThroughWalls()

        if target then
            for i, v in ipairs(args) do
                if typeof(v) == "Instance" and v:IsA("BasePart") then
                    pcall(function()
                        v.CFrame = CFrame.new(v.Position, target.Position)
                    end)
                    break
                end

                -- Some games pass a CFrame or Vector3 direction directly
                if typeof(v) == "CFrame" then
                    args[i] = CFrame.new(v.Position, target.Position)
                    break
                end

                if typeof(v) == "Vector3" then
                    args[i] = (target.Position - Camera.CFrame.Position).Unit
                    break
                end
            end
        end

        local result = table.pack(original(table.unpack(args)))
        isFiring = false
        return table.unpack(result)
    end))
else
    warn("[NOX] Silent Aim: No bullet module found in this game — feature disabled")
end

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

return Aimbot
