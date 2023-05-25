-- --------------------------------------
-- Create Date:2023-04-18 15:45:05
-- Author  : sgys
-- Version : 1.0
-- Filename: effectUtil.lua
-- Introduce  : 效果管理 玩家模块注册自己影响的buff附加值
-- --------------------------------------

---@class effectUtil
local effectUtil = BuildUtil("effectUtil")

-- 效果注册表 {BuffEffect, func}
local effectFunc = CreateBlankTable(effectUtil, "effectFunc")

-- t: 类型 共用BuffEffect类型
-- func -- function xxx(t) { return yy} 类型做参数
-- 添加影响效果
function effectUtil.registerEffect(t, moduleKey, func)
    local modules = effectFunc[t]
    if not modules then
        modules = {}
        effectFunc[t] = modules
    end
    modules[moduleKey] = func
end

function effectUtil.getEffect(t)
    local modules = effectFunc[t]
    if not modules then
        return 0
    end

    local val = 0
    for k, func in pairs(modules) do
        val = val + func(t)
    end
    return val
end

-- 指定模块效果值
function effectUtil.getEffectByModule(t, moduleKey)
    local modules = effectFunc[t]
    if not modules then
        return 0
    end
    local func = modules[moduleKey]
    return func and func(t) or 0
end

return effectUtil
