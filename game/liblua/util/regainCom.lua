-- --------------------------------------
-- Create Date:2021-09-07 19:23:29
-- Author  : Happy Su
-- Version : 1.0
-- Filename: regainCom.lua
-- Introduce  : 数值恢复(有玩法时间)
-- --------------------------------------
---@type agentPoolApi
local agentPoolApi = require("agentPoolApi")
local delayTimer = require("delayTimer")
---@class regainCom
local _M = class("regainCom")

local default_init_value = 0

local dayResetTypeCfg =
    CreateBlankTable(
    _M,
    "dayResetTypeCfg",
    {
        reset = 1, -- 重置到初始值
        resetLow = 2, -- 重置低于初始值
        noReset = 3 -- 不重置
    }
)

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
        dayStart/dayOver 什么范围内恢复
        dayResetType 跨天是否重置
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
    self.dayStart = param.dayStart or 0 -- 每日开始时间 秒数
    self.dayOver = param.dayOver or 86400 -- 每日结束时间 秒数
    self.triggerId = param.triggerId
    self.triggerTimelen = param.triggerTimelen
    self.actid = param.actid

    self:checkTriggerGift()

    if self.dayOver - self.dayStart >= 86400 then
        log.ErrorStack("sys", "使用了错误的组件", self.dayStart, self.dayOver)
    end

    self.dayResetType = param.dayResetType or dayResetTypeCfg.reset -- 跨天是否重置
    self.updateFunc = param.updateFunc -- 入库函数
    self.synFunc = param.synFunc -- 同步函数
    self.logUnUserInfo = param.logUnUserInfo -- 属性变化日志是否不带userData

    -- 初始化
    if not data.value then
        data.value = self.initValue or default_init_value
    end
end

function _M:setRecoverExVal(val)
    self.recoveryExVal = val
end

function _M:getRecoverVal()
    return self.recoveryVal + (self.recoveryExVal or 0)
end

-- -------------------------------------- 对外函数
-- 开启恢复定时器
function _M:start()
    self:caculateTimer(true, 1)

    local nextZeroTime = timeUtil.getTomorrowZeroHourUTC()
    self.dayZeroTimer =
        delayTimer:uniqueDelay(nextZeroTime, handlerName(self, "onDayZeroHandler"), nil, self.dayZeroTimer)
end

-- 关闭恢复定时器
function _M:stop()
    self:clearTimer()
    if self.dayZeroTimer then
        delayTimer:removeNode(self.dayZeroTimer)
        self.dayZeroTimer = nil
    end
end

-- 触发礼包配置验证[触发礼包和触发时间、活动id必须配套]
function _M:checkTriggerGift()
    if self.triggerId and self.triggerId > 0 then
        if self.triggerTimelen and self.triggerTimelen > 0 and self.actid then
            return true
        else
            log.ErrorStack(
                "sys",
                "regainCom param.triggerTimelen or actid is error",
                self.uid,
                self.triggerId,
                self.triggerTimelen,
                self.actid
            )
        end
    end
    return false
end

-- 数值变化，外部调用了之后，需要自己调用一次saveDB
function _M:alterValue(alterValue, sourceInfo, bUnSyn)
    local data = self.data
    log.Info("sys", "regainCom.alterValue 0", self.uid, self.id, alterValue, data.value)
    local newValue = data.value + alterValue
    if newValue < 0 then
        return false
    end

    data.value = newValue

    -- 消耗值统计
    if alterValue < 0 then
        data.totalCost = (data.totalCost or 0) + math.abs(alterValue)

        -- 体力减到0时生成触发礼包
        if self:checkTriggerGift() then
            if newValue == 0 and not data.triggerTag then
                data.triggerTag = true
                -- 给玩家发触发礼包
                agentPoolApi.sendAgentCtrl(
                    self.uid,
                    gModuleDef.triggerGiftCtrl,
                    "add",
                    self.triggerId,
                    self.triggerTimelen,
                    self.actid
                )
                log.Info("sys", "regainCom.add trigger gift", self.triggerId, self.triggerTimelen, self.actid)
            end
        end
    end

    log.Info("sys", "regainCom.alterValue 1", alterValue, data.value)

    self:caculateTimer(false, 1)
    log.Info("sys", "regainCom.alterValue 2", alterValue, data.value)
    -- log.Dump("sys", self, "regainCom.self")

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

-- 取totalCost
function _M:getTotalCost()
    return self.data.totalCost or 0
end

-- -------------------------------------- 基础函数
-- 获取指定日期恢复开始时间
function _M:getStartTime(time)
    local dayZeroTime = timeUtil.getTodayZeroHourUTC(time)
    return dayZeroTime + self.dayStart
end

-- 获取指定日期恢复结束时间
function _M:getOverTime(time)
    local dayZeroTime = timeUtil.getTodayZeroHourUTC(time)
    return dayZeroTime + self.dayOver
end

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
function _M:checkRecMax(oldValue, recValue)
    local newValue = oldValue + recValue
    local maxValue = self.maxValue
    if not maxValue or maxValue <= 0 then
        return false, newValue
    end

    if maxValue <= newValue then
        newValue = math.max(oldValue, maxValue)
        return true, newValue
    end

    return false, newValue
end

function _M:getNextTime()
    -- 如果有nextTime，直接返回
    local recove_sec = self.recoverySec
    local calTime = self.data.calTime
    local startTime = self:getStartTime(calTime)
    if not calTime then
        -- 如果startTime还未到，使用startTime(活动开始计时)。 如果超过startTime（curTime-startTime）这段时间丢掉了，体力恢复不满足开始时间起计时。
        local curTime = timeUtil.systemTime()
        calTime = math.max(curTime, startTime)
        self.data.calTime = calTime
        -- TODOS:这里后期观察下
        self:updateDB()
    end

    local nextTime = calTime + recove_sec
    local overTime = self:getOverTime(calTime)
    if nextTime > overTime then
        nextTime = startTime + 86400
    end

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
        if data.calTime then
            return
        else
            self:clearTimer()
        end
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
            string.safeFormat("caculateTimer nextTime:%s curTime:%s calTime:%s", nextTime, curTime, data.calTime)
        )
        self:onRecoveTimer(bInitTag, calTimes)
    else
        self.recoveTimer =
            delayTimer:uniqueDelay(nextTime, handlerName(self, "onRecoveTimerHandler"), nil, self.recoveTimer)
    end

    return
end

-- 处理每日刷新
function _M:dayRefresh()
    local data = self.data
    -- 体力是满的
    if data.calTime and data.calTime > timeUtil.systemTime() then
        log.Error("sys", "dayRefresh err", self.uid, dumpTable(data, "data", 10))
        return false
    end
    local oldValue = data.value
    -- 跨天重置
    local dayResetType = self.dayResetType
    if dayResetType == dayResetTypeCfg.reset then -- 跨天必须重置
        data.value = self.initValue or default_init_value
        if self:isFull() then
            data.calTime = nil
        else
            -- 给calTime赋值
            -- 跨天必须重置的，就没有必要一天天计算了
            -- 判断下当前时间是否小于今日开始结束时间
            local curTime = timeUtil.systemTime()
            local overTime = self:getOverTime()
            if curTime < overTime then
                data.calTime = self:getStartTime()
            else
                data.calTime = self:getStartTime() + 86400
            end
        end
    else -- 2.小于初始值重置  3.完全不重置
        -- 如果跨天不重置，则计算一下恢复时间
        local recoverySec = self.recoverySec
        local calTime = data.calTime
        if calTime then
            local overTime = self:getOverTime(calTime)
            local passTime = overTime - calTime
            -- 当天的时间够恢复一次以上数值
            if passTime >= recoverySec then
                local recValue = (passTime // recoverySec) * self:getRecoverVal()
                local _, newValue = self:checkRecMax(data.value, recValue)
                data.value = newValue
            end
        end
        -- 如果值小于初始值，需要重置的，处理下
        if dayResetType == dayResetTypeCfg.resetLow then
            local initValue = self.initValue or default_init_value
            data.value = math.max(initValue, data.value)
        end
        -- 计算时间重置为第二天
        if self:isFull() then
            data.calTime = nil
        else
            data.calTime = self:getStartTime(calTime) + 86400
        end
    end
    self:writeLog(data.value - oldValue, {source = gItemSource.NEW_DAY_RESET})

    return true
end

-- 处理定时器到期
function _M:onRecoveTimer(bInitTag, calTimes)
    calTimes = (calTimes or 1) + 1
    if calTimes > 20 then
        log.ErrorStack("sys", "onRecoveTimer stack out")
        return
    end
    local curTime = timeUtil.systemTime()
    local dayZeroTime = timeUtil.getTodayZeroHourUTC()
    local data = self.data
    local calTime = data.calTime
    local bNeedSyn = false
    log.Info("sys", "onRecoveTimer bInitTag", self.uid, self.id, curTime, dayZeroTime, bInitTag)
    -- 先看是否跨天
    while calTime and calTime <= dayZeroTime do
        if self:dayRefresh() then
            bNeedSyn = true
        end
        -- 重新获取一下calTime
        calTime = data.calTime
    end

    -- 如果没有calTime，说明满了，直接返回
    if not calTime then
        if not bInitTag and bNeedSyn then
            self:updateDB()
            self:synClient()
        end
        return
    end
    local oldValue = data.value
    -- 今日结束时间
    local overTime = self:getOverTime()
    -- 计算下这次恢复的数值
    local recove_sec = self.recoverySec
    local newCalTime = math.min(overTime, curTime)
    local passTime = newCalTime - calTime
    if passTime >= recove_sec then
        local recTimes = (passTime // recove_sec)
        local recValue = recTimes * self:getRecoverVal()
        newCalTime = calTime + recTimes * recove_sec
        data.calTime = newCalTime
        local bFull, newValue = self:checkRecMax(data.value, recValue)
        data.value = newValue
        if bFull then
            data.calTime = nil
        end
        bNeedSyn = true
        self:writeLog(data.value - oldValue, {source = gItemSource.TIME_RESTORE})
    end

    log.Info(
        "sys",
        string.safeFormat(
            "onRecoveTimer complete uid:%s id:%s curTime:%s dayZeroTime:%s bInit:%s bNeedSyn:%s oldValue:%s newValue:%s ",
            self.uid,
            self.id,
            curTime,
            dayZeroTime,
            bInitTag,
            bNeedSyn,
            oldValue,
            data.value
        )
    )

    if not bInitTag and bNeedSyn then
        self:updateDB()
        self:synClient()
    end

    -- 检查下是否需要继续添加定时器
    self:caculateTimer(bInitTag, calTimes)
end

function _M:onRecoveTimerHandler(node)
    -- 定时器到期，先清理定时器标记
    self.recoveTimer = nil

    self:onRecoveTimer(false, 1)
end

function _M:onDayZeroHandler(node)
    local curTime = timeUtil.systemTime()
    local nextZeroTime = timeUtil.getTomorrowZeroHourUTC(curTime + 10)
    log.Info("sys", "onDayZeroHandler:", os.date("%Y-%m-%d %X", curTime), os.date("%Y-%m-%d %X", nextZeroTime))
    self.dayZeroTimer =
        delayTimer:uniqueDelay(nextZeroTime, handlerName(self, "onDayZeroHandler"), nil, self.dayZeroTimer)

    self:dayRefresh()
    self:updateDB()
    self:synClient()
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
