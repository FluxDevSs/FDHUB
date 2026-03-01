local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local ESP = {Value = false}
local PlayerESP = {Value = false}
local ContainerESP = {Value = false}
local CorpseESP = {Value = false}
local HighlightESP = {Value = false}
local BoxESP = {Value = false}
local SkeletonESP = {Value = false}
local KeyESP = {Value = false}
local NPCE = {Value = false}

local AimbotEnabled = false
local FOV_RADIUS = 150
local TARGET_PART = "Head"
local holdingRightClick = false

local PlayerESPDistance = 2000
local NPCEspDistance = 2000
local ContainerESPDistance = 2000
local CorpseESPDistance = 5000
local KeyESPDistance = 2000

local NameESPColor = Color3.fromRGB(255,255,255)
local npcNameESPColor = Color3.fromRGB(128,128,0)
local ContainerESPColor = Color3.fromRGB(255,255,0)
local CorpseESPColor = Color3.fromRGB(255,100,100)
local HighlightColor = Color3.fromRGB(255,0,0)
local BoxESPColor = Color3.fromRGB(255,0,255)
local npcBoxESPColor = Color3.fromRGB(128,128,0)
local SkeletonColor = Color3.fromRGB(0,255,255)
local KeyESPColor = Color3.fromRGB(255,215,0)
local HPBackColor = Color3.fromRGB(30,30,30)
local HPHighColor = Color3.fromRGB(0,255,0)
local HPLowColor = Color3.fromRGB(255,0,0)


local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Radius = FOV_RADIUS
FOVCircle.Thickness = 2
FOVCircle.Color = Color3.fromRGB(255,255,255)
FOVCircle.Filled = false
FOVCircle.Transparency = 1

local ESPObjects = {}
local NPCObjects = {}
local ContainerObjects = {}
local CorpseObjects = {}
local HighlightObjects = {}
local KeyObjects = {}
local CachedNPCTargets = {}

local Bones = {
	{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
	{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
	{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
	{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
	{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}
}

local function NewText(size)
	local t = Drawing.new("Text")
	t.Center = true
	t.Outline = true
	t.Font = 2
	t.Size = size
	t.Visible = false
	return t
end

local function NewBox(filled, thickness)
	local b = Drawing.new("Square")
	b.Visible = false
	b.Filled = filled or false
	b.Thickness = thickness or 2
	return b
end

local function NewLine()
	local l = Drawing.new("Line")
	l.Thickness = 2
	l.Visible = false
	return l
end

local function CreateHighlight(player)
	if player == LocalPlayer then return end
	if HighlightObjects[player] then return end
	local h = Instance.new("Highlight")
	h.FillColor = HighlightColor
	h.OutlineColor = HighlightColor
	h.FillTransparency = 0.5
	h.OutlineTransparency = 0
	h.Enabled = false
	h.Parent = game:GetService("CoreGui")
	HighlightObjects[player] = h
end

local function CreatePlayerESP(player)
	if player == LocalPlayer then return end
	if ESPObjects[player] then return end
	local skel = {}
	for i = 1,#Bones do skel[i] = NewLine() end
	ESPObjects[player] = {
		Name = NewText(14),
		Box = NewBox(false,2),
		HPBack = NewBox(true,0),
		HPFill = NewBox(true,0),
		Skeleton = skel
	}
	CreateHighlight(player)
end

local function CreateNPCEsp(npc)
	if NPCObjects[npc] then return end
	local skel = {}
	for i = 1,#Bones do skel[i] = NewLine() end
	NPCObjects[npc] = {
		Name = NewText(14),
		Box = NewBox(false,2),
		HPBack = NewBox(true,0),
		HPFill = NewBox(true,0),
		Skeleton = skel
	}
end

local function RemovePlayerESP(player)
	if ESPObjects[player] then
		for _,v in pairs(ESPObjects[player]) do
			if typeof(v) == "table" then
				for _,l in pairs(v) do l:Remove() end
			else
				v:Remove()
			end
		end
		ESPObjects[player] = nil
	end
	if HighlightObjects[player] then
		HighlightObjects[player]:Destroy()
		HighlightObjects[player] = nil
	end
end

local function CreateContainerESP(part)
	if ContainerObjects[part] then return end
	ContainerObjects[part] = {Name = NewText(13)}
end

local function CreateCorpseESP(model)
	if CorpseObjects[model] then return end
	if not Players:FindFirstChild(model.Name) then return end
	CorpseObjects[model] = {Name = NewText(13)}
end

local function CreateKeyESP(part)
	if KeyObjects[part] then return end
	KeyObjects[part] = {Name = NewText(13)}
end

local ContainersFolder = workspace:WaitForChild("Containers",10)

if ContainersFolder then
	for _,obj in ipairs(ContainersFolder:GetDescendants()) do
		if obj:IsA("BasePart") then CreateContainerESP(obj) end
	end
	ContainersFolder.DescendantAdded:Connect(function(obj)
		if obj:IsA("BasePart") then CreateContainerESP(obj) end
	end)
end

local DroppedItems = workspace:WaitForChild("DroppedItems",10)
if DroppedItems then
	for _,m in ipairs(DroppedItems:GetChildren()) do
		if m:IsA("Model") then
			CreateCorpseESP(m)
		end
		if m:IsA("Model") and string.find(string.lower(m.Name),"key") then
			local keyPart = m:FindFirstChildWhichIsA("Part")
			CreateKeyESP(keyPart)
		end
	end
	DroppedItems.ChildAdded:Connect(function(m)
		if m:IsA("Model") then
			CreateCorpseESP(m)
		end
		if m:IsA("Model") and string.find(string.lower(m.Name),"key") then
			local keyPart = m:FindFirstChildWhichIsA("Part")
			CreateKeyESP(keyPart)
		end
	end)
	DroppedItems.ChildRemoved:Connect(function(m)
		if CorpseObjects[m] then
			CorpseObjects[m].Name:Remove()
			CorpseObjects[m] = nil
		end
		if KeyObjects[m] then
			KeyObjects[m].Name:Remove()
			KeyObjects[m] = nil
		end
	end)
end

local AiZones = workspace:WaitForChild("AiZones",10)
if AiZones then
	for _,zone in ipairs(AiZones:GetChildren()) do
		for _,npc in ipairs(zone:GetDescendants()) do
			if npc:IsA("Model") and npc:FindFirstChildOfClass("Humanoid") then
				CreateNPCEsp(npc)
			end
		end
	end

	AiZones.DescendantAdded:Connect(function(obj)
		if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
			CreateNPCEsp(obj)
		end
	end)

	AiZones.DescendantRemoving:Connect(function(obj)
		if NPCObjects[obj] then
			for _,v in pairs(NPCObjects[obj]) do
				if typeof(v) == "table" then
					for _,l in pairs(v) do l:Remove() end
				else
					v:Remove()
				end
			end
			NPCObjects[obj] = nil
		end
	end)
end

for _,p in ipairs(Players:GetPlayers()) do CreatePlayerESP(p) end
Players.PlayerAdded:Connect(CreatePlayerESP)
Players.PlayerRemoving:Connect(RemovePlayerESP)

local function GetCameraBox(char)
	local hrp =
		char:FindFirstChild("HumanoidRootPart")
		or char.PrimaryPart
		or char:FindFirstChildWhichIsA("BasePart")

	if not hrp then return false end

	local head =
		char:FindFirstChild("Head")
		or char:FindFirstChild("UpperTorso")
		or hrp

	local top = head.Position + Vector3.new(0, head.Size.Y * 0.6, 0)
	local bottom = hrp.Position - Vector3.new(0, hrp.Size.Y * 2, 0)

	local t2d, v1 = Camera:WorldToViewportPoint(top)
	local b2d, v2 = Camera:WorldToViewportPoint(bottom)
	if not (v1 and v2) then return false end

	local h = math.abs(t2d.Y - b2d.Y)
	local w = h * 0.6

	return true,
		Vector2.new(t2d.X - w / 2, t2d.Y),
		Vector2.new(w, h)
end

local function GetNPCBox(model)
	local root =
		model:FindFirstChild("HumanoidRootPart")
		or model:FindFirstChild("Torso")
		or model:FindFirstChild("UpperTorso")
		or model.PrimaryPart

	if not root then
		for _,v in ipairs(model:GetChildren()) do
			if v:IsA("BasePart") then
				root = v
				break
			end
		end
	end

	if not root then return false end

	local cf,size = model:GetBoundingBox()
	local top = cf.Position + Vector3.new(0, size.Y/2, 0)
	local bottom = cf.Position - Vector3.new(0, size.Y/2, 0)

	local t2d,vis1 = Camera:WorldToViewportPoint(top)
	local b2d,vis2 = Camera:WorldToViewportPoint(bottom)
	if not (vis1 and vis2) then return false end

	local h = math.abs(t2d.Y - b2d.Y)
	local w = h * 0.6

	return true,
		Vector2.new(t2d.X - w/2, t2d.Y),
		Vector2.new(w, h),
		root
end

local function LerpColor(a,b,t)
	return Color3.new(a.R+(b.R-a.R)*t,a.G+(b.G-a.G)*t,a.B+(b.B-a.B)*t)
end

UserInputService.InputBegan:Connect(function(i,g)
	if g then return end
	if i.UserInputType == Enum.UserInputType.MouseButton2 then
		holdingRightClick = true
	end
end)

UserInputService.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton2 then
		holdingRightClick = false
	end
end)

local function GetNPCTargets()
	local targets = {}

	local AiZones = workspace:FindFirstChild("AiZones")
	if not AiZones then return targets end

	for _,zone in ipairs(AiZones:GetChildren()) do
		for _,npc in ipairs(zone:GetDescendants()) do
			if npc:IsA("Model") then
				local hum = npc:FindFirstChildOfClass("Humanoid")
				local part =
					npc:FindFirstChild(TARGET_PART)
					or npc:FindFirstChild("Head")
					or npc:FindFirstChild("UpperTorso")
					or npc:FindFirstChild("Torso")
					or npc.PrimaryPart
					or npc:FindFirstChildWhichIsA("BasePart")

				if part and (not hum or hum.Health > 0) then
					table.insert(targets, part)
				end
			end
		end
	end

	return targets
end

local function GetClosestTarget()
	local closest
	local shortest = FOV_RADIUS
	local center = Vector2.new(
		Camera.ViewportSize.X/2,
		Camera.ViewportSize.Y/2
	)

	-- players
	for _,player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local part = char and char:FindFirstChild(TARGET_PART)
			if hum and part and hum.Health > 0 then
				local pos,vis = Camera:WorldToViewportPoint(part.Position)
				if vis then
					local dx = pos.X - center.X
					local dy = pos.Y - center.Y
					local dist = dx*dx + dy*dy
					if dist < shortest*shortest then
						shortest = math.sqrt(dist)
						closest = part
					end
				end
			end
		end
	end

	-- NPCs
	for _,part in ipairs(GetNPCTargets()) do
		local pos,vis = Camera:WorldToViewportPoint(part.Position)
		if vis then
			local dx = pos.X - center.X
			local dy = pos.Y - center.Y
			local dist = dx*dx + dy*dy
			if dist < shortest*shortest then
				shortest = math.sqrt(dist)
				closest = part
			end
		end
	end

	for _,part in ipairs(CachedNPCTargets) do
		local pos,vis = Camera:WorldToViewportPoint(part.Position)
		if vis then
			local dx = pos.X - center.X
			local dy = pos.Y - center.Y
			local dist = dx*dx + dy*dy

			if dist < shortest*shortest then
				shortest = math.sqrt(dist)
				closest = part
			end
		end
	end

	return closest
end

local function HideObjects(objs)
	for _,v in pairs(objs) do
		if typeof(v) == "table" then
			for _,l in pairs(v) do
				l.Visible = false
			end
		else
			v.Visible = false
		end
	end
end

local function WithinDistanceSquared(a,b,dist)
	local d = a - b
	return d:Dot(d) <= dist*dist
end

local function BuildNPCCache()
	table.clear(CachedNPCTargets)

	local zones = workspace:FindFirstChild("AiZones")
	if not zones then return end

	for _,zone in ipairs(zones:GetChildren()) do
		for _,npc in ipairs(zone:GetDescendants()) do
			if npc:IsA("Model") then
				local hum = npc:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then
					local part =
						npc:FindFirstChild(TARGET_PART)
						or npc:FindFirstChild("Head")
						or npc:FindFirstChild("UpperTorso")
						or npc:FindFirstChild("Torso")
						or npc.PrimaryPart
						or npc:FindFirstChildWhichIsA("BasePart")

					if part then
						CachedNPCTargets[#CachedNPCTargets+1] = part
					end
				end
			end
		end
	end
end

pcall(function()
	RunService.RenderStepped:Connect(function()

		BuildNPCCache()

		local cam = Camera
		local viewport = cam.ViewportSize
		local camCenter = Vector2.new(viewport.X/2, viewport.Y/2)

		FOVCircle.Position = camCenter

		local myChar = LocalPlayer.Character
		local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
		if not myHRP then return end

		-- PLAYER ESP
		for player,objs in pairs(ESPObjects) do
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local highlight = HighlightObjects[player]

			if HighlightESP.Value and char then
				highlight.FillColor = HighlightColor
				highlight.OutlineColor = HighlightColor
				highlight.Adornee = char
				highlight.Enabled = true
			else
				highlight.Enabled = false
			end

			if ESP.Value and PlayerESP.Value and char and hum and hrp and hum.Health > 0 then
				local d = hrp.Position - myHRP.Position
				if d:Dot(d) <= PlayerESPDistance*PlayerESPDistance then
					local onScreen,pos,size = GetCameraBox(char)
					if onScreen then
						objs.Box.Position = pos
						objs.Box.Size = size
						objs.Box.Color = BoxESPColor
						objs.Box.Visible = BoxESP.Value

						local hp = math.clamp(hum.Health/hum.MaxHealth,0,1)
						local bw = 4
						local bp = Vector2.new(pos.X-bw-3,pos.Y)

						objs.HPBack.Position = bp
						objs.HPBack.Size = Vector2.new(bw,size.Y)
						objs.HPBack.Color = HPBackColor
						objs.HPBack.Visible = BoxESP.Value

						objs.HPFill.Position = Vector2.new(bp.X,bp.Y+(size.Y-size.Y*hp))
						objs.HPFill.Size = Vector2.new(bw,size.Y*hp)
						objs.HPFill.Color = LerpColor(HPLowColor,HPHighColor,hp)
						objs.HPFill.Visible = BoxESP.Value

						local head = char:FindFirstChild("Head")
						if head then
							local v = cam:WorldToViewportPoint(head.Position)
							objs.Name.Text = player.Name.." | "..math.floor(hum.Health).." | "..math.floor(d.Magnitude)
							objs.Name.Position = Vector2.new(v.X,pos.Y-16)
							objs.Name.Color = NameESPColor
							objs.Name.Visible = true
						end

						if SkeletonESP.Value then
							for i,b in ipairs(Bones) do
								local p1,p2 = char:FindFirstChild(b[1]),char:FindFirstChild(b[2])
								local l = objs.Skeleton[i]
								if p1 and p2 then
									local v1,vi1 = cam:WorldToViewportPoint(p1.Position)
									local v2,vi2 = cam:WorldToViewportPoint(p2.Position)
									if vi1 and vi2 then
										l.From = Vector2.new(v1.X,v1.Y)
										l.To = Vector2.new(v2.X,v2.Y)
										l.Color = SkeletonColor
										l.Visible = true
									else
										l.Visible = false
									end
								else
									l.Visible = false
								end
							end
						else
							for _,l in pairs(objs.Skeleton) do
								l.Visible = false
							end
						end
					else
						HideObjects(objs)
					end
				else
					HideObjects(objs)
				end
			else
				HideObjects(objs)
			end
		end

		-- CONTAINERS
		for part,objs in pairs(ContainerObjects) do
			if ESP.Value and ContainerESP.Value then
				local d = part.Position - myHRP.Position
				if d:Dot(d) <= ContainerESPDistance*ContainerESPDistance then
					local pos,vis = cam:WorldToViewportPoint(part.Position)
					objs.Name.Visible = vis
					if vis then
						objs.Name.Text = "[Container] "..part.Parent.Name.." ["..math.floor(d.Magnitude).."]"
						objs.Name.Color = ContainerESPColor
						objs.Name.Position = Vector2.new(pos.X,pos.Y)
					end
				else
					objs.Name.Visible = false
				end
			else
				objs.Name.Visible = false
			end
		end

		-- CORPSES
		for model,objs in pairs(CorpseObjects) do
			if ESP.Value and CorpseESP.Value then
				local part = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
				if part then
					local d = part.Position - myHRP.Position
					if d:Dot(d) <= CorpseESPDistance*CorpseESPDistance then
						local pos,vis = cam:WorldToViewportPoint(part.Position)
						objs.Name.Visible = vis
						if vis then
							objs.Name.Text = "[Corpse] "..model.Name.." ["..math.floor(d.Magnitude).."]"
							objs.Name.Color = CorpseESPColor
							objs.Name.Position = Vector2.new(pos.X,pos.Y)
						end
					else
						objs.Name.Visible = false
					end
				end
			else
				objs.Name.Visible = false
			end
		end

		-- KEYS
		for part,objs in pairs(KeyObjects) do
			if ESP.Value and KeyESP.Value then
				local d = part.Position - myHRP.Position
				if d:Dot(d) <= KeyESPDistance*KeyESPDistance then
					local pos,vis = cam:WorldToViewportPoint(part.Position)
					objs.Name.Visible = vis
					if vis then
						objs.Name.Text = part.Parent.Name.." [KEY] ["..math.floor(d.Magnitude).."]"
						objs.Name.Color = KeyESPColor
						objs.Name.Position = Vector2.new(pos.X,pos.Y)
					end
				else
					objs.Name.Visible = false
				end
			else
				objs.Name.Visible = false
			end
		end

		-- NPC ESP
		for npc,objs in pairs(NPCObjects) do
			local char = npc
			local hum = char:FindFirstChildOfClass("Humanoid")
			local hrp =
				char:FindFirstChild("HumanoidRootPart")
				or char:FindFirstChild("UpperTorso")
				or char:FindFirstChild("Torso")
				or char.PrimaryPart
				or char:FindFirstChildWhichIsA("BasePart")

			if ESP.Value and NPCE.Value and hrp then
				local d = hrp.Position - myHRP.Position
				if d:Dot(d) <= NPCEspDistance*NPCEspDistance then
					local onScreen,pos,size,root = GetNPCBox(char)
					if onScreen then
						objs.Box.Position = pos
						objs.Box.Size = size
						objs.Box.Color = npcBoxESPColor
						objs.Box.Visible = true

						local hp = (hum and hum.MaxHealth > 0) and math.clamp(hum.Health/hum.MaxHealth,0,1) or 1
						local bw = 4
						local bp = Vector2.new(pos.X-bw-3,pos.Y)

						objs.HPBack.Position = bp
						objs.HPBack.Size = Vector2.new(bw,size.Y)
						objs.HPBack.Color = HPBackColor
						objs.HPBack.Visible = true

						objs.HPFill.Position = Vector2.new(bp.X,bp.Y+(size.Y-size.Y*hp))
						objs.HPFill.Size = Vector2.new(bw,size.Y*hp)
						objs.HPFill.Color = LerpColor(HPLowColor,HPHighColor,hp)
						objs.HPFill.Visible = true

						local head = char:FindFirstChild("Head") or char:FindFirstChild("UpperTorso") or root
						if head then
							local v = cam:WorldToViewportPoint(head.Position)
							objs.Name.Text = npc.Name.." (NPC) | "..math.floor(hum.Health).." | "..math.floor(d.Magnitude)
							objs.Name.Position = Vector2.new(v.X,pos.Y-16)
							objs.Name.Color = npcNameESPColor
							objs.Name.Visible = true
						end

						if SkeletonESP.Value then
							for i,b in ipairs(Bones) do
								local p1,p2 = char:FindFirstChild(b[1]),char:FindFirstChild(b[2])
								local l = objs.Skeleton[i]
								if p1 and p2 then
									local v1,vi1 = cam:WorldToViewportPoint(p1.Position)
									local v2,vi2 = cam:WorldToViewportPoint(p2.Position)
									if vi1 and vi2 then
										l.From = Vector2.new(v1.X,v1.Y)
										l.To = Vector2.new(v2.X,v2.Y)
										l.Color = SkeletonColor
										l.Visible = true
									else
										l.Visible = false
									end
								else
									l.Visible = false
								end
							end
						else
							for _,l in pairs(objs.Skeleton) do
								l.Visible = false
							end
						end
					else
						HideObjects(objs)
					end
				else
					HideObjects(objs)
				end
			else
				HideObjects(objs)
			end
		end

		-- AIMBOT
		if AimbotEnabled and holdingRightClick then
			local target = GetClosestTarget()
			if target then
				cam.CFrame = CFrame.new(cam.CFrame.Position, target.Position)
			end
		end
	end)
end)

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/cat"))()
local Window = Library:CreateWindow("NΞON",Vector2.new(492,598),Enum.KeyCode.RightControl)
local Aimbot = Window:CreateTab("Aimbot")
local esp = Window:CreateTab("ESP")

local AimbotSection = Aimbot:CreateSector("Aimbot","left")
local ESPSection = esp:CreateSector("ESP","right")
local WorldSection = esp:CreateSector("World","right")
local SettingsSection = esp:CreateSector("Settings","left")

AimbotSection:AddSlider("FOV",0,500,150,1,function(v)
	FOV_RADIUS = v
	FOVCircle.Radius = v
end)

AimbotSection:AddToggle("Enable Aimbot",false,function(v)
	AimbotEnabled = v
end)

AimbotSection:AddToggle("Show FOV",false,function(v)
	FOVCircle.Visible = v
end)

AimbotSection:AddDropdown("Aim Part", {"Head", "HumanoidRootPart"}, "Head", false, function(dropdown)
	TARGET_PART = dropdown
end)

ESPSection:AddToggle("Enable ESP",false,function(v) ESP.Value = v end)
ESPSection:AddToggle("Player ESP",false,function(v) PlayerESP.Value = v end)
ESPSection:AddToggle("Box + HP ESP",false,function(v) BoxESP.Value = v end)
ESPSection:AddToggle("Skeleton ESP",false,function(v) SkeletonESP.Value = v end)
ESPSection:AddToggle("Player Highlight",false,function(v) HighlightESP.Value = v end)

WorldSection:AddToggle("Container ESP",false,function(v) ContainerESP.Value = v end)
WorldSection:AddToggle("Corpse ESP",false,function(v) CorpseESP.Value = v end)
WorldSection:AddToggle("Key ESP",false,function(v) KeyESP.Value = v end)
WorldSection:AddToggle("NPC ESP",false,function(v) NPCE.Value = v end)


SettingsSection:AddSlider("Player ESP Distance",0,5000,2000,50,function(v) PlayerESPDistance = v end)
SettingsSection:AddSlider("Container ESP Distance",0,5000,2000,50,function(v) ContainerESPDistance = v end)
SettingsSection:AddSlider("Corpse ESP Distance",0,5000,5000,50,function(v) CorpseESPDistance = v end)
SettingsSection:AddSlider("Key ESP Distance",0,5000,2000,50,function(v) KeyESPDistance = v end)
SettingsSection:AddSlider("NPC ESP Distance",0,5000,2000,50,function(v) NPCEspDistance = v end)

local KeyColorToggle = SettingsSection:AddToggle("Key Color",false,function() end)
KeyColorToggle:AddColorpicker(KeyESPColor,function(c) KeyESPColor = c end)

local NameColorToggle = SettingsSection:AddToggle("Name ESP Color",false,function() end)
NameColorToggle:AddColorpicker(NameESPColor,function(c)
	NameESPColor = c
end)

local BoxColorToggle = SettingsSection:AddToggle("Box ESP Color",false,function() end)
BoxColorToggle:AddColorpicker(BoxESPColor,function(c)
	BoxESPColor = c
end)

local SkeletonColorToggle = SettingsSection:AddToggle("Skeleton ESP Color",false,function() end)
SkeletonColorToggle:AddColorpicker(SkeletonColor,function(c)
	SkeletonColor = c
end)

local ContainerColorToggle = SettingsSection:AddToggle("Container ESP Color",false,function() end)
ContainerColorToggle:AddColorpicker(ContainerESPColor,function(c)
	ContainerESPColor = c
end)

local CorpseColorToggle = SettingsSection:AddToggle("Corpse ESP Color",false,function() end)
CorpseColorToggle:AddColorpicker(CorpseESPColor,function(c)
	CorpseESPColor = c
end)

local KeyColorToggle = SettingsSection:AddToggle("Key ESP Color",false,function() end)
KeyColorToggle:AddColorpicker(KeyESPColor,function(c)
	KeyESPColor = c
end)

local HighlightColorToggle = SettingsSection:AddToggle("Highlight Color",false,function() end)
HighlightColorToggle:AddColorpicker(HighlightColor,function(c)
	HighlightColor = c
end)

local HPBackToggle = SettingsSection:AddToggle("HP Background Color",false,function() end)
HPBackToggle:AddColorpicker(HPBackColor,function(c)
	HPBackColor = c
end)

local HPHighToggle = SettingsSection:AddToggle("HP High Color",false,function() end)
HPHighToggle:AddColorpicker(HPHighColor,function(c)
	HPHighColor = c
end)

local HPLowToggle = SettingsSection:AddToggle("HP Low Color",false,function() end)
HPLowToggle:AddColorpicker(HPLowColor,function(c)
	HPLowColor = c
end)