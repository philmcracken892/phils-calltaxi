local RSGCore = exports['rsg-core']:GetCoreObject()
local blips = {}

local Config = {
    destinations = {
        {label = 'Valentine', coords = vector3(-291.98, 792.83, 118.59)},
        {label = 'Rhodes', coords = vector3(1322.94, -1305.65, 76.39)},
        {label = 'Saint Denis', coords = vector3(2633.57, -1282.14, 52.18)},
        {label = 'Blackwater', coords = vector3(-800.19, -1337.22, 43.54)},
        {label = 'armadillo', coords = vector3(-3704.67, -2612.14, -13.73)},
        {label = 'tumbleweed', coords = vector3(-5509.87, -2939.77, -2.54)},
        {label = 'strawberry', coords = vector3(-1792.92, -370.35, 160.41)},
        {label = 'Vanhorn', coords = vector3(2960.2, 526.74, 44.47)},
        {label = 'annesburg', coords = vector3(2920.71, 1286.93, 44.38)}
    },
	blips = {
        {label = 'Rhodes', coords = vector3(1247.74, -1291.24, 75.93)},
        {label = 'Saint Denis', coords = vector3(2666.43, -1467.04, 46.31)},
        {label = 'Blackwater', coords = vector3(-744.09, -1247.21, 43.43)},
        {label = 'strawberry', coords = vector3(-1736.9, -413.71, 154.99)},
        {label = 'annesburg', coords = vector3(2927.01, 1296.79, 44.58)}
    },
    vehicles = {
        {
            label = 'Standard Coach',
            model = 'COACH3',
            price_multiplier = 1.0,
            description = 'A comfortable standard coach'
        },
        {
            label = 'Luxury Coach',
            model = 'stagecoach005x',
            price_multiplier = 1.5,
            description = 'A premium coach with extra comfort'
        },
        {
            label = 'Budget Coach',
            model = 'COACH5',
            price_multiplier = 0.8,
            description = 'An affordable option for travel'
        }
    },
    driverModel = 'A_M_M_SDDockWorkers_02',
    spawnDistance = 25.0,
    drivingSpeed = 7.0,
    arrivalDistance = 10.0,
    blipScale = 0.8,
	waitTimeForReturn = 180, -- seconds to wait for player to return
	lastNotificationTime = 0,
	notificationCooldown = 5000 
}

local State = {
    activeVehicle = nil,
    activeDriver = nil,
    activeBlip = nil,
    isJourneyActive = false,
    journeyStarted = false,
    selectedVehicle = nil,
	originalPassenger = nil  
}

local function CanSendNotification()
    local currentTime = GetGameTimer()
    if State.lastNotificationTime == nil then
        State.lastNotificationTime = 0  -- Initialize if nil
    end
    if currentTime - State.lastNotificationTime >= Config.notificationCooldown then
        State.lastNotificationTime = currentTime
        return true
    end
    return false
end

local function LoadModel(model)
    local hash = GetHashKey(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(10)
    end
    return hash
end

CreateThread(function()
   
    local function IsResourceStarted(resourceName)
        return GetResourceState(resourceName) == 'started'
    end
    
    
    Wait(1000)
    
   
    if IsResourceStarted('rsg-target') then
        
        exports['rsg-target']:AddTargetModel('s_fasttravelmarker01x', {
            options = {
                {
                    type = "client",
                    event = 'taxi:OpenTaxiMenu',
                    icon = "fas fa-horse",
                    label = "Call Wagon",
                }
            },
            distance = 3.0
        })
    elseif IsResourceStarted('ox_target') then
        
        exports.ox_target:addModel('s_fasttravelmarker01x', {
            {
                name = 'call_taxi',
                icon = 'fas fa-horse',
                label = 'Call Wagon',
                onSelect = function()
                    TriggerEvent('taxi:OpenTaxiMenu')
                end
            }
        })
    else
        
    end
end)



local function ClearTaxiService()
    if not State.journeyStarted then
        return
    end

    State.isJourneyActive = false
    State.journeyStarted = false

    if State.activeBlip then 
        RemoveBlip(State.activeBlip)
        State.activeBlip = nil
    end

    if State.activeDriver then
        if DoesEntityExist(State.activeDriver) then
            ClearPedTasks(State.activeDriver)
            SetEntityAsMissionEntity(State.activeDriver, true, true)
            DeletePed(State.activeDriver)
        end
        State.activeDriver = nil
    end

    if State.activeVehicle then
        if DoesEntityExist(State.activeVehicle) then
            SetEntityAsMissionEntity(State.activeVehicle, true, true)
            DeleteVehicle(State.activeVehicle)
        end
        State.activeVehicle = nil
    end
end

local function ConfigureVehicleAccess(vehicle)
    
    SetVehicleDoorsLocked(vehicle, 0)
    SetVehicleDoorsLockedForAllPlayers(vehicle, false)
    
    
    for i = 0, 3 do
        Citizen.InvokeNative(0x7C65DAC73C35C862, vehicle, i, true)
    end
    
    
    Citizen.InvokeNative(0x7C65DAC73C35C862, vehicle, -1, false)
end

local function CreateTaxiBlip(vehicle)
    local blip = Citizen.InvokeNative(0x23f74c2fda6e7c61, 0x318C617C, vehicle)
    Citizen.InvokeNative(0x9CB1A1623062F402, blip, "Coach Service")
    SetBlipScale(blip, Config.blipScale)
    
   
    SetBlipSprite(blip, -1989306548)  
    
    return blip
end

local function GetPlayerIntoTaxi(vehicle)
    local playerPed = PlayerPedId()
    
    
    if IsPedInVehicle(playerPed, vehicle, false) then
        local seat = GetPedInVehicleSeat(vehicle, -1) 
        if seat == playerPed then
            
            TaskLeaveVehicle(playerPed, vehicle, 0)
            Wait(2000)
            lib.notify({
                title = 'Taxi',
                description = 'Please enter through the passenger door',
                type = 'error'
            })
        end
    end
    
    
    ClearPedTasks(playerPed)
    
    
    SetVehicleDoorCanBreak(vehicle, 0, false)
    Citizen.InvokeNative(0x7C65DAC73C35C862, vehicle, 0, false) 
    
    
    local seats = {2, 3} 
    
    for _, seat in ipairs(seats) do
        
        Citizen.InvokeNative(0x7C65DAC73C35C862, vehicle, seat, true)
        
       
        TaskEnterVehicle(playerPed, vehicle, 20000, seat, 1.0, 1, 0)
        
        
        local timeout = 0
        while timeout < 100 do
            Wait(100)
            if IsPedInVehicle(playerPed, vehicle, false) then
                local currentSeat = GetPedInVehicleSeat(vehicle, seat)
                if currentSeat == playerPed then
                    return true
                end
            end
            timeout = timeout + 1
        end
        
        
        ClearPedTasks(playerPed)
        Wait(500)
    end
    
   
end



local function ConfigureVehicleAccess(vehicle)
    
    SetVehicleDoorsLocked(vehicle, 0)
    SetVehicleDoorsLockedForAllPlayers(vehicle, false)
    
    
    for i = 0, 3 do
        Citizen.InvokeNative(0x7C65DAC73C35C862, vehicle, i, true)
    end
    
    
    Citizen.InvokeNative(0x165BE2001E5E4B75, vehicle, true)
end

local function SetupDriverForVehicle(driver, vehicle)
    ClearPedTasks(driver)
    
    SetPedIntoVehicle(driver, vehicle, -1)
    Wait(500)
    
    if not IsPedInVehicle(driver, vehicle, false) then
        TaskEnterVehicle(driver, vehicle, -1, -1, 2.0, 1, 0)
        
        local timeout = 0
        while not IsPedInVehicle(driver, vehicle, false) and timeout < 50 do
            Wait(100)
            timeout = timeout + 1
        end
        
        if not IsPedInVehicle(driver, vehicle, false) then
            SetPedIntoVehicle(driver, vehicle, -1)
            Wait(500)
        end
    end
    
    return IsPedInVehicle(driver, vehicle, false)
end

local function HandleJourneyEnd()
    local playerPed = PlayerPedId()
    
    if IsPedInVehicle(playerPed, State.activeVehicle, false) then
        TaskLeaveVehicle(playerPed, State.activeVehicle, 0)
        Wait(3000) 
    end

    if State.currentFareDetails then
        TriggerEvent('rNotify:NotifyLeft', "Destination Reached", "You have arrived at " .. State.currentFareDetails.destination.label, "generic_textures", "tick", 4000)
        State.currentFareDetails = nil
    end

    local vehicleHeading = GetEntityHeading(State.activeVehicle)
    local vehicleCoords = GetEntityCoords(State.activeVehicle)
    local departureDistance = 200.0 
    
    local departureX = vehicleCoords.x + (departureDistance * math.sin(-math.rad(vehicleHeading)))
    local departureY = vehicleCoords.y + (departureDistance * math.cos(-math.rad(vehicleHeading)))
    
    local ground, groundZ = GetGroundZFor_3dCoord(departureX, departureY, vehicleCoords.z + 10.0, false)
    local departureZ = ground and groundZ or vehicleCoords.z

    if DoesEntityExist(State.activeDriver) and DoesEntityExist(State.activeVehicle) then
        if State.activeBlip then 
            RemoveBlip(State.activeBlip)
            State.activeBlip = nil
        end

        SetBlockingOfNonTemporaryEvents(State.activeDriver, true)
        TaskVehicleDriveToCoord(
            State.activeDriver,
            State.activeVehicle,
            departureX,
            departureY,
            departureZ,
            8.0,
            1.0,
            GetHashKey(State.selectedVehicle.model),
            786603,
            1.0,
            true
        )

        CreateThread(function()
            local startTime = GetGameTimer()
            local timeout = 20000 
            local minDriveTime = 8000 
            local hasReachedMinTime = false
            
            while true do
                Wait(1000)
                local currentTime = GetGameTimer()
                local elapsedTime = currentTime - startTime
                
                if elapsedTime >= minDriveTime then
                    hasReachedMinTime = true
                end
                
                if not DoesEntityExist(State.activeVehicle) or not DoesEntityExist(State.activeDriver) then
                   
                    break
                end
                
                local currentCoords = GetEntityCoords(State.activeVehicle)
                local distanceTraveled = #(vehicleCoords - currentCoords)
                
                if hasReachedMinTime and (distanceTraveled > 50.0 or elapsedTime > timeout) then
                   
                    if DoesEntityExist(State.activeDriver) then
                       
                        SetEntityAsMissionEntity(State.activeDriver, true, true)
                        DeletePed(State.activeDriver)
                    end
                    
                    if DoesEntityExist(State.activeVehicle) then
                       
                        SetEntityAsMissionEntity(State.activeVehicle, true, true)
                        DeleteVehicle(State.activeVehicle)
                       
                        Wait(500)
                        if DoesEntityExist(State.activeVehicle) then
                            SetVehicleAsNoLongerNeeded(State.activeVehicle)
                            Wait(500)
                            DeleteVehicle(State.activeVehicle)
                        end
                    end
                    
                   
                    break
                end
            end
            
            State.isJourneyActive = false
            State.journeyStarted = false
            State.activeDriver = nil
            State.activeVehicle = nil
            
        end)
    else
        ClearTaxiService()
    end
end

local function GetRoadSpawnPoint(playerCoords, heading, distance)
    
    local bestSpawnPoint = nil
    local bestDistance = 9999.0
    local testPoints = {}
    
    
    for i = -30, 30, 10 do 
        local testHeading = heading + i
        local testX = playerCoords.x + (distance * math.sin(-math.rad(testHeading)))
        local testY = playerCoords.y + (distance * math.cos(-math.rad(testHeading)))
        local testZ = playerCoords.z
        
        table.insert(testPoints, vector3(testX, testY, testZ))
    end
    
    
    for _, testPoint in ipairs(testPoints) do
        
        local roadPosition = vector3(0, 0, 0)
        local roadHeading = 0
        
        
        local success = GetClosestRoad(
            testPoint.x, testPoint.y, testPoint.z,
            1.0, 1,
            roadPosition, roadPosition, 
            0, 0, roadHeading, true
        )
        
        if success then
            
            local clearRadius = 4.0 
            local isClear = true
            
           
            local objects = GetGamePool('CObject')
            for _, object in ipairs(objects) do
                if DoesEntityExist(object) then
                    local objectCoords = GetEntityCoords(object)
                    local dist = #(roadPosition - objectCoords)
                    if dist < clearRadius then
                        isClear = false
                        break
                    end
                end
            end
            
            
            local vehicles = GetGamePool('CVehicle')
            for _, vehicle in ipairs(vehicles) do
                if DoesEntityExist(vehicle) then
                    local vehicleCoords = GetEntityCoords(vehicle)
                    local dist = #(roadPosition - vehicleCoords)
                    if dist < clearRadius then
                        isClear = false
                        break
                    end
                end
            end
            
            
            local peds = GetGamePool('CPed')
            for _, ped in ipairs(peds) do
                if DoesEntityExist(ped) then
                    local pedCoords = GetEntityCoords(ped)
                    local dist = #(roadPosition - pedCoords)
                    if dist < clearRadius then
                        isClear = false
                        break
                    end
                end
            end
            
            
            if isClear then
                local distToPlayer = #(roadPosition - playerCoords)
                if distToPlayer < bestDistance then
                    bestDistance = distToPlayer
                    bestSpawnPoint = {
                        coords = roadPosition,
                        heading = roadHeading
                    }
                end
            end
        end
    end
    
    return bestSpawnPoint
end

local function ValidateSpawnPoint(coords, heading)
    
    local minDistanceFromObjects = 3.0
    local heightCheckPoints = {
        vector3(coords.x + 1.0, coords.y + 1.0, coords.z),
        vector3(coords.x - 1.0, coords.y - 1.0, coords.z),
        vector3(coords.x + 1.0, coords.y - 1.0, coords.z),
        vector3(coords.x - 1.0, coords.y + 1.0, coords.z)
    }
    
   
    local groundLevels = {}
    for _, point in ipairs(heightCheckPoints) do
        local ground, z = GetGroundZFor_3dCoord(point.x, point.y, point.z + 1.0, true)
        if ground then
            table.insert(groundLevels, z)
        end
    end
    
    
    if #groundLevels >= 4 then
        local maxDiff = 0
        local baseLevel = groundLevels[1]
        for i = 2, #groundLevels do
            local diff = math.abs(groundLevels[i] - baseLevel)
            if diff > maxDiff then
                maxDiff = diff
            end
        end
        
        
        if maxDiff > 0.5 then
            return false
        end
    end
    
    
    local rayFlags = 1 + 16 + 256
    local start = vector3(coords.x, coords.y, coords.z + 2.0)
    local offset = vector3(0, 0, -3.0)
    local ray = StartShapeTestRay(
        start.x, start.y, start.z,
        start.x + offset.x, start.y + offset.y, start.z + offset.z,
        rayFlags, 0, 0
    )
    local retval, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(ray)
    
    return hit == 0 or (entityHit == 0 and #(start - endCoords) > 2.0)
end



local function SpawnTaxi(destination)
    local journeyStartTime = GetGameTimer()
    if not State.selectedVehicle then
        lib.notify({
            title = 'Taxi',
            description = 'No vehicle selected',
            type = 'error'
        })
        return false
    end
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    -- Get road position and heading
    local success, nodePosition, nodeHeading = GetClosestVehicleNodeWithHeading(playerCoords.x, playerCoords.y, playerCoords.z, 0, 50.0, 0.0)
    local heading
    if not success then
        -- Fallback to GetRoadSpawnPoint if needed
        local spawnPoint = GetRoadSpawnPoint(playerCoords, GetEntityHeading(playerPed), Config.spawnDistance)
        if spawnPoint then
            nodePosition = spawnPoint.coords
            heading = spawnPoint.heading
        else
            lib.notify({
                title = 'Taxi',
                description = 'Could not find valid road position',
                type = 'error',
                duration = 7000
            })
            return false
        end
    else
        heading = nodeHeading
    end
    
    if not success or not nodePosition then
        local spawnDistance = 20.0
        local bestNode = nil
        local bestDistance = 999.0
        
        for angle = 0, 315, 45 do
            local testX = playerCoords.x + (spawnDistance * math.sin(math.rad(angle)))
            local testY = playerCoords.y + (spawnDistance * math.cos(math.rad(angle)))
            local testZ = playerCoords.z
            
            local testSuccess, testNode = GetClosestVehicleNode(testX, testY, testZ, 0, 15.0, 0.0)
            if testSuccess and testNode then
                local distToPlayer = #(testNode - playerCoords)
                
                if distToPlayer > 10.0 and distToPlayer < 40.0 and distToPlayer < bestDistance then
                    bestDistance = distToPlayer
                    bestNode = testNode
                end
            end
        end
        
        if bestNode then
            nodePosition = bestNode
            success = true
        end
    end
    
    if not success or not nodePosition then
        lib.notify({
            title = 'Taxi',
            description = 'Could not find valid road position',
            type = 'error',
            duration = 7000
        })
        return false
    end

    local distance = math.floor(#(nodePosition - playerCoords))
    
    if distance >= 60 then
        lib.notify({
            title = 'Taxi',
            description = 'Please move closer to a road to call a taxi',
            type = 'error',
            duration = 7000
        })
        return false
    end

    State.isJourneyActive = false
    State.journeyStarted = false
    ClearTaxiService()

    local taxiHash = LoadModel(State.selectedVehicle.model)
    local driverHash = LoadModel(Config.driverModel)
    
    if not HasModelLoaded(taxiHash) or not HasModelLoaded(driverHash) then
        lib.notify({
            title = 'Taxi',
            description = 'Failed to load required models',
            type = 'error'
        })
        return false
    end

    State.activeVehicle = CreateVehicle(
        taxiHash,
        nodePosition.x,
        nodePosition.y,
        nodePosition.z,
        heading, -- Use the road-aligned heading
        true,
        false
    )
    
    if not DoesEntityExist(State.activeVehicle) then
        lib.notify({
            title = 'Taxi',
            description = 'Failed to spawn vehicle',
            type = 'error'
        })
        return false
    end

    SetEntityAsMissionEntity(State.activeVehicle, true, true)
    Citizen.InvokeNative(0x7263332501E07F52, State.activeVehicle, true)
    SetVehicleOnGroundProperly(State.activeVehicle)
    Citizen.InvokeNative(0x165BE2001E5E4B75, State.activeVehicle, true)
    
    SetVehicleDoorsLocked(State.activeVehicle, 0)
    SetVehicleDoorsLockedForAllPlayers(State.activeVehicle, false)
    for i = 0, 3 do
        Citizen.InvokeNative(0x7C65DAC73C35C862, State.activeVehicle, i, true)
    end
    ConfigureVehicleAccess(State.activeVehicle)

    State.activeDriver = CreatePed(driverHash, nodePosition.x, nodePosition.y, nodePosition.z, heading, true, true, true)
    if not DoesEntityExist(State.activeDriver) then
        DeleteVehicle(State.activeVehicle)
        lib.notify({
            title = 'Taxi',
            description = 'Failed to spawn driver',
            type = 'error'
        })
        return false
    end

    Citizen.InvokeNative(0x283978A15512B2FE, State.activeDriver, true)
    SetBlockingOfNonTemporaryEvents(State.activeDriver, true)
    SetEntityInvincible(State.activeDriver, true)
    SetEntityAsMissionEntity(State.activeDriver, true, true)
    SetPedFleeAttributes(State.activeDriver, 0, false)
    SetPedCombatAttributes(State.activeDriver, 46, true)
    SetPedKeepTask(State.activeDriver, true)
    Citizen.InvokeNative(0x0A36F5CA51F21C9A, State.activeDriver, true)
    Citizen.InvokeNative(0xB8B6430EAD2D2437, State.activeDriver, GetHashKey("COACH_DRIVER"))

    State.activeBlip = CreateTaxiBlip(State.activeVehicle)

    Wait(1000)

    local driverEnterAttempts = 0
    while not IsPedInVehicle(State.activeDriver, State.activeVehicle, false) and driverEnterAttempts < 3 do
        if not SetupDriverForVehicle(State.activeDriver, State.activeVehicle) then
            Wait(1000)
            driverEnterAttempts = driverEnterAttempts + 1
        else
            break
        end
    end

    if not IsPedInVehicle(State.activeDriver, State.activeVehicle, false) then
        ClearTaxiService()
        lib.notify({
            title = 'Taxi',
            description = 'Driver failed to enter vehicle',
            type = 'error'
        })
        return false
    end

    local playerEnterAttempts = 0
    while not IsPedInVehicle(playerPed, State.activeVehicle, false) and playerEnterAttempts < 3 do
        if not GetPlayerIntoTaxi(State.activeVehicle) then
            Wait(1000)
            playerEnterAttempts = playerEnterAttempts + 1
        else
            break
        end
    end

    if not IsPedInVehicle(playerPed, State.activeVehicle, false) then
        ClearTaxiService()
        lib.notify({
            title = 'Taxi',
            description = 'Failed to enter vehicle. Please try again.',
            type = 'error'
        })
        return false
    end

    State.journeyStarted = true
    State.isJourneyActive = true

    local function DriveToDestination()
        if DoesEntityExist(State.activeDriver) and DoesEntityExist(State.activeVehicle) then
            TaskVehicleDriveToCoord(
                State.activeDriver,
                State.activeVehicle,
                destination.coords.x,
                destination.coords.y,
                destination.coords.z,
                Config.drivingSpeed,
                1.0,
                GetHashKey(State.selectedVehicle.model),
                67633207,
                0.5,
                true
            )
        end
    end

    DriveToDestination()

    CreateThread(function()
        while State.isJourneyActive and State.journeyStarted do
            Wait(1000)

            if not DoesEntityExist(State.activeVehicle) or not DoesEntityExist(State.activeDriver) then
                print("Entity check failed")
                HandleJourneyEnd()
                break
            end

            local vehCoords = GetEntityCoords(State.activeVehicle)
            local dist = #(vehCoords - destination.coords)

            local health = GetEntityHealth(State.activeVehicle)
            if health < 500 then
                lib.notify({
                    title = 'Taxi',
                    description = 'Your taxi was damaged and the journey was canceled!',
                    type = 'error'
                })
                HandleJourneyEnd()
                break
            end

            if not IsPedInVehicle(PlayerPedId(), State.activeVehicle, false) then
                if CanSendNotification() then
                    TriggerEvent('rNotify:NotifyLeft', "you left the taxi ", "driver is waiting", "generic_textures", "tick", 4000)
                end
                ClearPedTasks(State.activeDriver)
                TaskVehicleTempAction(State.activeDriver, State.activeVehicle, 1, 5000)

                local waitingForReturn = true
                local waitStartTime = GetGameTimer()
                while waitingForReturn and State.isJourneyActive do
                    Wait(1000)
                    
                    local currentTime = GetGameTimer()
                    local timeWaited = (currentTime - waitStartTime) / 1000
                    
                    if timeWaited > Config.waitTimeForReturn then
                        if CanSendNotification() then
                            TriggerEvent('rNotify:NotifyLeft', "taxi got tired of waiting ", "and left", "generic_textures", "tick", 4000)
                        end
                        local vehicleHeading = GetEntityHeading(State.activeVehicle)
                        local vehicleCoords = GetEntityCoords(State.activeVehicle)
                        local departureDistance = 200.0 
            
                        local departureX = vehicleCoords.x + (departureDistance * math.sin(-math.rad(vehicleHeading)))
                        local departureY = vehicleCoords.y + (departureDistance * math.cos(-math.rad(vehicleHeading)))
            
                        local ground, groundZ = GetGroundZFor_3dCoord(departureX, departureY, vehicleCoords.z + 10.0, false)
                        local departureZ = ground and groundZ or vehicleCoords.z
            
                        if DoesEntityExist(State.activeDriver) and DoesEntityExist(State.activeVehicle) then
                            if State.activeBlip then 
                                RemoveBlip(State.activeBlip)
                                State.activeBlip = nil
                            end
                
                            SetBlockingOfNonTemporaryEvents(State.activeDriver, true)
                            TaskVehicleDriveToCoord(
                                State.activeDriver,
                                State.activeVehicle,
                                departureX,
                                departureY,
                                departureZ,
                                8.0,
                                1.0,
                                GetHashKey(State.selectedVehicle.model),
                                786603,
                                1.0,
                                true
                            )
                
                            CreateThread(function()
                                local startTime = GetGameTimer()
                                local timeout = 20000 
                                local minDriveTime = 8000 
                                local hasReachedMinTime = false
                    
                                while true do
                                    Wait(1000)
                                    local currentTime = GetGameTimer()
                                    local elapsedTime = currentTime - startTime
                        
                                    if elapsedTime >= minDriveTime then
                                        hasReachedMinTime = true
                                    end
                        
                                    if not DoesEntityExist(State.activeVehicle) or not DoesEntityExist(State.activeDriver) then
                                        break
                                    end
                        
                                    local currentCoords = GetEntityCoords(State.activeVehicle)
                                    local distanceTraveled = #(vehicleCoords - currentCoords)
                        
                                    if hasReachedMinTime and (distanceTraveled > 50.0 or elapsedTime > timeout) then
                            
                                        if DoesEntityExist(State.activeDriver) then
                                            SetEntityAsMissionEntity(State.activeDriver, true, true)
                                            DeletePed(State.activeDriver)
                                        end
                            
                                        if DoesEntityExist(State.activeVehicle) then
                                            SetEntityAsMissionEntity(State.activeVehicle, true, true)
                                            DeleteVehicle(State.activeVehicle)
                                
                                            Wait(500)
                                            if DoesEntityExist(State.activeVehicle) then
                                                SetVehicleAsNoLongerNeeded(State.activeVehicle)
                                                Wait(500)
                                                DeleteVehicle(State.activeVehicle)
                                            end
                                        end
                            
                                        break
                                    end
                                end
                    
                                State.isJourneyActive = false
                                State.journeyStarted = false
                                State.activeDriver = nil
                                State.activeVehicle = nil
                    
                            end)
                        end
                    end
        
                    local playerPed = PlayerPedId()
                    local playerCoords = GetEntityCoords(playerPed)
                    local vehicleCoords = GetEntityCoords(State.activeVehicle)
                    local distance = #(playerCoords - vehicleCoords)
                    
                    if distance < 3.0 then
                        if IsPedInVehicle(playerPed, State.activeVehicle, false) then
                            local seat = GetPedInVehicleSeat(State.activeVehicle, -1)
                            if seat == playerPed then
                                TaskLeaveVehicle(playerPed, State.activeVehicle, 0)
                                Wait(2000)
                                lib.notify({
                                    title = 'Taxi',
                                    description = 'Please enter through the passenger door',
                                    type = 'error'
                                })
                            end
                        end
                        
                        if GetPlayerIntoTaxi(State.activeVehicle) then
                            waitingForReturn = false
                            TriggerEvent('rNotify:NotifyLeft', "Journey Resumed", "You got back in. Resuming journey!", "generic_textures", "tick", 4000)
                            DriveToDestination()
                        end
                    end
                end
            end

            if dist < Config.arrivalDistance then
                local journeyTime = GetGameTimer() - journeyStartTime
                if journeyTime > 5000 then  
                    HandleJourneyEnd()
                    break
                end
            end
        end
    end)  

    return true
end






RegisterNetEvent('taxi:receiveFareDetails', function(fareDetails)
    State.currentFareDetails = fareDetails
    SpawnTaxi(fareDetails.destination)
    
    
    TriggerEvent('rNotify:NotifyLeft', "Fare Paid", "Paid $" .. fareDetails.fare .. " for taxi to " .. fareDetails.destination.label, "generic_textures", "tick", 4000)
end)


RegisterNetEvent('taxi:OpenTaxiMenu', function()
    local mainMenu = {
        {
            title = 'Select Vehicle',
            description = 'Choose your preferred coach',
            icon = 'fas fa-car',
            event = 'taxi:ShowVehicles',
            arrow = true
        },
        {
            title = "Close Menu",
            icon = 'fas fa-times',
            event = 'ox:menu:close'
        }
    }

    lib.registerContext({
        id = 'taxi_main_menu',
        title = 'Taxi Services',
        options = mainMenu
    })

    lib.showContext('taxi_main_menu')
end)

RegisterNetEvent('taxi:ShowVehicles', function()
    local vehicleMenu = {}
    
    for _, vehicle in ipairs(Config.vehicles) do
        table.insert(vehicleMenu, {
            title = vehicle.label,
            description = vehicle.description,
            icon = 'fas fa-car',
            event = 'taxi:SelectVehicle',
            args = vehicle,
            arrow = true
        })
    end

    table.insert(vehicleMenu, {
        title = "Back to Main Menu",
        icon = 'fas fa-arrow-left',
        event = 'taxi:OpenTaxiMenu'
    })

    lib.registerContext({
        id = 'taxi_vehicles',
        title = 'Select Vehicle',
        options = vehicleMenu
    })

    lib.showContext('taxi_vehicles')
end)

RegisterNetEvent('taxi:ShowDestinations', function()
    if not State.selectedVehicle then
        lib.notify({
            title = 'Taxi',
            description = 'Please select a vehicle first',
            type = 'error'
        })
        TriggerEvent('taxi:ShowVehicles')
        return
    end

    local taxiMenu = {}
    
    for _, dest in ipairs(Config.destinations) do
        table.insert(taxiMenu, {
            title = dest.label,
            description = "Travel to " .. dest.label .. " - Base fare: $5",
            icon = 'fas fa-taxi',
            event = 'taxi:InitiateRide',
            args = dest,
            arrow = true
        })
    end

    table.insert(taxiMenu, {
        title = "Back to Main Menu",
        icon = 'fas fa-arrow-left',
        event = 'taxi:OpenTaxiMenu'
    })

    lib.registerContext({
        id = 'taxi_destinations',
        title = 'Select Destination',
        options = taxiMenu
    })

    lib.showContext('taxi_destinations')
end)

RegisterNetEvent('taxi:SelectVehicle', function(vehicle)
    State.selectedVehicle = vehicle
    lib.notify({
        title = 'Taxi',
        description = 'Selected ' .. vehicle.label,
        type = 'success'
    })
    TriggerEvent('taxi:ShowDestinations')
end)



RegisterNetEvent('taxi:InitiateRide', function(destination)
    if not State.selectedVehicle then
        lib.notify({
            title = 'Taxi',
            description = 'Please select a vehicle first',
            type = 'error'
        })
        return
    end
    
    TriggerServerEvent('taxi:requestRide', destination, State.selectedVehicle)
end)

local function CreateTravelBlips()
    
    for _, blip in ipairs(blips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    blips = {}
    
    
    for _, location in ipairs(Config.blips) do
        
        local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, location.coords.x, location.coords.y, location.coords.z)
        SetBlipSprite(blip, -1989306548)
        Citizen.InvokeNative(0x9CB1A1623062F402, blip, location.label .. " Travel")
        BlipAddModifier(blip, `BLIP_MODIFIER_MP_COLOR_8`)
        table.insert(blips, blip)
    end
end


AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Wait(2000)
        CreateTravelBlips()
    end
end)


AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for _, blip in ipairs(blips) do
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end
        blips = {}
    end
end)




--RegisterCommand('taxi', function()
    --TriggerEvent('taxi:OpenTaxiMenu')
--end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if State.journeyStarted then
            ClearTaxiService()
        end
    end
end)
