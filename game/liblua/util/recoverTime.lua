-- --------------------------------
-- Filename: recoverTime.lua
-- Project: util
-- Date: 2020-11-15, 10:52:47 am
-- Author: lxy
-- --------------------------------

--[[
    根据策划要求，给定活动时间，然后就散在这时间里得到的真正的值，
    超过最大值就是最大值，如果跨多天要计算当天通过计算如果小于初始值 第二天是要变成初始值的
    如果超过初始值，第二天就按照超过的初始值来计算
]]
---@class recoverTime
local recoverTime = BuildUtil("recoverTime")
InitalValue(recoverTime, "ONE_DAY", 86400)

--- 获取相差天数
function recoverTime.getDifferDay(oldTime, newTime)
    local oldZeroTime = timeUtil.getTodayZeroHourUTC(oldTime)
    local newZeroTime = timeUtil.getTodayZeroHourUTC(newTime)
    local difDay = math.floor((newZeroTime - oldZeroTime) / recoverTime.ONE_DAY)
    return difDay
end

---@param data RecoverData value, calTime(操作时间)
---@param startTime number  策划配置的每日开始时间(秒)
---@param endTime number  策划配置的每日结束时间(秒)
---@param doingBeginTime number 活动的doing开始时间戳
---@param createTime number 创角时间
---@param orival number 默认次数
---@param max number 最大值
---@param recoverVal number 每个cd恢复次数
function recoverTime.getValue(data, cd, orival, max, doingBeginTime, createTime, startTime, endTime, recoverVal)
    if not doingBeginTime or not createTime then
        log.Error("sys", "getValue doingBeginTime or createTime nil", doingBeginTime, createTime)
    end
    local nTime = timeUtil.systemTime()
    --- 初始化
    if not data.calTime or not data.value then
        local beginZero = timeUtil.getTodayZeroHourUTC(doingBeginTime)
        local nCalTime = beginZero + startTime
        if createTime > nCalTime then
            nCalTime = createTime
        end
        data.calTime = nCalTime
        data.value = orival
    end

    if data.value >= max then
        return data.value
    end

    local calTime = data.calTime
    local oldTime = data.calTime
    if calTime >= nTime then
        return data.value
    end

    local nZeroTime = timeUtil.getTodayZeroHourUTC(nTime)
    local todayEnd = nZeroTime + endTime
    local nEndTime = todayEnd
    local nStartTime = nZeroTime + startTime

    local difDay = recoverTime.getDifferDay(oldTime, nTime)
    if difDay < 0 then
        return data.value
    end

    if nTime < nEndTime then
        nEndTime = nTime
    end

    local difTime = nEndTime - calTime
    -- 如果相差时间还小于cd值
    if difTime < 0 then
        return data.value
    end

    -- log.Dump("gg", difDay, "recoverTime difDay :")
    -- log.Dump("gg", nEndTime, "recoverTime nEndTime :")
    --- 说明是当天的
    if difDay == 0 then
        if nTime < nStartTime then
            if data.value < orival then
                data.value = orival
            end

            data.calTime = nStartTime

            return data.value
        end

        if calTime < nStartTime then
            difTime = nEndTime - nStartTime
        end

        local add = math.floor(difTime / cd) * recoverVal

        local leftTime = math.floor(difTime % cd)
        local nCalTime = nTime - leftTime --difTime会扣掉不在开放时间的部分只能用减法不能用加法

        data.calTime = nCalTime
        if data.value + add > max then
            data.value = max
            data.calTime = 0
            return data.value
        end

        data.value = data.value + add
        if nTime >= todayEnd then
            if data.value < orival then
                data.value = orival
            end

            data.calTime = nStartTime + 86400
        end

        --log.Dump("gg", data, "recoverTime difDay == 0")
        return data.value
    elseif difDay > 0 then
        --- 一开始默认累加值为初始值
        local newVal = data.value
        --- 第一天和今天是比较特殊的
        for i = 0, difDay do
            --- 第一天的话
            if i == 0 then
                local oneZeroTime = timeUtil.getTodayZeroHourUTC(oldTime)
                local oneEndTime = oneZeroTime + endTime
                local oneStartTime = oneZeroTime + startTime

                if calTime <= oneEndTime then
                    local temp = calTime
                    if temp <= oneStartTime then
                        temp = oneStartTime
                        if newVal < orival then
                            newVal = orival
                        end
                    end
                    difTime = oneEndTime - temp
                    local add = math.floor(difTime / cd) * recoverVal
                    if newVal + add < orival then
                        newVal = orival
                        difTime = 0
                    end
                else
                    difTime = 0
                    if newVal < orival then
                        newVal = orival
                    end
                end
            elseif i == difDay then
                if nTime <= nStartTime then
                    if newVal < orival then
                        newVal = orival
                    end
                end

                difTime = nEndTime - nStartTime
                if difTime < 0 then
                    difTime = 0
                end
            else
                --- 小于初始值就直接等于初始值
                if newVal < orival then
                    newVal = orival
                end
                difTime = (endTime - startTime)
            end
            local add = math.floor(difTime / cd) * recoverVal
            newVal = newVal + add
            --- 大于最大值就直接返回最大值
            if newVal >= max then
                newVal = max
                data.calTime = 0
                data.value = max
                return newVal
            end
        end
        -- 如果还是没达到最大值，说明可以继续恢复，那么时间就要记录成刚好cd的那个时间
        --difTime这里可以直接用是因为会走到这一步说明刚好计算到今天，那么上面循环中的difTime就是我要的
        local leftTime = math.floor(difTime % cd)
        local nCalTime = nTime - leftTime
        if nTime >= todayEnd then
            if newVal < orival then
                newVal = orival
            end
            nCalTime = nStartTime + 86400
        end

        if nTime < nStartTime then
            if newVal < orival then
                newVal = orival
            end
            nCalTime = nStartTime
        end

        data.calTime = nCalTime
        data.value = newVal
        --log.Dump("gg", data, "recoverTime difDay ~= 0")
        return newVal
    end
end

--- 扣除次数
--- 注意 调用这个接口前 一定要调用过getvalue，不然数据都没初始化
---@param data RecoverData value, calTime(操作时间)
function recoverTime.reduceValue(data, count, max)
    if count == 0 then
        return true
    end
    if not data.value then
        log.Warn("sys", "recoverTime.reduceValue data is empty table")
        return false
    end

    local newVal = data.value - count
    if newVal < 0 then
        return false
    end

    local nTime = timeUtil.systemTime()
    data.value = newVal

    if data.value < max and data.calTime == 0 then
        data.calTime = nTime
    end

    log.Dump("gg", data, "recoverTime.reduceValue")
    return true, data.value
end

-- 增加次数
---@param data RecoverData value, calTime(操作时间)
function recoverTime.addValue(data, count, max)
    if not data.value then
        log.Warn("sys", "recoverTime.reduceValue data is empty table")
        return
    end
    data.value = data.value + count
    ---- 如果数量是大于最大值的，那要更新时间点，小于就不用更新
    if data.value >= max and data.calTime ~= 0 then
        data.calTime = 0
    end
    log.Dump("gg", data, "recoverTime.addValue")
    return data.value
end

return recoverTime
