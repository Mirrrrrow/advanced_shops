local shops, shopTypes = lib.load('data.shops'), lib.load('data.shopTypes')
local swapItemHook, buyItemHook

local function formatStashItems(stashId)
    local stashItems = exports.ox_inventory:GetInventoryItems(stashId)
    local items = Shared.mapTable(stashItems, function(stashItem)
        stashItem.price = stashItem.metadata.price or 9999
        stashItem.currency = stashItem.metadata.currency or 'money'
        stashItem.metadata = {}

        return stashItem
    end)

    return items
end

local function updateShopItems(key)
    local shop = shops[key]
    local storageInventoryId = ('shop_storage_%s'):format(key)

    local shopInventoryId = ('owned_shop_%s'):format(key)
    exports.ox_inventory:RegisterShop(shopInventoryId, {
        name = shop.label,
        inventory = formatStashItems(storageInventoryId),
    })
end

local function registerShopInventory(key, type)
    local shop = shops[key]
    if not shop then return end

    local storageInventoryId = ('shop_storage_%s'):format(key)
    exports.ox_inventory:RegisterStash(storageInventoryId, shop.label, 50, 50000)

    updateShopItems(key)
end

local function addShopItem(key, inventoryId, item, slot, price, currency)
    item.metadata.price = price
    item.metadata.currency = currency

    exports.ox_inventory:SetMetadata(inventoryId, slot, item.metadata)
    Wait(200)

    updateShopItems(key)
end

for key, shopData in pairs(shops) do
    registerShopInventory(key, shopData.type)
end

for key, data in pairs(shopTypes) do
    local shopInventoryId = ('default_shop_%s'):format(key)
    exports.ox_inventory:RegisterShop(shopInventoryId, {
        name = data.label,
        inventory = data.defaultInventory,
    })
end

CreateThread(function()
    swapItemHook = exports.ox_inventory:registerHook('swapItems', function(payload)
        local playerId = payload.source
        if payload.fromType == 'stash' and payload.toType ~= 'stash' then
            local shopId = payload.fromInventory:match('^shop_storage_([%w_]+)$')

            payload.fromSlot.metadata.price = nil
            payload.fromSlot.metadata.currency = nil

            CreateThread(function()
                Wait(500)
                updateShopItems(shopId)

                exports.ox_inventory:SetMetadata(payload.toInventory, payload.toSlot, payload.fromSlot.metadata)
            end)

            return true
        end

        local itemLabel = payload.fromSlot.label
        local price, currency = lib.callback.await('shop:client:requestItemPrice', playerId, itemLabel)
        if not price then return false end

        currency = currency or 'money'

        local shopId = payload.toInventory:match('^shop_storage_([%w_]+)$')
        CreateThread(function()
            Wait(200)
            addShopItem(shopId, payload.toInventory, payload.fromSlot, payload.toSlot, price, currency)
        end)

        return true
    end, {
        inventoryFilter = {
            '^shop_storage_(.+)$'
        }
    })

    buyItemHook = exports.ox_inventory:registerHook('buyItem', function(payload)
        local shopId = payload.shopType:match('^owned_shop_(.+)$')
        if not shopId then return false end

        local storageInventoryId = ('shop_storage_%s'):format(shopId)
        exports.ox_inventory:RemoveItem(storageInventoryId, payload.itemName, payload.count)

        return true
    end, {
        inventoryFilter = {
            '^owned_shop_(.+)$'
        }
    })
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= cache.resource then return end

    if swapItemHook then
        exports.ox_inventory:removeHooks(swapItemHook)
    end

    if buyItemHook then
        exports.ox_inventory:removeHooks(buyItemHook)
    end
end)
