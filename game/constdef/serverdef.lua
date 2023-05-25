return {
    gServerType = {
        loginServer = "loginserver",
        globalServer = "globalserver",
        gameServer = "gameserver",
        chatServer = "chatserver",
        infoServer = "infoserver",
        crossServer = "crossserver",
        webServer = "webserver"
    },
    -- 服务状态
    gServerStatus = {
        NORMAL = 1, -- 正常
        MAINTENANCE = 2, -- 维护
        NEWSERVER = 3 --新服
    },
    -- 全服状态
    gGlobalServerStatus = {
        NORMAL = 1, -- 正常
        MAINTENANCE = 2, -- 维护
        WHITEIP = 3 -- 白名单
    },
    gServerTag = {
        FREE = 1,
        --通畅
        BUSY = 2
        --繁忙
    },
    -- 服务类型
    ServiceType = {
        red = 1, -- 红点系统
        playerModule = 2, -- 玩家模块
        marriage = 3, -- 联姻
        meal = 4, -- 膳食活动[狩猎/海盗]
        rank = 5, -- 排行榜
        stats = 6, -- 统计
        mail = 7, -- 邮件
        activity = 8 -- 活动
    },
    -- 踢人标示
    TickCode = {
        tick = 101, -- 踢人
        maintenance = 102, -- 服务器维护
        seal = 103, -- 被封
        gdpr = 104, -- GDPR踢人
        sessionerr = 105 -- session异常
    }
}
