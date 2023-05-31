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
local db

local nodeId, slaveId = ...
nodeId = tonumber(nodeId)
slaveId = tonumber(slaveId)
gNodeId = nodeId

local CMD = {}

function CMD.heartbeat()
    heartbeatCount = heartbeatCount + 1
    -- 第一次不执行
    if heartbeatCount == 1 or not dbClient or not db then
        return
    end

    log.Debug("mongo", "heartbeat", gNodeId, slaveId or 0)
end

function CMD.start(conf)
    -- log.DebugFormat("mongo", "mongo start %s", dumpTable(conf, "mongoConf"))
    dbClient = mongo.client(conf)
    db = dbClient[conf["dbname"]]

    log.InfoFormat("mongo", "mongo slaveId %s %s %s start success", slaveId or 0, dbClient, db)
    -- 定时执行连接超时检查
    local schedulerTimer = scheduler.create(CMD.heartbeat, db_heartbeat_inteval)
    schedulerTimer:start()

    skynet.retpack(true)
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
