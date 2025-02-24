Shared = {}

lib.locale()

function Shared.mapTable(list, cb, noIndex)
    local retval = {}

    for key, value in pairs(list) do
        local data = cb(value, key)
        if data ~= nil then
            if noIndex then
                table.insert(retval, data)
            else
                retval[key] = data
            end
        end
    end

    return retval
end
