Server.cache = {}

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    for key, data in pairs(Server.cache) do
        lib.print.debug(('Saving cache data for key \'%s\'...'):format(key))
        data()
    end
end)
