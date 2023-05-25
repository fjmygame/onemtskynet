--------------------------------------------------------------------------------
-- 文件: serviceList.lua
-- 作者: zkb
-- 时间: 2020-02-29 14:58:31
-- 描述: gameserver服务启动列表
--------------------------------------------------------------------------------

local serviceList = {
        --可能需要先init和start的服务
        --{},
        -- 要开启的服务列表
        {
                "batchDataService", -- 游戏服uid管理中心 by sgys
                "externalService", --外部服务 by happy
                "rankService", --排行榜服务 by gjy
                "allianceService", --联盟服务  by gjy
                "activityPostService", -- 活动驿站
                "agentPoolService", --玩家agent池服务 by happy
                "microActivityService", -- 活动服务 by happy
                "certificateService", -- 参赛资格服务
                "rechargeService", --充值服务 bys gys
                "feastService", -- 功能宴会服务 by happy
                "marriageService", -- 子嗣联姻 by sgys
                "arenaService", -- 竞技场 by sgys
                "socialService", -- 社交 by sgys
                "redService", -- 红点服务 by happy
                "mealService", -- 膳食服务 by happy
                "statsService", -- 统计服务 by sgys
                "newMailService", -- 邮件服务 by happy
                "usePropService", -- 使用道具活动服务
                "bloodLadyService", -- 血腥夫人
                "chariotService", -- 战车大赛
                "rankActivityService", -- 个人冲榜活动
                "allianceChessService", -- 联盟棋局
                "playerModuleService", -- 玩家模块服务[用于支持离线模块] by sgys
                "kingdomSettingService", -- 通用配置服务 by happy
                "palaceService", -- 宫殿服务
                "dancingPartyService", -- 舞会服务
                "heroContestService", -- 英雄大赛
                "summitService", -- 会谈服务
                "infoService", -- 信息服
                "allianceAssembleService", -- 联盟集结
                "niebelungenService", -- 尼伯龙根的宝藏
                "crossBloodLadySlaveService", -- 跨服血腥夫人
                "crossMsgReadService", -- 跨服消息处理
                "triggerQuestService", --触发任务
                "conquestService", --征服之战
                "gmTriggerGiftService", -- GM触发礼包服务
                "battlepassService",
                "miniGameService", --小游戏服务
                "festivalActivityService", --节日活动
                "navigationService", --本服大航海
                "athensService",
                "pubPokerService", --本服扑克
                "festivalPackService", --节日礼袋
                "itemDepositService",
                "petService",
                "homeService",
                "propelService",
                "rankAchievementService",
                "petRunService",
                "rankAchieveCelebrationSlaveService",
                "petRunGameService",
                "cookingService",
                "detectiveService",
                "pushService",
                "loseBackService",
                "translateService",
                "monsterSurroundService",
                "danceBattleService",
                "danceBattleRunService",
                "monopolyService"
        }
}

return serviceList
