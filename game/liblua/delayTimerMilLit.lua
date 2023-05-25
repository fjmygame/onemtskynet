-- --------------------------------------
-- Create Date : 2023-04-09 10:38:35
-- Author      : LHS
-- Version     : 1.0
-- Filename    : delayTimerMilLit.lua
-- Introduce   : 回调只会传content
-- --------------------------------------

local skynet = require("skynet")
local zset = require("zset")
---@type timeUtil
local timeUtil = require("timeUtil")

---@class delayTimerMilLit
local _M = BuildOther("delayTimerMilLit")

function _M:init()
    if self.initTag then
        return
    end

    self.initTag = true
    self.auto = 1
    self.set = zset.new() -- {time, "node.id"}
    self.nodeList = {} -- 保存node, 索引用time
    self.period = 5 -- 定时器间隔周期(默认50毫秒)
    self.running = false
end

function _M:start(period)
    if self.startTag then
        return
    end

    self.startTag = true

    if period then
        self.period = period
    end

    self:run()
end

--- 添加唯一延迟定时器
---@param delayMilliSecond integer 延迟多少毫秒
---@param cb function 定时器回调函数
---@param content any 定时器回调参数
---@param rmTimerId string 添加前需要删除的定时id
---@return string timerId 定时器唯一id
function _M:uniqueDelay(delayMilliSecond, cb, content, rmTimerId)
    if rmTimerId then
        self:removeTimer(rmTimerId)
    end
    return self:delay(delayMilliSecond, cb, content)
end

--- 添加延迟定时器
---@param delayMilliSecond integer 延迟多少毫秒
---@param cb function 定时器回调函数
---@param content any 定时器回调参数
---@return string timerId 定时器唯一id
function _M:delay(delayMilliSecond, cb, content)
    local time = timeUtil.systemMilTime() + delayMilliSecond
    local node = {
        time = time,
        content = content,
        cb = cb
    }

    return self:addTimer(node)
end

--- 添加周期定时器
---@param periodMilliSecond integer 定时器周期间隔
---@param cb function 定时器回调函数
---@param content any 定时器回调参数
---@param firstMilliSecond integer 首次回调间隔
---@return string timerId 定时器唯一id
function _M:every(periodMilliSecond, cb, content, firstMilliSecond)
    firstMilliSecond = firstMilliSecond or periodMilliSecond
    local time = timeUtil.systemMilTime() + firstMilliSecond
    local node = {
        time = time,
        periodMilliSecond = periodMilliSecond,
        firstMilliSecond = firstMilliSecond,
        content = content,
        cb = cb
    }

    return self:addTimer(node)
end

-- 是否存在定时器
---@param timerId string 定时id
function _M:hasTimer(timerId)
    return self.nodeList[timerId] ~= nil
end

-- 添加定时器
function _M:addTimer(node)
    if not node.id then
        node.id = self.auto
        self.auto = self.auto + 1
    end

    local timerId = tostring(node.id)
    if not self.nodeList[timerId] then
        self.nodeList[timerId] = {}
    end
    self.set:add(node.time, timerId)
    self.nodeList[timerId] = node
    return timerId
end

-- 删除
---@param timerId string 定时id
function _M:removeTimer(timerId)
    local node = self.nodeList[timerId]
    if node then
        self.set:rem(timerId) --  删除
        self.nodeList[timerId] = nil
    end
    return node
end

function _M:update()
    if self.set:count() > 0 then
        self.running = true
        local curTime = timeUtil.systemMilTime()
        local rank = self.set:range_by_score(0, curTime)
        for _, timerId in ipairs(rank) do
            local node = self.nodeList[timerId]
            -- callback
            if node then
                local ok, err = xpcall(node.cb, debug.traceback, node.content)
                if not ok then
                    log.Error("sys", "delayTimerMilLit timeout err->", timerId, err, dumpTable(node.content))
                end
                --周期定时器
                local periodMilliSecond = node.periodMilliSecond
                if periodMilliSecond and self.nodeList[timerId] then
                    self:removeTimer(timerId)
                    node.time = node.time + periodMilliSecond
                    self:addTimer(node)
                else
                    self:removeTimer(timerId)
                end
            end
        end
        self.running = false
    end

    self:run() -- 继续定时
end

function _M:run()
    skynet.timeout(self.period, handlerName(self, "update"))
end

function _M:isRun()
    return self.running
end

_M:init()

return _M
