local Rarity = {
    Common = Color3.fromRGB(169, 169, 169),      -- Gray
    Uncommon = Color3.fromRGB(0, 255, 0),        -- Green
    Rare = Color3.fromRGB(0, 112, 221),          -- Blue
    Epic = Color3.fromRGB(163, 53, 238),         -- Purple
    Legendary = Color3.fromRGB(255, 128, 0),     -- Orange
}

local camera = workspace.CurrentCamera
local runservice = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local hrp = LocalPlayer.Character:WaitForChild("HumanoidRootPart")

local activeESP = {} -- Store active ESP objects
local stopESP = false -- Flag to stop ESP

function esp(drop)
    local dropesp = Drawing.new("Text")
    dropesp.Visible = false
    dropesp.Center = true
    dropesp.Outline = true
    dropesp.Font = 2
    dropesp.Size = 13

    local renderstepped
    renderstepped = runservice.RenderStepped:Connect(function()
        if stopESP then
            dropesp.Visible = false
            dropesp:Remove()
            renderstepped:Disconnect()
            return
        end

        if drop and drop.Parent and drop:FindFirstChild("PrimaryPart") then
            local drop_pos, drop_onscreen = camera:WorldToViewportPoint(drop.PrimaryPart.Position)
            local dist = (hrp.Position - drop.PrimaryPart.Position).Magnitude

            if drop_onscreen then
                dropesp.Position = Vector2.new(drop_pos.X, drop_pos.Y)
                dropesp.Text = drop.Parent.Name .. "\n" .. math.floor(dist) .. "m"
                dropesp.Visible = false

                -- Ore
                if drop.Name == "Moonstone" or drop.Parent.Name == "Moonstone" then
                    if drop.ModelParts:FindFirstChild("Cube").Transparency == 0 then
                        dropesp.Color = Rarity.Uncommon
                        dropesp.Text = drop.Parent.Name .. "\n" .. math.floor(dist) .. "m \nRarity: (Uncommon)"
                        dropesp.Visible = _G.EspSettings.Moonstone
                    else
                        dropesp.Visible = false
                    end
                elseif drop.Name == "Amberite" or drop.Parent.Name == "Amberite" then 
                    if drop.ModelParts:FindFirstChild("MeshPart").Transparency == 0 then
                        dropesp.Color = Rarity.Epic
                        dropesp.Text = drop.Parent.Name .. "\n" .. math.floor(dist) .. "m \nRarity: (Epic)"
                        dropesp.Visible = _G.EspSettings.Amberite
                    else
                        dropesp.Visible = false
                    end
                elseif drop.Name == "Emeraldite" or drop.Parent.Name == "Emeraldite" then 
                    if drop.ModelParts:FindFirstChild("Meshes/iceSpikesSav_Cone.017").Transparency == 0 then
                        dropesp.Color = Rarity.Rare
                        dropesp.Text = drop.Parent.Name .. "\n" .. math.floor(dist) .. "m \nRarity: (Rare)"
                        dropesp.Visible = _G.EspSettings.Emeraldite
                    else
                        dropesp.Visible = false
                    end
                elseif drop.Name == "Rock" or drop.Parent.Name == "Rock" then 
                    if drop.ModelParts:FindFirstChild("Rock").Transparency == 0 then
                        dropesp.Color = Rarity.Common
                        dropesp.Text = drop.Parent.Name .. "\n" .. math.floor(dist) .. "m \nRarity: (Common)"
                        dropesp.Visible = _G.EspSettings.Rock
                    else
                        dropesp.Visible = false
                    end

                -- Lumber
                elseif drop.Name == "OakTree" or drop.Parent.Name == "OakTree" then 
                    if drop.ModelParts:FindFirstChild("Model")["Tree_LOD0"].Transparency == 0 then
                        dropesp.Color = Rarity.Common
                        dropesp.Text = drop.Parent.Name .. "\n" .. math.floor(dist) .. "m \nRarity: (Common)"
                        dropesp.Visible = _G.EspSettings.OakTree
                    else
                        dropesp.Visible = false
                    end
                elseif drop.Name == "PalmTree" or drop.Parent.Name == "PalmTree" then 
                    if drop.ModelParts:FindFirstChild("Model")["Meshes/Palm tree 4_Plane"].Transparency == 0 then
                        dropesp.Color = Rarity.Rare
                        dropesp.Text = drop.Parent.Name .. "\n" .. math.floor(dist) .. "m \nRarity: (Rare)"
                        dropesp.Visible = _G.EspSettings.PalmTree
                    else
                        dropesp.Visible = false
                    end
                elseif drop.Name == "PhoenixheartRedwood" or drop.Parent.Name == "PhoenixheartRedwood" then 
                    if drop.ModelParts:FindFirstChild("tree").Transparency == 0 then
                        dropesp.Color = Rarity.Legendary
                        dropesp.Text = drop.Parent.Name .. "\n" .. math.floor(dist) .. "m \nRarity: (Legendary)"
                        dropesp.Visible = _G.EspSettings.PhoenixheartRedwood
                    else
                        dropesp.Visible = false
                    end

                else
                    dropesp.Color = drop.PrimaryPart.Color 
                end
            else
                dropesp.Visible = false
            end
        else
            dropesp.Visible = false
            dropesp:Remove()
            renderstepped:Disconnect()
        end
    end)

    table.insert(activeESP, {drawing = dropesp, connection = renderstepped})
end

-- Initial ESP for existing harvest drops
for _, drop in pairs(workspace.Game.Harvest:GetDescendants()) do
    if drop.Name == "HarvestModel" and drop:FindFirstChild("PrimaryPart") then
        esp(drop)
    end
end


-- End key to stop all ESP
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.End then
        stopESP = true
        for _, data in pairs(activeESP) do
            if data.drawing then
                data.drawing:Remove()
            end
            if data.connection then
                data.connection:Disconnect()
            end
        end
        table.clear(activeESP)
        print("ESP stopped and cleaned up.")
    end
end)
