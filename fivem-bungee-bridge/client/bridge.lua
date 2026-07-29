local isMenuOpen = false


local portals = {
    { name = "Roleplay Server", bucket = 1, coords = vector3(239.5, -895.5, 30.4) }, 
    { name = "Minigames", bucket = 2, coords = vector3(250.5, -895.5, 30.4) }
}




RegisterNetEvent('bungee:client:fadeScreen', function(fadeOut)
    if fadeOut then
        DoScreenFadeOut(1000)
    else
        DoScreenFadeIn(1000)
    end
end)




local function ToggleServerHub(state)
    isMenuOpen = state
    SetNuiFocus(state, state)
    SendNUIMessage({
        action = state and "openHub" or "closeHub"
    })
end


RegisterCommand("hub", function()
    ToggleServerHub(true)
end, false)

RegisterNUICallback("close", function(data, cb)
    ToggleServerHub(false)
    cb("ok")
end)

RegisterNUICallback("switchServer", function(data, cb)
    ToggleServerHub(false)
    
    ExecuteCommand("server " .. tostring(data.bucket))
    cb("ok")
end)




Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local pCoords = GetEntityCoords(ped)

        for i = 1, #portals do
            local dist = #(pCoords - portals[i].coords)

            if dist < 20.0 then
                sleep = 0
                
                DrawMarker(1, portals[i].coords.x, portals[i].coords.y, portals[i].coords.z - 1.0, 
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
                    2.0, 2.0, 1.5, 
                    0, 150, 255, 100, 
                    false, false, 2, false, nil, nil, false)

                if dist < 2.0 then
                    
                    BeginTextCommandDisplayHelp("STRING")
                    AddTextComponentSubstringPlayerName("Press ~INPUT_CONTEXT~ to enter " .. portals[i].name)
                    EndTextCommandDisplayHelp(0, false, true, -1)

                    if IsControlJustReleased(0, 38) then 
                        ExecuteCommand("server " .. tostring(portals[i].bucket))
                    end
                end
            end
        end
        Wait(sleep)
    end
end)