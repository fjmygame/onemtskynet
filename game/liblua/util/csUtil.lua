-- --------------------------------------
-- Create Date:2021-12-03 10:27:01
-- Version : 1.0
-- Filename: csUtil.lua
-- Introduce  : 类介绍
-- --------------------------------------
-- csUtil.lua
-- 队列工具
local skynetQueue = require "skynet.queue"
---@class csUtil
local csUtil = BuildUtil("csUtil")

local tb = CreateBlankTable(csUtil, "tb")
local counter = CreateBlankTable(csUtil, "counter")

-- 锁
function csUtil.lock(key, func, ...)
    if not tb[key] then
        tb[key] = skynetQueue()
        counter[key] = 1
    else
        counter[key] = counter[key] + 1
    end
    local cs = tb[key]
    return csUtil.procssLockRet(key, xpcall(cs, debug.traceback, func, ...))
end

-- 处理cs调用返回
function csUtil.procssLockRet(key, bok, err, ...)
    csUtil.unlock(key)
    if bok then
        return err, ...
    else
        log.Error("sys", "csUtil.procssLockRet", err, key)
    end
end

-- 删除cs
function csUtil.unlock(key)
    counter[key] = counter[key] - 1
    if counter[key] <= 0 then
        tb[key] = nil
    end
end

-- 获取协程队列

return csUtil
