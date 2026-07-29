RegisterCommand("glist", function(source, args, rawCommand)
    PerformHttpRequest(Config.GatewayURL .. "/api/glist", function(errorCode, resultData, headers)
        if errorCode == 200 then
            local data = json.decode(resultData)
            
            TriggerClientEvent('chat:addMessage', source, { args = { '^5[NETWORK]', 'Total Players Online: ^3' .. data.total } })
            
            for bucketId, count in pairs(data.servers) do
                TriggerClientEvent('chat:addMessage', source, { args = { '^5[NETWORK]', ('Virtual Server [%s]: ^2%s Players'):format(bucketId, count) } })
            end
        else
            TriggerClientEvent('chat:addMessage', source, { args = { '^1[ERROR]', 'Unable to reach Master Gateway.' } })
        end
    end, 'GET', '', { ['Content-Type'] = 'application/json' })
end, false)


RegisterCommand("find", function(source, args, rawCommand)
    if #args < 1 then
        TriggerClientEvent('chat:addMessage', source, { args = { '^1[SYSTEM]', 'Usage: /find [license]' } })
        return
    end

    local targetLicense = args[1]

    PerformHttpRequest(Config.GatewayURL .. "/api/find", function(errorCode, resultData, headers)
        if errorCode == 200 then
            local data = json.decode(resultData)
            
            if data.online then
                TriggerClientEvent('chat:addMessage', source, { args = { '^2[FOUND]', 'Player is currently in Virtual Server ^3' .. data.bucket } })
            else
                TriggerClientEvent('chat:addMessage', source, { args = { '^1[SYSTEM]', 'Player is currently offline.' } })
            end
        end
    end, 'POST', json.encode({ targetLicense = targetLicense }), { ['Content-Type'] = 'application/json' })
end, true) 