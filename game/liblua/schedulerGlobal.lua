--
-- Author: TQ
-- Date: 2015-07-25 16:31:59
--
local scheduler = require("scheduler")
-- 全局定时器
local schedulerGlobal = {}

local gScheduler = scheduler.new()

-- 启动定时器
function schedulerGlobal.start()
    gScheduler:start()
end

-- 停止定时器
function schedulerGlobal.stop()
    gScheduler:pause()
end

-- 每秒刷新一次
function schedulerGlobal.scheduleUpdate(fun)
    return gScheduler:scheduleUpdate(fun)
end

-- 移除每秒刷新函数
function schedulerGlobal.unscheduleUpdate(handle)
    gScheduler:unscheduleUpdate(handle)
end

return schedulerGlobal
