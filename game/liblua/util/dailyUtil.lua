---------------------------------------------------------------------------------
-- 作者: zkb
-- 时间: 2019-3-16
-- 描述: 每日更新相关
--------------------------------------------------------------------------------
---@class dailyUtil
local dailyUtil = BuildUtil("dailyUtil")

-- data.nextTime[下次更新时间]
-- data.value[值]
-- func 默认值方法
-- 推荐数值默认值用0 表则用 func=dailyUtil.empty
-- 每日更新时间：offsetTime 默认值为0点
function dailyUtil.getValue(data, func, offsetTime)
    local curTime = timeUtil.systemTime()
    if not data.nextTime or curTime >= data.nextTime then
        offsetTime = offsetTime and offsetTime or 0
        data.nextTime = timeUtil.getTomorrowZeroHourUTC(curTime - offsetTime) + offsetTime -- 明天0点
        if func then
            data.value = func()
        else
            data.value = 0 -- 默认值0
        end
    end
    return data.value, data.nextTime
end

-- 更新value
function dailyUtil.setValue(data, value)
    data.value = value
end

-- 空表
function dailyUtil.empty()
    return {}
end

return dailyUtil
