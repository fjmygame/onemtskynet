-- --------------------------------------
-- Create Date:2021-05-20 22:31:07
-- Author  : Happy Su
-- Version : 1.0
-- Filename: serviceHelp.lua
-- Introduce  : 服务启动辅助
-- --------------------------------------
local skynet = require "skynet"
---@type svrAddressMgr
local svrAddressMgr = require "svrAddressMgr"
local shareDefInit = require "shareDefInit"
---@class serviceHelp
local _M = BuildOther("serviceHelp")

-- 启动服务初始化
function _M.startServiceInit()
    shareDefInit()
    require "constDefInit"
end

-- 启动服务
function _M.startService(service)
    assert(service.getNodeId, string.safeFormat("service:%s no func getNodeId", SERVICE_NAME))
    assert(service.getCenter, string.safeFormat("service:%s no func getCenter", SERVICE_NAME))
    assert(service.getSvr, string.safeFormat("service:%s no func getSvr", SERVICE_NAME))

    log.DebugFormat("sys", "startService:%s addr:%s nodeId %s", SERVICE_NAME, service:getSvr(), service:getNodeId())
    skynet.start(
        function()
            _M.startServiceInit()
            local selfCenterInst = service:getCenter():sharedInstance()
            skynet.dispatch(
                "lua",
                function(session, source, command, ...)
                    local statId = selfCenterInst:commandStatStart(command)

                    local ok, err =
                        xpcall(
                        selfCenterInst.dispatchcmd,
                        debug.traceback,
                        selfCenterInst,
                        session,
                        source,
                        command,
                        ...
                    )

                    if not ok then
                        log.ErrorFormat(
                            "sys",
                            "ServiceName:%s dispatch cmd:%s err:%s %s",
                            SERVICE_NAME,
                            command,
                            err,
                            dumpTable({...}, "param", 5)
                        )
                    end

                    selfCenterInst:commandStatStop(command, statId, ...)

                    assert(ok, err)
                end
            )

            gAddrSvr = service:getSvr()

            -- 注册 info 函数，便于 debug 指令 INFO 查询。
            skynet.info_func(
                function()
                    local retData = selfCenterInst:getCmdMap()
                    log.Error("sys", dumpTable(retData, "service stat info", 10))
                    return retData
                end
            )

            svrAddressMgr.setSvr(skynet.self(), service:getSvr(), gNodeId, gSlaveId)
        end
    )
end

return _M
