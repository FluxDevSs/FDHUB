local Aimbot = {} -- v3.7

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
-- Since hookfunction on CreateBullet doesnt work on this executor build,
-- we hook workspace.Raycast instead. The bullet module uses workspace:Raycast
-- for hit detection. We spoof the result to always return the target's
-- HeadTopHitBox, which causes the game to naturally call ProjectileInflict
-- with the correct seed and timestamp.
------------------------------------------------

local cachedTarget = nil

RunService.Heartbeat:Connect(function()
    if Aimbot.Settings.BulletAimbot then
        cachedTarget = GetClosestPlayerInFOVThroughWalls()
    else
        cachedTarget = nil
    end
end)

local oldRaycast
oldRaycast = hookfunction(workspace.Raycast, newcclosure(function(self, origin, direction, params)
    if not Aimbot.Settings.BulletAimbot or not cachedTarget then
        return oldRaycast(self, origin, direction, params)
    end

    local character = cachedTarget.Parent or cachedTarget
    if not character then
        return oldRaycast(self, origin, direction, params)
    end

    local hitPart = character:FindFirstChild("HeadTopHitBox")
        or character:FindFirstChild("Head")
        or character:FindFirstChild("HumanoidRootPart")

    if not hitPart then
        return oldRaycast(self, origin, direction, params)
    end

    -- Run the real raycast first
    local result = oldRaycast(self, origin, direction, params)

    -- If it already hit our target naturally, dont touch it
    if result and result.Instance then
        local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
        if hitModel == character then
            return result
        end
    end

    -- Spoof: make the bullet think it hit the target's hitbox
    -- We return a fake result table pointing at the hitPart
    local fakeResult = {
        Instance = hitPart,
        Position = hitPart.Position,
        Normal   = (origin - hitPart.Position).Unit,
        Material = Enum.Material.SmoothPlastic,
        Distance = (hitPart.Position - origin).Magnitude,
    }

    return fakeResult
end))

-- Safety net namecall hook — the raycast spoof should handle everything
-- but this ensures the CFrame format is always correct if ProjectileInflict fires
local ProjectileInflict = game.ReplicatedStorage.Remotes.ProjectileInflict

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

    local args = {...}
    local hitPart = args[1]

    -- Check if raycast spoof already resolved to a valid enemy player part
    if hitPart and hitPart:IsDescendantOf(workspace) then
        local hitModel = hitPart:FindFirstAncestorOfClass("Model")
        local hitPlayer = hitModel and Players:GetPlayerFromCharacter(hitModel)
        if hitPlayer and hitPlayer ~= LocalPlayer then
            -- Already correct, pass through untouched
            return oldNamecall(self, ...)
        end
    end

    -- Fallback: manually spoof to cached target
    local character = cachedTarget.Parent or cachedTarget
    if not character then return oldNamecall(self, ...) end

    local newHitPart = character:FindFirstChild("HeadTopHitBox")
        or character:FindFirstChild("Head")
        or character:FindFirstChild("HumanoidRootPart")

    if not newHitPart then return oldNamecall(self, ...) end

    local newHitCFrame = newHitPart.CFrame:ToObjectSpace(CFrame.new(newHitPart.Position))
    return oldNamecall(self, newHitPart, newHitCFrame, args[3], args[4])
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
