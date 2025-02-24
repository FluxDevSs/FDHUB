getgenv().Settings = {
    AutoBroly = false, -- Auto Broly
    HTC = false, -- Hyperbolic Time Chamber
    AutoMob = true, -- AutoFarm Mobs
    MobName = "Brute" -- Put Mob Name Here | Mob Name List
}

if not game:IsLoaded() then game.Loaded:Wait() end 

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local noclipE = nil
local antifall = nil

local VirtualInputManager = game:GetService("VirtualInputManager")

-- Functions

local function eatbean()
    pcall(function()
        local args = {
            [1] = true
        }
    
        game:GetService("Players").LocalPlayer.Backpack.ServerTraits.EatSenzu:FireServer(unpack(args))
    end)
end

local function UnShiftLock()
	VirtualInputManager:SendKeyEvent(true, "LeftShift", false, game)
end

local function noclip()
    for _, v in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
        if v:IsA("BasePart") and v.CanCollide then
            v.CanCollide = false
            game.Players.LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
        end
    end
end

local function moveto(position, speed)
    local character = game.Players.LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        --warn("Character or HumanoidRootPart not found!")
        return
    end
    
    local humanoidRootPart = character.HumanoidRootPart
    local info = TweenInfo.new((humanoidRootPart.Position - position).Magnitude / speed, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(humanoidRootPart, info, {CFrame = CFrame.new(position)})
    
    if not humanoidRootPart:FindFirstChild("BodyVelocity") then
        antifall = Instance.new("BodyVelocity", humanoidRootPart)
        antifall.Velocity = Vector3.new(0, 0, 0)
        noclipE = RunService.Stepped:Connect(noclip)
    end
    
    tween:Play()
    
    tween.Completed:Connect(function()
        if antifall then antifall:Destroy() end
        if noclipE then noclipE:Disconnect() end
    end)
end

local function movetoobj(obj, speed)
    local character = game.Players.LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        --warn("Character or HumanoidRootPart not found!")
        return
    end

    local humanoidRootPart = character.HumanoidRootPart
    local info = TweenInfo.new(((humanoidRootPart.Position - obj.Position).Magnitude)/ speed,Enum.EasingStyle.Linear)
    local tween = TweenService:Create(humanoidRootPart, info, {CFrame = obj})
                     
    if not humanoidRootPart:FindFirstChild("BodyVelocity") then
        antifall = Instance.new("BodyVelocity", humanoidRootPart)
        antifall.Velocity = Vector3.new(0,0,0)
        noclipE = game:GetService("RunService").Stepped:Connect(noclip)
        tween:Play()
    end
                     
    tween.Completed:Connect(function()
        antifall:Destroy()
        noclipE:Disconnect()
    end) 
end

local function m1()
    pcall(function()
        function getNil(name,class) for _,v in pairs(getnilinstances())do if v.ClassName==class and v.Name==name then return v;end end end

        local args = {
            [1] = {
                [1] = "md"
            },
            [2] = CFrame.new(2797.16552734375, 3941.80517578125, -2401.011962890625) * CFrame.Angles(-1.5101770162582397, -1.4007257223129272, -1.5092918872833252),
            [3] = getNil("InputObject", "InputObject"),
            [4] = false
        }
        task.wait(0.25)
        game:GetService("Players").LocalPlayer.Backpack.ServerTraits.Input:FireServer(unpack(args))
    end)
end

-- Main Loop

--pcall(function()

    while Settings.AutoBroly do
        UnShiftLock()
        task.wait(0.1)
        if game.PlaceId == 536102540 then
            moveto(Vector3.new(2747.438, 3945.759, -2282.019), 1000)
        elseif game.PlaceId == 2050207304 then
            for i,v in pairs(game.Workspace.Live:GetChildren()) do
                if v.Name == "Broly BR" then
                    movetoobj(v.HumanoidRootPart.CFrame * CFrame.new(0,0,5), 1000)
                    m1()
                    eatbean()
                    UnShiftLock()
                    if v.Humanoid:FindFirstChild("DiedFromDamage") then
                        game:GetService('TeleportService'):Teleport(536102540)
                    end
                end
            end
        end
    end

    while Settings.HTC do
        UnShiftLock()
        task.wait()
        if game.PlaceId == 882375367 then
            for i,v in pairs(game.Workspace.Live:GetChildren()) do
                if v:IsA("Model") and v.Name ~= game.Players.LocalPlayer.Character.Name then
                    movetoobj(v.HumanoidRootPart.CFrame * CFrame.new(0,0,5), 1000)
                    m1()
                    UnShiftLock()
                end
            end
        elseif game.PlaceId == 536102540 then

        end
    end

    while Settings.AutoMob do
        UnShiftLock()
        task.wait()
        if game.PlaceId == 536102540 then
            for i,v in pairs(game.Workspace.Live:GetChildren()) do
                if v:FindFirstChild("OriginalName") and v.OriginalName.Value == Settings.MobName and v:FindFirstChild("Opos") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                    if v.HumanoidRootPart.Position == v.Opos.Value then
                        movetoobj(v.HumanoidRootPart.CFrame * CFrame.new(0,0,5), 1000)
                        m1()
                    end
                end
            end
        end
    end

--end)


--[[ Discord Inviter

task.delay(5, function()
    local discordInviter = loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/Utilities/main/Discord%20Inviter/Source.lua"))()
    discordInviter.Join("https://discord.gg/yjHzct63qB")
end)

--]]
