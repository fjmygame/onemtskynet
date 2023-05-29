-- --------------------------------------
-- Create Date : 2023-05-24 05:40:12
-- Author      : LHS
-- Version     : 1.0
-- Filename    : serverdef.lua
-- Introduce   : <<description>>
-- --------------------------------------
---@class serverDef
local serverDef = {
    -- 节点类型
    gNodeType = {
        gameserver = "gameserver",
        loginserver = "loginserver",
        globalserver = "globalserver",
        chatserver = "chatserver",
        infoserver = "infoserver",
        crossserver = "crossserver",
        webserver = "webserver"
    },
    -- 节点类型id
    gNodeTypeId = {
        gameserver = 1,
        loginserver = 2,
        globalserver = 3,
        chatserver = 4,
        infoserver = 5,
        crossserver = 6,
        webserver = 7
    },
    -- 节点id -> 节点类型
    gNodeTypeIdName = {
        [1] = "gameserver",
        [2] = "loginserver",
        [3] = "globalserver",
        [4] = "chatserver",
        [5] = "infoserver",
        [6] = "crossserver",
        [7] = "webserver"
    },
    -- 服务状态
    gServerStatus = {
        NORMAL = 1, -- 正常
        MAINTENANCE = 2, -- 维护
        WHITEIP = 3, -- 白名单
        NEWSERVER = 4 --新服
    },
    gServerTag = {
        FREE = 1, --通畅
        BUSY = 2 --繁忙
    },
    -- 踢人标识
    TickCode = {
        tick = 101, -- 踢人
        maintenance = 102, -- 服务器维护
        seal = 103, -- 被封
        gdpr = 104, -- GDPR踢人
        sessionerr = 105 -- session异常
    }
}

return serverDef
