-- --------------------------------------
-- Create Date:2021-04-29 19:47:24
-- Author  : sgys
-- Version : 1.0
-- Filename: logDef.lua
-- Introduce  : 类介绍
-- --------------------------------------
---@class logDef
local logDef = {
    MGR_LOG_SEND_BATCH_NUM = 30, -- 后台日志批量发送条数
    MGR_LOG_SEND_MIN_INV = 1, -- 后台日志发送最小间隔
    MGR_LOG_SEND_MAX_INV = 60, -- 后台日志发送最大间隔
    MGR_LOG_PLAYER_CACHE_TIMEOUT = 60 * 60, -- 缓存时间
    -- 日志类型
    logType = {
        gain_gold = "gain_gold", --金币获取日志
        consumer_gold = "consumer_gold" --金币消费日志
    },
    --同步日志类型
    -- sync_log = {
    --     recharge_log = true,
    --     real_online_log = true,
    --     rank_log = true,
    --     online_log = true,
    --     offline_log = true,
    -- 	worldmap_refresh_log = true,
    -- 	login_costtime_warn_log = true,
    -- 	login_unusual_warn_log = true,
    -- }

    -- 联盟log
    allianceJoinType = {
        APPLY = 1, -- 直接申请加入[申请就进的]
        INVITE = 2, -- 被邀请加入
        AGREE = 3 -- 申请了被同意加入
    },
    allianceOpType = {
        CREATE = 1, -- 联盟创建
        JOIN = 2, -- 加入联盟
        DISMISS = 3, -- 解散联盟
        APPLY_JOIN = 4, -- 申请加入
        AGREE_JOIN = 5, -- 同意申请
        REJECT_JOIN = 6, -- 拒绝申请
        INVITE_JOIN = 7, -- 邀请入盟
        INVITE_MOVE = 8, -- 邀请迁城
        RENAME = 9, -- 更改联盟名
        QUIT = 10, -- 退出联盟
        EXPEL = 11, -- 踢出联盟
        ROME = 12, -- 罗马战魂
        REJECT_INVITE = 13 --拒绝邀请
    },
    ------------------------------------------------------------
    --
    --邮件日志类型
    mailStatusType = {
        add = 1, -- 获得邮件
        del = 2, -- 删除邮件
        lock = 3, -- 锁定邮件
        unlock = 4, -- 解除锁定
        get = 5 -- 领取奖励
    },
    -----------------------数据中心日志定义------------------------
    --在线类型
    onlineLogType = {
        online = 1, --在线
        offline = 2 --离线
    },
    --日志行为类型
    logActionType = {
        server_error = "server_error", -- 服务器错误日志
        online = "online", --在线
        overline = "online_line", --跨天在线
        realline = "real_online", --实时在线
        consumer_gold = "consumer_gold",
        gain_gold = "gain_gold",
        gain_item = "gain_item",
        consumer_item = "consumer_item",
        consumer_res = "consumer_res",
        gain_res = "gain_res",
        cmd_cost_time_stat = "cmd_cost_time_stat" -- 服务消息耗时记录
    },
    --日志需求类型
    logNeedsType = {
        action = 0,
        point = 1
    },
    -- 日志对应的功能上的一些类型区分

    logGainHeroType = {
        RECOMMEND = 1, ----推荐信，
        EXCHANGE_HERO_ACTIVITY = 2, ----- 英雄活动
        ITEM = 3 -- 获得道具
    },
    --- 英雄资质提升对应的方式
    logHeroQlyupType = {
        EXP = 1, -- 骑士资质经验
        ITEM = 2, -- 武力结晶
        STAR_ITEM = 3 -- 星级卷轴
    },
    -- 英雄光环提升方式
    logHeroHaloUpType = {
        prop = 1, -- 道具提升
        attr = 2 -- 属性提升
    },
    ---- 通用的定义，没有指定什么功能的
    logCommonType = {
        prop = 1 ----使用道具
    },
    ---- 通畅数量值
    logCommonNum = {
        one = 1 -- 一次
    },
    --- 通用等级
    logCommonLevel = {
        one = 1, --通用等级
        ten = 10
    },
    logAffair = {
        one = 1, --单次征收
        many = 2, --多次
        onhook = 3 --挂机
    },
    logChangePrincess = {
        one = 1 --主动更换
    },
    logResult = {
        success = 1,
        fail = 2
    },
    -- 通用判断
    logCommonJudge = {
        yes = 1,
        no = 2
    },
    --技能
    logSkillType = {
        unlock = 1, --解锁
        uplevel = 2 --升级
    },
    -- 研修所学习类型
    logSchoolType = {
        start = 1, --开始
        finish = 2, --完成
        batch_start = 3, -- 批量开始
        batch_finish = 4, -- 批量完成
        onhook = 5 -- 挂机
    },
    ----任务类型
    logQuestType = {
        daily = 1,
        main = 2,
        achievement = 3,
        recharge = 4,
        common = 5,
        battlepass = 6
    },
    ----- 通用是否免费付费
    logCommonMoney = {
        free = 1,
        pay = 2
    },
    --- 通用开关类型
    logSwitchType = {
        open = 1, -- 开
        off = 2 -- 关
    },
    --- 宴会结束类型
    logFeastEndType = {
        time = 1, --时间到了
        advance = 2, --手动结束
        full = 3 -- 坐满结束
    },
    --1,举办奖励，2参加奖励
    logFeastRewardType = {
        hold = 1,
        join = 2
    },
    -- 求婚方式
    logProposeType = {
        target = 1, -- 指定
        kingdom = 2 -- 全服
    },
    -- 通用操作类型
    logOperationType = {
        one = 1, --单个
        onekey = 2, --一键
        gm = 3, -- gm操作
        onhook = 4 -- 挂机
    },
    -- 巡游移动类型
    logJourneyMoveType = {
        move = 1, -- 巡游
        onekey = 2,
        -- 一键巡游
        hook = 3 -- 挂机巡游
    },
    -- 巡游道具使用类型
    logJourneyItemType = {
        addpy = 1, --1. 使用道具增加体力
        addluck = 2 -- 2. 使用道具增加运势"
    },
    ---好友类型
    logFriendType = {
        add = 1,
        delete = 2,
        shile = 3
    },
    -- 会谈
    logSummitSiteDownType = {
        empty = 1, --空位
        kick = 2 --踢人
    },
    logSummitProtectType = {
        useItem = 1
    },
    logSummitInRoomType = {
        detail = 1,
        find = 2
    },
    logSummitOverType = {
        over = 1,
        beKick = 2,
        sitDownKick = 3
    },
    --- 战斗结果类型
    logFightResult = {
        kill = 1,
        notKill = 2
    },
    logTeamOrder = {
        create_team = 1,
        join_team = 2,
        apply_team = 3,
        agree_apply = 4,
        reject_apply = 5,
        cancel_apply = 6,
        onekey_reject = 7,
        kick_member = 8,
        quit_team = 9,
        dismiss_team = 10,
        invite_friend = 11,
        accept_invite = 12,
        modify_recruit = 13,
        reject_invite = 14
    },
    logRankRewardType = {
        person = 1, -- 个人榜
        alliance = 2, -- 联盟榜
        server = 3, -- 区服榜
        team = 4, -- 组队榜
        single = 5, -- single榜
        alliance_member = 6 --联盟成员得分
    },
    logRankRewardReciveType = {
        reqget = 1, -- 1. 主动领奖
        exitalliance = 2, -- 2.退盟补发
        actclose = 3 -- 3.活动结束补发
    },
    logGameType = {
        single = 1, --单局游戏
        daily = 2,
        --当天游戏
        weekly = 3 --游戏周期
    },
    logFortressEventType = {
        -- 1.探索 2.避开 3.击杀对方 4.拾取箱子 5.移动消失 6.过期 7.进入新的物资点 8.攻击npc
        explore = 1,
        skip = 2,
        attack_win = 3,
        get_box = 4,
        move = 5,
        expire = 6,
        enter_cell = 7,
        npc = 8
    },
    -- 堡垒血量变化日志类型
    logFortressHpType = {
        attack_player = 1, -- 攻击玩家
        attack_robot = 2, -- 攻击机器人
        legion_attack_player = 3, -- 军团攻击玩家
        legion_attack_robot = 4, -- 军团攻击机器人
        reset = 5, -- 重置
        rebuild = 6 --重建
    },
    -- 堡垒战斗类型
    logFrotressBattleType = {
        attack_player = 1, -- 攻击玩家
        attack_robot = 2, -- 攻击机器人
        legion_attack_player = 3, -- 军团攻击玩家
        legion_attack_robot = 4, -- 军团攻击机器人
        mercenary_attack_player = 5, --佣兵打玩家
        mercenary_attack_robot = 6 --佣兵打玩家
    },
    -- 堡垒机器人数量变更类型
    logFortressRobotChangeType = {
        add = 1, -- 投放
        kill = 2, -- 击杀
        reset = 3 -- 机器人堡垒重置
    },
    -- 英雄派遣类型
    logFortressWarHeroSetType = {
        auto = 1, -- 自动
        manual = 2 -- 手动
    },
    -- 宠物繁育请求操作类型
    logPetBreedOptType = {
        start = 1, -- 发起
        expire = 2, -- 到期
        undo = 3, -- 自己取消
        refused = 4, -- 被拒绝
        success = 5, -- 成功被接受
        fullSeat = 6, -- 宠物位满席自动取消
        onekey_refused = 7 -- 一键拒绝
    },
    --宠物随身位操作类型
    logPetFollowOptType = {
        set = 1, -- 设置
        delete = 2 -- 放生
    },
    -- 通知设置类型
    logNotificationSettingType = {
        General = 1, -- 通用
        Push = 2, -- 推送
        Chat = 3 -- 聊天
    },
    -- 通知设置子类型
    --[[
        1.上线通知  status_online
        2.推送系统推送允许总开关  permission_main_switch
        3.郊外活动（子目录）suburban_main_activities
        4.在郊外活动开启时通知 suburban_activities
        5.冲榜活动（子目录）billboard_flushing_main_activity
        6.在冲榜活动结束前30分钟通知  billboard_flushing_activity
        7.在玩法活动可以进行游玩时通知  play_activities
        8.好友私聊（子目录）main_private_chat
        9.在收到好友私聊消息时通知 private_chat
        10.私信-陌生人消息 stranger_message
    ]]
    logNotificationSettingSubType = {
        all = 0, -- 批量设置所有
        status_online = 1, -- 上线通知
        permission_main_switch = 2, -- 推送系统推送允许总开关
        suburban_main_activities = 3, -- 郊外活动（子目录）
        suburban_activities = 4, -- 在郊外活动开启时通知
        billboard_flushing_main_activity = 5, -- 冲榜活动（子目录）
        billboard_flushing_activity = 6, -- 在冲榜活动结束前30分钟通知
        play_activities = 7, -- 在玩法活动可以进行游玩时通知
        main_private_chat = 8, -- 好友私聊目录
        private_chat = 9, -- 在收到好友私聊消息时通知
        stranger_message = 10 -- 私信-陌生人消息
    }
}

return logDef
-----------------------------------------------------------------
