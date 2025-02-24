Client = {}

local spawnedPeds, pedCount = {}, 0
local cooldowns = {}

---@param data BlipData
---@return number
function Client.createBlip(data)
    local coords = data.coords
    local createdBlip = AddBlipForCoord(coords.x, coords.y, coords.z)

    SetBlipSprite(createdBlip, data.sprite)
    SetBlipScale(createdBlip, data.scale or 1.0)
    SetBlipColour(createdBlip, data.color)
    SetBlipAsShortRange(createdBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(data.label)
    EndTextCommandSetBlipName(createdBlip)

    return createdBlip
end

---@param data PedData
---@return number?
function Client.spawnPed(data)
    local model = lib.requestModel(data.model)
    if not model then return end

    local coords = data.coords
    local entity = CreatePed(0, model, coords.x, coords.y, coords.z, coords.w, false, true)

    local animation = data.animation
    if animation and animation.dict then
        lib.requestAnimDict(animation.dict)
        TaskPlayAnim(entity, animation.dict, animation.name, 8.0, 0.0, -1, animation.flag, 0, false, false, false)
    elseif animation and animation.name then
        TaskStartScenarioInPlace(entity, animation.name, 0, true)
    end

    SetModelAsNoLongerNeeded(model)
    FreezeEntityPosition(entity, true)
    SetEntityInvincible(entity, true)
    SetBlockingOfNonTemporaryEvents(entity, true)

    pedCount += 1
    spawnedPeds[pedCount] = entity

    return entity
end

---@param data PedInteractionData
function Client.addPedInteraction(data)
    local ped = data.ped
    lib.points.new({
        coords = ped.coords.xyz,
        distance = 50,
        onEnter = function(self)
            if self.entity then return end

            local entity = Client.functions.spawnPed({
                coords = ped.coords,
                model = ped.model,
                animation = ped.animation,
            })

            if not entity then return lib.print.error(('Could not spawn npc \'%s\'!'):format(data.key or 'PedInteraction')) end
            exports.ox_target:addLocalEntity(entity, data.interactions)
        end,
        onExit = function(self)
            local entity = self.entity
            if not entity then return end

            exports.ox_target:removeLocalEntity(entity)
            Client.deleteEntity(entity)
            self.entity = nil
        end
    })
end

---@param data PaymentMethodData
---@return string|false
function Client.selectPaymentMethod(data)
    local price = data.price
    local label = data.label

    if data.allowBlackMoney == nil then data.allowBlackMoney = false end

    local rows = {
        {
            label       = 'How would you like to pay?',
            description = label and ('Choose how you would like to pay %s$ for "%s".'):format(price, label) or
                ('Choose how you would like to pay %s$.'):format(price),
            type        = 'select',
            icon        = { 'fas', 'file-contract' },
            options     = {
                {
                    value = 'money',
                    label = 'Cash'
                },
                {
                    value = 'bank',
                    label = 'Card'
                }
            },
            default     = 'money',
            required    = true
        }
    }

    local retval = lib.inputDialog('Choose a payment method', rows)

    ---@diagnostic disable-next-line: return-type-mismatch
    return retval and retval[1] or false
end

---@param key string
---@param duration number
---@return boolean
function Client.hasCooldown(key, duration)
    local now = GetGameTimer()

    if not cooldowns[key] or cooldowns[key] < now then
        cooldowns[key] = now + duration
        return false
    end

    return true
end

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then
        for i = 1, pedCount do
            local entity = spawnedPeds[i]
            if DoesEntityExist(entity) then
                SetEntityAsMissionEntity(entity, false, true)
                DeleteEntity(entity)
            end
        end
    end
end)
