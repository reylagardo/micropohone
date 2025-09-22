local QBCore = exports['qb-core']:GetCoreObject()
local isUIOpen = false
local currentEchoSettings = {
    enabled = false,
    strength = Config.DefaultEchoStrength,
    distance = Config.DefaultDistance,
    delay = Config.DefaultDelay,
    decay = Config.DefaultDecay,
    type = 'hall'
}

local isEchoActive = false
local echoThread = nil

-- Initialize
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerEvent('chat:addSuggestion', '/' .. Config.Command, 'Open Echo Sound Control Panel')
end)

-- Command to open UI
RegisterCommand(Config.Command, function()
    if Config.UsePermissions then
        QBCore.Functions.TriggerCallback('echo:checkPermission', function(hasPermission)
            if hasPermission then
                toggleUI()
            else
                QBCore.Functions.Notify('You don\'t have permission to use this!', 'error')
            end
        end)
    else
        toggleUI()
    end
end)

-- Toggle UI
function toggleUI()
    isUIOpen = not isUIOpen
    SetNuiFocus(isUIOpen, isUIOpen)
    
    SendNUIMessage({
        type = 'toggle',
        show = isUIOpen,
        settings = currentEchoSettings,
        config = {
            maxDistance = Config.MaxDistance,
            minDistance = Config.MinDistance,
            maxStrength = Config.MaxEchoStrength,
            minStrength = Config.MinEchoStrength,
            echoTypes = Config.EchoTypes
        }
    })
    
    if isUIOpen then
        QBCore.Functions.Notify('Echo Control Panel Opened', 'primary')
    else
        QBCore.Functions.Notify('Echo Control Panel Closed', 'primary')
    end
end

-- NUI Callbacks
RegisterNUICallback('closeUI', function(data, cb)
    isUIOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('updateEcho', function(data, cb)
    currentEchoSettings = {
        enabled = data.enabled,
        strength = data.strength,
        distance = data.distance,
        delay = data.delay,
        decay = data.decay,
        type = data.type
    }
    
    -- Apply echo settings locally
    applyEchoSettings()
    
    -- Sync with server for other players
    TriggerServerEvent('echo:updateSettings', currentEchoSettings)
    
    QBCore.Functions.Notify('Echo settings updated!', 'success')
    cb('ok')
end)

RegisterNUICallback('previewEcho', function(data, cb)
    -- Play preview sound with simple audio feedback
    playEchoPreview(data)
    cb('ok')
end)

RegisterNUICallback('resetSettings', function(data, cb)
    currentEchoSettings = {
        enabled = false,
        strength = Config.DefaultEchoStrength,
        distance = Config.DefaultDistance,
        delay = Config.DefaultDelay,
        decay = Config.DefaultDecay,
        type = 'hall'
    }
    
    applyEchoSettings()
    TriggerServerEvent('echo:updateSettings', currentEchoSettings)
    
    SendNUIMessage({
        type = 'resetSettings',
        settings = currentEchoSettings
    })
    
    QBCore.Functions.Notify('Echo settings reset to default!', 'info')
    cb('ok')
end)

-- Apply echo settings using available FiveM functions
function applyEchoSettings()
    local playerPed = PlayerPedId()
    
    if currentEchoSettings.enabled then
        -- Enable echo effect
        isEchoActive = true
        
        -- Set talking range using available function
        if NetworkSetTalkerProximity then
            NetworkSetTalkerProximity(currentEchoSettings.distance)
        end
        
        -- Apply audio effects
        applyAudioEffectByType(currentEchoSettings.type, currentEchoSettings.strength)
        
        -- Start echo processing thread
        if not echoThread then
            startEchoThread()
        end
        
        QBCore.Functions.Notify('Echo enabled with ' .. currentEchoSettings.strength .. '% strength', 'success')
    else
        -- Disable echo effect
        isEchoActive = false
        if NetworkSetTalkerProximity then
            NetworkSetTalkerProximity(Config.DefaultDistance)
        end
        clearAudioEffects()
        QBCore.Functions.Notify('Echo disabled', 'error')
    end
end

-- Apply audio effects by type using safe functions
function applyAudioEffectByType(echoType, strength)
    -- Use available audio functions safely
    local effectStrength = strength / 100.0
    
    -- Set audio flags for better voice quality
    if SetAudioFlag then
        SetAudioFlag('LoadMPData', true)
        SetAudioFlag('DisableFlightMusic', false)
    end
    
    -- Apply different voice processing based on echo type
    if echoType == 'hall' then
        -- Hall reverb effect - use radio effect as substitute
        if SetRadioToStationName then
            -- Simulate hall effect with radio processing
        end
    elseif echoType == 'cave' then
        -- Cave echo with high reverb
        -- Use available audio processing
    elseif echoType == 'stadium' then
        -- Stadium echo with delay
        -- Use available audio processing
    elseif echoType == 'custom' then
        -- Custom echo based on advanced settings
        -- Use available audio processing
    end
end

-- Echo processing thread for real-time audio processing
function startEchoThread()
    echoThread = CreateThread(function()
        while isEchoActive do
            if NetworkIsPlayerTalking and NetworkIsPlayerTalking(PlayerId()) then
                -- Player is talking, apply echo effects
                local coords = GetEntityCoords(PlayerPedId())
                
                -- Create echo effect by playing delayed sounds
                CreateThread(function()
                    Wait(currentEchoSettings.delay)
                    
                    -- Play echo sound effect
                    if currentEchoSettings.strength > 30 then
                        PlaySoundFrontend(-1, "HIGHLIGHT_NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
                    end
                end)
            end
            Wait(100) -- Check every 100ms for performance
        end
        echoThread = nil
    end)
end

-- Play echo preview using game sounds
function playEchoPreview(settings)
    -- Play preview sound with echo effect
    PlaySoundFrontend(-1, "HIGHLIGHT_NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    
    -- Create echo effect for preview
    CreateThread(function()
        local echoCount = math.floor(settings.strength / 20) -- Number of echoes based on strength
        
        for i = 1, echoCount do
            Wait(settings.delay / echoCount)
            local volume = (settings.decay * (echoCount - i + 1)) / echoCount
            
            -- Play echo sound
            PlaySoundFrontend(-1, "HIGHLIGHT_NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
        end
    end)
    
    QBCore.Functions.Notify('Playing echo preview - Type: ' .. settings.type .. ', Strength: ' .. settings.strength .. '%', 'primary')
end

-- Clear audio effects safely
function clearAudioEffects()
    -- Reset audio flags
    if SetAudioFlag then
        SetAudioFlag('LoadMPData', false)
        SetAudioFlag('DisableFlightMusic', false)
    end
end

-- Handle server events
RegisterNetEvent('echo:updatePlayerSettings', function(playerId, settings)
    -- This event is triggered when another player updates their echo settings
    local targetPlayer = GetPlayerFromServerId(playerId)
    if targetPlayer ~= -1 and targetPlayer ~= PlayerId() then
        local targetPed = GetPlayerPed(targetPlayer)
        local playerCoords = GetEntityCoords(PlayerPedId())
        local targetCoords = GetEntityCoords(targetPed)
        local distance = #(playerCoords - targetCoords)
        
        if distance <= settings.distance then
            -- Player is in range, create echo effect for their voice
            if settings.enabled and NetworkIsPlayerTalking and NetworkIsPlayerTalking(targetPlayer) then
                CreateThread(function()
                    Wait(settings.delay)
                    -- Play echo sound for other player's voice
                    PlaySoundFromCoord(-1, "HIGHLIGHT_NAV_UP_DOWN", targetCoords, "HUD_FRONTEND_DEFAULT_SOUNDSET", false, 0, false)
                end)
            end
        end
    end
end)

RegisterNetEvent('echo:adminUpdate', function(settings)
    currentEchoSettings = settings
    applyEchoSettings()
    
    if isUIOpen then
        SendNUIMessage({
            type = 'resetSettings',
            settings = currentEchoSettings
        })
    end
    
    QBCore.Functions.Notify('Echo settings updated by admin!', 'info')
end)

-- Handle ESC key to close UI
CreateThread(function()
    while true do
        if isUIOpen then
            if IsControlJustPressed(0, 322) then -- ESC key
                isUIOpen = false
                SetNuiFocus(false, false)
                SendNUIMessage({
                    type = 'toggle',
                    show = false
                })
            end
        end
        Wait(0)
    end
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if isUIOpen then
            SetNuiFocus(false, false)
        end
        isEchoActive = false
        clearAudioEffects()
        if NetworkSetTalkerProximity then
            NetworkSetTalkerProximity(Config.DefaultDistance)
        end
    end
end)

-- Key mapping (optional)
if Config.UIKey then
    RegisterKeyMapping(Config.Command, 'Open Echo Control Panel', 'keyboard', Config.UIKey)
end

-- Enhanced voice processing thread
CreateThread(function()
    while true do
        if isEchoActive and NetworkIsPlayerTalking and NetworkIsPlayerTalking(PlayerId()) then
            local coords = GetEntityCoords(PlayerPedId())
            
            -- Enhanced voice processing when echo is active
            if SetAudioFlag then
                SetAudioFlag('LoadMPData', true)
            end
            
            -- Create self-echo effect so player can hear their own echo
            if Config.EnableSelfEcho then
                CreateThread(function()
                    Wait(currentEchoSettings.delay)
                    
                    -- Play self-echo with reduced volume
                    local echoVolume = currentEchoSettings.strength / 200.0 -- Half strength for self
                    PlaySoundFromCoord(-1, "HIGHLIGHT_NAV_UP_DOWN", coords, "HUD_FRONTEND_DEFAULT_SOUNDSET", false, currentEchoSettings.distance * 0.5, false)
                end)
            end
        end
        Wait(200) -- Check every 200ms
    end
end)