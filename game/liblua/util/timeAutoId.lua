-- --------------------------------------
-- Create Date:2023-04-18 10:22:38
-- Author  : Happy Su
-- Version : 1.0
-- Filename: timeAutoId.lua
-- Introduce  : 根据时间生成的唯一id
-- id规则：
--      时间戳*100+递增编号，当递增编号>99时，tonumber(时间戳 .. 递增编号)
-- --------------------------------------
---@class timeAutoId
local _M = class("timeAutoId")

function _M:ctor()
    self.curTime = 0
    self.idx = 0
end

function _M:genId()
    local curTime = timeUtil.systemTime()
    -- 时间回滚的情况，用组件里的当前时间
    if self.curTime > curTime then
        log.ErrorStack("sys", "时间回滚了", self.curTime, curTime)
        curTime = self.curTime
    end

    if self.curTime == curTime then
        local idx = self.idx + 1
        self.idx = idx
        if idx > 99 then
            return tonumber(self.curTime .. idx)
        else
            return self.curTime * 100 + idx
        end
    else
        self.curTime = curTime
        self.idx = 0
        return self.curTime * 100
    end
end

return _M
