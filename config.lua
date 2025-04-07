Config = {}
Config.AllowedJobs = {
    "sheriff",
    "police",
    "mechanic",
    "ambulance"
}
Config.NPCs = {
    mission = {
        model = "s_m_y_armymech_01",
        coords = {x = 2384.36, y = 3126.36, z = 48.12 - 1.0, h = 75.52}
    },
    sell = {
        model = "s_m_y_armymech_01",
        coords = {x = 2381.4, y = 3118.0, z = 48.12 - 1.0, h = 68.2}
    }
}
Config.FarmZones = {
    {x = 2399.92, y = 3095.56, z = 48.16},
    {x = 2412.96, y = 3088.04, z = 48.36},
    {x = 2422.32, y = 3094.8, z = 48.16},
    {x = 2418.0, y = 3114.32, z = 48.2},
    {x = 2404.68, y = 3117.6, z = 48.16}
}
Config.ClearZones = { -- Vùng zone để xóa NPC khi reset script, định nghĩa bằng tọa độ đa giác
    { -- Zone 1: Đa giác bao quanh khu vực farm
        vertices = {
            {x = 2301.04, y = 3009.44, z = 46.0},  -- Điểm 1
            {x = 2457.28, y = 3008.36, z = 42.16}, -- Điểm 2
            {x = 2505.44, y = 3190.16, z = 49.48}, -- Điểm 3
            {x = 2288.52, y = 3188.12, z = 48.08}  -- Điểm 4 (nối về điểm 1)
        }
    }
}
Config.Rewards = {
    scrapAmount = 1
}
Config.SellPrice = 100
Config.Thief = {
    chance = 100,
    minFarms = 3,
    maxFarms = 10,
    minCount = 2,
    maxCount = 3,
    model = "a_m_y_methhead_01",
    weapon = "WEAPON_ASSAULTRIFLE",
    spawnDistanceMin = 30,
    spawnDistanceMax = 40,
    delay = 15,
    rewardMin = 5,
    rewardMax = 10,
    duration = 60 -- Thời gian vụ cướp (giây), mặc định 60 giây (1 phút)
}
Config.FarmChange = {
    minFarms = 1,
    maxFarms = 5
}
Config.NotificationDuration = 10000
Config.NotificationPosition = "center-left"
Config.TargetIconColor = "#FFA500"
Config.WebhookURL = "https://discord.com/api/webhooks/1358412272526954607/eEstpHz323Dvooqlzspu5HgjkIPra8O1HFd-15dowlMo3_7KohCGkKx7sEiFTzKOnlW3"
