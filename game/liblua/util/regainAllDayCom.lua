-- --------------------------------------
-- Create Date:2022-06-02 10:02:29
-- Author  : Happy Su
-- Version : 1.0
-- Filename: regainAllDayCom.lua
-- Introduce  : 数值恢复(全天候)
-- --------------------------------------
local delayTimer = require("delayTimer")
---@class regainAllDayCom
local _M = class("regainAllDayCom")

local default_init_value = 0

--[[
    data = {
        value = 数值
        calTime = 计算时间,如果规则需要从第一天开始恢复，这里传入活动第一天开始时间！
    }
    param = {
        uid
        id 属性值id
        maxValue 恢复最大值
        recoverySec 多久恢复1次
        recoveryVal 每次恢复点数
        updateFunc 入库函数
        synFunc 同步函数
    }
]]
function _M:ctor(data, param)
    -- 必须字段校验
    assert(data)
    assert(param.uid)
    assert(param.id)
    assert(param.recoverySec and param.recoverySec > 0)
    assert(param.recoveryVal and param.recoveryVal > 0)

    self.data = data
    self.uid = param.uid
    self.id = param.id
    self.initValue = param.initValue -- 每日重置值
    self.maxValue = param.maxValue -- 恢复最大值
    self.recoverySec = param.recoverySec -- 多久恢复1次
    self.recoveryVal = param.recoveryVal -- 每次恢复点数
    self.updateFunc = param.updateFunc -- 入库函数
    self.synFunc = param.synFunc -- 同步函数
    self.logUnUserInfo = param.logUnUserInfo -- 属性变化日志是否不带userData

    -- 初始化 data 是外部值索引。data 内部值有可能外部做修改
    if not data.value then
        data.value = self.initValue or default_init_value
    end
end

function _M:updateMaxValue(maxValue, isCalcTimer)
    self.maxValue = maxValue
    if isCalcTimer then
        self:caculateTimer(true, 1)
    end
end

function _M:getMaxValue()
    return self.maxValue
end

function _M:getRecoverSec()
    return self.recoverySec
end

-- -------------------------------------- 对外函数
-- 开启恢复定时器
function _M:start()
    self:caculateTimer(true, 1)
end

-- 关闭恢复定时器
function _M:stop()
    self:clearTimer()
end

-- 数值变化，外部调用了之后，需要自己调用一次saveDB
function _M:alterValue(alterValue, sourceInfo, bUnSyn)
    local data = self.data
    log.Info("sys", "regainAllDayCom.alterValue 0", alterValue, data.value)
    local newValue = data.value + alterValue
    if newValue < 0 then
        return false
    end

    data.value = newValue

    log.Info("sys", "regainAllDayCom.alterValue 1", alterValue, data.value)

    self:caculateTimer(false, 1)
    log.Info("sys", "regainAllDayCom.alterValue 2", alterValue, data.value)

    if not bUnSyn then
        self:synClient()
    end
    self:writeLog(alterValue, sourceInfo)
    return true
end

-- 取值
function _M:getData()
    return self.data
end

-- 取value
function _M:getValue()
    return self.data.value
end

-- -------------------------------------- 基础函数
-- 入库
function _M:updateDB()
    if self.updateFunc then
        self.updateFunc()
    end
end

-- 通知客户端属性变化
function _M:synClient()
    if self.synFunc then
        self.synFunc(self.data)
    end
end

-- -------------------------------------- 恢复定时器
function _M:clearTimer()
    if self.recoveTimer then
        delayTimer:removeNode(self.recoveTimer)
        self.recoveTimer = nil
    end
end

-- 判断是否满了
function _M:isFull()
    local maxValue = self.maxValue
    if not maxValue or maxValue <= 0 then
        return false
    end

    if maxValue > self.data.value then
        return false
    end

    return true
end

-- 检查恢复的最大值
function _M:checkRecMax(oldValue, recValue, pMaxValue)
    local newValue = oldValue + recValue
    local maxValue = pMaxValue or self.maxValue
    if not maxValue or maxValue <= 0 then --不限制大小
        return false, newValue
    end

    if maxValue <= newValue then --newValue 达到最大值
        newValue = math.max(oldValue, maxValue)
        return true, newValue -- 返回最大值
    end

    return false, newValue -- 返回正常加值
end

function _M:getNextTime()
    -- 如果有nextTime，直接返回
    local recove_sec = self.recoverySec
    local calTime = self.data.calTime
    if not calTime then
        calTime = timeUtil.systemTime()
        self.data.calTime = calTime
        -- TODOS:这里后期观察下
        self:updateDB()
    end

    local nextTime = calTime + recove_sec

    return nextTime
end

-- 计算是否需要定时器
function _M:caculateTimer(bInitTag, calTimes)
    local data = self.data
    -- 如果满了，不再恢复
    if self:isFull() then
        -- 清理恢复信息
        self:clearTimer()
        if data.calTime then
            data.calTime = nil
        end
        return
    end

    -- 如果有timer了，不再计算(之所以放在isfull判断之后，是为了full的时候可以清掉定时器)
    if self.recoveTimer then
        return
    end

    local curTime = timeUtil.systemTime()
    local nextTime = self:getNextTime()
    if not nextTime then
        log.ErrorStack("sys", "nextTime is nil")
        return
    end
    if nextTime <= curTime then
        log.Info(
            "sys",
            string.safeFormat(
                "regainAllDayCom.caculateTimer nextTime:%s curTime:%s calTime:%s",
                nextTime,
                curTime,
                data.calTime
            )
        )
        self:onRecoveTimer(bInitTag, calTimes)
    else
        self.recoveTimer =
            delayTimer:uniqueDelay(nextTime, handlerName(self, "onRecoveTimerHandler"), nil, self.recoveTimer)
    end

    return
end

-- 处理定时器到期
function _M:onRecoveTimer(bInitTag, calTimes)
    calTimes = (calTimes or 1) + 1
    if calTimes > 20 then
        log.ErrorStack("sys", "regainAllDayCom.onRecoveTimer stack out")
        return
    end
    local curTime = timeUtil.systemTime()
    local dayZeroTime = timeUtil.getTodayZeroHourUTC()
    local data = self.data
    local calTime = data.calTime
    local bNeedSyn = false
    log.Info("sys", "regainAllDayCom.onRecoveTimer bInitTag", curTime, dayZeroTime, bInitTag)

    -- 如果没有calTime，说明满了，直接返回
    if not calTime then
        if not bInitTag and bNeedSyn then
            self:updateDB()
            self:synClient()
        end
        return
    end

    local oldValue = data.value
    local isSucc, newCalTime, newValue, bFull = self:calcValue(curTime, calTime, self.maxValue)
    if isSucc then
        data.calTime = newCalTime
        data.value = newValue
        if bFull then
            data.calTime = nil
        end
        bNeedSyn = true
        self:writeLog(data.value - oldValue, {source = gItemSource.TIME_RESTORE})
    end

    if not bInitTag and bNeedSyn then
        self:updateDB()
        self:synClient()
    end

    -- 检查下是否需要继续添加定时器
    self:caculateTimer(bInitTag, calTimes)
end

function _M:calcValue(curTime, calTime, max)
    local oldValue, recoverSec, recoverVal = self:getValue(), self.recoverySec, self.recoveryVal
    -- 计算下这次恢复的数值
    local passTime = curTime - calTime
    if passTime >= recoverSec then
        local recTimes = (passTime // recoverSec)
        local recValue = recTimes * recoverVal
        local newCalTime = calTime + recTimes * recoverSec
        local bFull, newValue = self:checkRecMax(oldValue, recValue, max)
        return true, newCalTime, newValue, bFull
    end
    return false, calTime, oldValue, self:isFull()
end

function _M:onRecoveTimerHandler(node)
    -- 定时器到期，先清理定时器标记
    self.recoveTimer = nil

    self:onRecoveTimer(false, 1)
end

-- 写日志
function _M:writeLog(change, sourceinfo)
    if self.logUnUserInfo then
        dataCenterLogAPI.writeAttrLogNoUserInfo(self.uid, self.id, change, self.data.value, sourceinfo)
    else
        dataCenterLogAPI.writeAttrLog(self.uid, self.id, change, self.data.value, sourceinfo)
    end
end

return _M
