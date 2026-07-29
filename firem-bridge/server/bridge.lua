


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