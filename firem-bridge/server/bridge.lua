


AddEventHandler('chatMessage', function(source, name, message)
    
    CancelEvent()

    local license = GetPlayerIdentifierByType(source, "license")
    local currentBucket = GetPlayerRoutingBucket(source)

    
    PerformHttpRequest(Config.GatewayURL .. "/internal/relay_chat", function(err, text, headers) 
        
        
    end, 'POST', json.encode({
        author = name,
        text = message,
        bucket = currentBucket,
        license = license
    }), { ['Content-Type'] = 'application/json' })
    
    
    TriggerClientEvent('chat:addMessage', -1, {
        args = { ("^5[VS-%s] ^7%s"):format(currentBucket, name), message }
    })
end)




RegisterCommand("server", function(source, args, rawCommand)
    if #args < 1 then
        TriggerClientEvent('chat:addMessage', source, { args = { '^1SYSTEM', 'Usage: /server [id]' } })
        return
    end

    local targetBucket = tonumber(args[1])
    local license = GetPlayerIdentifierByType(source, "license")

    
    PerformHttpRequest(Config.GatewayURL .. "/internal/assign_bucket", function(errorCode, resultData, headers)
        if errorCode == 200 then
            local data = json.decode(resultData)
            
            if data.success then
                TriggerEvent('bungee:internal:prepareTransfer', source, targetBucket)                
                SetPlayerRoutingBucket(source, targetBucket)
                TriggerClientEvent('chat:addMessage', source, { args = { '^2GATEWAY', 'Seamlessly routed to Virtual Server ' .. targetBucket } })
                SetTimeout(1500, function()
                SetPlayerRoutingBucket(source, targetBucket)
                TriggerClientEvent('bungee:client:fadeScreen', source, false)
                TriggerClientEvent('chat:addMessage', source, { args = { '^2GATEWAY', 'Seamlessly routed to Virtual Server ' .. targetBucket } })
            end)
            else
                TriggerClientEvent('chat:addMessage', source, { args = { '^1GATEWAY', 'Transfer Failed: ' .. (data.reason or 'Capacity reached.') } })
            end
        else
            TriggerClientEvent('chat:addMessage', source, { args = { '^1GATEWAY', 'Master Dispatcher is currently unreachable.' } })
        end
    end, 'POST', json.encode({
        license = license,
        targetBucket = targetBucket
    }), { ['Content-Type'] = 'application/json' })
end, false)




AddEventHandler('playerDropped', function(reason)
    local source = source
    local license = GetPlayerIdentifierByType(source, "license")

    if license then
        
        PerformHttpRequest(Config.GatewayURL .. "/internal/player_dropped", function(err, text, headers) end, 'POST', json.encode({
            license = license
        }), { ['Content-Type'] = 'application/json' })
    end
end)

Citizen.CreateThread(function()
    while true do
        Wait(5000) -- Poll every 5 seconds
        local playerPositions = {}

        for _, playerId in ipairs(GetPlayers()) do
            local src = tonumber(playerId)
            local ped = GetPlayerPed(src)
            local coords = GetEntityCoords(ped)
            local license = GetPlayerIdentifierByType(src, "license")

            if license then
                table.insert(playerPositions, {
                    license = license,
                    x = coords.x,
                    y = coords.y,
                    z = coords.z,
                    bucket = GetPlayerRoutingBucket(src)
                })
            end
        end

        -- Push telemetry payload to FireM
        PerformHttpRequest(Config.GatewayURL .. "/internal/telemetry", function(err, text, headers) end, 
        'POST', json.encode({ players = playerPositions }), { ['Content-Type'] = 'application/json' })
    end
end)