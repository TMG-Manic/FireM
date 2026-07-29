RegisterCommand("msg", function(source, args, rawCommand)
    if #args < 2 then
        TriggerClientEvent('chat:addMessage', source, { args = { '^1[SYSTEM]', 'Usage: /msg [license] [message]' } })
        return
    end

    local targetLicense = args[1]
    local message = table.concat(args, " ", 2)
    local senderLicense = GetPlayerIdentifierByType(source, "license")
    local senderName = GetPlayerName(source)

    PerformHttpRequest(Config.GatewayURL .. "/api/social/msg", function(err, text, headers)
        local data = json.decode(text)
        if data.success then
            TriggerClientEvent('chat:addMessage', source, { args = { '^d[To: '..targetLicense..']', message } })
        else
            TriggerClientEvent('chat:addMessage', source, { args = { '^1[SYSTEM]', data.reason } })
        end
    end, 'POST', json.encode({
        senderLicense = senderLicense,
        senderName = senderName,
        targetLicense = targetLicense,
        message = message
    }), { ['Content-Type'] = 'application/json' })
end, false)





RegisterCommand("party", function(source, args, rawCommand)
    local license = GetPlayerIdentifierByType(source, "license")
    local action = args[1]

    if action == "create" then
        PerformHttpRequest(Config.GatewayURL .. "/api/social/party", function(err, text, headers)
            TriggerClientEvent('chat:addMessage', source, { args = { '^5[PARTY]', 'Party created.' } })
        end, 'POST', json.encode({ action = "create", license = license }), { ['Content-Type'] = 'application/json' })

    elseif action == "invite" and args[2] then
        local targetLicense = args[2]
        PerformHttpRequest(Config.GatewayURL .. "/api/social/party", function(err, text, headers)
            TriggerClientEvent('chat:addMessage', source, { args = { '^5[PARTY]', 'Invite sent to ' .. targetLicense } })
        end, 'POST', json.encode({ action = "invite", license = license, targetLicense = targetLicense }), { ['Content-Type'] = 'application/json' })

    elseif action == "accept" then
        PerformHttpRequest(Config.GatewayURL .. "/api/social/party", function(err, text, headers)
            local data = json.decode(text)
            if data.success then
                TriggerClientEvent('chat:addMessage', source, { args = { '^5[PARTY]', 'Joined party! Routing to leader...' } })
                
                ExecuteCommand("server " .. tostring(data.bucket))
            else
                TriggerClientEvent('chat:addMessage', source, { args = { '^1[PARTY]', data.reason } })
            end
        end, 'POST', json.encode({ action = "accept", license = license }), { ['Content-Type'] = 'application/json' })

    elseif action == "warp" then
        local currentBucket = GetPlayerRoutingBucket(source)
        PerformHttpRequest(Config.GatewayURL .. "/api/social/party", function(err, text, headers)
            local data = json.decode(text)
            if data.success then
                TriggerClientEvent('chat:addMessage', source, { args = { '^5[PARTY]', 'Warping ' .. data.count .. ' members to your instance.' } })
            end
        end, 'POST', json.encode({ action = "warp", license = license, bucket = currentBucket }), { ['Content-Type'] = 'application/json' })
    else
        TriggerClientEvent('chat:addMessage', source, { args = { '^1[PARTY]', 'Usage: /party [create|invite|accept|warp]' } })
    end
end, false)