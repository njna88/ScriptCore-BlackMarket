Config = {}

Config.Debug = false
Config.SetWaypointAfterOrder = true
Config.ResourceName = 'ScriptCore-BlackMarket'


Config.Ped = {
    model = 'g_m_m_chigoon_02',
    coords = vec4(383.5441, 800.9215, 187.6748, 356.9015),
    scenario = 'WORLD_HUMAN_SMOKING',
    targetDistance = 2.2,
    label = 'Åbn Black Market',
    icon = 'fa-solid fa-user-secret'
}


Config.PickupPed = {
    model = 'g_m_m_armboss_01',
    coords = vec4(938.7860, 2428.8594, 50.9627, 32.9419),
    scenario = 'WORLD_HUMAN_GUARD_STAND',
    targetDistance = 2.2,
    label = 'Hent dine Varer',
    icon = 'fa-solid fa-box-open'
}

Config.Shop = {
    title = 'Black Market',
    subtitle = '',
    description = '',
    currencyItem = 'money', 
    currencyLabel = 'DKK'
}


Config.Items = {
    {
        item = 'lockpick',
        label = 'Lockpick',
        price = 2500,
        description = '',
        image = 'lockpick.png'
    },
    {
        item = 'weapon_knife',
        label = 'Kniv',
        price = 15000,
        description = '',
        image = 'weapon_knife.png'
    },
    {
        item = 'weapon_pistol',
        label = 'Pistol',
        price = 85000,
        description = '',
        image = 'weapon_pistol.png'
    },
    {
        item = 'ammo-9',
        label = '9mm Ammo',
        price = 1200,
        description = '',
        image = 'ammo-9.png'
    },
    {
        item = 'radio',
        label = 'Radio',
        price = 3500,
        description = '',
        image = 'radio.png'
    }
}

Config.Notify = function(source, msg, notifyType)
    if source == nil then
        lib.notify({
            title = 'Black Market',
            description = msg,
            type = notifyType or 'inform'
        })
    else
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Black Market',
            description = msg,
            type = notifyType or 'inform'
        })
    end
end
