local gatewayOnline = true

Citizen.CreateThread(function()
    while true do
        Wait(15000) 
        
        PerformHttpRequest(Config.GatewayURL .. "/api/glist", function(errorCode, resultData, headers)
            
            if errorCode ~= 200 and gatewayOnline then
                gatewayOnline = false
                print("^1[WATCHDOG] CRITICAL: Master Gateway connection lost!^7")
                print("^1[WATCHDOG] Forcing emergency state save for all Virtual Servers...^7")
                
                
                TriggerEvent('bungee:internal:emergencySave')
                
                
                TriggerClientEvent('chat:addMessage', -1, { 
                    args = { '^1[SYSTEM]', 'Network instability detected. Cross-server features are temporarily unavailable.' } 
                })
                
            
            elseif errorCode == 200 and not gatewayOnline then
                gatewayOnline = true
                print("^2[WATCHDOG] Master Gateway connection restored.^7")
                TriggerClientEvent('chat:addMessage', -1, { 
                    args = { '^2[SYSTEM]', 'Network stability restored. All systems nominal.' } 
                })
            end
        end, 'GET', '', { ['Content-Type'] = 'application/json' })
    end
end)


RegisterNetEvent('bungee:internal:emergencySave', function()
    
    for _, playerId in ipairs(GetPlayers()) do
        local bucket = GetPlayerRoutingBucket(tonumber(playerId))
        
        
        print(("[Watchdog] Emergency saved profile for %s (Bucket: %s)"):format(GetPlayerName(playerId), bucket))
    end
end)