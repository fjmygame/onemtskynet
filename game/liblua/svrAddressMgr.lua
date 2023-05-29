-- --------------------------------------
-- Create Date:2021-05-07 15:04:29
-- Author  : Happy Su
-- Version : 1.0
-- Filename: svrAddressMgr.lua
-- Introduce  : 类介绍
-- --------------------------------------
local skynet = require "skynet.manager"
---@type clusterExt
local clusterExt = require "clusterExt"
---@type nodeIdParser
local nodeIdParser = require "game.liblua.util.nodeIdParser"
---@class svrAddressMgr
local svrAddressMgr = BuildOther("svrAddressMgr")

---------------------------服务名称格式---------------------------------
-- 港口/中心港口
svrAddressMgr.clusterInfSvr = ".clusterInfSvr@%d"
-- 数据中心
svrAddressMgr.datacenterLogSvr = ".datacenterLogSvr@%d"
-- 网关服务
svrAddressMgr.gateSvr = ".gateSvr%d"

-- svrAddressMgr.statsSvr = ".statsSvr@%d@%d"

-- 服务数量配置
local serviceNum = {
    -- [svrAddressMgr.statsSvr] = 9,
}
svrAddressMgr.serviceNum = serviceNum
-- 配置名称对应的服务数
svrAddressMgr.serviceName2Num = {
    -- statsService = serviceNum[svrAddressMgr.statsSvr],
}

-- 服务地址均衡id[例如:id==uid], svrNum服务实例数
local function genServiceId(id, svrNum)
    if type(id) == "number" and svrNum and svrNum > 1 then
        return (id % svrNum) + 1
    else
        return 1
    end
end
svrAddressMgr.genServiceId = genServiceId

function svrAddressMgr.setSvr(address, key, nodeId, otherId)
    local server_name = key
    if nodeId and otherId then
        server_name = string.safeFormat(key, nodeId, otherId)
    elseif nodeId then
        server_name = string.safeFormat(key, nodeId)
    elseif otherId then
        server_name = string.safeFormat(key, otherId)
    end

    skynet.name(server_name, address)
    return server_name
end

--获取服务地址
function svrAddressMgr.getSvr(key, nodeId, otherId)
    if nodeId and otherId then
        local svrNum = serviceNum[key]
        local index = genServiceId(otherId, svrNum)
        key = string.safeFormat(key, nodeId, index)
    elseif nodeId then
        key = string.safeFormat(key, nodeId)
    elseif otherId then
        key = string.safeFormat(key, otherId)
    end

    --获取本节点服务地址
    local address = skynet.localname(key)

    --如果本节点服务地址为nil，则跨节点获取服务地址
    if nodeId and not address then
        local _, _, nodeName = nodeIdParser.parseNodeId(nodeId)
        if not nodeName then
            log.ErrorStack("sys", "can not found nodeName for", nodeId)
            return
        end
        address = clusterExt.pack_cluster_address(nodeName, key)
    end

    return address
end

return svrAddressMgr
