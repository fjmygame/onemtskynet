-- --------------------------------------
-- Create Date:2021-12-07 17:44:59
-- Author  : sgys
-- Version : 1.0
-- Filename: autoValueCom.lua
-- Introduce  : 自动加值组件
-- --------------------------------------

local delayTimer = require("delayTimer")
---@class autoValueCom
local _M = class("autoValueCom")
--[[
    param = {
        addValue 添加值
        cd 添加间隔
        endTime 定时器截止时间
        addFunc 添加回调
    }
]]
function _M:ctor(param)
    self.addValue = param.addValue
    self.cd = param.cd
    self.endTime = param.endTime
    self.addFunc = param.addFunc
end

-- 启动
function _M:start()
    local curTime = timeUtil.systemTime()
    local nextTime = curTime + self.cd
    if nextTime < self.endTime then
        self.timerIndex = delayTimer:uniqueDelay(nextTime, handlerName(self, "onAddHandler"), nil, self.timerIndex)
        self.nextTime = nextTime
    end
end

-- 停止
function _M:stop()
    if self.timerIndex then
        delayTimer:removeNode(self.timerIndex)
        self.timerIndex = nil
    end
end

-- 添加值
function _M:onAddHandler()
    self.addFunc(self.addValue)
    -- 下一个定时器
    local nextTime = self.nextTime + self.cd
    if nextTime < self.endTime then
        self.timerIndex = delayTimer:uniqueDelay(nextTime, handlerName(self, "onAddHandler"), nil, self.timerIndex)
        self.nextTime = nextTime
    else
        self.timerIndex = nil
        self.nextTime = nil
    end
end

return _M
