local activeFarmLocation = nil
local farmCount = 0
local missionNPC, sellNPC

-- Sinh và thêm target cho NPC nhận nhiệm vụ
Citizen.CreateThread(function()
    local npc = Config.NPCs.mission
    RequestModel(GetHashKey(npc.model))
    while not HasModelLoaded(GetHashKey(npc.model)) do
        Citizen.Wait(100)
    end
    missionNPC = CreatePed(4, GetHashKey(npc.model), npc.coords.x, npc.coords.y, npc.coords.z, npc.coords.h, false, true)
    SetEntityInvincible(missionNPC, true)
    FreezeEntityPosition(missionNPC, true)
    SetBlockingOfNonTemporaryEvents(missionNPC, true)

    exports.ox_target:addLocalEntity(missionNPC, {
        {
            name = 'start_mission',
            label = 'Nhận nhiệm vụ farm phế liệu',
            icon = 'fa-solid fa-briefcase',
            iconColor = Config.TargetIconColor,
            onSelect = function()
                TriggerServerEvent("sheriff:startMission")
            end,
            distance = 2.0
        }
    })
end)

-- Sinh và thêm target cho NPC bán phế liệu
Citizen.CreateThread(function()
    local npc = Config.NPCs.sell
    RequestModel(GetHashKey(npc.model))
    while not HasModelLoaded(GetHashKey(npc.model)) do
        Citizen.Wait(100)
    end
    sellNPC = CreatePed(4, GetHashKey(npc.model), npc.coords.x, npc.coords.y, npc.coords.z, npc.coords.h, false, true)
    SetEntityInvincible(sellNPC, true)
    FreezeEntityPosition(sellNPC, true)
    SetBlockingOfNonTemporaryEvents(sellNPC, true)

    exports.ox_target:addLocalEntity(sellNPC, {
        {
            name = 'sell_scrap',
            label = 'Bán phế liệu',
            icon = 'fa-solid fa-money-bill',
            iconColor = Config.TargetIconColor,
            onSelect = function()
                TriggerServerEvent("sheriff:sellScrap")
            end,
            distance = 2.0
        }
    })
end)

-- Farm phế liệu với mini-game và animation
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if activeFarmLocation then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local dist = GetDistanceBetweenCoords(playerCoords, activeFarmLocation.x, activeFarmLocation.y, activeFarmLocation.z, true)
            if dist < 30.0 then
                DrawMarker(1, activeFarmLocation.x, activeFarmLocation.y, activeFarmLocation.z - 1.0, 0, 0, 0, 0, 0, 0, 1.0, 1.0, 1.0, 255, 255, 0, 100, false, true, 2, nil, nil, false)
                if dist < 2.0 then
                    lib.showTextUI("[E] Farm phế liệu", {position = "right-center", icon = "hand"})
                    if IsControlJustPressed(0, 38) then
                        lib.hideTextUI()
                        RequestAnimDict("amb@world_human_welding@male@base")
                        while not HasAnimDictLoaded("amb@world_human_welding@male@base") do
                            Citizen.Wait(100)
                        end
                        TaskPlayAnim(playerPed, "amb@world_human_welding@male@base", "base", 8.0, -8.0, -1, 1, 0, false, false, false)
                        Citizen.Wait(2000)
                        ClearPedTasks(playerPed)

                        local success = lib.skillCheck({'easy', 'easy', 'medium'}, {'e', 'q', 'e'})
                        if success then
                            farmCount = farmCount + 1
                            TriggerServerEvent("sheriff:farmScrap", farmCount, activeFarmLocation)
                            if farmCount >= math.random(Config.FarmChange.minFarms, Config.FarmChange.maxFarms) then
                                TriggerServerEvent("sheriff:changeFarmLocation")
                                farmCount = 0
                            end
                        else
                            lib.notify({
                                title = "Thất bại",
                                description = "Bạn không farm được phế liệu!",
                                type = "error",
                                position = Config.NotificationPosition,
                                duration = Config.NotificationDuration,
                                icon = "times"
                            })
                        end
                    end
                else
                    lib.hideTextUI()
                end
            else
                lib.hideTextUI()
            end
        end
    end
end)

-- Nhận vị trí farm
RegisterNetEvent("sheriff:setFarmLocation")
AddEventHandler("sheriff:setFarmLocation", function(location)
    activeFarmLocation = location
    if location then
        SetNewWaypoint(location.x, location.y)
        lib.notify({
            title = "Nhiệm vụ",
            description = "Đi đến vị trí farm phế liệu được đánh dấu trên bản đồ!",
            type = "inform",
            position = Config.NotificationPosition,
            duration = Config.NotificationDuration,
            icon = "map"
        })
    else
        SetWaypointOff()
        farmCount = 0
        lib.hideTextUI()
    end
end)

-- Thông báo cướp sắp xuất hiện với âm thanh báo động
RegisterNetEvent("sheriff:thiefWarning")
AddEventHandler("sheriff:thiefWarning", function(thiefCount)
    lib.notify({
        title = "Cảnh báo!",
        description = "Bạn có 15 giây để phòng thủ! " .. thiefCount .. " kẻ cướp đang đến!",
        type = "warning",
        position = Config.NotificationPosition,
        duration = Config.NotificationDuration,
        icon = "exclamation-triangle",
        iconColor = "#FF4500"
    })
    PlaySoundFrontend(-1, "Beep_Red", "DLC_HEIST_HACKING_SNAKE_SOUNDS", true)
end)

-- Thông báo cướp bỏ chạy
RegisterNetEvent("sheriff:thiefFled")
AddEventHandler("sheriff:thiefFled", function()
    lib.notify({
        title = "Kết thúc vụ cướp!",
        description = "Cướp đã bỏ chạy sau " .. Config.Thief.duration .. " giây!",
        type = "inform",
        position = Config.NotificationPosition,
        duration = Config.NotificationDuration,
        icon = "info"
    })
end)

-- Xóa NPC trên tất cả client
RegisterNetEvent("sheriff:removeThief")
AddEventHandler("sheriff:removeThief", function(netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
end)

-- NPC cướp tấn công với thời gian từ config
RegisterNetEvent("sheriff:spawnThief")
AddEventHandler("sheriff:spawnThief", function(coords, thiefCount)
    local playerPed = PlayerPedId()
    RequestModel(GetHashKey(Config.Thief.model))
    while not HasModelLoaded(GetHashKey(Config.Thief.model)) do
        Citizen.Wait(100)
    end

    local thieves = {}
    for i = 1, thiefCount do
        local offsetX = math.random(Config.Thief.spawnDistanceMin, Config.Thief.spawnDistanceMax) * (math.random(0, 1) == 1 and 1 or -1)
        local offsetY = math.random(Config.Thief.spawnDistanceMin, Config.Thief.spawnDistanceMax) * (math.random(0, 1) == 1 and 1 or -1)
        local thiefCoords = {
            x = coords.x + offsetX,
            y = coords.y + offsetY,
            z = coords.z
        }
        local thief = CreatePed(4, GetHashKey(Config.Thief.model), thiefCoords.x, thiefCoords.y, thiefCoords.z, 0.0, true, true)
        if DoesEntityExist(thief) then
            local netId = NetworkGetNetworkIdFromEntity(thief)
            GiveWeaponToPed(thief, GetHashKey(Config.Thief.weapon), 100, false, true)
            TaskCombatPed(thief, playerPed, 0, 16)
            SetPedCombatAttributes(thief, 46, true)
            SetPedFleeAttributes(thief, 0, false)
            SetPedRelationshipGroupHash(thief, GetHashKey("HATES_PLAYER"))

            local blip = AddBlipForEntity(thief)
            SetBlipSprite(blip, 1)
            SetBlipColour(blip, 1)
            SetBlipScale(blip, 0.8)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Kẻ cướp phế liệu")
            EndTextCommandSetBlipName(blip)

            table.insert(thieves, {ped = thief, blip = blip, netId = netId})
            TriggerServerEvent("sheriff:registerThief", netId)
        end
    end

    lib.notify({
        title = "Cảnh báo!",
        description = thiefCount .. " kẻ cướp đã xuất hiện để cướp phế liệu của bạn!",
        type = "warning",
        position = Config.NotificationPosition,
        duration = Config.NotificationDuration,
        icon = "exclamation-triangle",
        iconColor = "#FF4500"
    })

    Citizen.CreateThread(function()
        local timeLeft = Config.Thief.duration -- Lấy thời gian từ config
        while timeLeft > 0 and #thieves > 0 do
            if IsEntityDead(playerPed) then
                TriggerServerEvent("sheriff:playerDied")
            end
            local allDead = true
            for i = #thieves, 1, -1 do
                if IsEntityDead(thieves[i].ped) then
                    RemoveBlip(thieves[i].blip)
                    TriggerServerEvent("sheriff:removeThiefSync", thieves[i].netId)
                    table.remove(thieves, i)
                else
                    allDead = false
                end
            end
            if allDead then
                TriggerServerEvent("sheriff:thiefDefeated", thiefCount)
                break
            end
            timeLeft = timeLeft - 1
            Citizen.Wait(1000)
        end

        -- Hết thời gian, xóa tất cả NPC cướp và thông báo
        if timeLeft <= 0 then
            for _, thief in pairs(thieves) do
                RemoveBlip(thief.blip)
                TriggerServerEvent("sheriff:removeThiefSync", thief.netId)
            end
            TriggerEvent("sheriff:thiefFled")
            TriggerServerEvent("sheriff:thiefFledCleanup", thiefCount)
        end
    end)
end)

-- Hàm kiểm tra điểm trong đa giác (Point in Polygon - PIP)
local function isPointInPolygon(x, y, vertices)
    local inside = false
    for i = 1, #vertices do
        local j = i % #vertices + 1
        local xi, yi = vertices[i].x, vertices[i].y
        local xj, yj = vertices[j].x, vertices[j].y
        if ((yi > y) ~= (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi) + xi) then
            inside = not inside
        end
    end
    return inside
end

-- Xóa tất cả NPC trong vùng zone khi reset script
RegisterNetEvent("sheriff:resetScript")
AddEventHandler("sheriff:resetScript", function()
    for _, zone in pairs(Config.ClearZones) do
        local entities = GetGamePool('CPed') -- Lấy tất cả NPC trong game
        for _, entity in ipairs(entities) do
            if DoesEntityExist(entity) then
                local coords = GetEntityCoords(entity)
                local x, y = coords.x, coords.y
                if isPointInPolygon(x, y, zone.vertices) then
                    local netId = NetworkGetNetworkIdFromEntity(entity)
                    if netId then
                        TriggerServerEvent("sheriff:removeThiefSync", netId)
                    else
                        DeleteEntity(entity) -- Xóa cục bộ nếu không có netId
                    end
                end
            end
        end
    end
    lib.notify({
        title = "Reset Script",
        description = "Đã xóa tất cả NPC trong vùng zone!",
        type = "success",
        position = Config.NotificationPosition,
        duration = Config.NotificationDuration,
        icon = "check"
    })
end)

-- Lệnh để reset script (ví dụ: /resetscrap)
RegisterCommand("resetscrap", function(source, args, rawCommand)
    TriggerEvent("sheriff:resetScript")
end, false)
