ESX = exports['es_extended']:getSharedObject()

local function getRandomFarmLocation()
    return Config.FarmZones[math.random(#Config.FarmZones)]
end

local function isAllowedJob(jobName)
    for _, job in ipairs(Config.AllowedJobs) do
        if job == jobName then
            return true
        end
    end
    return false
end

local function sendWebhook(title, description, color)
    if Config.WebhookURL and Config.WebhookURL ~= "YOUR_DISCORD_WEBHOOK_URL_HERE" then
        local embed = {
            {
                ["title"] = title,
                ["description"] = description,
                ["color"] = color,
                ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                ["footer"] = {
                    ["text"] = "Sheriff Scrap Farming Log"
                }
            }
        }
        PerformHttpRequest(Config.WebhookURL, function(err, text, headers) end, 'POST', json.encode({embeds = embed}), { ['Content-Type'] = 'application/json' })
    end
end

RegisterServerEvent("sheriff:startMission")
AddEventHandler("sheriff:startMission", function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then
        return
    end
    if isAllowedJob(xPlayer.job.name) then
        local farmLocation = getRandomFarmLocation()
        TriggerClientEvent("sheriff:setFarmLocation", src, farmLocation)
        sendWebhook("Nhận nhiệm vụ", "Người chơi: " .. xPlayer.getName() .. " (ID: " .. src .. ")\nJob: " .. xPlayer.job.name .. "\nVị trí farm: " .. farmLocation.x .. ", " .. farmLocation.y .. ", " .. farmLocation.z, 65280)
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = "Lỗi",
            description = "Bạn không có quyền làm nhiệm vụ này!",
            type = "error",
            position = Config.NotificationPosition,
            duration = Config.NotificationDuration,
            icon = "times"
        })
    end
end)

RegisterServerEvent("sheriff:farmScrap")
AddEventHandler("sheriff:farmScrap", function(farmCount, currentLocation)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then
        return
    end
    if isAllowedJob(xPlayer.job.name) then
        if exports.ox_inventory:CanCarryItem(src, "phelieu", Config.Rewards.scrapAmount) then
            exports.ox_inventory:AddItem(src, "phelieu", Config.Rewards.scrapAmount)
            TriggerClientEvent('ox_lib:notify', src, {
                title = "Thành công",
                description = "Bạn đã thu gom " .. Config.Rewards.scrapAmount .. " phế liệu!",
                type = "success",
                position = Config.NotificationPosition,
                duration = Config.NotificationDuration,
                icon = "check"
            })
            sendWebhook("Farm phế liệu", "Người chơi: " .. xPlayer.getName() .. " (ID: " .. src .. ")\nSố phế liệu: " .. Config.Rewards.scrapAmount .. "\nVị trí: " .. currentLocation.x .. ", " .. currentLocation.y .. ", " .. currentLocation.z, 255)

            if farmCount >= Config.Thief.minFarms and farmCount <= Config.Thief.maxFarms and math.random(100) <= Config.Thief.chance then
                local thiefCount = math.random(Config.Thief.minCount, Config.Thief.maxCount)
                TriggerClientEvent("sheriff:thiefWarning", src, thiefCount)
                sendWebhook("Kích hoạt cướp", "Người chơi: " .. xPlayer.getName() .. " (ID: " .. src .. ")\nSố cướp: " .. thiefCount, 16711680)
                Citizen.Wait(Config.Thief.delay * 1000)
                TriggerClientEvent("sheriff:spawnThief", src, currentLocation, thiefCount)
            end
        else
            TriggerClientEvent('ox_lib:notify', src, {
                title = "Lỗi",
                description = "Túi đồ của bạn đã đầy! Không thể nhận thêm phế liệu.",
                type = "error",
                position = Config.NotificationPosition,
                duration = Config.NotificationDuration,
                icon = "times"
            })
            sendWebhook("Túi đồ đầy", "Người chơi: " .. xPlayer.getName() .. " (ID: " .. src .. ")\nKhông thể nhận " .. Config.Rewards.scrapAmount .. " phế liệu", 16776960)
        end
    end
end)

RegisterServerEvent("sheriff:changeFarmLocation")
AddEventHandler("sheriff:changeFarmLocation", function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then
        return
    end
    if isAllowedJob(xPlayer.job.name) then
        local newFarmLocation = getRandomFarmLocation()
        TriggerClientEvent("sheriff:setFarmLocation", src, newFarmLocation)
        sendWebhook("Thay đổi vị trí farm", "Người chơi: " .. xPlayer.getName() .. " (ID: " .. src .. ")\nVị trí mới: " .. newFarmLocation.x .. ", " .. newFarmLocation.y .. ", " .. newFarmLocation.z, 65280)
    end
end)

RegisterServerEvent("sheriff:sellScrap")
AddEventHandler("sheriff:sellScrap", function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then
        return
    end
    if isAllowedJob(xPlayer.job.name) then
        local scrapCount = exports.ox_inventory:Search(src, 'count', 'phelieu')
        if scrapCount > 0 then
            local totalMoney = scrapCount * Config.SellPrice
            exports.ox_inventory:RemoveItem(src, "phelieu", scrapCount)
            xPlayer.addMoney(totalMoney)
            TriggerClientEvent('ox_lib:notify', src, {
                title = "Thành công",
                description = "Bạn đã bán " .. scrapCount .. " phế liệu và nhận $" .. totalMoney .. "!",
                type = "success",
                position = Config.NotificationPosition,
                duration = Config.NotificationDuration,
                icon = "check"
            })
            sendWebhook("Bán phế liệu", "Người chơi: " .. xPlayer.getName() .. " (ID: " .. src .. ")\nSố phế liệu: " .. scrapCount .. "\nTiền nhận: $" .. totalMoney, 255)
            TriggerClientEvent("sheriff:setFarmLocation", src, nil)
        else
            TriggerClientEvent('ox_lib:notify', src, {
                title = "Lỗi",
                description = "Bạn không có phế liệu để bán!",
                type = "error",
                position = Config.NotificationPosition,
                duration = Config.NotificationDuration,
                icon = "times"
            })
        end
    end
end)

RegisterServerEvent("sheriff:playerDied")
AddEventHandler("sheriff:playerDied", function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then
        return
    end
    local scrapCount = exports.ox_inventory:Search(src, 'count', 'phelieu')
    if scrapCount and scrapCount > 0 then
        local removed = exports.ox_inventory:RemoveItem(src, "phelieu", scrapCount)
        if removed then
            TriggerClientEvent('ox_lib:notify', src, {
                title = "Thất bại",
                description = "Bạn đã chết và mất hết " .. scrapCount .. " phế liệu!",
                type = "error",
                position = Config.NotificationPosition,
                duration = Config.NotificationDuration,
                icon = "exclamation-circle"
            })
            sendWebhook("Người chơi chết", "Người chơi: " .. xPlayer.getName() .. " (ID: " .. src .. ")\nMất " .. scrapCount .. " phế liệu", 16711680)
        end
    end
    TriggerClientEvent("sheriff:setFarmLocation", src, nil)
end)

RegisterServerEvent("sheriff:thiefDefeated")
AddEventHandler("sheriff:thiefDefeated", function(thiefCount)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then
        return
    end
    if isAllowedJob(xPlayer.job.name) then
        local rewardAmount = math.random(Config.Thief.rewardMin, Config.Thief.rewardMax)
        if exports.ox_inventory:CanCarryItem(src, "phelieu", rewardAmount) then
            exports.ox_inventory:AddItem(src, "phelieu", rewardAmount)
            TriggerClientEvent('ox_lib:notify', src, {
                title = "Phòng thủ thành công!",
                description = "Bạn đã tiêu diệt " .. thiefCount .. " kẻ cướp và nhận " .. rewardAmount .. " phế liệu!",
                type = "success",
                position = Config.NotificationPosition,
                duration = Config.NotificationDuration,
                icon = "check"
            })
            sendWebhook("Phòng thủ thành công", "Người chơi: " .. xPlayer.getName() .. " (ID: " .. src .. ")\nTiêu diệt: " .. thiefCount .. " cướp\nPhần thưởng: " .. rewardAmount .. " phế liệu", 65280)
        else
            TriggerClientEvent('ox_lib:notify', src, {
                title = "Phòng thủ thành công!",
                description = "Bạn đã tiêu diệt " .. thiefCount .. " kẻ cướp nhưng túi đồ đầy, không nhận được phế liệu!",
                type = "success",
                position = Config.NotificationPosition,
                duration = Config.NotificationDuration,
                icon = "check"
            })
            sendWebhook("Phòng thủ thành công (túi đầy)", "Người chơi: " .. xPlayer.getName() .. " (ID: " .. src .. ")\nTiêu diệt: " .. thiefCount .. " cướp\nKhông nhận phần thưởng do túi đầy", 16776960)
        end
    end
end)