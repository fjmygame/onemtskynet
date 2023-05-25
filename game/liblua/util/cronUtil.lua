-- --------------------------------------
-- Create Date:2021-04-17 11:04:01
-- Author  : tangheng
-- Version : 1.0
-- Filename: cronUtil.lua
-- Introduce  : 类介绍
-- --------------------------------------
local delayTimer = require("delayTimer")
---@class cronUtil
local cronUtil = BuildUtil("cronUtil")

-- ------------------ 变量初始化 ------------------
local taskTimers = CreateBlankTable(cronUtil, "taskTimers")
InitalValue(cronUtil, "auto", 0)

-- ------------------ 函数开始 ------------------
function cronUtil.genTaskId()
    cronUtil.auto = cronUtil.auto + 1
    return cronUtil.auto
end

function cronUtil.addDailyTask(atTime, deleteTime, func, param)
    if not func or not atTime then
        log.Error("sys", "cronUtil:addDailyTask input err", debug.traceback())
        return
    end
    local curTime = timeUtil.systemTime()
    local nextTime = timeUtil.getTodayZeroHourUTC(curTime) + atTime
    if curTime > nextTime then
        nextTime = nextTime + 86400
    end

    if deleteTime and nextTime >= deleteTime then
        return
    end

    local taskId = cronUtil.genTaskId()

    local content = {
        taskId = taskId,
        atTime = atTime,
        func = func,
        deleteTime = deleteTime,
        param = param,
        triggerTime = nextTime
    }
    local handle = function()
        cronUtil.dailyTimeout(content)
    end

    local timer = delayTimer:delay(nextTime, handle)
    taskTimers[taskId] = timer
    return taskId
end

function cronUtil.dailyTimeout(content)
    local func = content.func
    if not func then
        log.Error("sys", "cronUtil:timeout err1", content)
        return
    end

    -- 先计算下个子状态切换时间
    local curTime = timeUtil.systemTime()
    local nextTime = timeUtil.getTodayZeroHourUTC(curTime) + content.atTime
    if curTime >= nextTime then
        nextTime = nextTime + 86400
    end

    func(content.param, nextTime, content.triggerTime)

    local taskId = content.taskId
    local deleteTime = content.deleteTime
    if deleteTime and curTime > deleteTime then
        log.Info("sys", "cronUtil:timeout delete", content)
        taskTimers[taskId] = nil
        return
    end

    if deleteTime and nextTime >= deleteTime then
        taskTimers[taskId] = nil
        return
    end

    if not taskTimers[taskId] then
        return
    end

    content.triggerTime = nextTime
    local handle = function()
        cronUtil.dailyTimeout(content)
    end

    local timer = delayTimer:delay(nextTime, handle)
    taskTimers[taskId] = timer
end

function cronUtil.closeTask(taskId)
    if not taskId then
        log.Error("sys", "cronUtil.closeTask taskId is nil")
        return
    end

    local timer = taskTimers[taskId]
    if not timer then
        return
    end

    taskTimers[taskId] = nil
    delayTimer:removeNode(timer)
end

return cronUtil
