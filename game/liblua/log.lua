-- --------------------------------------
-- Create Date:2021-05-24 19:15:16
-- Author  : sgys
-- Version : 1.0
-- Filename: log.lua
-- Introduce  : 类介绍
-- --------------------------------------
local skynet = require("skynet")
local hloggerlib = require("hloggerlib")

local tconcat = table.concat

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
    player = true,
    log = true,
    mongo = true
}

-- 保留名字data,模块不要用
log.openModule.data = nil

-- log等级
local LEVEL_DEBUG = 0
local LEVEL_INFO = 1
local LEVEL_WARNING = 2
local LEVEL_ERROR = 3

log.level = LEVEL_DEBUG

-- 设置log等级[后面可以改成配置]
-- if dbconf.logLevel then
--     log.level = dbconf.logLevel
-- end

local function logPrefix(lv, moduleName, other)
    local str = ""
    if gNodeId then
        str = str .. "n(" .. gNodeId .. ") "
    end
    if moduleName then
        str = str .. "m(" .. moduleName .. ")"
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

    local tag = skynet.tracetag()
    if tag then
        return string.safeFormat("<TRACE %s> %s [%s] %s:", tag, timeStr, lv, str)
    else
        return string.safeFormat("%s [%s] %s:", timeStr, lv, str)
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
    local pre = logPrefix("ERROR", moduleName)
    hloggerlib.error(pre, tconcat({...}, " "), getLogFileLine())
    skynet.sleep(50)
    skynet.abort()
end

function log.Error(moduleName, ...)
    local pre = logPrefix("ERROR", moduleName)
    hloggerlib.error(pre, tconcat({...}, " "), getLogFileLine())
end

function log.ErrorFormat(moduleName, fmt, ...)
    local logStr = string.safeFormat(fmt, ...)
    local pre = logPrefix("ERROR", moduleName)
    hloggerlib.error(pre, logStr, getLogFileLine())
end

function log.ErrorStack(moduleName, ...)
    local pre = logPrefix("ERROR", moduleName)
    hloggerlib.error(pre, debug.traceback(), ...)
end

function log.Warn(moduleName, ...)
    if log.level > LEVEL_WARNING or not log.openModule[moduleName] then
        return
    end

    local pre = logPrefix("WARN", moduleName)
    hloggerlib.warn(pre, tconcat({...}, " "), getLogFileLine())
end

function log.WarnFormat(moduleName, fmt, ...)
    if log.level > LEVEL_WARNING or not log.openModule[moduleName] then
        return
    end

    local pre = logPrefix("WARN", moduleName)
    local logStr = string.safeFormat(fmt, ...)
    hloggerlib.warn(pre, logStr, getLogFileLine())
end

function log.Info(moduleName, ...)
    if log.level > LEVEL_INFO or not log.openModule[moduleName] then
        return
    end

    hloggerlib.info(logPrefix("INFO", moduleName), tconcat({...}, " "), getLogFileLine())
end

function log.InfoFormat(moduleName, fmt, ...)
    if log.level > LEVEL_INFO or not log.openModule[moduleName] then
        return
    end

    local logStr = string.safeFormat(fmt, ...)
    hloggerlib.info(logPrefix("INFO", moduleName), logStr, getLogFileLine())
end

function log.Debug(moduleName, ...)
    if log.level > LEVEL_DEBUG or not log.openModule[moduleName] then
        return
    end

    skynet.error(logPrefix("DEBUG", moduleName), tconcat({...}, " "), getLogFileLine())
end

function log.DebugFormat(moduleName, fmt, ...)
    if log.level > LEVEL_DEBUG or not log.openModule[moduleName] then
        return
    end

    local logStr = string.safeFormat(fmt, ...)
    skynet.error(logPrefix("DEBUG", moduleName), logStr, getLogFileLine())
end

function log.Dump(moduleName, value, desciption, nesting, ...)
    if log.level > LEVEL_DEBUG or not log.openModule[moduleName] then
        return
    end

    skynet.error(
        logPrefix("DEBUG", moduleName),
        dumpTable(value, desciption, nesting),
        tconcat({...}, " "),
        getLogFileLine()
    )
end

-- 打印堆栈
function log.PrintTrace(moduleName, ...)
    if log.level > LEVEL_DEBUG or not log.openModule[moduleName] then
        return
    end

    skynet.error("name:" .. moduleName .. " " .. logPrefix("D") .. "----------------------------------------------")
    skynet.error("name:" .. moduleName .. " " .. logPrefix("DT"), ...)
    skynet.error("name:" .. moduleName .. " " .. logPrefix("D") .. debug.traceback("", 2))
    skynet.error("name:" .. moduleName .. " " .. logPrefix("D") .. "----------------------------------------------")
end

function log.SetLevel(lv)
    if lv < LEVEL_DEBUG or lv > LEVEL_ERROR then
        log.WarnFormat("sys", "log set level err lv %s", lv)
        return
    end
    log.level = lv
end

return log
