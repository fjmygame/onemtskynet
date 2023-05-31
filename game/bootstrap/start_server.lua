local skynet = require "skynet"

local clusterExt = require "clusterExt"
local svrAddressMgr = require "svrAddressMgr"
local shareDefInit = require "sharedef.shareDefInit"
local mongoAPI = require "game.service.mongo.mongoAPI"

local gNodeType = gServerDef.gNodeType

local start_cfg = {
    [gNodeType.gameserver] = require "bootstrap.gameserver.startlogic"
    -- [gNodeType.loginserver] = require "bootstrap.loginserver.startlogic",
    -- [gNodeType.chatserver] = require "bootstrap.chatserver.startlogic",
    -- [gNodeType.globalserver] = require "bootstrap.globalserver.startlogic",
    -- [gNodeType.infoserver] = require "bootstrap.infoserver.startlogic",
    -- [gNodeType.crossserver] = require "bootstrap.crossserver.startlogic",
    -- [gNodeType.webserver] = require "bootstrap.webserver.startlogic"
}

skynet.start(
    function()
        local zone = tonumber(skynet.getenv("zone"))
        local nodeType = skynet.getenv("node_type")
        local nodeId = tonumber(skynet.getenv("node_id"))
        -- 唯一节点名称
        local nodeName = nodeType .. "_" .. nodeId
        gNodeId = nodeId

        -- 启动日志服务
        -- skynet.newservice("serverLogService")
        -- 初始化sharetable，需要放最前面
        shareDefInit.load()
        timeUtil = require "util.timeUtil"

        --启动debug服务
        -- skynet.newservice("debug_console", 8000)

        -- 获取配置db
        local dbconfStr = skynet.getenv("conf_db_addr")
        local dbconf = load(dbconfStr)()
        -- 启动配置DB服务
        mongoAPI:launchGameConfDbService()
        mongoAPI:startGameConfDbService(dbconf)

        -- mongoAPI:launchNodeDbService(2)
        -- mongoAPI:startNodeDbService(dbconf)

        -- clusterExt.open(nodeName)
        -- 数据中心日志服务
        local logAddr = skynet.newservice("dataCenterLogService", nodeId)
        skynet.call(logAddr, "lua", "start")

        local fileName = string.safeFormat("./.startsuccess_%s", nodeName)

        -- 启动港口服务
        local clusterInfAddr = skynet.newservice("clusterInfService", nodeId, nodeType)
        local startLogic = start_cfg[nodeType]
        startLogic()

        if clusterInfAddr then
            local completeRet, completeErr = skynet.call(clusterInfAddr, "lua", "nodeStartComplete", fileName)
            if not completeRet then
                log.Error("sys", "nodeStartComplete err:", completeRet, completeErr)
            end
        end

        local file = io.open(fileName, "w+")
        file:close()

        local dataCenterLogAPI = require "dataCenterLog.dataCenterLogAPI"
        dataCenterLogAPI.writeSpecialDataLog(
            "server_start",
            {nodeid = nodeId},
            {
                type = 1,
                servertype = nodeType,
                kids = {1, 2}
            }
        )

        skynet.call(".launcher", "lua", "GC")

        log.InfoFormat("sys", "zone %s nodeType %s nodeId %s start success!", zone, nodeType, nodeId)

        skynet.exit()
    end
)
