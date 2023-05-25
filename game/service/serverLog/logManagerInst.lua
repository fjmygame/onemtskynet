-- --------------------------------------
-- Create Date:2020-03-09 10:45:22
-- Author  : Happy Su
-- Version : 1.0
-- Filename: logManagerInst.lua
-- Introduce  : 服务器日志管理
-- --------------------------------------
local skynet = require "skynet"
local DDRobot = require "liblua.robot.DDRobot"
local queue = require "skynet.queue"
---@class logManagerInst
local LogManager = instanceClass("logManagerInst")
---@type dataLogInst
local dataLogInst = require("service.serverLog.dataLogInst")

function LogManager:ctor()
    self.ddQueue = queue()
end

local function dd_notify_err(msg_type, msg_stack)
    return DDRobot:notifyException("[" .. msg_type .. "]\n" .. msg_stack)
end

local function dd_notify_msg(msg_type, msg_stack, url)
    return DDRobot:notifyMsg("[" .. msg_type .. "]\n" .. msg_stack, url)
end

local function concat_str(msg, ...)
    local str = msg
    for i = 1, select("#", ...) do
        str = string.format("%s%s ", str, tostring(select(i, ...)))
    end
    return str
end

function LogManager:fatal(pre, msg)
    if not pre or not msg then
        return
    end
    -- 发送钉钉
    local bok, errMsg = self.ddQueue(dd_notify_err, "FATAL", msg)
    skynet.error("DDResult:", tostring(bok), " msg:", tostring(errMsg))
end

function LogManager:error(moduleName, uid, createtime, pre, msg, ...)
    if not pre or not msg then
        return
    end
    msg = concat_str(pre, "\n", msg, ...)
    -- 发送钉钉
    local bok, errMsg = self.ddQueue(dd_notify_err, "ERROR", msg)
    skynet.error("DDResult:", tostring(bok), " msg:", tostring(errMsg))

    -- 记录数据中心日志
    local data = {
        createtime = createtime,
        basic = {
            -- nodeid = nodeid
        },
        ptype = "server_error",
        scxt = {
            -- type = dbconf.zone or 1,
            -- nodeid = nodeid,
            uid = uid,
            module = moduleName,
            err = msg
        }
    }
    bok, errMsg = dataLogInst:writeFile("error", data)
    if not bok then
        skynet.error("log dataLogInst:writeFile fail:", errMsg)
    end
end

function LogManager:ddNotify(msg, url)
    -- 发送钉钉
    local bok, errMsg = self.ddQueue(dd_notify_msg, "ddNotify", msg, url)
    skynet.error("DDResult:", tostring(bok), " msg:", tostring(errMsg))
end

function LogManager:close()
    dataLogInst:close()
end

return LogManager.instance()
