local Aimbot = {} -- v3.3

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
-- BULLET AIMBOT HOOK
------------------------------------------------

local ProjectileInflict = game.ReplicatedStorage.Remotes.ProjectileInflict
local cachedTarget = nil

local function makeHook(orig)
    local isFiring = false
    local original

    original = hookfunction(orig, newcclosure(function(...)
        if not Aimbot.Settings.BulletAimbot then return original(...) end
        if isFiring then return original(...) end

        isFiring = true

        local args = {...}
        local target = GetClosestPlayerInFOVThroughWalls()
        cachedTarget = target

        if target then
            local targetPos
            local character = target.Parent or target
            if character:FindFirstChild("Head") then
                targetPos = character.Head.Position
            elseif character:FindFirstChild("HumanoidRootPart") then
                targetPos = character.HumanoidRootPart.Position
            elseif target:IsA("BasePart") then
                targetPos = target.Position
            end

            if targetPos then
                -- arg[5] is p69 — the part whose CFrame.LookVector is bullet direction
                local p69 = args[5]
                if p69 and typeof(p69) == "Instance" and p69:IsA("BasePart") then
                    pcall(function()
                        p69.CFrame = CFrame.new(p69.Position, targetPos)
                    end)
                end
                -- Also handle CFrame/Vector3 args as fallback
                for i, v in ipairs(args) do
                    if typeof(v) == "CFrame" then
                        args[i] = CFrame.new(v.Position, targetPos)
                        break
                    end
                    if typeof(v) == "Vector3" then
                        args[i] = (targetPos - Camera.CFrame.Position).Unit
                        break
                    end
                end
            end
        end

        local r1, r2, r3, r4 = original(...)

        coroutine.wrap(function()
            isFiring = true
            original(table.unpack(args))
            isFiring = false
            cachedTarget = nil
        end)()

        isFiring = false
        return r1, r2, r3, r4
    end))
end

-- Hook BulletModule directly
local BulletModule = require(game.ReplicatedStorage.Modules.FPS.Bullet)
if BulletModule and BulletModule.CreateBullet then
    makeHook(BulletModule.CreateBullet)
    warn("[NOX] CreateBullet hooked via module")
end

-- Also scan GC for any other copies of CreateBullet
task.delay(1, function()
    local hooked = 0
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" then
            local ok, fn = pcall(function() return rawget(v, "CreateBullet") end)
            if ok and type(fn) == "function" and fn ~= BulletModule.CreateBullet then
                pcall(function()
                    makeHook(fn)
                    hooked = hooked + 1
                end)
            end
        end
    end
    if hooked > 0 then
        warn("[NOX] Also hooked", hooked, "GC copies of CreateBullet")
    end
end)

-- Namecall hook for ProjectileInflict damage registration
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    if rawequal(self, ProjectileInflict) == false then
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
    local head = character:FindFirstChild("Head")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local newHitPart = head or hrp

    if not newHitPart then
        return oldNamecall(self, ...)
    end

    local ok, newHitCFrame = pcall(function()
        return newHitPart.CFrame:ToObjectSpace(CFrame.new(newHitPart.Position))
    end)

    if not ok then
        return oldNamecall(self, ...)
    end

    local args = {...}
    return oldNamecall(self, newHitPart, newHitCFrame, args[3], args[4])
end))

-- Raycast hook to pass bullets through walls
local oldRaycast
oldRaycast = hookfunction(workspace.Raycast, newcclosure(function(self, origin, direction, params)
    if not Aimbot.Settings.BulletAimbot or not cachedTarget then
        return oldRaycast(self, origin, direction, params)
    end

    local result = oldRaycast(self, origin, direction, params)

    if result then
        local hit = result.Instance
        local hitCharacter = hit and hit:FindFirstAncestorOfClass("Model")
        local isPlayer = hitCharacter and Players:GetPlayerFromCharacter(hitCharacter)

        if not isPlayer then
            local character = cachedTarget.Parent or cachedTarget
            local head = character:FindFirstChild("Head")
            if head then
                return nil
            end
        end
    end

    return result
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
