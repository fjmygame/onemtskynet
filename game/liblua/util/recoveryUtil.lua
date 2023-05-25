--------------------------------------------------------------------------------
-- 文件: recoveryUtil.lua
-- 作者: zkb
-- 时间: 2019-11-26 16:58:54
-- 描述: 恢复[固定时间间隔恢复值]
--------------------------------------------------------------------------------
---@class recoveryUtil
local recoveryUtil = BuildUtil("recoveryUtil")

--[[
    注意：调用这个里面的接口，增删查一定都要用到这里面的接口
]]
function recoveryUtil.getValue(data, cd, max, oriVal, defaultStartTime)
    ---- 这里如果大的话直接返回是因为可以如果是道具导致的，是可以无限叠加的
    if data.value and data.value >= max then
        return data.value
    end
    local curTime = timeUtil.systemTime()
    ---- 下一次更新时间
    local flushTime = timeUtil.getWeehoursUTC() + 86400
    if not data.nextTime then -- 初始化
        data.nextTime = defaultStartTime + cd
        data.flushTime = flushTime
        data.value = oriVal
    -- return oriVal
    end
    ---- 等于跨天更新到初始值
    if data.flushTime and data.flushTime <= curTime then
        data.flushTime = flushTime
        data.nextTime = defaultStartTime + cd
        data.value = oriVal
    -- return oriVal
    end
    local nextTime = data.nextTime
    -- 不需要增加次数了
    if nextTime > curTime then -- 时间没到
        return data.value
    end

    local passTime = curTime - nextTime -- 超过的时间
    local count = math.floor(passTime / cd) + 1
    local oldVal = data.value
    data.value = data.value + count
    ----- 这里是因为是通过实践计算的，这里的话就是自然恢复，最大不能超过最大值
    -- 重新生成下一次事件
    if data.value < max then
        local pass = math.fmod(passTime, cd) -- 下一次已经走过的时间
        data.nextTime = curTime + cd - pass -- 当前时间 + 还要多久[一次时间-已过时间]
        return data.value, oldVal
    else
        data.nextTime = 0
        data.value = max
        return max, oldVal
    end
end

----- 获取数据，不用刷新，超过最大值就返回当前值就用这个接口

function recoveryUtil.getValueNotFlush(data, cd, max, oriVal)
    if data.value and data.value >= max then
        return data.value
    end
    local curTime = timeUtil.systemTime()
    if not data.nextTime then -- 初始化
        data.nextTime = curTime + cd
        data.value = oriVal
        return oriVal
    end
    local nextTime = data.nextTime
    -- 不需要增加次数了
    if nextTime > curTime then -- 时间没到
        return data.value
    end

    local passTime = curTime - nextTime -- 超过的时间
    local count = math.floor(passTime / cd) + 1
    local oldVal = data.value
    data.value = data.value + count
    if data.value < max then
        ----- 这里是因为是通过实践计算的，这里的话就是自然恢复，最大不能超过最大值
        -- 重新生成下一次事件
        local pass = math.fmod(passTime, cd) -- 下一次已经走过的时间
        data.nextTime = curTime + cd - pass -- 当前时间 + 还要多久[一次时间-已过时间]
        return data.value, oldVal
    else
        data.value = max
        data.nextTime = 0
        return max, oldVal
    end
end

-- 外部力量增加值
function recoveryUtil.addValue(data, count, max)
    data.value = data.value + count
    if data.value >= max then
        data.nextTime = 0
    end
    return data.value
end

-- 回满
function recoveryUtil.restoreFull(data, max)
    if data.value >= max then
        return
    end
    local oldVal = data.value
    data.value = max
    data.nextTime = 0
    return oldVal
end

-- 消耗值
function recoveryUtil.delValue(data, count, cd, max)
    data.value = data.value - count
    if data.value < max and data.nextTime == 0 then
        -- 生成下一次恢复次数时间
        local curTime = timeUtil.systemTime()
        data.nextTime = curTime + cd
    end
    return data.value
end

--- 直接设置count 和nextTime
function recoveryUtil.setValue(data, count, nextTime)
    data.value = count
    data.nextTime = nextTime
end

return recoveryUtil
