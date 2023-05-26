-- --------------------------------
-- Filename: timeUtil.lua
-- Project: util
-- Date: 2020-02-13, 3:16:58 pm
-- Author: lxy
-- --------------------------------
--[[
    时间相关接口
]]
local skynet = require("skynet")

---@class timeUtil
local timeUtil = BuildUtil("timeUtil")

local function getStarttime()
    return skynet.starttime()
end

-- 获取系统时间
function timeUtil.systemTime()
    return math.floor(getStarttime() + skynet.now() / 100)
end

-- 毫秒（实际精度只有0.01秒）
function timeUtil.systemMilTime()
    return getStarttime() * 1000 + skynet.now() * 10
end

-- 获取系统时间[警告:这个接口仅限于文件require初始化脚本解析的时候用，正常情况用timeUtil.systemTime()]
function timeUtil.skynetSysTime()
    return math.floor(skynet.time())
end

--系统时间是否达到凌晨0点
function timeUtil.isInWeehours()
    local ret = false
    local systemTime = timeUtil.systemTime()
    local hour = os.date("%H", systemTime)
    local minute = os.date("%M", systemTime)
    local second = os.date("%S", systemTime)
    if hour == "00" and minute == "00" and second == "00" then
        ret = true
    end
    return ret
end

--系统时间是否达到周一凌晨0点
function timeUtil.isInSundayWeehours()
    local ret = false
    local systemTime = timeUtil.systemTime()
    local week = os.date("%A", systemTime)
    local isInWeehours = timeUtil.isInWeehours()
    if isInWeehours and week == "Monday" then
        ret = true
    end
    return ret
end

--获取当前时间0点时刻的UTC时间
function timeUtil.getWeehoursUTC()
    local tb = os.date("*t", timeUtil.systemTime())
    tb.hour = 0
    tb.min = 0
    tb.sec = 0
    local weehoursutc = os.time(tb)
    return weehoursutc
end

function timeUtil.getUTC0(time)
    time = time or timeUtil.systemTime()
    local tb = os.date("!*t", time)
    local weehoursutc = os.time(tb)
    return weehoursutc
end

--获取当前时间0点UTC0的时间
function timeUtil.getZeroHourUTC0(time)
    time = time or timeUtil.systemTime()
    local tb = os.date("!*t", time)
    tb.hour = 0
    tb.min = 0
    tb.sec = 0
    local weehoursutc = os.time(tb)
    return weehoursutc
end

--将字符串的时间格式转化为ostime
function timeUtil.convertStrTime2OsTime(strtime)
    local year, month, day, hour, min, sec = string.match(strtime, "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
    local tb = {
        year = year,
        month = month,
        day = day,
        hour = hour,
        min = min,
        sec = sec
    }
    return os.time(tb)
end

--获取和当前时间的差值
function timeUtil.getTimeDiffWithCurTime(year, month, day, hour, min, sec)
    local tab = {
        year = year or 2015,
        month = month or 1,
        day = day or 1,
        hour = hour or 0,
        min = min or 0,
        sec = sec or 0,
        isdst = false
    }
    local time1 = os.time(tab)
    local time = timeUtil.systemTime()
    return time1 - time
end

-- 获取星期天数
--[[
    星期一：1
    星期二：2
    星期三：3
    星期四：4
    星期五：5
    星期六：6
    星期天：7
--]]
function timeUtil.getWeekDay(time)
    time = time or timeUtil.systemTime()
    local weekDay = tonumber(os.date("%w", time))
    weekDay = (weekDay == 0) and 7 or weekDay
    return tonumber(weekDay)
end

-- 获取上个小时开始时的UTC
function timeUtil.getPreHourUTC(time)
    time = time or timeUtil.systemTime()
    local m = tonumber(os.date("%M", time))
    local s = tonumber(os.date("%S", time))
    return time - (m * 60 + s)
end

-- 获取下个小时开始时的UTC
function timeUtil.getNextHourUTC(time)
    time = time or timeUtil.systemTime()
    local m = tonumber(os.date("%M", time))
    local s = tonumber(os.date("%S", time))
    return time + ((59 - m) * 60 + (60 - s))
end

--[[
    获取下个星期的UTC零时

    -- 星期
    gWeekDay = {
        MONDAY = 1,
        TUESDA = 2,
        WEDNESDAY = 3,
        THURSDAY = 4,
        FRIDAY = 5,
        SATURDAY = 6,
        SUNDAY = 7,
    }
--]]
function timeUtil.getNextWeekDayUTC(nextWeekDay)
    nextWeekDay = nextWeekDay or gWeekDay.MONDAY
    local secOfOneDay = 24 * 60 * 60
    return timeUtil.getCurWeekDayUTC(nextWeekDay) + secOfOneDay * gWeekDay.SUNDAY
end

--[[
    获取上个星期的UTC零时

    -- 星期
    gWeekDay = {
        MONDAY = 1,
        TUESDA = 2,
        WEDNESDAY = 3,
        THURSDAY = 4,
        FRIDAY = 5,
        SATURDAY = 6,
        SUNDAY = 7,
    }
--]]
function timeUtil.getPreWeekDayUTC(preWeekDay)
    local secOfOneDay = 24 * 60 * 60
    return timeUtil.getCurWeekDayUTC(preWeekDay) - secOfOneDay * gWeekDay.SUNDAY
end

--[[
    -- 获取本周的UTC零时
]]
function timeUtil.getCurWeekDayUTC(weekDay)
    if "number" ~= type(weekDay) or weekDay < 1 or weekDay > 7 then
        return nil
    end
    -- 获取当前时间第二天 00:00:00 时的秒数
    local sec0 = timeUtil.getTodayZeroHourUTC()
    local secOfOneDay = 24 * 60 * 60

    local curWeekDay = timeUtil.getWeekDay(sec0)
    return sec0 + secOfOneDay * (weekDay - curWeekDay)
end

function timeUtil.getYesterdayWeekDay()
    local weekDay = timeUtil.getWeekDay()
    if weekDay == 1 then
        return 7
    else
        return weekDay - 1
    end
end

-- 两个时间对比，是否在同一天
-- time2 默认为当前时间
function timeUtil.isSameDay(time1, time2)
    time2 = time2 or timeUtil.systemTime()

    local day1 = os.date("%d", time1)
    local day2 = os.date("%d", time2)
    if day1 ~= day2 then
        return false
    end

    local mon1 = os.date("%m", time1)
    local mon2 = os.date("%m", time2)
    if mon1 ~= mon2 then
        return false
    end

    local year1 = os.date("%Y", time1)
    local year2 = os.date("%Y", time2)
    if year1 ~= year2 then
        return false
    end

    return true
end

-- 两个时间对比，是否在同一周
-- time2 默认为当前时间
function timeUtil.isSameWeek(time1, time2)
    time2 = time2 or timeUtil.systemTime()

    local week1 = os.date("%W", time1)
    local week2 = os.date("%W", time2)
    if week1 ~= week2 then
        return false
    end

    local year1 = os.date("%Y", time1)
    local year2 = os.date("%Y", time2)
    if year1 ~= year2 then
        return false
    end

    return true
end

-- 获取某一个时刻N天前的时刻
function timeUtil.getDayBeforeTime(time, day)
    return time - day * 24 * 60 * 60
end

function timeUtil.getDayAfterTime(time, day)
    return time + day * 24 * 60 * 60
end

-- 获取某一时间当天零时UTC
function timeUtil.getTodayZeroHourUTC(time)
    time = time or timeUtil.systemTime()
    -- 获取当前时间的时分秒
    local h = tonumber(os.date("%H", time))
    local m = tonumber(os.date("%M", time))
    local s = tonumber(os.date("%S", time))
    return time - (h * 3600 + m * 60 + s)
end

-- 获取某一天过了几秒UTC
function timeUtil.getTodayPassSecUTC(time)
    time = time or timeUtil.systemTime()
    -- 获取当前时间的时分秒
    local h = tonumber(os.date("%H", time))
    local m = tonumber(os.date("%M", time))
    local s = tonumber(os.date("%S", time))
    return h * 3600 + m * 60 + s
end

-- 获取某一时间第二天零时UTC
function timeUtil.getTomorrowZeroHourUTC(time)
    time = time or timeUtil.systemTime()
    -- 获取当前时间的时分秒
    local h = tonumber(os.date("%H", time))
    local m = tonumber(os.date("%M", time))
    local s = tonumber(os.date("%S", time))
    return time + ((23 - h) * 3600 + (59 - m) * 60 + (60 - s))
end

-- 当前月某一天的utc零时
function timeUtil.getCurMonthDayUTC(time, monthDay)
    time = time or timeUtil.systemTime()
    local year = tonumber(os.date("%Y", time))
    local month = tonumber(os.date("%m", time))
    -- 默认每月1号
    if not monthDay then
        monthDay = 1
    end
    return os.time({year = year, month = month, day = monthDay, hour = 0})
end

function timeUtil.getNextMonthDayUTC(time, monthDay)
    time = time or timeUtil.systemTime()
    local year = tonumber(os.date("%Y", time))
    local month = tonumber(os.date("%m", time))
    if month < 12 then
        month = month + 1
    else
        month = 1
        year = year + 1
    end
    -- 默认每月1号
    if not monthDay then
        monthDay = 1
    end
    return os.time({year = year, month = month, day = monthDay, hour = 0})
end

-- 两个时间对比，是否是连续的两天
function timeUtil.differOneDay(time1, time2)
    -- 检查参数
    if not time1 then
        return
    end
    -- time2 默认当前时间
    time2 = time2 or timeUtil.systemTime()
    -- time1 一定要比 time2 小
    if time1 > time2 then
        time1, time2 = time2, time1
    end

    -- 1.判断今日是否已经登陆
    local ret = timeUtil.isSameDay(time1, time2)
    if ret then
        return false, 0
    end

    -- 判断两个时间相差是否超过一天
    -- 获取当前时间的时分秒
    local h = os.date("%H", time2)
    local m = os.date("%M", time2)
    local s = os.date("%S", time2)
    -- 获取 time2 00:00:00时的秒数
    local sec0 = time2 - (h * 3600 + m * 60 + s)
    -- 上次登陆到今日零时，经过的秒数
    local passSecond = sec0 - time1
    -- 判断秒数是否超过一天
    local secOfOneDay = 24 * 60 * 60
    if passSecond <= secOfOneDay then
        -- 不超过一天，是连续的两天
        return true, 1
    else
        -- 超过一天，非连续的两天
        return false, math.ceil(passSecond / secOfOneDay)
    end
end

-- 将字符串的时间格式转化为时间戳
-- 字符串格式 2015_10_08_09_00_00
-- 字符串格式2 2015-10-08 09:00:00
function timeUtil.convertStrTime2Timestamp(strtime)
    local year, month, day, hour, min, sec = string.match(strtime, "(%d+)_(%d+)_(%d+)_(%d+)_(%d+)_(%d+)")
    if not year then
        year, month, day, hour, min, sec = string.match(strtime, "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
    end
    local tb = {
        year = year,
        month = month,
        day = day,
        hour = hour,
        min = min,
        sec = sec
    }
    return os.time(tb)
end

-- 获取当前日期
function timeUtil.getCurDayInYear(time)
    if not time then
        time = timeUtil.systemTime()
    end
    local temp = os.date("*t", time)
    return temp.day
end

-- 获取当前日期
function timeUtil.getCurDate(time)
    if not time then
        -- time = os.time()
        time = timeUtil.systemTime()
    end

    -- 判断两个时间相差是否超过一天
    -- 获取当前时间的时分秒
    local h = os.date("%H", time)
    local m = os.date("%M", time)
    local s = os.date("%S", time)
    -- 获取 time 00:00:00时的秒数
    local sec0 = time - (h * 3600 + m * 60 + s)
    return sec0
end

--获取月份后的秒数
function timeUtil.getSecondsAfterMonth(month, hour)
    local curTime = timeUtil.systemTime()
    local temp_date = os.date("*t", curTime)
    local temp_date_seconds =
        os.time({year = temp_date.year, month = temp_date.month, day = temp_date.day, hour = hour})
    temp_date_seconds = temp_date_seconds + month * 30 * 24 * 60 * 60
    local tableDate = os.date("*t", temp_date_seconds)
    if tableDate.wday == 5 + 1 then --周五顺延到周六中午12点
        temp_date_seconds = temp_date_seconds + 24 * 60 * 60
    end
    return temp_date_seconds - curTime
end

--获取月份后的秒数
function timeUtil.getSecondsAfterDays(days, hour)
    days = days - 1
    if days < 0 then
        return 0
    else
        local curTime = timeUtil.systemTime()
        local temp_date = os.date("*t", curTime + days * 24 * 60 * 60)
        local temp_date_seconds =
            os.time({year = temp_date.year, month = temp_date.month, day = temp_date.day, hour = hour})
        local ret = temp_date_seconds - curTime
        if ret < 0 then
            ret = 0
        end
        return ret
    end
end

--获取月份后的秒数
function timeUtil.getSecondsAfterDaysAtFixedWeekAndHour(days, week, hour)
    if days < 0 then
        return 0
    else
        local curTime = timeUtil.systemTime()
        local temp_date = os.date("*t", curTime + days * 24 * 60 * 60)
        local temp_date_seconds =
            os.time({year = temp_date.year, month = temp_date.month, day = temp_date.day, hour = hour})
        local tableDate = os.date("*t", temp_date_seconds)
        local weekday = week + 1 --从周日开始为一周的第一天
        if tableDate.wday ~= weekday then
            if tableDate.wday > weekday then
                temp_date_seconds = temp_date_seconds + (7 - tableDate.wday + weekday) * 24 * 60 * 60
            else
                temp_date_seconds = temp_date_seconds + (weekday - tableDate.wday) * 24 * 60 * 60
            end
        end
        return temp_date_seconds - curTime
    end
end

--[[
    skynet.call 超时调用

    @param time         number          超时时间，单位秒
    @param timeoutCall  true or false   超时是否调用 callback 函数
    @param callback     function        回调函数
        该函数的参数： ok, ... = 是否未超时, skynet.call 返回值，例如
        function callback(ok, ...)
            if ok then
                -- 未超时

            else
                -- 超时

            end
        end

        注意，在 callback 函数中处理业务时，注意数据状态，小心重入

    @param ... skynet.call 调用需要的参数

    @return true    不超时
    @return false   超时
--]]
function timeUtil.timeoutSkynetCall(time, timeoutCall, callback, ...)
    local timeout = false
    local ok = false
    local co = coroutine.running()

    skynet.fork(
        function(...)
            local function f(...)
                if not timeout then
                    ok = true
                    skynet.wakeup(co)
                end
                if timeout then
                    if timeoutCall then
                        callback(ok, ...)
                    end
                else
                    callback(ok, ...)
                end
            end
            f(skynet.call(...))
        end,
        ...
    )

    skynet.sleep(time * 100)
    timeout = true

    return ok
end

--获取月杪时间KEY
function timeUtil.getSec2MonKey()
    local temp_date = os.date("*t", timeUtil.systemTime())
    local ret = temp_date.month * 1000000 + temp_date.day * 10000 + temp_date.hour * 100 + temp_date.min
    return ret
end

-- 时间是否达到凌晨0点
function timeUtil.isInZerohours(inputTime)
    local ret = false
    local time = inputTime or timeUtil.systemTime()
    local hour = os.date("%H", time)
    local minute = os.date("%M", time)
    local second = os.date("%S", time)

    if hour == "00" and minute == "00" and second == "00" then
        ret = true
    end
    return ret
end

-- 判断传入的时间是否满足在传入时间那天的时间范围
---@param startSecond integer 每日开始的秒数
---@param endSecond integer 每日结束的秒数
---@param checktime integer 判断的时间戳，不传默认当前时间
function timeUtil.isInTimeRange(startTime, endTime, checktime)
    checktime = checktime or timeUtil.systemTime()
    local zeroTime = timeUtil.getTodayZeroHourUTC(checktime)
    if (checktime >= zeroTime + startTime) and (checktime <= zeroTime + endTime) then
        return true
    else
        return false
    end
end

-- 是否满足特定的时间
function timeUtil.isSatisfySpecialTime(inputTime, inputHour, inputMin, inputSec)
    local ret = false
    local time = inputTime or timeUtil.systemTime()
    local hour = os.date("%H", time)
    local minute = os.date("%M", time)
    local second = os.date("%S", time)
    if hour == inputHour and minute == inputMin and second == inputSec then
        ret = true
    end
    return ret
end

-- 距离服务器开服时间, 转化为开服当天0点之后多少秒
--[[
例如: 1 09:00:00 第一天 9点
     3 22:00:00 第三天 22点
]]
function timeUtil.openServerTime2Sec(strtime)
    local day, hour, min, sec = string.match(strtime, "(%d+) (%d+):(%d+):(%d+)")
    day, hour, min, sec = tonumber(day), tonumber(hour), tonumber(min), tonumber(sec)
    if day < 1 then
        return 0
    end
    return (day - 1) * 86400 + hour * 3600 + min * 60 + sec
end

---- 获取当天对应时间转换成时间戳 9:00:00转成时间戳
function timeUtil.str_to_time(str)
    local hour, min, sec = string.match(str, "(%d+):(%d+):(%d+)")
    hour, min, sec = tonumber(hour), tonumber(min), tonumber(sec)
    local zeroTime = timeUtil.getWeehoursUTC()
    local tranTime = hour * 3600 + min * 60 + sec
    return zeroTime + tranTime
end

function timeUtil.time2Str(timestamp)
    timestamp = timestamp or timeUtil.systemTime()
    return os.date("%Y-%m-%d %H:%M:%S", timestamp)
end

-- --------------------- 一个服务只能有一个(不推荐) ---------------------
local _close
local last_time = skynet.now()
local function clock(clock_func, interval)
    interval = interval or 100
    while true do
        if _close then
            break
        end
        local new_time = skynet.now()
        local diff_time = new_time - last_time
        last_time = new_time
        if clock_func then
            local ok, err = xpcall(clock_func, debug.traceback, diff_time)
            if not ok then
                log.Error("sys", tostring(err))
            end
        end

        skynet.sleep(interval)
    end
end

--启动时钟  clock_func为回调函数  interval为时钟间隔时间（0.01秒）
function timeUtil.open_clock(clock_func, interval)
    skynet.fork(clock, clock_func, interval)
    _close = false
end

--关闭时钟
function timeUtil.close_clock()
    _close = true
end

--- 获取两个时间相差了多少天
function timeUtil.diffDayFromTime(time1, time2)
    if time1 == time2 then
        return 0, 0
    end
    local oldZeroTime = timeUtil.getTodayZeroHourUTC(time1)
    local newZeroTime = timeUtil.getTodayZeroHourUTC(time2)
    local diffDay = math.floor((newZeroTime - oldZeroTime) / 86400)
    return diffDay, math.abs(diffDay)
end

function timeUtil.getYYYYMMDD(time)
    if not time then
        time = timeUtil.systemTime()
    end
    return tonumber(os.date("%Y%m%d", time))
end

function timeUtil.diffDayYYYYMMDD(yyyymmdd, day)
    local diffTime = day * 86400
    local time = os.time({year = yyyymmdd // 10000, month = yyyymmdd // 100 % 100, day = yyyymmdd % 100})
    return timeUtil.getYYYYMMDD(time + diffTime)
end

---判断闰年
function timeUtil.isLeapYear(year)
    if not year then
        year = tonumber(os.date("%Y", timeUtil.systemTime()))
    end

    if year % 100 == 0 then
        return year % 400 == 0
    else
        return year % 4 == 0
    end
end

--判断日期合法性
function timeUtil.checkDate(year, month, day)
    if month < 1 or month > 12 then
        return
    end

    local month31Day = {
        [1] = true,
        [3] = true,
        [5] = true,
        [7] = true,
        [8] = true,
        [10] = true,
        [12] = true
    }

    local maxDay = 30
    if month31Day[month] then
        maxDay = 31
    end

    if month == 2 then
        maxDay = 28
        if timeUtil.isLeapYear(year) then
            maxDay = 29
        end
    end

    if day < 1 and day > maxDay then
        return
    end

    return true
end

return timeUtil
