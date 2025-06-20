ESX = exports['es_extended']:getSharedObject()

-- Jármű törlése
ESX.RegisterServerCallback('vehicledelete:deleteVehicle', function(source, cb, netId)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    -- Jogosultság ellenőrzése (opcionális)
    -- if xPlayer.getGroup() ~= 'admin' then
    --     cb(false)
    --     return
    -- end
    
    -- A kliens oldalon kell törölni a járművet, triggereljünk egy eseményt
    TriggerClientEvent('vehicledelete:deleteVehicleClient', source, netId, function(success)
        cb(success)
    end)
end)