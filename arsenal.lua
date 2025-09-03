local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/FluxDevSs/FDHUB/refs/heads/main/FDHubLib.lua"))()

local camera = workspace.CurrentCamera
local players = game:GetService("Players")
local localPlayer = players.LocalPlayer
local runService = game:GetService("RunService")
local userInput = game:GetService("UserInputService")

local Teamcheck = {Value = false}
local ESP = {Value = false}
local NESP = {Value = false}
local FOVC = {Value = 80}
local FOV = {Value = false}
local AIMBOT = {Value = false}
local AimKey = {Value = Enum.UserInputType.MouseButton2}

local Wm = library:Watermark("FDHUB | v1.0.0" .. " | " .. library:GetUsername())
local FpsWm = Wm:AddWatermark("FPS: " .. library.fps)
coroutine.wrap(function()
    while wait(0.1) do
        FpsWm:Text("FPS: " .. library.fps)
    end
end)()


local Notif = library:InitNotifications()

local LoadingXSX = Notif:Notify("Loading FDHUB, please be patient.", 5, "information") 

library.title = "FDHUB Arsenal"

library:Introduction() 

local Init = library:Init()


--// ESP \\-- 

local ESPTab = Init:NewTab("ESP")

local Section1 = ESPTab:NewSection("Main")

local ESPs = ESPTab:NewToggle("ESP", false, function(value)
    
    ESP.Value = value
    
end)

local NESPs = ESPTab:NewToggle("Name ESP", false, function(value)
    
    NESP.Value = value
    
end)

local TeamCheck = ESPTab:NewToggle("Teamcheck", false, function(value)
    
    Teamcheck.Value = value
    
end)


--// Aimbot \\-- 

local AimbotTab = Init:NewTab("AIMBOT")

local Aimbot = AimbotTab:NewToggle("Aimbot", false, function(value)
    
    AIMBOT.Value = value
    
end)

local fov = AimbotTab:NewToggle("FOV Circle", false, function(value)
    
    FOV.Value = value
    
end)

local fovc = AimbotTab:NewSlider("FOV Slider", "", true, "/", {min = 30, max = 350, default = 80}, function(value)

    FOVC.Value = value

end)


local FinishedLoading = Notif:Notify("Loaded FDHUB", 4, "success")



local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 2
fovCircle.Filled = false
fovCircle.Transparency = 1

-- Update FOV circle position
runService.RenderStepped:Connect(function()
    local mousePos = userInput:GetMouseLocation()
    fovCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
    fovCircle.Radius = FOVC.Value
    fovCircle.Visible = FOV.Value
    fovCircle.Color = Color3.fromRGB(170, 0, 255)
end)

-- Aimbot key toggle
local aimbotHeld = false
userInput.InputBegan:Connect(function(input)
    if input.UserInputType == AimKey.Value then
        aimbotHeld = true
    end
end)

userInput.InputEnded:Connect(function(input)
    if input.UserInputType == AimKey.Value then
        aimbotHeld = false
    end
end)

local espTargets = {}

local function isVisible(targetPart)
    local origin = camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit * 500

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {localPlayer.Character}
    rayParams.IgnoreWater = true

    local result = workspace:Raycast(origin, direction, rayParams)
    return result and result.Instance and result.Instance:IsDescendantOf(targetPart.Parent)
end

local function createESP(player, character)
    local humanoid = character:WaitForChild("Humanoid")
    local hrp = character:WaitForChild("HumanoidRootPart")
    local head = character:WaitForChild("Head")

    local box = Drawing.new("Square")
    box.Visible = true
    box.Thickness = 2
    box.Filled = false
    box.Color = Color3.fromRGB(255, 255, 255)

    local nameEsp = Drawing.new("Text")
    nameEsp.Visible = true
    nameEsp.Center = true
    nameEsp.Outline = true
    nameEsp.Font = 2
    nameEsp.Color = Color3.fromRGB(255, 255, 255)
    nameEsp.Size = 13

    local conn
    conn = runService.RenderStepped:Connect(function()
        if not character:IsDescendantOf(workspace) or humanoid.Health <= 0 then
            box:Remove()
            nameEsp:Remove()
            conn:Disconnect()
            espTargets[player] = nil
            return
        end

        if player.Team == localPlayer.Team and Teamcheck.Value then
            box.Visible = false
            nameEsp.Visible = false
            return
        end

        -- Project top (Head) and bottom (HRP) to screen space
        local headPos, headOnScreen = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.3, 0))
        local hrpPos, hrpOnScreen = camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 2.5, 0))
        local namePos3D = hrp.Position - Vector3.new(0, 3, 0)
        local screenPos, onScreen = camera:WorldToViewportPoint(namePos3D)

        if headOnScreen and hrpOnScreen and onScreen then
            local top = Vector2.new(headPos.X, headPos.Y)
            local bottom = Vector2.new(hrpPos.X, hrpPos.Y)
            local height = math.abs(bottom.Y - top.Y)
            local width = height / 2  -- Approximate width of player model

            box.Size = Vector2.new(width, height)
            box.Position = Vector2.new(top.X - width / 2, top.Y)
            box.Visible = ESP.Value

            local distance = (hrp.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            nameEsp.Position = Vector2.new(screenPos.X, screenPos.Y)
            nameEsp.Text = player.Name .. " (" .. math.floor(distance) .. "m)"
            nameEsp.Visible = NESP.Value


            espTargets[player] = head

            if isVisible(head) then
                box.Color = Color3.fromRGB(170, 0, 255) -- Purple if visible
            else
                box.Color = Color3.fromRGB(255, 255, 255) -- White if not visible
            end
            
        else
            box.Visible = false
            nameEsp.Visible = false
            espTargets[player] = nil
        end
    end)
end

local function onPlayerAdded(player)
    if player == localPlayer then return end

    if player.Character then
        createESP(player, player.Character)
    end

    player.CharacterAdded:Connect(function(char)
        createESP(player, char)
    end)
end

for _, player in ipairs(players:GetPlayers()) do
    onPlayerAdded(player)
end

players.PlayerAdded:Connect(onPlayerAdded)



runService.RenderStepped:Connect(function()
    if not AIMBOT.Value or not aimbotHeld then return end -- Must be toggled on and right-click held

    local mousePos = userInput:GetMouseLocation()
    local closest = nil
    local shortestDist = FOVC.Value

    for player, head in pairs(espTargets) do
        if head and head:IsDescendantOf(workspace) then
            local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(mousePos.X, mousePos.Y)).Magnitude
                if dist < shortestDist then
                    -- Team check
                    if not Teamcheck.Value or player.Team ~= localPlayer.Team then
                        closest = head
                        shortestDist = dist
                    end
                end
            end
        end
    end

    if closest then
        local camCF = CFrame.new(camera.CFrame.Position, closest.Position)
        camera.CFrame = camCF
    end
end)

