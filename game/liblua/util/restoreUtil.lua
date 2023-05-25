--------------------------------------------------------------------------------
-- 文件: restoreUtil.lua
-- 作者: zkb
-- 时间: 2019-11-26 16:58:54
-- 描述: 恢复[固定时间间隔恢复值]
--------------------------------------------------------------------------------
local restoreUtil = BuildUtil("restoreUtil")

-- calcTime: 结算时间，默认当前时间
function restoreUtil.getValue(data, cd, max, calcTime)
    if not data.nextTime then -- 初始化
        data.nextTime = 0
        data.value = max
        return max
    end
    if data.nextTime == 0 then
        return data.value
    end

    local curTime = calcTime or timeUtil.systemTime()
    local nextTime = data.nextTime
    -- 不需要增加次数了
    if nextTime > curTime then -- 时间没到
        return data.value
    end

    local passTime = curTime - nextTime -- 超过的时间
    local count = math.floor(passTime / cd) + 1

    local oldVal = data.value
    data.value = data.value + count
    if data.value >= max then
        data.value = max
        data.nextTime = 0
    else
        -- 重新生成下一次事件
        local pass = math.fmod(passTime, cd) -- 下一次已经走过的时间
        data.nextTime = curTime + cd - pass -- 当前时间 + 还要多久[一次时间-已过时间]
    end
    return data.value, oldVal
end

-- 外部力量增加值
function restoreUtil.addValue(data, count, max)
    data.value = data.value + count
    if data.value >= max then
        data.nextTime = 0
    end
end

-- 回满
function restoreUtil.restoreFull(data, max)
    if data.value >= max then
        return
    end
    local oldVal = data.value
    data.value = max
    data.nextTime = 0
    return oldVal
end

-- 消耗值
function restoreUtil.delValue(data, count, cd, max, calcTime)
    data.value = data.value - count
    if data.value < max and data.nextTime == 0 then
        -- 生成下一次恢复次数时间
        local curTime = calcTime or timeUtil.systemTime()
        data.nextTime = curTime + cd
    end
    return data.value
end

return restoreUtil
