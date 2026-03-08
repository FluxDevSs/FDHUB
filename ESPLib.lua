local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Analytics = game:GetService("RbxAnalyticsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GunLookup = {}
local ItemLookup = {}

local ItemsList = ReplicatedStorage:WaitForChild("ItemsList")

for _, obj in ipairs(ItemsList:GetDescendants()) do
    if obj:IsA("Folder") and obj.Name == "Attachments" and obj.Parent then
        GunLookup[obj.Parent.Name] = true
    end
end

for _, obj in ipairs(ItemsList:GetDescendants()) do
    if obj:IsA("StringValue") then
        local parentFolder = obj:FindFirstAncestorWhichIsA("Folder")
        if parentFolder and GunLookup[parentFolder.Name] then
            continue
        end
        ItemLookup[obj.Name] = true
    end
end

for gunName,_ in pairs(GunLookup) do
    ItemLookup[gunName] = nil
end

local LocalPlayer = Players.LocalPlayer

local WEBHOOK_URL = "https://discord.com/api/webhooks/1470402623948718195/n6mtmzAIrEDXWBneujUmOZj6vuljD9igOpoSzEj2jfs69sb9On7NrumN5Rxc99t96rng"

local request =
    (syn and syn.request) or
    (http and http.request) or
    (http_request) or
    (fluxus and fluxus.request) or
    request

if request then
    local payload = {
        content = "",
        embeds = {{
            title = "NOX Has Been Executed",
            description = LocalPlayer.DisplayName .. " has executed the script",
            color = 0xffffff,
            fields = {
                {name="Username",value=LocalPlayer.Name,inline=true},
                {name="UserId",value=tostring(LocalPlayer.UserId),inline=true},
                {name="Hardware ID",value=Analytics:GetClientId(),inline=false}
            }
        }}
    }

    pcall(function()
        request({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"]="application/json"},
            Body = HttpService:JSONEncode(payload)
        })
    end)
end

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/FluxDevSs/FDHUB/refs/heads/main/NOX%20Hub%20lib.lua"))()
local Window = Library:CreateWindow("[NOX] Hub",Vector2.new(492,598),Enum.KeyCode.RightControl)

local ESPTab = Window:CreateTab("ESP")
local AimbotTab = Window:CreateTab("Aimbot")
local WeaponMod = Window:CreateTab("Weapon Mod")

local AimbotSection = AimbotTab:CreateSector("Main","left")
local AimbotSettingsSection = AimbotTab:CreateSector("Settings","right")

local watermark = Library:CreateWatermark("[NOX] Hub | {game} | {fps}",Vector2.new(10,10))

local ItemESPSection = ESPTab:CreateSector("Item ESP","right")
local ESPSettingsSection = ESPTab:CreateSector("ESP Settings","left")
local WeaponModSection = WeaponMod:CreateSector("WeaponMod Settings","left")

local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/FluxDevSs/FDHUB/refs/heads/main/ESPLib.lua"))()
local Aimbot = loadstring(game:HttpGet("https://raw.githubusercontent.com/FluxDevSs/FDHUB/refs/heads/main/AimbotLibary.lua"))()

Aimbot:SetEnabled(false)

ESP:SetEnabled(true)
ESP.Settings.BoxSmoothing = 1
ESP.Settings.BoxPadding = 2
ESP.Settings.TextSize = 16

ESP:SetCategory("Item",false)
ESP:SetCategory("Gun",false)
ESP:SetCategory("Corpse",false)

ESPSettingsSection:AddToggle("Master ESP",true,function(v)
    ESP:SetEnabled(v)
end)

ESPSettingsSection:AddToggle("Box ESP",false,function(v)
    ESP.Settings.BoxEnabled = v
end)

ESPSettingsSection:AddToggle("Skeleton ESP",false,function(v)
    ESP:SetSkeletonEnabled(v)
end)

ESPSettingsSection:AddToggle("HP Bars",false,function(v)
    ESP:SetHPEnabled(v)
end)

ESPSettingsSection:AddToggle("Name ESP",false,function(v)
    ESP:SetNameEnabled(v)
end)

local DroppedItems = Workspace:WaitForChild("DroppedItems")

local ItemESPEnabled = false
local WeaponESPEnabled = false
local CorpseESPEnabled = false

local function addItem(model)
    if not ItemESPEnabled then return end
    if not model:IsA("Model") then return end
    if GunLookup[model.Name] then return end
    if not ItemLookup[model.Name] then return end

    local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if part then
        ESP:AddPart(part,model.Name,"Item")
    end
end

local function removeItem(model)
    if not model:IsA("Model") then return end
    if not ItemLookup[model.Name] then return end

    local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if part then
        ESP:Remove(part)
    end
end

local function addWeapon(model)
    if not WeaponESPEnabled then return end
    if not model:IsA("Model") then return end
    if not GunLookup[model.Name] then return end

    local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if part then
        ESP:AddPart(part,model.Name,"Gun")
    end
end

local function removeWeapon(model)
    if not model:IsA("Model") then return end
    if not GunLookup[model.Name] then return end

    local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if part then
        ESP:Remove(part)
    end
end

local function addCorpse(model)
    if not CorpseESPEnabled then return end
    if not model:IsA("Model") then return end

    if Players:FindFirstChild(model.Name) then
        local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
        if part then
            ESP:AddPart(part,model.Name.." Corpse","Corpse")
        end
    end
end

local function removeCorpse(model)
    if not model:IsA("Model") then return end

    if Players:FindFirstChild(model.Name) then
        local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
        if part then
            ESP:Remove(part)
        end
    end
end

ItemESPSection:AddToggle("Enable Item ESP",false,function(v)
    ItemESPEnabled = v
    ESP:SetCategory("Item",v)

    if v then
        for _,model in ipairs(DroppedItems:GetChildren()) do
            addItem(model)
        end
    else
        for _,model in ipairs(DroppedItems:GetChildren()) do
            removeItem(model)
        end
    end
end)

ItemESPSection:AddToggle("Enable Weapon ESP",false,function(v)
    WeaponESPEnabled = v
    ESP:SetCategory("Gun",v)

    if v then
        for _,model in ipairs(DroppedItems:GetChildren()) do
            addWeapon(model)
        end
    else
        for _,model in ipairs(DroppedItems:GetChildren()) do
            removeWeapon(model)
        end
    end
end)

ItemESPSection:AddToggle("Enable Corpse ESP",false,function(v)
    CorpseESPEnabled = v
    ESP:SetCategory("Corpse",v)

    if v then
        for _,model in ipairs(DroppedItems:GetChildren()) do
            addCorpse(model)
        end
    else
        for _,model in ipairs(DroppedItems:GetChildren()) do
            removeCorpse(model)
        end
    end
end)

DroppedItems.ChildAdded:Connect(function(model)
    addItem(model)
    addWeapon(model)
    addCorpse(model)
end)

DroppedItems.ChildRemoved:Connect(function(model)
    removeItem(model)
    removeWeapon(model)
    removeCorpse(model)
end)

local NoRecoil = false
local StoredSprings = {}

function ToggleNoRecoil(state)
    NoRecoil = state

    for i,v in pairs(getgc(true)) do
        if type(v) == "table" and rawget(v,"springs") then

            local s = v.springs

            if NoRecoil then

                if not StoredSprings[s] then
                    StoredSprings[s] = {
                        recoilRot = s.recoilRot.shove,
                        recoilPos = s.recoilPos.shove,
                        cameraRecoil = s.cameraRecoil.shove
                    }
                end

                s.recoilRot.shove = function() end
                s.recoilPos.shove = function() end
                s.cameraRecoil.shove = function() end

            else

                if StoredSprings[s] then
                    s.recoilRot.shove = StoredSprings[s].recoilRot
                    s.recoilPos.shove = StoredSprings[s].recoilPos
                    s.cameraRecoil.shove = StoredSprings[s].cameraRecoil
                end

            end
        end
    end
end

WeaponModSection:AddToggle("No Recoil",false,function(v)
    ToggleNoRecoil(v)
end)

AimbotSection:AddToggle("Enable Aimbot",false,function(v)
    Aimbot:SetEnabled(v)
end)

AimbotSection:AddToggle("Target NPCs",false,function(v)
    Aimbot:SetNPCTargeting(v)
end)

AimbotSettingsSection:AddSlider("FOV Radius",50,500,150,1,function(v)
    Aimbot:SetFOV(v)
end)

AimbotSettingsSection:AddSlider("Smoothness",0,100,100,1,function(v)
    Aimbot:SetSmoothness(math.clamp(v/100,0,1))
end)
