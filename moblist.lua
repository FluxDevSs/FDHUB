local Module = {}

local MonsterData = {

    -- Existing
    {
        Sea = "First",
        Min = 1,
        Max = 9,
        Ms = "Bandit",
        NameQuest = "BanditQuest1",
        QuestLv = 1,
        NameMon = "Bandit",
        CFrameQ = CFrame.new(1060.938,16.455,1547.784),
        CFrameMon = CFrame.new(1038.553,41.296,1576.509)
    },

    {
        Sea = "First",
        Min = 10,
        Max = 14,
        Ms = "Monkey",
        NameQuest = "JungleQuest",
        QuestLv = 1,
        NameMon = "Monkey",
        CFrameQ = CFrame.new(-1601.6553955078,36.85213470459,153.38809204102),
        CFrameMon = CFrame.new(-1448.1446533203,50.851993560791,63.60718536377)
    },

    {
        Sea = "First",
        Min = 15,
        Max = 29,
        Ms = "Gorilla",
        NameQuest = "JungleQuest",
        QuestLv = 2,
        NameMon = "Gorilla",
        CFrameQ = CFrame.new(-1601.6553955078,36.85213470459,153.38809204102),
        CFrameMon = CFrame.new(-1142.6488037109,40.462348937988,-515.39227294922)
    },

    -- Pirate
    {
        Sea = "First",
        Min = 30,
        Max = 39,
        Ms = "Pirate",
        NameQuest = "BuggyQuest1",
        QuestLv = 1,
        NameMon = "Pirate",
        CFrameQ = CFrame.new(-1140.1761474609,4.752049446106,3827.4057617188),
        CFrameMon = CFrame.new(-1201.0881347656,40.628940582275,3857.5966796875)
    },

    -- Brute
    {
        Sea = "First",
        Min = 40,
        Max = 59,
        Ms = "Brute",
        NameQuest = "BuggyQuest1",
        QuestLv = 2,
        NameMon = "Brute",
        CFrameQ = CFrame.new(-1140.1761474609,4.752049446106,3827.4057617188),
        CFrameMon = CFrame.new(-1387.5324707031,24.592035293579,4100.9575195313)
    },

    -- Desert Bandit
    {
        Sea = "First",
        Min = 60,
        Max = 74,
        Ms = "Desert Bandit",
        NameQuest = "DesertQuest",
        QuestLv = 1,
        NameMon = "Desert Bandit",
        CFrameQ = CFrame.new(896.51721191406,6.4384617805481,4390.1494140625),
        CFrameMon = CFrame.new(984.99896240234,16.109552383423,4417.91015625)
    },

    -- Desert Officer
    {
        Sea = "First",
        Min = 75,
        Max = 89,
        Ms = "Desert Officer",
        NameQuest = "DesertQuest",
        QuestLv = 2,
        NameMon = "Desert Officer",
        CFrameQ = CFrame.new(896.51721191406,6.4384617805481,4390.1494140625),
        CFrameMon = CFrame.new(1547.1510009766,14.452038764954,4381.8002929688)
    },

    -- Snow Bandit
    {
        Sea = "First",
        Min = 90,
        Max = 99,
        Ms = "Snow Bandit",
        NameQuest = "SnowQuest",
        QuestLv = 1,
        NameMon = "Snow Bandit",
        CFrameQ = CFrame.new(1386.8073730469,87.272789001465,-1298.3576660156),
        CFrameMon = CFrame.new(1356.3028564453,105.76865386963,-1328.2418212891)
    },

    -- Snowman
    {
        Sea = "First",
        Min = 100,
        Max = 119,
        Ms = "Snowman",
        NameQuest = "SnowQuest",
        QuestLv = 2,
        NameMon = "Snowman",
        CFrameQ = CFrame.new(1386.8073730469,87.272789001465,-1298.3576660156),
        CFrameMon = CFrame.new(1218.7956542969,138.01184082031,-1488.0262451172)
    },

    -- Chief Petty Officer
    {
        Sea = "First",
        Min = 120,
        Max = 149,
        Ms = "Chief Petty Officer",
        NameQuest = "MarineQuest2",
        QuestLv = 1,
        NameMon = "Chief Petty Officer",
        CFrameQ = CFrame.new(-5035.49609375,28.677835464478,4324.1840820313),
        CFrameMon = CFrame.new(-4931.1552734375,65.793113708496,4121.8393554688)
    },

    -- Sky Bandit
    {
        Sea = "First",
        Min = 150,
        Max = 174,
        Ms = "Sky Bandit",
        NameQuest = "SkyQuest",
        QuestLv = 1,
        NameMon = "Sky Bandit",
        CFrameQ = CFrame.new(-4842.1372070313,717.69543457031,-2623.0483398438),
        CFrameMon = CFrame.new(-4955.6411132813,365.46365356445,-2908.1865234375)
    },

    -- Dark Master
    {
        Sea = "First",
        Min = 175,
        Max = 189,
        Ms = "Dark Master",
        NameQuest = "SkyQuest",
        QuestLv = 2,
        NameMon = "Dark Master",
        CFrameQ = CFrame.new(-4842.1372070313,717.69543457031,-2623.0483398438),
        CFrameMon = CFrame.new(-5148.1650390625,439.04571533203,-2332.9611816406)
    },

    -- Prisoner
    {
        Sea = "First",
        Min = 190,
        Max = 209,
        Ms = "Prisoner",
        NameQuest = "PrisonerQuest",
        QuestLv = 1,
        NameMon = "Prisoner",
        CFrameQ = CFrame.new(5310.60547,0.350014925,474.946594,0.0175017118,0,0.999846935,0,1,0,-0.999846935,0,0.0175017118),
        CFrameMon = CFrame.new(4937.31885,0.332031399,649.574524,0.694649816,0,-0.719348073,0,1,0,0.719348073,0,0.694649816)
    },

    -- Dangerous Prisoner
    {
        Sea = "First",
        Min = 210,
        Max = 249,
        Ms = "Dangerous Prisoner",
        NameQuest = "PrisonerQuest",
        QuestLv = 2,
        NameMon = "Dangerous Prisoner",
        CFrameQ = CFrame.new(5310.60547,0.350014925,474.946594,0.0175017118,0,0.999846935,0,1,0,-0.999846935,0,0.0175017118),
        CFrameMon = CFrame.new(5099.6626,0.351562679,1055.7583,0.898906827,0,-0.438139856,0,1,0,0.438139856,0,0.898906827)
    },

    -- Toga Warrior
    {
        Sea = "First",
        Min = 250,
        Max = 274,
        Ms = "Toga Warrior",
        NameQuest = "ColosseumQuest",
        QuestLv = 1,
        NameMon = "Toga Warrior",
        CFrameQ = CFrame.new(-1577.7890625,7.4151420593262,-2984.4838867188),
        CFrameMon = CFrame.new(-1872.5166015625,49.080215454102,-2913.810546875)
    },

    -- Gladiator
    {
        Sea = "First",
        Min = 275,
        Max = 299,
        Ms = "Gladiator",
        NameQuest = "ColosseumQuest",
        QuestLv = 2,
        NameMon = "Gladiator",
        CFrameQ = CFrame.new(-1577.7890625,7.4151420593262,-2984.4838867188),
        CFrameMon = CFrame.new(-1521.3740234375,81.203170776367,-3066.3139648438)
    },

    -- Military Soldier
    {
        Sea = "First",
        Min = 300,
        Max = 324,
        Ms = "Military Soldier",
        NameQuest = "MagmaQuest",
        QuestLv = 1,
        NameMon = "Military Soldier",
        CFrameQ = CFrame.new(-5316.1157226563,12.262831687927,8517.00390625),
        CFrameMon = CFrame.new(-5369.0004882813,61.24352645874,8556.4921875)
    },

    -- Military Spy
    {
        Sea = "First",
        Min = 325,
        Max = 374,
        Ms = "Military Spy",
        NameQuest = "MagmaQuest",
        QuestLv = 2,
        NameMon = "Military Spy",
        CFrameQ = CFrame.new(-5316.1157226563,12.262831687927,8517.00390625),
        CFrameMon = CFrame.new(-5787.00293,75.8262634,8651.69922,0.838590562,0,-0.544762194,0,1,0,0.544762194,0,0.838590562)
    },

    -- Fishman Warrior
    {
        Sea = "First",
        Min = 375,
        Max = 399,
        Ms = "Fishman Warrior",
        NameQuest = "FishmanQuest",
        QuestLv = 1,
        NameMon = "Fishman Warrior",
        CFrameQ = CFrame.new(61122.65234375,18.497442245483,1569.3997802734),
        CFrameMon = CFrame.new(60844.10546875,98.462875366211,1298.3985595703),
        Entrance = Vector3.new(61163.8515625,11.6796875,1819.7841796875)
    },

    -- Fishman Commando
    {
        Sea = "First",
        Min = 400,
        Max = 449,
        Ms = "Fishman Commando",
        NameQuest = "FishmanQuest",
        QuestLv = 2,
        NameMon = "Fishman Commando",
        CFrameQ = CFrame.new(61122.65234375,18.497442245483,1569.3997802734),
        CFrameMon = CFrame.new(61738.3984375,64.207321166992,1433.8375244141),
        Entrance = Vector3.new(61163.8515625,11.6796875,1819.7841796875)
    },

    -- God's Guard
    {
        Sea = "First",
        Min = 450,
        Max = 474,
        Ms = "God's Guard",
        NameQuest = "SkyExp1Quest",
        QuestLv = 1,
        NameMon = "God's Guard",
        CFrameQ = CFrame.new(-4721.8603515625,845.30297851563,-1953.8489990234),
        CFrameMon = CFrame.new(-4628.0498046875,866.92877197266,-1931.2352294922),
        Entrance = Vector3.new(-4607.82275,872.54248,-1667.55688)
    },

    -- Shanda
    {
        Sea = "First",
        Min = 475,
        Max = 524,
        Ms = "Shanda",
        NameQuest = "SkyExp1Quest",
        QuestLv = 2,
        NameMon = "Shanda",
        CFrameQ = CFrame.new(-7863.1596679688,5545.5190429688,-378.42266845703),
        CFrameMon = CFrame.new(-7685.1474609375,5601.0751953125,-441.38876342773),
        Entrance = Vector3.new(-7894.6176757813,5547.1416015625,-380.29119873047)
    },

    -- Royal Squad
    {
        Sea = "First",
        Min = 525,
        Max = 549,
        Ms = "Royal Squad",
        NameQuest = "SkyExp2Quest",
        QuestLv = 1,
        NameMon = "Royal Squad",
        CFrameQ = CFrame.new(-7903.3828125,5635.9897460938,-1410.923828125),
        CFrameMon = CFrame.new(-7654.2514648438,5637.1079101563,-1407.7550048828)
    },

    -- Royal Soldier
    {
        Sea = "First",
        Min = 550,
        Max = 624,
        Ms = "Royal Soldier",
        NameQuest = "SkyExp2Quest",
        QuestLv = 2,
        NameMon = "Royal Soldier",
        CFrameQ = CFrame.new(-7903.3828125,5635.9897460938,-1410.923828125),
        CFrameMon = CFrame.new(-7760.4106445313,5679.9077148438,-1884.8112792969)
    },

    -- Galley Pirate
    {
        Sea = "First",
        Min = 625,
        Max = 649,
        Ms = "Galley Pirate",
        NameQuest = "FountainQuest",
        QuestLv = 1,
        NameMon = "Galley Pirate",
        CFrameQ = CFrame.new(5258.2788085938,38.526931762695,4050.044921875),
        CFrameMon = CFrame.new(5557.1684570313,152.32717895508,3998.7758789063)
    },

    -- Galley Captain
    {
        Sea = "First",
        Min = 650,
        Max = math.huge,
        Ms = "Galley Captain",
        NameQuest = "FountainQuest",
        QuestLv = 2,
        NameMon = "Galley Captain",
        CFrameQ = CFrame.new(5258.2788085938,38.526931762695,4050.044921875),
        CFrameMon = CFrame.new(5677.6772460938,92.786109924316,4966.6323242188)
    },
}

local First_Sea = false
local Second_Sea = false
local Third_Sea = false

local placeId = game.PlaceId

if placeId == 2753915549 then
    First_Sea = true
elseif placeId == 4442272183 then
    Second_Sea = true
elseif placeId == 7449423635 then
    Third_Sea = true
end

function module.CheckLevel()
    local Lv = player:WaitForChild("Data"):WaitForChild("Level").Value
    for _, data in ipairs(MonsterData) do
        local correctSea =
            (First_Sea and data.Sea == "First") or
            (Second_Sea and data.Sea == "Second") or
            (Third_Sea and data.Sea == "Third")
        if correctSea and Lv >= data.Min and Lv <= data.Max then
            return data
        end
    end

    return nil
end


return Module
