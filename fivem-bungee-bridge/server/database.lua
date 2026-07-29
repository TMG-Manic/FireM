local function SaveVirtualProfile(source, bucketId)
    local license = GetPlayerIdentifierByType(source, "license")
    if not license then return false end

    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    
    
    local positionData = json.encode({ x = coords.x, y = coords.y, z = coords.z })
    local inventoryData = json.encode({}) 

    local query = [[
        INSERT INTO bungee_virtual_profiles (license, bucket_id, position, inventory) 
        VALUES (?, ?, ?, ?) 
        ON DUPLICATE KEY UPDATE position = VALUES(position), inventory = VALUES(inventory)
    ]]

    MySQL.Async.execute(query, { license, bucketId, positionData, inventoryData })
    return true
end


local function LoadVirtualProfile(source, bucketId)
    local license = GetPlayerIdentifierByType(source, "license")
    if not license then return false end

    local query = "SELECT position, inventory FROM bungee_virtual_profiles WHERE license = ? AND bucket_id = ?"
    
    MySQL.Async.fetchAll(query, { license, bucketId }, function(results)
        if results and #results > 0 then
            local data = results[1]
            local pos = json.decode(data.position)
            
            
            if pos then
                SetEntityCoords(GetPlayerPed(source), pos.x, pos.y, pos.z, false, false, false, false)
            end

            
            
            
            TriggerClientEvent('chat:addMessage', source, { args = { '^2SYNC', 'Virtual Profile loaded successfully.' } })
        else
            
            TriggerClientEvent('chat:addMessage', source, { args = { '^3SYNC', 'New Virtual Profile created for this instance.' } })
        end
    end)
end






RegisterNetEvent('bungee:internal:prepareTransfer', function(source, targetBucket)
    local currentBucket = GetPlayerRoutingBucket(source)
    
    
    SaveVirtualProfile(source, currentBucket)
    
    
    TriggerClientEvent('bungee:client:fadeScreen', source, true)
    Wait(1000) 
    
    
    LoadVirtualProfile(source, targetBucket)
end)


AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for _, playerId in ipairs(GetPlayers()) do
            local bucket = GetPlayerRoutingBucket(tonumber(playerId))
            SaveVirtualProfile(tonumber(playerId), bucket)
        end
        print("[Gateway Bridge] Successfully saved all Virtual Profiles.")
    end
end)