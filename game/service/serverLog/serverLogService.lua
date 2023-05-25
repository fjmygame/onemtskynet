-- --------------------------------------
-- Create Date:2020-03-09 10:55:44
-- Author  : Happy Su
-- Version : 1.0
-- Filename: serverLogService.lua
-- Introduce  : 服务端运行日志
-- --------
-- Last Modified: Tue Mar 28 2023
-- Modified By: Happy Su
-- --------------------------------------
local skynet = require "skynet"
require "skynet.manager"
local logManagerInst = require("service.serverLog.logManagerInst")

skynet.start(
    function()
        print("server log service addr:", skynet.self())
        skynet.dispatch(
            "lua",
            function(session, source, command, ...)
                local func = logManagerInst[command]
                if not func then
                    logManagerInst:ddNotify("logService can not found cmd" .. tostring(command))
                else
                    local ok, err = xpcall(func, debug.traceback, logManagerInst, ...)
                    if not ok then
                        -- log.Error("sys", "logService cmd err", command, err)
                        logManagerInst:ddNotify(command .. tostring(err))
                        assert(ok, err)
                    end
                end
            end
        )

        skynet.name(".serverLogSvr", skynet.self())
    end
)
