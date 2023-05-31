-- --------------------------------------
-- Create Date : 2023-05-31 02:41:01
-- Author      : LHS
-- Version     : 1.0
-- Filename    : mongoAPI.lua
-- Introduce   : <<description>>
-- --------------------------------------
local skynet = require "skynet"

---@class mongoAPI
local _M = BuildAPI("mongoAPI")

local nodeType = skynet.getenv("node_type")
local nodeId = tonumber(skynet.getenv("node_id"))
-- 唯一节点名称
local nodeName = nodeType .. "_" .. nodeId

local gameConfDbSvr = ".gameConfDbSvr" -- 配置DB服务地址
local nodeDbSvr = ".nodeDbSvr@%d@%d"

function _M:launchGameConfDbService()
    if self.isLaunchGameConfDbService then
        return
    end
    self.isLaunchGameConfDbService = true

    local mongoAddr = skynet.newservice("mongoService", nodeId)
    skynet.name(gameConfDbSvr, mongoAddr)
end

function _M:startGameConfDbService(conf)
    --[[
        conf = {
            host = "127.0.0.1",
            port = 27017,
            username = "db_user",
            password = "123456",
            authdb = "admin",
        }
    ]]
    if self.isGameConfDbServiceStart then
        return
    end
    self.isGameConfDbServiceStart = true

    conf["dbname"] = conf["dbname"] or "gameconf"
    local bok = skynet.call(gameConfDbSvr, "lua", "start", conf)
    if not bok then
        assert(bok, "startGameConfDbService fail!")
        return
    end

    return bok
end

function _M:launchNodeDbService(serviceNum)
    if self.isLaunchNodeDbService then
        return
    end
    self.isLaunchNodeDbService = true

    serviceNum = serviceNum or 1
    self.nodeDbServiceNum = serviceNum
    for i = 1, serviceNum, 1 do
        local mongoAddr = skynet.newservice("mongoService", nodeId, i)
        skynet.name(string.format(nodeDbSvr, nodeId, i), mongoAddr)
    end
end

function _M:startNodeDbService(conf)
    if self.isNodeDbServiceStart then
        return
    end
    self.isNodeDbServiceStart = true

    conf["dbname"] = conf["dbname"] or nodeName

    local serviceNum = self.nodeDbServiceNum
    for i = 1, serviceNum, 1 do
        local addr = string.format(nodeDbSvr, nodeId, i)
        local bok = skynet.call(addr, "lua", "start", conf)
        if not bok then
            assert(bok, "startNodeDbService fail!")
            return
        end
    end

    return true
end

return _M
