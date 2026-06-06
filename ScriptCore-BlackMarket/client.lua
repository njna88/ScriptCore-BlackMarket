local blackMarketPed = nil
local pickupPed = nil
local uiOpen = false
local buying = false

local function debugPrint(...)
    if Config.Debug then
        print('[ScriptCore-BlackMarket]', ...)
    end
end

local function loadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)

    if HasModelLoaded(hash) then
        return hash
    end

    RequestModel(hash)

    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) do
        Wait(25)

        if GetGameTimer() > timeout then
            debugPrint('Model timeout:', model)
            return nil
        end
    end

    return hash
end

local function setupPed(data, targetName, onSelect)
    if not data or not data.coords or not data.model then
        debugPrint('Ped config mangler data:', targetName)
        return nil
    end

    local model = loadModel(data.model)
    if not model then
        debugPrint('Kunne ikke loade ped model:', data.model)
        return nil
    end

    local coords = data.coords
    local ped = CreatePed(0, model, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)

    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedDiesWhenInjured(ped, false)
    SetPedCanPlayAmbientAnims(ped, true)
    SetPedCanRagdollFromPlayerImpact(ped, false)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)

    if data.scenario and data.scenario ~= '' then
        TaskStartScenarioInPlace(ped, data.scenario, 0, true)
    end

    exports.ox_target:addLocalEntity(ped, {
        {
            name = targetName,
            icon = data.icon or 'fa-solid fa-circle',
            label = data.label or 'Åbn',
            distance = data.targetDistance or 2.0,
            onSelect = onSelect
        }
    })

    SetModelAsNoLongerNeeded(model)
    return ped
end

local function openBlackMarket()
    if uiOpen then return end

    uiOpen = true
    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'open',
        shop = Config.Shop,
        items = Config.Items
    })
end

local function closeBlackMarket()
    if not uiOpen then return end

    uiOpen = false
    buying = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function pickupOrder()
    lib.callback('scriptcore:blackmarket:pickupOrder', false, function(result)
        if result and result.message then
            lib.notify({
                title = 'Black Market',
                description = result.message,
                type = result.ok and 'success' or 'error'
            })
        end
    end)
end

RegisterNUICallback('close', function(_, cb)
    closeBlackMarket()
    cb({ ok = true })
end)

RegisterNUICallback('buyItem', function(data, cb)
    if buying then
        cb({ ok = false, message = 'Vent lige et sekund.' })
        return
    end

    local item = data and data.item
    local amount = math.floor(tonumber(data and data.amount) or 1)

    if not item or amount < 1 or amount > 100 then
        cb({ ok = false, message = 'Ugyldigt køb.' })
        return
    end

    buying = true

    lib.callback('scriptcore:blackmarket:buyItem', false, function(result)
        buying = false

        if result and result.ok and Config.SetWaypointAfterOrder then
            local coords = Config.PickupPed.coords
            SetNewWaypoint(coords.x, coords.y)
        end

        cb(result or { ok = false, message = 'Ingen server respons.' })
    end, item, amount)
end)

CreateThread(function()
    blackMarketPed = setupPed(Config.Ped, 'scriptcore_blackmarket_open', openBlackMarket)
    pickupPed = setupPed(Config.PickupPed, 'scriptcore_blackmarket_pickup', pickupOrder)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    if blackMarketPed and DoesEntityExist(blackMarketPed) then
        exports.ox_target:removeLocalEntity(blackMarketPed, 'scriptcore_blackmarket_open')
        DeleteEntity(blackMarketPed)
    end

    if pickupPed and DoesEntityExist(pickupPed) then
        exports.ox_target:removeLocalEntity(pickupPed, 'scriptcore_blackmarket_pickup')
        DeleteEntity(pickupPed)
    end

    SetNuiFocus(false, false)
end)
