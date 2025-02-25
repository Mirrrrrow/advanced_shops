local shops, shopTypes = lib.load('data.shops'), lib.load('data.shopTypes')

local function openShop(key, type)
    local shop = shops[key]

    if Client.hasCooldown('open_shop', 1000) then
        return lib.notify({
            title = shop.label,
            description = 'Please wait a second before opening the shop again.',
            type = 'error',
        })
    end

    local isOwned = lib.callback.await('shop:server:getShopOwnership', false, key)
    if not isOwned then
        local shopInventoryId = ('default_shop_%s'):format(type)
        return exports.ox_inventory:openInventory('shop', {
            type = shopInventoryId,
            id = key
        })
    end

    local shopInventoryId = ('owned_shop_%s'):format(key)
    exports.ox_inventory:openInventory('shop', {
        type = shopInventoryId,
        id = key
    })
end

local function openStorage(key, type)
    local shop = shops[key]

    if Client.hasCooldown('open_shop_storage', 1000) then
        return lib.notify({
            title = shop.label,
            description = 'Please wait a second before opening the shop storage again.',
            type = 'error',
        })
    end

    local isOwned, isOwner = lib.callback.await('shop:server:getShopOwnership', false, key)
    if not isOwned or not isOwner then
        return lib.notify({
            title = shop.label,
            description = 'You do not own this shop.',
            type = 'error',
        })
    end

    local storageInventoryId = ('shop_storage_%s'):format(key)
    exports.ox_inventory:openInventory('stash', storageInventoryId)
end

for key, data in pairs(shops) do
    local shopType = shopTypes[data.type]
    if not shopType then lib.print.error(('Shop type \'%s\' does not exist!'):format(data.type)) end

    local blip = shopType.blip
    if blip then
        Client.createBlip({
            coords = data.coords.xyz,
            sprite = blip.sprite,
            scale = blip.scale,
            color = blip.color,
            label = shopType.label,
        })
    end

    local ped = shopType.ped
    Client.addPedInteraction({
        key = ('shop_keeper_%s'):format(key),
        ped = {
            coords = data.coords,
            model = ped.model,
            animation = ped.animation,
        },
        interactions = {
            {
                label = 'Open shop',
                icon = 'fas fa-store',
                onSelect = function()
                    openShop(key, data.type)
                end
            }
        }
    })

    exports.ox_target:addSphereZone({
        coords = data.storageCoords,
        radius = 1.5,
        options = {
            {
                label = 'Open storage',
                icon = 'fas fa-boxes',
                onSelect = function()
                    openStorage(key, data.type)
                end
            }
        }
    })
end

lib.callback.register('shop:client:requestItemPrice', function(itemLabel)
    local retval = lib.inputDialog('Item: ' .. itemLabel, {
        {
            icon = { 'fas', 'dollar-sign' },
            label = 'Price',
            description = 'Enter the price for this item.',
            type = 'number',
            default = 1,
            required = true,
            min = 1
        },
        {
            icon = { 'fas', 'file-contract' },
            label = 'Currency',
            description = 'Enter the currency for this item.',
            type = 'select',
            options = {
                {
                    value = 'money',
                    label = 'Money'
                },
                {
                    value = 'bank',
                    label = 'Bank'
                }
            },
            default = 'money',
            required = true
        }
    })

    if not retval then return false end
    return retval[1]
end)
