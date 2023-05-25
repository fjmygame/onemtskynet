---------------------------------------------------------------------------------
-- 作者: sgys
-- 时间: 2020-2-20
-- 描述: 周期更新相关
--------------------------------------------------------------------------------
local periodUtil = BuildUtil("periodUtil")

-- type : 周期类型 gPeriodType
-- data.nextTime[下次更新时间]
-- data.value[值]
-- func 默认值方法
-- 推荐数值默认值用0 表则用 func=dailyUtil.empty
-- 每个周期更新时间：offset 默认（每日0点 每周一0点，每月1号0点）
function periodUtil.getValue(type, data, func, offset)
    local curTime = timeUtil.systemTime()
    if not data.nextTime or curTime >= data.nextTime then
        if type == gPeriodType.Daily or type == gPeriodType.DailyFullReset then
            offset = offset and offset * 3600 or 0
            data.nextTime = timeUtil.getTomorrowZeroHourUTC(curTime - offset) + offset
        elseif type == gPeriodType.Weekly then
            offset = offset or gWeekDay.MONDAY
            data.nextTime = timeUtil.getNextWeekDayUTC(offset)
        elseif type == gPeriodType.Monthly then
            offset = offset or 1
            data.nextTime = timeUtil.getNextMonthDayUTC(curTime, offset)
        else
            assert(false, string.safeFormat("period type:%d error.", type))
        end
        if func then
            data.value = func()
        else
            data.value = 0 -- 默认值0
        end
    end
    return data.value, data.nextTime
end

-- 更新value
function periodUtil.setValue(data, value)
    data.value = value
end

-- 空表
function periodUtil.empty()
    return {}
end

return periodUtil
