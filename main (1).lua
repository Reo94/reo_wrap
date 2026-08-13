--========================================================--
--                    REO WRAP SYSTEM                     --
--                     SERVER SIDE                        --
--========================================================--
print('^2[REO WRAP]^7 Server loaded successfully.')
if Config.Debug then print('^3[REO WRAP]^7 Debug mode is enabled.') end

--========================================================--
--                    WRAPPED PLAYERS                     --
--========================================================--
local wrappedPlayers = {}

--========================================================--
--                    HELPER FUNCTIONS                    --
--========================================================--
local function debugPrint(message)
    if Config.Debug then print(('[REO WRAP] %s'):format(message)) end
end

local function notifyPlayer(playerId, description, notifyType)
    TriggerClientEvent('reo_wrap:client:notify', playerId, description, notifyType or 'inform')
end

local function isPlayerWrapped(playerId)
    return wrappedPlayers[playerId] ~= nil
end

local function isAuthorized(playerId)
    local player = exports.qbx_core:GetPlayer(playerId)
    if not player or not player.PlayerData or not player.PlayerData.job then return false end
    return Config.AllowedJobs[player.PlayerData.job.name] == true
end

local function isValidPlayer(playerId)
    playerId = tonumber(playerId)
    if not playerId or not GetPlayerName(playerId) then return false end
    local ped = GetPlayerPed(playerId)
    return ped and ped ~= 0
end

local function arePlayersClose(sourceId, targetId)
    local sourcePed, targetPed = GetPlayerPed(sourceId), GetPlayerPed(targetId)
    if sourcePed == 0 or targetPed == 0 then return false end
    return #(GetEntityCoords(sourcePed) - GetEntityCoords(targetPed)) <= Config.MaxDistance
end

--========================================================--
--                   SECURITY CHECKS                      --
--========================================================--
local function stateBagIsTrue(playerId, keys)
    local player = Player(playerId)
    if not player or not player.state then return false end
    for i = 1, #keys do
        if player.state[keys[i]] == true then return true end
    end
    return false
end

local function isTargetRestrained(playerId)
    if not Config.RequireRestrainedTarget then return true end
    return stateBagIsTrue(playerId, Config.CuffedStateKeys)
        or stateBagIsTrue(playerId, Config.IncapacitatedStateKeys)
end

--========================================================--
--                  INVENTORY HANDLING                    --
--========================================================--
local function hasWrapItem(playerId)
    return (exports.ox_inventory:Search(playerId, 'count', Config.WrapItem) or 0) > 0
end

local function removeWrapItem(playerId)
    if not Config.ConsumeWrap then return true end
    return exports.ox_inventory:RemoveItem(playerId, Config.WrapItem, 1)
end

local function returnWrapItem(playerId)
    if not Config.ConsumeWrap or not Config.ReturnWrapOnRemoval then return true end
    if not exports.ox_inventory:CanCarryItem(playerId, Config.WrapItem, 1) then return false end
    return exports.ox_inventory:AddItem(playerId, Config.WrapItem, 1)
end

--========================================================--
--                  STATE SYNCHRONIZATION                 --
--========================================================--
local function setWrappedState(targetId, state, appliedBy)
    if state then
        wrappedPlayers[targetId] = { appliedBy = appliedBy, appliedAt = os.time() }
    else
        wrappedPlayers[targetId] = nil
    end
    local target = Player(targetId)
    if target and target.state then target.state:set('reoWrapped', state == true, true) end
    TriggerClientEvent('reo_wrap:client:setWrapped', targetId, state == true)
end

--========================================================--
--                     WRAP EVENTS                        --
--========================================================--
RegisterNetEvent('reo_wrap:server:applyWrap', function(targetId)
    local src = source
    targetId = tonumber(targetId)
    if not isAuthorized(src) then return notifyPlayer(src, 'You are not authorized to use the WRAP.', 'error') end
    if not isValidPlayer(targetId) or targetId == src then return notifyPlayer(src, 'Invalid target.', 'error') end
    if not arePlayersClose(src, targetId) then return notifyPlayer(src, 'That person is too far away.', 'error') end
    if isPlayerWrapped(targetId) then return notifyPlayer(src, 'That person is already in a WRAP.', 'error') end
    if not isTargetRestrained(targetId) then return notifyPlayer(src, 'The person must be cuffed or incapacitated first.', 'error') end
    if not hasWrapItem(src) then return notifyPlayer(src, 'You do not have a WRAP restraint.', 'error') end
    if not removeWrapItem(src) then return notifyPlayer(src, 'The WRAP could not be removed from your inventory.', 'error') end

    setWrappedState(targetId, true, src)
    notifyPlayer(src, 'WRAP restraint applied.', 'success')
    notifyPlayer(targetId, 'You have been secured in a WRAP restraint.', 'inform')
    debugPrint(('Player %s applied a WRAP to Player %s.'):format(src, targetId))
end)

RegisterNetEvent('reo_wrap:server:removeWrap', function(targetId)
    local src = source
    targetId = tonumber(targetId)
    if not isAuthorized(src) then return notifyPlayer(src, 'You are not authorized to remove the WRAP.', 'error') end
    if not isValidPlayer(targetId) then return notifyPlayer(src, 'Invalid target.', 'error') end
    if not arePlayersClose(src, targetId) then return notifyPlayer(src, 'That person is too far away.', 'error') end
    if not isPlayerWrapped(targetId) then return notifyPlayer(src, 'That person is not in a WRAP.', 'error') end

    setWrappedState(targetId, false)
    if Config.ReturnWrapOnRemoval and returnWrapItem(src) then
        notifyPlayer(src, 'WRAP removed and returned to your inventory.', 'success')
    elseif Config.ReturnWrapOnRemoval then
        notifyPlayer(src, 'WRAP removed, but your inventory could not carry the returned item.', 'warning')
    else
        notifyPlayer(src, 'WRAP restraint removed.', 'success')
    end
    notifyPlayer(targetId, 'The WRAP restraint has been removed.', 'inform')
end)

--========================================================--
--                   VEHICLE HANDLING                     --
--========================================================--
RegisterNetEvent('reo_wrap:server:putInVehicle', function(targetId, vehicleNetId)
    local src = source
    targetId, vehicleNetId = tonumber(targetId), tonumber(vehicleNetId)
    if not isAuthorized(src) or not isPlayerWrapped(targetId) then return end
    if not isValidPlayer(targetId) or not arePlayersClose(src, targetId) then return end
    TriggerClientEvent('reo_wrap:client:putInVehicle', targetId, vehicleNetId)
end)

RegisterNetEvent('reo_wrap:server:takeOutVehicle', function(targetId)
    local src = source
    targetId = tonumber(targetId)
    if not isAuthorized(src) or not isPlayerWrapped(targetId) then return end
    if not isValidPlayer(targetId) or not arePlayersClose(src, targetId) then return end
    TriggerClientEvent('reo_wrap:client:takeOutVehicle', targetId)
end)

--========================================================--
--                    PLAYER CLEANUP                      --
--========================================================--
AddEventHandler('playerDropped', function() wrappedPlayers[source] = nil end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    for playerId in pairs(wrappedPlayers) do
        local player = Player(playerId)
        if player and player.state then player.state:set('reoWrapped', false, true) end
    end
end)

--========================================================--
--                  DEVELOPMENT COMMANDS                  --
--========================================================--
if Config.EnableDevCommands then
    RegisterCommand('wrapstatus', function(source)
        if source == 0 then return print('[REO WRAP] /wrapstatus must be used in-game.') end
        notifyPlayer(source, ('Your WRAP state is: %s'):format(tostring(isPlayerWrapped(source))), 'inform')
    end, false)
end
