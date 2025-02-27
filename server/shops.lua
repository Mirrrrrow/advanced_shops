local shops, shopTypes = lib.load('data.shops'), lib.load('data.shopTypes')

local _shopCache = {}

Server.cache.shopCache = setmetatable({}, {
    __index = function(self, key)
        if _shopCache[key] then return _shopCache[key] end

        local result = MySQL.single.await('SELECT * FROM advanced_shops WHERE shop = ?', { key })
        if not result then
            MySQL.insert.await('INSERT INTO advanced_shops (shop, owner) VALUES (?, ?)', { key, 'none' })
            return self[key]
        end

        _shopCache[key] = result
        return result
    end,
    __newindex = function(self, key, value)
        _shopCache[key] = value
    end,
    __call = function()
        for key, shopData in pairs(_shopCache) do
            MySQL.update.await('UPDATE advanced_shops SET owner = ? WHERE shop = ?', { shopData.owner, key })
        end
    end
})

lib.callback.register('shop:server:getShopOwnership', function(source, shopId)
    local playerId = source
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return false, false end

    if not shops[shopId] then return false, false end

    local shopData = Server.cache.shopCache[shopId]
    if not shopData then return false, false end

    return true, true
    --return shopData.owner ~= 'none', shopData.owner == xPlayer.getIdentifier()
end)
