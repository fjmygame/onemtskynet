-- --------------------------------------
-- Create Date : 2023-05-31 02:39:29
-- Author      : LHS
-- Version     : 1.0
-- Filename    : mongoService.lua
-- Introduce   : <<description>>
-- --------------------------------------
local skynet = require "skynet.manager"
local mongo = require "skynet.db.mongo"

local skynetTime = skynet.now
local db_opt_timeout = 100 -- db操作超时时间（单位0.01秒, 超时会有个打印）

local dbClient

local nodeId, slaveId = ...
nodeId = tonumber(nodeId)
slaveId = tonumber(slaveId)
gNodeId = nodeId

local CMD = {}

function CMD.start(conf)
    -- log.DebugFormat("mongo", "mongo start %s", dumpTable(conf, "mongoConf"))
    local f = function()
        dbClient = mongo.client(conf)
    end

    local ok = pcall(f)
    if not ok then
        log.Fatal("mongo", "start mongo fail!", dumpTable(conf, "dbAddrConf"))
    end

    log.InfoFormat("mongo", "mongo slaveId %s %s start success", slaveId or 0, dbClient)

    skynet.retpack(true)
end

function CMD.runTest(database, collectionName)
    log.InfoFormat("mongo", "runTest database[%s] collectionName[%s] begin", database, collectionName)
    local db = dbClient[database]
    local collection = db[collectionName]
    local bok, err
    -- collection:safe_delete({_id = gNodeId}) -- safe_delete会挂起，delete也会挂起
    -- bok, err =
    --     collection:safe_insert(
    --     {_id = gNodeId, zone = 0, nodeType = "gameserver", other = {name = "lhs", age = 1024}, tt = "welcome"}
    -- ) -- safe_insert会挂起，insert不会挂起
    -- bok, err =
    --     collection:safe_insert({_id = 10002, zone = 0, nodeType = "gameserver", other = {name = "lhs", age = 1299}}) -- safe_insert会挂起，insert不会挂起

    -- if not bok then
    --     log.Error("mongo", database, bok, err)
    -- end
    local int64 = 6917529027641082023 --(1 << 62) | (1 << 61)
    local int32 = 1 << 31
    print("type(int64)===>", type(int64))
    bok, err =
        collection:safe_update(
        {_id = gNodeId},
        {
            ["$set"] = {
                ["other.name"] = "liuhuasheng",
                ["bignumber"] = int64,
                ["int32"] = int32
            },
            ["$unset"] = {
                tt = ""
            },
            ["$currentDate"] = {
                ["lastModified"] = {["$type"] = "timestamp"}
            }
        }
    )
    if not bok then
        log.Error("mongo", database, bok, err)
    end

    local ret1 = collection:findOne({_id = gNodeId}, {lastModified = 0})
    log.Info("mongo", "findOne ret1", dumpTable(ret1, "findOneResult", 10))

    local ret = {}
    local cursor = collection:find({})
    while cursor:hasNext() do
        ret[#ret + 1] = cursor:next()
    end
    log.Info("mongo", dumpTable(ret, "findResult", 10))

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
