-- --------------------------------------
-- Create Date : 2023-05-29 11:15:08
-- Author      : LHS
-- Version     : 1.0
-- Filename    : nodeIdParser.lua
-- Introduce   : 节点id解析期
-- --------------------------------------
---@class nodeIdParser
local _M = class("nodeIdParser")

local gNodeTypeIdName = gServerDef.gNodeTypeIdName

-- 构造一个节点id
---@param zone 游戏大区(详见:gZoneType)
---@param nodeTypeId 节点类型(详见:gNodeTypeId)
---@param zoneId 区服Id(1~9999)
---@return integer 唯一节点id
function _M.makeNodeId(zone, nodeTypeId, zoneId)
    -- 2位大区id + 2位节点类型id + 4位区服id
    zone = zone % 100
    nodeTypeId = nodeTypeId % 100
    zoneId = zoneId % 10000

    return zone * 1000000 + nodeTypeId * 10000 + zoneId
end

---@return integer, integer, string, integer 游戏大区 节点类型id 节点类型 区服id
function _M.parseNodeId(nodeId)
    local zoneId = nodeId % 10000
    local nodeTypeId = math.floor((nodeId % 1000000) / 10000)
    local zone = math.floor(nodeId / 1000000)

    return zone, nodeTypeId, gNodeTypeIdName[nodeTypeId], zoneId
end

function _M.runTest()
    local nodeId = _M.makeNodeId(0, 1, 1)
    local zone, nodeTypeId, nodeType, zoneId = _M.parseNodeId(nodeId)
    log.Info("sys", nodeId, zone, nodeTypeId, nodeType, zoneId)

    nodeId = _M.makeNodeId(33, 2, 9999)
    zone, nodeTypeId, nodeType, zoneId = _M.parseNodeId(nodeId)
    log.Info("sys", nodeId, zone, nodeTypeId, nodeType, zoneId)
end

return _M
