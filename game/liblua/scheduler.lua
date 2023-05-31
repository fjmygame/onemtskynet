--
-- Author: TQ
-- Date: 2015-07-25 16:31:59
--
local skynet = require("skynet")
-- 定时器
local scheduler = class("schedule")

local defaultRefreshTime = 1

local schedulerCount = 0

local initialHandle = 0

------------------API--------------------
function scheduler.create(fun, time)
    local sche = scheduler.new(time)
    local handle = sche:scheduleUpdate(fun)
    return sche, handle
end

-- 销毁计时器
function scheduler:destroy()
    self.open = false
    self.continue = false
    skynet.wakeup(self.schedulerCo)
end

-- 获取定时器数量
function scheduler.getSchedulerCount()
    return schedulerCount
end

-- 设置刷新函数
function scheduler:scheduleUpdate(fun)
    if "function" == type(fun) then
        local handle = self:newHandle()
        self.call_map[handle] = fun
        return handle
    end
end

-- 移除刷新函数
function scheduler:unscheduleUpdate(handle)
    if handle then
        if self.call_map[handle] then
            self.call_map[handle] = true
        end
    end
end

-- 设置定时器刷新时间
function scheduler:setRefreshTime(time)
    if "number" == type(time) and time > 0 then
        self.refreshTime_ = time
    end
end

-- 获取定时器刷新时间
function scheduler:getRefreshTime()
    return self.refreshTime_
end

-- 启动计时器
function scheduler:start()
    self.continue = true
    if self.schedulerCo then
        skynet.wakeup(self.schedulerCo)
    end
end

-- 暂停计时器
function scheduler:pause()
    self.continue = false
end

local tkeys = table.keys
-- 刷新
function scheduler:update()
    local call_map = self.call_map
    local keys = tkeys(call_map)
    for _, handle in ipairs(keys) do
        local func = call_map[handle]
        if func then
            local ok, err = xpcall(func, debug.traceback)
            if not ok then
                log.Error("sys", "LUA EXCEPTION: ", err)
            end
        end
    end
end

-- 是否正在运行
function scheduler:isRunning()
    return self.continue
end

----------------------------------------

local function coFun(self)
    while self.open do
        if self.continue then
            local startTime = skynet.now()
            self:update()
            local remainTime = self:getRefreshTime() * 100 - (skynet.now() - startTime)
            skynet.sleep(remainTime)
        else
            skynet.wait()
        end
    end
end

function scheduler:ctor(refreshTime)
    schedulerCount = schedulerCount + 1
    if schedulerCount > 10000 then
        log.Debug("sys", "scheduler.create( fun, time )", schedulerCount)
    end

    self:setRefreshTime(refreshTime or defaultRefreshTime)
    -- 是否继续运行，默认未不继续
    self.continue = false
    -- 开关
    self.open = true
    -- 刷新回调列表
    self.call_map = {}
    -- 定时器协程
    self.schedulerCo = skynet.fork(coFun, self)
end

function scheduler:newHandle()
    initialHandle = initialHandle + 1
    return initialHandle
end

return scheduler
