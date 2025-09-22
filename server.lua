local QBCore = exports['qb-core']:GetCoreObject()

-- Player echo settings storage
local playerEchoSettings = {}

-- Check permission callback
QBCore.Functions.CreateCallback('echo:checkPermission', function(source, cb)
    if not Config.UsePermissions then
        cb(true)
        return
    end
    
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(false)
        return
    end
    
    local playerJob = Player.PlayerData.job.name
    local playerJobGrade = Player.PlayerData.job.grade.name
    
    -- Check if player has allowed job
    for _, job in ipairs(Config.AllowedJobs) do
        if playerJob == job then
            cb(true)
            return
        end
    end
    
    -- Check if player has allowed rank
    for _, rank in ipairs(Config.AllowedRanks) do
        if playerJobGrade == rank then
            cb(true)
            return
        end
    end
    
    cb(false)
end)

-- Update echo settings
RegisterNetEvent('echo:updateSettings', function(settings)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    
    if not Player then return end
    
    -- Store player settings
    playerEchoSettings[source] = settings
    
    -- Notify nearby players about the change
    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    local nearbyPlayers = {}
    
    for _, playerId in ipairs(GetPlayers()) do
        local targetPlayerId = tonumber(playerId)
        if targetPlayerId ~= source then
            local targetCoords = GetEntityCoords(GetPlayerPed(targetPlayerId))
            local distance = #(playerCoords - targetCoords)
            
            if distance <= settings.distance then
                table.insert(nearbyPlayers, targetPlayerId)
            end
        end
    end
    
    -- Trigger event for nearby players
    for _, nearbyPlayer in ipairs(nearbyPlayers) do
        TriggerClientEvent('echo:updatePlayerSettings', nearbyPlayer, source, settings)
    end
    
    -- Log the action
    print(string.format('[Echo System] Player %s (%s) updated echo settings - Enabled: %s, Strength: %d, Distance: %.1f', 
        Player.PlayerData.name, 
        Player.PlayerData.citizenid, 
        tostring(settings.enabled), 
        settings.strength, 
        settings.distance
    ))
end)

-- Get player echo settings
RegisterNetEvent('echo:getSettings', function()
    local source = source
    local settings = playerEchoSettings[source] or {
        enabled = false,
        strength = Config.DefaultEchoStrength,
        distance = Config.DefaultDistance,
        delay = Config.DefaultDelay,
        decay = Config.DefaultDecay,
        type = 'hall'
    }
    
    TriggerClientEvent('echo:receiveSettings', source, settings)
end)

-- Player disconnection cleanup
AddEventHandler('playerDropped', function()
    local source = source
    if playerEchoSettings[source] then
        playerEchoSettings[source] = nil
    end
end)

-- Admin commands (optional)
QBCore.Commands.Add('echoadmin', 'Manage player echo settings (Admin Only)', {
    {name = 'id', help = 'Player ID'},
    {name = 'action', help = 'enable/disable/reset'},
}, true, function(source, args)
    local targetId = tonumber(args[1])
    local action = args[2]
    
    if not targetId or not action then
        TriggerClientEvent('QBCore:Notify', source, 'Invalid arguments! Usage: /echoadmin [id] [enable/disable/reset]', 'error')
        return
    end
    
    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        TriggerClientEvent('QBCore:Notify', source, 'Player not found!', 'error')
        return
    end
    
    if action == 'enable' then
        playerEchoSettings[targetId] = playerEchoSettings[targetId] or {}
        playerEchoSettings[targetId].enabled = true
        TriggerClientEvent('echo:adminUpdate', targetId, playerEchoSettings[targetId])
        TriggerClientEvent('QBCore:Notify', source, 'Echo enabled for player ' .. targetId, 'success')
    elseif action == 'disable' then
        if playerEchoSettings[targetId] then
            playerEchoSettings[targetId].enabled = false
            TriggerClientEvent('echo:adminUpdate', targetId, playerEchoSettings[targetId])
        end
        TriggerClientEvent('QBCore:Notify', source, 'Echo disabled for player ' .. targetId, 'success')
    elseif action == 'reset' then
        playerEchoSettings[targetId] = {
            enabled = false,
            strength = Config.DefaultEchoStrength,
            distance = Config.DefaultDistance,
            delay = Config.DefaultDelay,
            decay = Config.DefaultDecay,
            type = 'hall'
        }
        TriggerClientEvent('echo:adminUpdate', targetId, playerEchoSettings[targetId])
        TriggerClientEvent('QBCore:Notify', source, 'Echo settings reset for player ' .. targetId, 'success')
    else
        TriggerClientEvent('QBCore:Notify', source, 'Invalid action! Use: enable, disable, or reset', 'error')
    end
end, 'admin')

-- Resource start/stop events
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print('[Echo System] Started successfully!')
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print('[Echo System] Stopped successfully!')
        -- Clean up all player settings
        playerEchoSettings = {}
    end
end)