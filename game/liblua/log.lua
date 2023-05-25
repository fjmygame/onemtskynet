-- --------------------------------------
-- Create Date:2021-05-24 19:15:16
-- Author  : sgys
-- Version : 1.0
-- Filename: log.lua
-- Introduce  : 类介绍
-- --------------------------------------
local skynet = require("skynet")
local hloggerlib = require("hloggerlib")
---@class log
local log = {}

-- 要开启的模块
log.openModule = {
    sys = true, -- 系统log，必开
    init = true,
    login = true, -- 登录
    clusterext = true, -- 服务间调用
    gate = true, -- 网关
    base = true,
    player = true
}

-- debug模式才需要的日志
-- if dbconf.DEBUG then
--     log.openModule.offlineInfo = true
--     log.openModule.database = true
-- end

-- 保留名字data,模块不要用
log.openModule.data = nil

-- log等级
local LEVEL_ERROR = 0
local LEVEL_WARNING = 1
local LEVEL_INFO = 2
local LEVEL_DEBUG = 4

log.level = LEVEL_DEBUG

-- -- 设置log等级[后面可以改成配置]
-- if dbconf.logLevel == nil then
--     log.level = LEVEL_DEBUG
-- else
--     log.level = dbconf.logLevel
-- end

local function logPrefix(lv, moduleName, other)
    local str = "n(" .. dbconf.curnodeid .. ")"
    -- 加玩家ID前缀
    if "number" == type(gUid) then
        str = str .. " uid(" .. gUid .. ")"
    end
    if moduleName then
        str = str .. " m(" .. moduleName .. ")"
    end
    if other then
        str = str .. other
    end

    local timeStr
    if timeUtil then
        timeStr = os.date("%Y-%m-%d %H:%M:%S", timeUtil.systemTime())
    else
        timeStr = os.date("%Y-%m-%d %H:%M:%S")
    end

    if skynet.tracetag() then
        return string.safeFormat(" <TRACE %s> %s [%s] %s: ", skynet.tracetag(), timeStr, lv, str)
    else
        return string.safeFormat(" %s [%s] %s: ", timeStr, lv, str)
    end
end

local function getLogFileLine()
    local debugInfo = debug.getinfo(3)
    if debugInfo then
        if debugInfo.what == "C" then -- is a C function?
            return "C:" .. debugInfo.name
        elseif (debugInfo.name) then
            return string.format("%s:%s:%s", debugInfo.source, debugInfo.currentline, debugInfo.name)
        else
            return string.format("%s:%s", debugInfo.source, debugInfo.currentline)
        end
    end

    return ""
end
-------------------------------------------------------------
local function sendToLogSvr(...)
    skynet.send(".serverLogSvr", "lua", ...)
end

-- 钉钉消息
---@param msg string 发送钉钉的消息
---@param url string 钉钉的hook地址，不传使用默认配置
function log.ddNotify(msg, url)
    sendToLogSvr("ddNotify", msg, url)
end

-- 杀进程级别的报错
function log.Fatal(moduleName, ...)
    local pre = logPrefix("E", moduleName, getLogFileLine())
    -- skynet.error(pre, ...)
    sendToLogSvr("error", moduleName, gUid, math.floor(skynet.time()), pre, ...)
    hloggerlib.error(pre, ...)
    skynet.sleep(50)
    skynet.abort()
end

-- log 扩展
-- moduleName 保留保证接口一致
function log.Error(moduleName, ...)
    local pre = logPrefix("E", moduleName, getLogFileLine())
    -- skynet.error(pre, ...)
    sendToLogSvr("error", moduleName, gUid, math.floor(skynet.time()), pre, ...)
    hloggerlib.error(pre, ...)
end

function log.ErrorFormat(moduleName, fmt, ...)
    local logStr = string.safeFormat(fmt, ...)
    local pre = logPrefix("E", moduleName, getLogFileLine())
    sendToLogSvr("error", moduleName, gUid, math.floor(skynet.time()), pre, logStr)
    hloggerlib.error(pre, logStr)
end

-- 限时Error接口：即同一信息在多长时间内不重复报
local limitErrTimeMap = CreateBlankTable(log, "limitErrTimeMap")
function log.limitError(moduleName, str, ...)
    local curTime = skynet.time()
    local lastTime = limitErrTimeMap[str]
    -- 默认5分钟不重复报error，转成报info
    if lastTime and curTime - lastTime < 300 then
        log.Info(moduleName, str, ...)
        return
    end
    limitErrTimeMap[str] = curTime
    log.Error(moduleName, str, ...)
end

-- Debug环境报错提示
function log.debugErrorStack(moduleName, ...)
    if not dbconf.DEBUG then
        return
    end
    local pre = logPrefix("E", moduleName)
    -- skynet.error(pre, ...)
    sendToLogSvr("error", moduleName, gUid, math.floor(skynet.time()), pre, debug.traceback(), ...)
    hloggerlib.error(pre, debug.traceback(), ...)
end

function log.ErrorStack(moduleName, ...)
    local pre = logPrefix("E", moduleName)
    -- skynet.error(pre, ...)
    sendToLogSvr("error", moduleName, gUid, math.floor(skynet.time()), pre, debug.traceback(), ...)
    hloggerlib.error(pre, debug.traceback(), ...)
end

function log.Warn(moduleName, ...)
    if log.level > LEVEL_ERROR and not log.openModule[moduleName] then
        return
    end

    if log.level >= LEVEL_WARNING then
        local pre = logPrefix("W", moduleName)
        -- skynet.error(pre, ...)
        -- sendToLogSvr("warn", pre, ...)
        hloggerlib.warn(pre, ...)
    end
end

function log.WarnFormat(moduleName, fmt, ...)
    if log.level > LEVEL_ERROR and not log.openModule[moduleName] then
        return
    end

    if log.level >= LEVEL_WARNING then
        local pre = logPrefix("W", moduleName)
        local logStr = string.safeFormat(fmt, ...)
        hloggerlib.warn(pre, logStr)
    end
end

function log.Info(moduleName, ...)
    if log.level > LEVEL_ERROR and not log.openModule[moduleName] then
        return
    end

    if log.level >= LEVEL_INFO then
        skynet.error(logPrefix("I", moduleName), ...)
    end
end

function log.InfoFormat(moduleName, fmt, ...)
    if log.level > LEVEL_ERROR and not log.openModule[moduleName] then
        return
    end

    if log.level >= LEVEL_INFO then
        local logStr = string.safeFormat(fmt, ...)
        skynet.error(logPrefix("I", moduleName), logStr)
    end
end

function log.Debug(moduleName, ...)
    if not dbconf.DEBUG then
        return
    end

    if log.level > LEVEL_ERROR and not log.openModule[moduleName] then
        return
    end

    if log.level >= LEVEL_DEBUG then
        skynet.error(logPrefix("D", moduleName), ...)
    end
end

function log.DebugFormat(moduleName, fmt, ...)
    if not dbconf.DEBUG then
        return
    end

    if log.level > LEVEL_ERROR and not log.openModule[moduleName] then
        return
    end

    if log.level >= LEVEL_DEBUG then
        local logStr = string.safeFormat(fmt, ...)
        skynet.error(logPrefix("D", moduleName), logStr)
    end
end

-- dump 只有debug模式下可以使用
function log.Dump(moduleName, value, desciption, nesting, ...)
    if not dbconf.DEBUG then
        return
    end

    if log.level > LEVEL_ERROR and not log.openModule[moduleName] then
        return
    end

    if log.level >= LEVEL_DEBUG then
        skynet.error(dumpTable(value, desciption, nesting), ...)
    end
end

-- dumpError 错误时候用 lv级别error moduleName 保留保证接口一致
function log.ErrorDump(moduleName, value, desciption, nesting, ...)
    skynet.error(dumpTable(value, desciption, nesting), ...)
end

-- 打印堆栈
function log.PrintTrace(moduleName, ...)
    if log.level > LEVEL_ERROR and not log.openModule[moduleName] then
        return
    end

    if log.level >= LEVEL_DEBUG then
        skynet.error("name:" .. moduleName .. " " .. logPrefix("D") .. "----------------------------------------------")
        skynet.error("name:" .. moduleName .. " " .. logPrefix("DT"), ...)
        skynet.error("name:" .. moduleName .. " " .. logPrefix("D") .. debug.traceback("", 2))
        skynet.error("name:" .. moduleName .. " " .. logPrefix("D") .. "----------------------------------------------")
    end
end

function log.SetLevel(lv)
    if lv > LEVEL_DEBUG then
        log.Warn("log set level err lv > debug!!")
        return
    end
    log.level = lv
end

return log
