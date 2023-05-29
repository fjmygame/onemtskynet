-- --------------------------------------
-- Create Date:2021-05-07 10:37:21
-- Author  : sgys
-- Version : 1.0
-- Filename: eventNameDef.lua
-- Introduce  : 事件类型枚举[注意：枚举必须是 string, 且如果有字母的话，必须全部大写]
-- --------------------------------------

---@class eventNameDef
local gEventName = {
    -- 新的一天
    event_new_day = string.upper("event_new_day"),
    event_new_week = string.upper("event_new_week")
}

return gEventName
