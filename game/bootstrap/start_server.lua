local skynet = require "skynet"

-- local clusterExt = require "clusterExt"
-- local svrAddressMgr = require "svrAddressMgr"
local sharedefinit = require "sharedef.sharedefinit"
local serverdef = require "constDef.serverdef"

local gServerType = serverdef.gServerType

local start_cfg = {
    [gServerType.gameServer] = require "bootstrap.gameserver.startlogic"
    -- [gServerType.loginServer] = require "bootstrap.loginserver.startlogic",
    -- [gServerType.chatServer] = require "bootstrap.chatserver.startlogic",
    -- [gServerType.globalServer] = require "bootstrap.globalserver.startlogic",
    -- [gServerType.infoServer] = require "bootstrap.infoserver.startlogic",
    -- [gServerType.crossServer] = require "bootstrap.crossserver.startlogic",
    -- [gServerType.webServer] = require "bootstrap.webserver.startlogic"
}

skynet.start(
    function()
        -- 启动日志服务
        -- skynet.newservice("serverLogService")
        -- 初始化sharetable，需要放最前面
        sharedefinit.load()
        timeUtil = require "util.timeUtil"

        --启动debug服务
        -- skynet.newservice("debug_console", clusterCfg.debug_port)

        local startLogic = start_cfg[gServerType.gameServer]
        startLogic(gServerType.gameServer)

        skynet.call(".launcher", "lua", "GC")

        skynet.error("start server success!!!!!")

        skynet.exit()
    end
)
