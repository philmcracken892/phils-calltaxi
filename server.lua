
local RSGCore = exports['rsg-core']:GetCoreObject()

local TaxiService = {
    basePrice = 5,        -- Base fare
    pricePerMile = 2,     -- Price per mile traveled
    maxFare = 50,         -- Maximum possible fare
    minFare = 5          -- Minimum fare
}

RSGCore.Functions.CreateUseableItem("transport_ticket", function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return end
    
    TriggerClientEvent('taxi:OpenTaxiMenu', source)
    Player.Functions.RemoveItem("transport_ticket", 1)
    TriggerClientEvent('inventory:client:ItemBox', source, RSGCore.Shared.Items['transport_ticket'], "remove")
end)

RegisterServerEvent('taxi:removeTicket')
AddEventHandler('taxi:removeTicket', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if Player then
        Player.Functions.RemoveItem('transport_ticket', 1)
        TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items['transport_ticket'], "remove")
    end
end)


local function CalculateDistance(coord1, coord2)
    return #(coord1 - coord2)
end


local function CalculateFare(startCoord, endCoord, vehiclePriceMultiplier)
    local distanceMeters = CalculateDistance(startCoord, endCoord)
    local distanceMiles = distanceMeters / 1609.34  -- Convert meters to miles
    local baseFare = TaxiService.basePrice + (distanceMiles * TaxiService.pricePerMile)
    
   
    local multiplier = vehiclePriceMultiplier or 1.0
    local calculatedFare = baseFare * multiplier
    
    
    calculatedFare = math.max(TaxiService.minFare, math.min(calculatedFare, TaxiService.maxFare))
    
    return math.floor(calculatedFare)
end


RegisterServerEvent('taxi:requestRide')
AddEventHandler('taxi:requestRide', function(destination, selectedVehicle)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    
    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    
    
    local multiplier = selectedVehicle and selectedVehicle.price_multiplier or 1.0
    local fare = CalculateFare(playerCoords, destination.coords, multiplier)
    
    
    if Player.Functions.GetMoney('cash') >= fare then
        
        Player.Functions.RemoveMoney('cash', fare)
        
        
        TriggerClientEvent('taxi:receiveFareDetails', src, {
            fare = fare,
            destination = destination,
            vehicle = selectedVehicle
        })
    else
        
        TriggerClientEvent('RSGCore:Notify', src, 'Not enough money for taxi', 'error')
    end
end)