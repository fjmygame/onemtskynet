-- --------------------------------------
-- Create Date:2021-05-20 10:13:07
-- Author  : sgys
-- Version : 1.0
-- Filename: main.lua
-- Introduce  : 类介绍
-- --------
-- Last Modified: Thu Mar 16 2023
-- Modified By: Happy Su
-- --------------------------------------

local skynet = require "skynet"
require "skynet.cluster"
local scheduler = require "scheduler"
local svrAddressMgr = require "svrAddressMgr"
local serviceHelp = require("serviceHelp")

local gNodeType = gServerDef.gNodeType

local nodeId, nodeType = ...
gNodeId = tonumber(nodeId)
assert(gNodeId)
assert(nodeType)

local nodeMgrCfg = {
    [gNodeType.gameserver] = require "clusterInf.clusterInfMgr",
    -- [gNodeType.loginserver] = require "clusterInf.clusterMgr",
    -- [gNodeType.globalserver] = require "clusterInf.clusterInfMgr",
    -- [gNodeType.chatserver] = require "clusterInf.clusterInfMgr",
    -- [gNodeType.infoserver] = require "clusterInf.clusterInfMgr",
    -- [gNodeType.crossserver] = require "clusterInf.clusterInfMgr",
    -- [gNodeType.webserver] = require "clusterInf.clusterInfMgr"
}

local infMgr
do
    local mgr = nodeMgrCfg[nodeType]
    assert(mgr ~= nil, "can not found nodeTypeMgr nodeType:" .. (nodeType or "nil"))
    infMgr = mgr.instance()
end

function getInfMgr()
    return infMgr
end

local schedulerTimer

skynet.init(
    function()
        infMgr:init(nodeType)
        -- 定时执行连接超时检查
        schedulerTimer =
            scheduler.create(
            function()
                infMgr:update()
            end,
            5
        )
        schedulerTimer:start()
    end
)

skynet.start(
    function()
        serviceHelp.startServiceInit()
        skynet.dispatch(
            "lua",
            function(_, _, command, ...)
                -- log.Info("sys", "ServiceName:clusterInfService dispatch .command:", command, ...)
                local ok, err =
                    xpcall(
                    function(_command, ...)
                        local f = infMgr[_command]
                        if f then
                            f(infMgr, ...)
                        else
                            log.Error(
                                "sys",
                                "ServiceName:clusterInfService dispatch err can not found command:",
                                _command
                            )
                        end
                    end,
                    debug.traceback,
                    command,
                    ...
                )
                if not ok then
                    log.Error("sys", "ServiceName:clusterInfService dispatch cmd err", command, dumpTable({...}), err)
                end
                assert(ok, err)
            end
        )

        svrAddressMgr.setSvr(skynet.self(), svrAddressMgr.clusterInfSvr, gNodeId)
    end
)
