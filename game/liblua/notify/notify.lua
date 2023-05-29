-- --------------------------------------
-- Create Date:2023-04-18 15:31:57
-- Author  : sgys
-- Version : 1.0
-- Filename: notify.lua
-- Introduce  : 本地通知管理
-- --------------------------------------

---@class notify
local notify = BuildOther("notify")

local listeners = CreateBlankTable(notify, "listeners") -- {"name": {index, handle}}
InitalValue(notify, "auto", 0) -- nodeid自增

-- 注册监听
---@param evName 事件名
---@param handle 事件回调
---@return integer 存根id
function notify.subscribe(evName, handle)
    assert(evName and handle)
    local stubId = notify.auto + 1
    notify.auto = stubId

    local nodes = listeners[evName]
    if not nodes then
        nodes = {}
        listeners[evName] = nodes
    end
    nodes[stubId] = handle
    return stubId
end

-- 注销监听
---@param evName 事件名
---@param stubId 存根id
function notify.unsubscribe(evName, stubId)
    local nodes = listeners[evName]
    if not nodes then
        return
    end
    nodes[stubId] = nil
end

-- 发布
function notify.publish(name, data, ...)
    local nodes = listeners[name]
    if not nodes then
        return
    end
    for _, handle in pairs(nodes) do
        local ok, err = xpcall(handle, debug.traceback, name, data, ...)
        if not ok then
            log.Error("sys", "notify.publish.err:", err, name, data, ...)
        end
    end
end

return notify
