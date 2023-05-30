-- --------------------------------------
-- Create Date:2020-08-28 15:45:16
-- Author  : Happy Su
-- Version : 1.0
-- Filename: dataCenterLogService.lua
-- Introduce  : 类介绍
-- --------
-- Last Modified: Wed Mar 22 2023
-- Modified By: sgys
-- --------------------------------------

local skynet = require "skynet"
local cmdCtrl = require "cmdCtrl"
local svrAddressMgr = require "svrAddressMgr"
local dataLogMgr = require "dataCenterLog.dataLogMgr"

gZone = tonumber(skynet.getenv("zone"))
gNodeId = tonumber(...)
assert(gNodeId)

local s_dataLogMgr = dataLogMgr.new()
s_dataLogMgr:init()

skynet.start(
    function()
        timeUtil = require "util.timeUtil"
        skynet.dispatch(
            "lua",
            function(session, source, command, ...)
                local ok, err = xpcall(cmdCtrl.handle, debug.traceback, command, ...)
                if not ok then
                    log.Error("sys", "dataCenterLogService cmd err", command, err)
                    assert(ok, err)
                elseif err == false then
                    log.Error("sys", "dataCenterLogService can not found cmd", command)
                end
            end
        )

        svrAddressMgr.setSvr(skynet.self(), svrAddressMgr.datacenterLogSvr, gNodeId)
    end
)
