local Aimbot = {} -- v3.1

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

local BulletModule = require(game.ReplicatedStorage.Modules.FPS.Bullet)
local ProjectileInflict = game.ReplicatedStorage.Remotes.ProjectileInflict

local cachedTarget = nil

-- DEBUG: Check if BulletModule loaded correctly
warn("[NOX] BulletModule =", tostring(BulletModule))
warn("[NOX] CreateBullet =", tostring(BulletModule and BulletModule.CreateBullet))

if BulletModule and BulletModule.CreateBullet then
    local isFiring = false
    local original

    original = hookfunction(BulletModule.CreateBullet, newcclosure(function(...)
        -- DEBUG: Log every time the hook fires
        local args = {...}
        warn("[NOX] CreateBullet fired! arg count =", #args)
        for i, v in ipairs(args) do
            warn("[NOX] arg["..i.."] typeof="..typeof(v).." value="..tostring(v))
        end

        if not Aimbot.Settings.BulletAimbot then
            return original(table.unpack(args))
        end

        if isFiring then
            return original(table.unpack(args))
        end

        isFiring = true

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
                warn("[NOX] Redirecting bullet to target at", tostring(targetPos))
                for i, v in ipairs(args) do
                    if typeof(v) == "CFrame" then
                        args[i] = CFrame.new(v.Position, targetPos)
                        warn("[NOX] Modified CFrame arg at index", i)
                        break
                    elseif typeof(v) == "Vector3" then
                        args[i] = (targetPos - Camera.CFrame.Position).Unit
                        warn("[NOX] Modified Vector3 arg at index", i)
                        break
                    elseif typeof(v) == "Instance" and v:IsA("BasePart") then
                        pcall(function() v.CFrame = CFrame.new(v.Position, targetPos) end)
                        warn("[NOX] Modified BasePart CFrame at index", i)
                        break
                    end
                end
            else
                warn("[NOX] No targetPos found on target character")
            end
        else
            warn("[NOX] No target in FOV for bullet redirect")
        end

        local results = table.pack(original(table.unpack(args)))

        isFiring = false
        cachedTarget = nil

        return table.unpack(results)
    end))

    warn("[NOX] Hook attached, original =", tostring(original))
else
    warn("[NOX] FAILED - BulletModule or CreateBullet is nil, cannot hook")
end

-- Namecall hook for ProjectileInflict
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
    warn("[NOX] ProjectileInflict intercepted, spoofing hit to", newHitPart.Name)
    return oldNamecall(self, newHitPart, newHitCFrame, args[3], args[4])
end))

-- Raycast hook
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
