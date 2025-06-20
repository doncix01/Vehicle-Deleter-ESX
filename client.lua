local isInDeleteZone = false
local currentZone = nil
local markerVisible = true
local blips = {}

-- Törlő zónák definiálása (koordináták, sugár, blip szín, név)
local deleteZones = {
    {
        coords = vector3(2136.2241, 4779.8374, 40.9703),
        radius = 3.0,
        blipColor = 1,  -- Piros (RED)
        blipText = "Járműtörlő (Sandy Shores)" --Vehicle deleter(Sandy Shores)
    },

    ----Extendable locations
    --{
       --coords = vector3(-454.68, -2443.57, 6.0),
        --radius = 3.0,
        --blipColor = 3,  -- Kék
        --blipText = "Járműtörlő (Kikötő)"
    --}
}

-- Blipek létrehozása
Citizen.CreateThread(function()
    for _, zone in ipairs(deleteZones) do
        -- Terület blip (kör alakú)
        local blip = AddBlipForRadius(zone.coords.x, zone.coords.y, zone.coords.z, zone.radius)
        SetBlipColour(blip, zone.blipColor)
        SetBlipAlpha(blip, 100)
        
        -- Jelző blip (ikon)
        local markerBlip = AddBlipForCoord(zone.coords.x, zone.coords.y, zone.coords.z)
        SetBlipSprite(markerBlip, 380) -- Garázs ikon
        SetBlipColour(markerBlip, zone.blipColor)
        SetBlipAsShortRange(markerBlip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(zone.blipText)
        EndTextCommandSetBlipName(markerBlip)
        
        table.insert(blips, {area = blip, marker = markerBlip})
    end
end)

-- Marker és checkpoint rajzolása
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerCoords = GetEntityCoords(PlayerPedId())
        local foundZone = false
        
        for _, zone in ipairs(deleteZones) do
            local distance = #(playerCoords - zone.coords)
            
            -- Marker megjelenítése
            if markerVisible and distance < 20.0 then
                DrawMarker(1, zone.coords.x, zone.coords.y, zone.coords.z - 1.0, 
                           0, 0, 0, 0, 0, 0, 
                           zone.radius * 2.0, zone.radius * 2.0, 1.0, 
                           255, 0, 0, 100, false, true, 2, false, nil, nil, false)
            end
            
            -- Zóna ellenőrzése
            if distance < zone.radius then
                if not isInDeleteZone or currentZone ~= zone then
                    isInDeleteZone = true
                    currentZone = zone
                    ESX.ShowNotification('Nyomd meg az E gombot a jármű törléséhez')
                end
                foundZone = true
                break
            end
        end
        
        if not foundZone and isInDeleteZone then
            isInDeleteZone = false
            currentZone = nil
        end
    end
end)

-- Jármű törlése az E gomb lenyomására
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isInDeleteZone and IsControlJustReleased(0, 38) then -- 38 = E gomb
            DeleteVehicleInZone()
        end
    end
end)

RegisterNetEvent('vehicledelete:deleteVehicleClient')
AddEventHandler('vehicledelete:deleteVehicleClient', function(netId, cb)
    local vehicle = NetToVeh(netId)
    if DoesEntityExist(vehicle) then
        DeleteEntity(vehicle)
        cb(true)
    else
        cb(false)
    end
end)

function DeleteVehicleInZone()
    local playerPed = PlayerPedId()
    
    if IsPedInAnyVehicle(playerPed, false) then
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        
        if DoesEntityExist(vehicle) then
            ESX.TriggerServerCallback('vehicledelete:deleteVehicle', function(success)
                if success then
                    ESX.ShowNotification('Jármű sikeresen törölve!')
                else
                    ESX.ShowNotification('Hiba történt a törlés során!')
                end
            end, VehToNet(vehicle))
        end
    else
        ESX.ShowNotification('Nem ülsz járműben!')
    end
end

-- Debug parancs új zóna hozzáadásához
RegisterCommand('adddeletezone', function()
    local coords = GetEntityCoords(PlayerPedId())
    local newZone = {
        coords = vector3(coords.x, coords.y, coords.z),
        radius = 3.0,
        blipColor = 1,
        blipText = "Járműtörlő (Egyedi)"
    }
    
    table.insert(deleteZones, newZone)
    
    -- Blip létrehozása az új zónához
    local blip = AddBlipForRadius(newZone.coords.x, newZone.coords.y, newZone.coords.z, newZone.radius)
    SetBlipColour(blip, newZone.blipColor)
    SetBlipAlpha(blip, 100)
    
    local markerBlip = AddBlipForCoord(newZone.coords.x, newZone.coords.y, newZone.coords.z)
    SetBlipSprite(markerBlip, 380)
    SetBlipColour(markerBlip, newZone.blipColor)
    SetBlipAsShortRange(markerBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(newZone.blipText)
    EndTextCommandSetBlipName(markerBlip)
    
    table.insert(blips, {area = blip, marker = markerBlip})
    
    ESX.ShowNotification('Új törlő zóna hozzáadva a jelenlegi pozíciódhoz!')
end, false)