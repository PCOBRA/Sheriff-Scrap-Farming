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

-- NPC cướp tấn công
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
        local thief = CreatePed(4, GetHashKey(Config.Thief.model), thiefCoords.x, thiefCoords.y, thiefCoords.z, 0.0, true, false)
        if DoesEntityExist(thief) then
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

            table.insert(thieves, {ped = thief, blip = blip})
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
        while #thieves > 0 do
            if IsEntityDead(playerPed) then
                TriggerServerEvent("sheriff:playerDied")
                for _, thief in pairs(thieves) do
                    RemoveBlip(thief.blip)
                    DeleteEntity(thief.ped)
                end
                break
            end
            local allDead = true
            for i = #thieves, 1, -1 do
                if IsEntityDead(thieves[i].ped) then
                    RemoveBlip(thieves[i].blip)
                    table.remove(thieves, i)
                else
                    allDead = false
                end
            end
            if allDead then
                TriggerServerEvent("sheriff:thiefDefeated", thiefCount)
                break
            end
            Citizen.Wait(1000)
        end
    end)
end)