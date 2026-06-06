local pendingOrders = {}
local itemCache = {}

CreateThread(function()
    for _, data in ipairs(Config.Items or {}) do
        if data.item then
            itemCache[data.item] = data
        end
    end
end)

local function findConfigItem(itemName)
    return itemCache[itemName]
end

local function getPlayerKey(source)
    return GetPlayerIdentifierByType(source, 'license') or tostring(source)
end

local function getCurrencyCount(source, currencyItem)
    local count = exports.ox_inventory:Search(source, 'count', currencyItem)
    return tonumber(count) or 0
end

lib.callback.register('scriptcore:blackmarket:buyItem', function(source, itemName, amount)
    amount = math.floor(tonumber(amount) or 1)

    if amount < 1 or amount > 100 then
        return { ok = false, message = 'Ugyldigt antal.' }
    end

    local itemData = findConfigItem(itemName)
    if not itemData then
        return { ok = false, message = 'Varen findes ikke.' }
    end

    local price = tonumber(itemData.price) or 0
    if price < 0 then
        return { ok = false, message = 'Ugyldig pris i config.' }
    end

    local totalPrice = price * amount
    local currencyItem = Config.Shop.currencyItem or 'money'
    local currencyLabel = Config.Shop.currencyLabel or ''
    local count = getCurrencyCount(source, currencyItem)

    if count < totalPrice then
        return {
            ok = false,
            message = ('Du mangler %s %s.'):format(totalPrice - count, currencyLabel)
        }
    end

    if totalPrice > 0 then
        local removed = exports.ox_inventory:RemoveItem(source, currencyItem, totalPrice)
        if not removed then
            return { ok = false, message = 'Køb fejlede.' }
        end
    end

    local key = getPlayerKey(source)
    pendingOrders[key] = pendingOrders[key] or {}
    pendingOrders[key][itemData.item] = (pendingOrders[key][itemData.item] or 0) + amount

    return {
        ok = true,
        message = ('Købt: %sx %s.'):format(amount, itemData.label or itemData.item)
    }
end)

lib.callback.register('scriptcore:blackmarket:pickupOrder', function(source)
    local key = getPlayerKey(source)
    local order = pendingOrders[key]

    if not order then
        return { ok = false, message = 'Du har ikke noget at hente.' }
    end

    local labels = {}

    for itemName, amount in pairs(order) do
        local itemData = findConfigItem(itemName)
        local label = itemData and itemData.label or itemName

        if amount and amount > 0 and not exports.ox_inventory:CanCarryItem(source, itemName, amount) then
            return { ok = false, message = ('Du har ikke plads til %sx %s.'):format(amount, label) }
        end
    end

    for itemName, amount in pairs(order) do
        local itemData = findConfigItem(itemName)
        local label = itemData and itemData.label or itemName

        if amount and amount > 0 then
            local added = exports.ox_inventory:AddItem(source, itemName, amount)
            if not added then
                return { ok = false, message = ('Kunne ikke give %sx %s. Prøv igen.'):format(amount, label) }
            end

            labels[#labels + 1] = ('%sx %s'):format(amount, label)
        end
    end

    pendingOrders[key] = nil

    return {
        ok = true,
        message = ('Du hentede dine varer: %s.'):format(table.concat(labels, ', '))
    }
end)
