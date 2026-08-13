--========================================================--
--                    REO WRAP SYSTEM                     --
--                     CLIENT SIDE                        --
--========================================================--
CreateThread(function()
    print('^2[REO WRAP]^7 Client loaded successfully.')
    if Config.Debug then print('^3[REO WRAP]^7 Client debug mode is enabled.') end
end)

--========================================================--
--                     LOCAL STATE                        --
--========================================================--
local isWrapped = false

--========================================================--
--                    HELPER FUNCTIONS                    --
--========================================================--
local function notify(description, notifyType)
    lib.notify({ title = 'WRAP', description = description, type = notifyType or 'inform' })
end

local function requestAnimDict(dict)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) do
        if GetGameTimer() > timeout then return false end
        Wait(50)
    end
    return true
end

local function getServerIdFromPed(ped)
    local playerIndex = NetworkGetPlayerIndexFromPed(ped)
    if playerIndex == -1 then return nil end
    return GetPlayerServerId(playerIndex)
end

local function targetIsWrapped(ped)
    local playerIndex = NetworkGetPlayerIndexFromPed(ped)
    if playerIndex == -1 then return false end
    local player = Player(GetPlayerServerId(playerIndex))
    return player and player.state and player.state.reoWrapped == true
end

local function findNearbyVehicle()
    local coords = GetEntityCoords(PlayerPedId())
    return GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 70)
end

local function findFreePassengerSeat(vehicle)
    if vehicle == 0 then return nil end
    for seat = 0, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
        if IsVehicleSeatFree(vehicle, seat) then return seat end
    end
    return nil
end

--========================================================--
--                    WRAP ANIMATIONS                     --
--========================================================--
local function startWrappedAnimation()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then return end
    local anim = Config.WrappedAnim
    if not requestAnimDict(anim.dict) then return end
    if not IsEntityPlayingAnim(ped, anim.dict, anim.clip, 3) then
        TaskPlayAnim(ped, anim.dict, anim.clip, 8.0, -8.0, -1, anim.flag, 0.0, false, false, false)
    end
end

local function stopWrappedAnimation()
    ClearPedTasks(PlayerPedId())
end

--========================================================--
--                   CONTROL LOCKOUTS                     --
--========================================================--
CreateThread(function()
    while true do
        if not isWrapped then
            Wait(500)
        else
            Wait(0)
            local ped = PlayerPedId()
            for i = 1, #Config.DisableControls do DisableControlAction(0, Config.DisableControls[i], true) end
            DisablePlayerFiring(PlayerId(), true)
            SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
            if not IsPedInAnyVehicle(ped, false) then startWrappedAnimation() end
        end
    end
end)

--========================================================--
--                    NETWORK EVENTS                      --
--========================================================--
RegisterNetEvent('reo_wrap:client:notify', function(description, notifyType) notify(description, notifyType) end)

RegisterNetEvent('reo_wrap:client:setWrapped', function(state)
    isWrapped = state == true
    if isWrapped then startWrappedAnimation() else stopWrappedAnimation() end
end)

--========================================================--
--                   VEHICLE HANDLING                     --
--========================================================--
RegisterNetEvent('reo_wrap:client:putInVehicle', function(vehicleNetId)
    if not isWrapped then return end
    local vehicle = NetToVeh(vehicleNetId)
    if vehicle == 0 or not DoesEntityExist(vehicle) then return end
    local seat = findFreePassengerSeat(vehicle)
    if seat == nil then return notify('There is no free passenger seat.', 'error') end
    ClearPedTasksImmediately(PlayerPedId())
    TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, seat)
end)

RegisterNetEvent('reo_wrap:client:takeOutVehicle', function()
    if not isWrapped then return end
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then return end
    TaskLeaveVehicle(ped, GetVehiclePedIsIn(ped, false), 16)
    SetTimeout(750, function() if isWrapped then startWrappedAnimation() end end)
end)

--========================================================--
--                   OX_TARGET OPTIONS                    --
--========================================================--
exports.ox_target:addGlobalPlayer({
    {
        name = 'reo_wrap_apply',
        icon = 'fa-solid fa-person-circle-xmark',
        label = 'Apply WRAP Restraint',
        distance = Config.TargetDistance,
        canInteract = function(entity) return entity ~= PlayerPedId() and not targetIsWrapped(entity) end,
        onSelect = function(data)
            local targetId = getServerIdFromPed(data.entity)
            if not targetId then return end
            local completed = lib.progressCircle({
                duration = Config.ApplyDuration, label = 'Applying WRAP restraint...',
                position = 'bottom', canCancel = true,
                disable = { move = true, car = true, combat = true }
            })
            if completed then TriggerServerEvent('reo_wrap:server:applyWrap', targetId) end
        end
    },
    {
        name = 'reo_wrap_remove',
        icon = 'fa-solid fa-unlock',
        label = 'Remove WRAP Restraint',
        distance = Config.TargetDistance,
        canInteract = function(entity) return targetIsWrapped(entity) end,
        onSelect = function(data)
            local targetId = getServerIdFromPed(data.entity)
            if not targetId then return end
            local completed = lib.progressCircle({
                duration = Config.RemoveDuration, label = 'Removing WRAP restraint...',
                position = 'bottom', canCancel = true,
                disable = { move = true, car = true, combat = true }
            })
            if completed then TriggerServerEvent('reo_wrap:server:removeWrap', targetId) end
        end
    },
    {
        name = 'reo_wrap_vehicle',
        icon = 'fa-solid fa-car-side',
        label = 'Place WRAPPED Person in Vehicle',
        distance = Config.TargetDistance,
        canInteract = function(entity) return targetIsWrapped(entity) and not IsPedInAnyVehicle(entity, false) end,
        onSelect = function(data)
            local targetId, vehicle = getServerIdFromPed(data.entity), findNearbyVehicle()
            if not targetId then return end
            if vehicle == 0 then return notify('No nearby vehicle found.', 'error') end
            TriggerServerEvent('reo_wrap:server:putInVehicle', targetId, VehToNet(vehicle))
        end
    },
    {
        name = 'reo_wrap_vehicle_remove',
        icon = 'fa-solid fa-person-walking-arrow-right',
        label = 'Remove WRAPPED Person from Vehicle',
        distance = Config.TargetDistance,
        canInteract = function(entity) return targetIsWrapped(entity) and IsPedInAnyVehicle(entity, false) end,
        onSelect = function(data)
            local targetId = getServerIdFromPed(data.entity)
            if targetId then TriggerServerEvent('reo_wrap:server:takeOutVehicle', targetId) end
        end
    }
})

--========================================================--
--                  DEVELOPMENT COMMANDS                  --
--========================================================--
if Config.EnableDevCommands then
    RegisterCommand('wrap', function(_, args)
        local targetId = tonumber(args[1])
        if not targetId then return notify('Usage: /wrap [server ID]', 'error') end
        TriggerServerEvent('reo_wrap:server:applyWrap', targetId)
    end, false)

    RegisterCommand('unwrap', function(_, args)
        local targetId = tonumber(args[1])
        if not targetId then return notify('Usage: /unwrap [server ID]', 'error') end
        TriggerServerEvent('reo_wrap:server:removeWrap', targetId)
    end, false)
end

--========================================================--
--                    RESOURCE CLEANUP                    --
--========================================================--
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if isWrapped then stopWrappedAnimation() end
end)
