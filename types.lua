---@class BlipDataRaw
---@field label string
---@field sprite number
---@field color number
---@field scale? number

---@class BlipData : BlipDataRaw
---@field coords vector3|vector4|{x: number, y: number, z: number, w?: number}

---@class PedDataRaw
---@field model string|number
---@field animation? PedAnimation

---@class PedData : PedDataRaw
---@field coords vector4|{x: number, y: number, z: number, w: number}

---@class PaymentMethodData
---@field price number
---@field label string?
---@field allowBlackMoney boolean?

---@class PedInteractionData
---@field key? string
---@field ped PedData
---@field interactions PedInteraction|PedInteraction[]

---@class PedInteraction
---@field label string
---@field icon string
---@field onSelect function

---@alias PedAnimation { name: string }|{ dict: string, name: string, flag: number? }|nil;
