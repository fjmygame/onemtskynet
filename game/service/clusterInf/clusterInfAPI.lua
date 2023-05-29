-- --------------------------------------
-- Create Date:2021-05-20 10:12:42
-- Author  : sgys
-- Version : 1.0
-- Filename: clusterInfAPI.lua
-- Introduce  : 类介绍
-- --------------------------------------

local svrAddressMgr = require("svrAddressMgr")
local clusterExt = require("clusterExt")
---@class clusterInfAPI
local API = BuildAPI("clusterInfAPI")

local function getSvrAddress()
    if not API.address then
        API.address = svrAddressMgr.getSvr(svrAddressMgr.clusterInfSvr, dbconf.curnodeid)
    end
    return API.address
end

function API.getGameServerFinishChannelId()
    return clusterExt.call(getSvrAddress(), "lua", "getGameServerFinishChannelId")
end

-- 节点启动成功
function API.nodeStartComplete()
    return clusterExt.call(getSvrAddress(), "lua", "nodeStartComplete")
end

-- 服务启动成功
function API.registerService(serviceName, addr, slaveId, ...)
    clusterExt.send(getSvrAddress(), "lua", "registerService", serviceName, addr, slaveId, ...)
end

-- 数据服务启动成功
function API.registerDBService(serviceName, addr, slaveId, ...)
    return clusterExt.call(getSvrAddress(), "lua", "registerDBService", serviceName, addr, slaveId, ...)
end

return API
