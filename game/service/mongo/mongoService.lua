-- --------------------------------------
-- Create Date : 2023-05-31 02:39:29
-- Author      : LHS
-- Version     : 1.0
-- Filename    : mongoService.lua
-- Introduce   : <<description>>
-- --------------------------------------
local skynet = require "skynet.manager"
local mongo = require "skynet.db.mongo"
local scheduler = require "scheduler"

local skynetTime = skynet.now
local db_opt_timeout = 100 -- db操作超时时间（单位0.01秒, 超时会有个打印）
local db_heartbeat_inteval = 10 -- db心跳间隔(单位秒)
local heartbeatCount = 0

local dbClient

local nodeId, slaveId = ...
nodeId = tonumber(nodeId)
slaveId = tonumber(slaveId)
gNodeId = nodeId

local CMD = {}

function CMD.heartbeat()
    heartbeatCount = heartbeatCount + 1
    -- 第一次不执行
    if heartbeatCount == 1 or not dbClient then
        return
    end

    log.Debug("mongo", "heartbeat", gNodeId, slaveId or 0)
end

function CMD.start(conf)
    -- log.DebugFormat("mongo", "mongo start %s", dumpTable(conf, "mongoConf"))
    dbClient = mongo.client(conf)

    log.InfoFormat("mongo", "mongo slaveId %s %s start success", slaveId or 0, dbClient)
    -- 定时执行连接超时检查
    local schedulerTimer = scheduler.create(CMD.heartbeat, db_heartbeat_inteval)
    schedulerTimer:start()

    skynet.retpack(true)
end

function CMD.runTest(database, collectionName)
    log.InfoFormat("mongo", "runTest database[%s] collectionName[%s] begin", database, collectionName)
    local db = dbClient[database]
    local collection = db[collectionName]
    collection:safe_delete({_id = gNodeId}) -- safe_delete会挂起，delete也会挂起
    local bok, err =
        collection:safe_insert({_id = gNodeId, zone = 0, nodeType = "gameserver", other = {name = "lhs", age = 1024}}) -- safe_insert会挂起，insert不会挂起

    if not bok then
        log.Error("mongo", database, bok, err)
    end
    bok, err =
        collection:safe_update(
        {_id = gNodeId},
        {
            ["$set"] = {
                ["other.name"] = "liuhuasheng"
            },
            ["$currentDate"] = {
                ["lastModified"] = {["$type"] = "timestamp"}
            }
        }
    )
    if not bok then
        log.Error("mongo", database, bok, err)
    end

    log.InfoFormat("mongo", "runTest database[%s] collectionName[%s] end", database, collectionName)
    skynet.retpack()
end

skynet.start(
    function()
        skynet.dispatch(
            "lua",
            function(_, _, cmd, ...)
                local f = assert(CMD[cmd], "mongoService not find command:" .. cmd)
                f(...)
            end
        )
    end
)
