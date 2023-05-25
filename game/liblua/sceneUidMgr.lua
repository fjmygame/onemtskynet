-- --------------------------------------
-- Create Date:2023-01-02 07:48:01
-- Author  : Happy Su
-- Version : 1.0
-- Filename: sceneUidMgr.lua
-- Introduce  : 玩家玩家uid管理
-- --------------------------------------
local playerAgent = require("playerAgent")
local accountUtil = require("accountUtil")
---@class sceneUidMgr
local _M = class("sceneUidMgr")

function _M:ctor()
    ---@type table<integer, table> <nodeid, uidMap>
    self.scenePlayerMap = {}
end

-- 场景对象是否为空
function _M:isEmpty()
    if not next(self.scenePlayerMap) then
        return true
    end
    return false
end

-- 获取玩家map
function _M:getPlayerMap()
    return self.scenePlayerMap
end

-- 给场景内对象广播
function _M:boardToSence(sprotoName, synData)
    for nodeid, uidMap in pairs(self.scenePlayerMap) do
        playerAgent.sendOnlineClientMap(nodeid, uidMap, sprotoName, synData)
    end
end

-- 发送协议给场景内的指定玩家
function _M:sendSprotoToSceneUids(uids, sprotoName, synData)
    local nodeid2SceneUids = {}
    for _, uid in ipairs(uids) do
        if self:isInScene(uid) then
            local nodeid = accountUtil.getNodeId(uid)
            local sceneUids = CreateBlankTable(nodeid2SceneUids, nodeid)
            sceneUids[#sceneUids + 1] = uid
        end
    end
    for nodeid, uidlist in pairs(nodeid2SceneUids) do
        playerAgent.sendOnlineClientList(nodeid, uidlist, sprotoName, synData)
    end
end

-- 所有场景的玩家对象管理
function _M:getPlayerScene(uid)
    local scenePlayerMap = self.scenePlayerMap
    local nodeid = accountUtil.getNodeId(uid)
    local playerMap = scenePlayerMap[nodeid]
    if playerMap then
        return playerMap[uid]
    end
end

-- 玩家是否在场景中
function _M:isInScene(uid)
    local nodeid = accountUtil.getNodeId(uid)
    local uidMap = self.scenePlayerMap[nodeid]
    if uidMap and uidMap[uid] then
        return true
    end
end

-- 单场景活动，给个默认sceneId
function _M:onEnterScene(uid, sceneId)
    sceneId = sceneId or 1
    local scenePlayerMap = self.scenePlayerMap
    local nodeid = accountUtil.getNodeId(uid)
    local playerMap = CreateBlankTable(scenePlayerMap, nodeid)
    playerMap[uid] = sceneId
end

function _M:onExitScene(uid)
    local scenePlayerMap = self.scenePlayerMap
    local nodeid = accountUtil.getNodeId(uid)
    local playerMap = scenePlayerMap[nodeid]
    if playerMap then
        playerMap[uid] = nil
        if not next(playerMap) then
            scenePlayerMap[nodeid] = nil
        end
    end
end

return _M
