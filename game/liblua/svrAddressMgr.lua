-- --------------------------------------
-- Create Date:2021-05-07 15:04:29
-- Author  : Happy Su
-- Version : 1.0
-- Filename: svrAddressMgr.lua
-- Introduce  : 类介绍
-- --------------------------------------

local skynet = require "skynet.manager"
local svrconf = require "svrconf"
local clusterExt = require "clusterExt"
local dbDef = require("dbDef")
---@class svrAddressMgr
local svrAddressMgr = BuildOther("svrAddressMgr")

local DBType = dbDef.DBType
local DBSvrAddr = dbDef.DBSvrAddr

---------------------------服务名称格式---------------------------------
--全局服bub服务(中转与登陆服、游戏等信息)
svrAddressMgr.hubSvr = ".hubSvr"

--配置数据DB服务名称
svrAddressMgr.confDBSvr = DBSvrAddr[DBType.confdb]
--游戏数据DB服务名称
svrAddressMgr.gameDBSvr = DBSvrAddr[DBType.gamedb]
--全局数据DB服务名称
svrAddressMgr.globalDBSvr = DBSvrAddr[DBType.globaldb]
--跨服聊天数据DB服务名称
svrAddressMgr.chatDBSvr = DBSvrAddr[DBType.chatdb]
-- 跨服数据库服务名称
svrAddressMgr.crossDBSvr = DBSvrAddr[DBType.crossdb]

--广告分量器服务
svrAddressMgr.adImportRuleSvr = ".adImportRuleSvr@%d"
-- 王国列表web服务
svrAddressMgr.kingdomWebSvr = ".kingdomWebSvr@%d"
--login slave 服务
svrAddressMgr.loginSlaveSvr = ".loginSlaveSvr@%d"
--系统时间服务
svrAddressMgr.systimeSvr = ".systimeservice@%d"
--游戏数据Redis服务名称
svrAddressMgr.redisSvr = ".redis_gamedb@%d"
svrAddressMgr.redisSubSvr = ".r_gamedb_sub@%d@%s"
-- 全局的数据库服务
svrAddressMgr.globalDataCenterSvr = ".globalDataCenterSvr@%d"
-- 港口/中心港口
svrAddressMgr.clusterInfSvr = ".clusterInfSvr@%d"
-- 用户数据中心
svrAddressMgr.datacenterLogSvr = ".datacenterLogSvr@%d"
svrAddressMgr.playerAgentPoolSvr = ".playerAgentPoolSvr@%d"
svrAddressMgr.globalBackupSvr = ".globalBackupSvr@%d"
-- 网关服务
svrAddressMgr.gateSvr = ".gateSvr%d"

-- 自动生成 %d=nodeid
--#auto address begin
svrAddressMgr.debugCheckSvr = ".debugCheckSvr@%d"
svrAddressMgr.batchDataSvr = ".batchDataSvr@%d"
svrAddressMgr.feastSvr = ".feastSvr@%d"
svrAddressMgr.arenaSvr = ".arenaSvr@%d"
svrAddressMgr.socialSvr = ".socialSvr@%d"
svrAddressMgr.microActivitySvr = ".microActivitySvr@%d"
svrAddressMgr.playerModuleSvr = ".playerModuleSvr@%d"
svrAddressMgr.newMailSvr = ".newMailSvr@%d"
svrAddressMgr.redSvr = ".redSvr@%d"
svrAddressMgr.marriageSvr = ".marriageSvr@%d"
svrAddressMgr.allianceSvr = ".allianceSvr@%d"
svrAddressMgr.rankSvr = ".rankSvr@%d"
svrAddressMgr.externalSvr = ".externalSvr@%d"
svrAddressMgr.rechargeSvr = ".rechargeSvr@%d"
svrAddressMgr.mealSvr = ".mealSvr@%d"
svrAddressMgr.dancingPartySvr = ".dancingPartySvr@%d"
svrAddressMgr.palaceSvr = ".palaceSvr@%d"
svrAddressMgr.heroContestSvr = ".heroContestSvr@%d"
svrAddressMgr.summitSvr = ".summitSvr@%d"
svrAddressMgr.infoSvr = ".infoSvr@%d"
svrAddressMgr.allianceAssembleSvr = ".allianceAssembleSvr@%d"
svrAddressMgr.certificateSvr = ".certificateSvr@%d"
svrAddressMgr.crossBloodLadySlaveSvr = ".crossBloodLadySlaveSvr@%d"
svrAddressMgr.crossMsgReadSvr = ".crossMsgReadSvr@%d"
svrAddressMgr.activityPostSvr = ".activityPostSvr@%d"
svrAddressMgr.triggerQuestSvr = ".triggerQuestSvr@%d"
svrAddressMgr.kingdomSettingSvr = ".kingdomSettingSvr@%d"
svrAddressMgr.conquestSvr = ".conquestSvr@%d"
svrAddressMgr.gmTriggerGiftSvr = ".gmTriggerGiftSvr@%d"
svrAddressMgr.chariotSvr = ".chariotSvr@%d"
svrAddressMgr.crossChatRoomSvr = ".crossChatRoomSvr@%d"
svrAddressMgr.activityMonitorSvr = ".activityMonitorSvr@%d"
svrAddressMgr.crossRankSvr = ".crossRankSvr@%d"
svrAddressMgr.crossMessageSvr = ".crossMessageSvr@%d"
svrAddressMgr.globalSettingSvr = ".globalSettingSvr@%d"
svrAddressMgr.usePropSvr = ".usePropSvr@%d"
svrAddressMgr.statsSvr = ".statsSvr@%d@%d"
svrAddressMgr.battleRoyaleSvr = ".battleRoyaleSvr@%d@%d"
svrAddressMgr.crossChatSvr = ".crossChatSvr@%d@%d"
svrAddressMgr.crossDataCenterSvr = ".crossDataCenterSvr@%d@%d"
svrAddressMgr.playerInfoCacheSvr = ".playerInfoCacheSvr@%d@%d"
svrAddressMgr.allianceInfoCacheSvr = ".allianceInfoCacheSvr@%d@%d"
svrAddressMgr.subscribeSvr = ".subscribeSvr@%d@%d"
svrAddressMgr.loginCacheSvr = ".loginCacheSvr@%d@%d"
svrAddressMgr.bloodLadySvr = ".bloodLadySvr@%d"
svrAddressMgr.crossBloodLadySvr = ".crossBloodLadySvr@%d@%d"
svrAddressMgr.niebelungenSvr = ".niebelungenSvr@%d"
svrAddressMgr.crossNiebelungenSvr = ".crossNiebelungenSvr@%d@%d"
svrAddressMgr.crossDragonNestSvr = ".crossDragonNestSvr@%d@%d"
svrAddressMgr.preregisterSvr = ".preregisterSvr@%d"
svrAddressMgr.battlepassSvr = ".battlepassSvr@%d"
svrAddressMgr.navigationSvr = ".navigationSvr@%d"
svrAddressMgr.crossNavigationSvr = ".crossNavigationSvr@%d@%d"
svrAddressMgr.rankActivitySvr = ".rankActivitySvr@%d"
svrAddressMgr.inviteSvr = ".inviteSvr@%d"
svrAddressMgr.miniGameSvr = ".miniGameSvr@%d"
svrAddressMgr.pubPokerSvr = ".pubPokerSvr@%d"
svrAddressMgr.crossPubPokerSvr = ".crossPubPokerSvr@%d@%d"
svrAddressMgr.festivalActivitySvr = ".festivalActivitySvr@%d"
svrAddressMgr.athensSvr = ".athensSvr@%d"
svrAddressMgr.crossAthensSvr = ".crossAthensSvr@%d@%d"
svrAddressMgr.crossDragonNestTeamActivitySvr = ".crossDragonNestTeamActivitySvr@%d@%d"
svrAddressMgr.allianceChessSvr = ".allianceChessSvr@%d"
svrAddressMgr.crossAllianceChessSvr = ".crossAllianceChessSvr@%d@%d"
svrAddressMgr.festivalPackSvr = ".festivalPackSvr@%d"
svrAddressMgr.crossTimedTaskSvr = ".crossTimedTaskSvr@%d"
svrAddressMgr.crossSkinRankSvr = ".crossSkinRankSvr@%d"
svrAddressMgr.itemDepositSvr = ".itemDepositSvr@%d"
svrAddressMgr.fortressSvr = ".fortressSvr@%d@%d"
svrAddressMgr.crossCakeSvr = ".crossCakeSvr@%d@%d"
svrAddressMgr.battleMineSvr = ".battleMineSvr@%d@%d"
svrAddressMgr.petSvr = ".petSvr@%d"
svrAddressMgr.homeSvr = ".homeSvr@%d"
svrAddressMgr.propelSvr = ".propelSvr@%d"
svrAddressMgr.crossPropelSvr = ".crossPropelSvr@%d@%d"
svrAddressMgr.crossArenaNewSvr = ".crossArenaNewSvr@%d@%d"
svrAddressMgr.petRunSvr = ".petRunSvr@%d"
svrAddressMgr.crossPetRunSvr = ".crossPetRunSvr@%d@%d"
svrAddressMgr.petRunGameSvr = ".petRunGameSvr@%d"
svrAddressMgr.crossPersonRankActivitySvr = ".crossPersonRankActivitySvr@%d@%d"
svrAddressMgr.rankAchievementSvr = ".rankAchievementSvr@%d"
svrAddressMgr.rankAchieveCelebrationSvr = ".rankAchieveCelebrationSvr@%d"
svrAddressMgr.rankAchieveCelebrationSlaveSvr = ".rankAchieveCelebrationSlaveSvr@%d"
svrAddressMgr.crossHalloweenCandySvr = ".crossHalloweenCandySvr@%d@%d"
svrAddressMgr.combineVoteSvr = ".combineVoteSvr@%d"
svrAddressMgr.cookingSvr = ".cookingSvr@%d"
svrAddressMgr.crossCookingSvr = ".crossCookingSvr@%d@%d"
svrAddressMgr.crossTurkeySvr = ".crossTurkeySvr@%d@%d"
svrAddressMgr.detectiveSvr = ".detectiveSvr@%d"
svrAddressMgr.crossDetectiveSvr = ".crossDetectiveSvr@%d@%d"
svrAddressMgr.crossSnowmanSvr = ".crossSnowmanSvr@%d@%d"
svrAddressMgr.recallFriendSvr = ".recallFriendSvr@%d"
svrAddressMgr.loseBackSvr = ".loseBackSvr@%d"
svrAddressMgr.crossFireworkSvr = ".crossFireworkSvr@%d@%d"
svrAddressMgr.crossAllianceRankActivitySvr = ".crossAllianceRankActivitySvr@%d@%d"
svrAddressMgr.globalSprotoStatSvr = ".globalSprotoStatSvr@%d"
svrAddressMgr.pushSvr = ".pushSvr@%d"
svrAddressMgr.translateSvr = ".translateSvr@%d"
svrAddressMgr.monsterSurroundSvr = ".monsterSurroundSvr@%d"
svrAddressMgr.crossMonsterSurroundSvr = ".crossMonsterSurroundSvr@%d@%d"
svrAddressMgr.crossRoseGardenSvr = ".crossRoseGardenSvr@%d@%d"
svrAddressMgr.danceBattleSvr = ".danceBattleSvr@%d"
svrAddressMgr.crossDanceBattleSvr = ".crossDanceBattleSvr@%d@%d"
svrAddressMgr.danceBattleRunSvr = ".danceBattleRunSvr@%d"
svrAddressMgr.monopolySvr = ".monopolySvr@%d"
svrAddressMgr.monopolyCrossSvr = ".monopolyCrossSvr@%d@%d"
svrAddressMgr.activityPlayControlSvr = ".activityPlayControlSvr@%d"
svrAddressMgr.inheritActivateSvr = ".inheritActivateSvr@%d"
svrAddressMgr.crossHolidaysSvr = ".crossHolidaysSvr@%d@%d"
--#auto address end

-----------begin ！！！！！ 以下配置由脚本auto_service生成， 请勿手动修改！！！！！----------
-- 服务数量配置
local serviceNum = {
    --#auto serviceNum begin
    [svrAddressMgr.statsSvr] = 9,
    [svrAddressMgr.battleRoyaleSvr] = 9,
    [svrAddressMgr.crossChatSvr] = 9,
    [svrAddressMgr.crossDataCenterSvr] = 9,
    [svrAddressMgr.playerInfoCacheSvr] = 9,
    [svrAddressMgr.allianceInfoCacheSvr] = 9,
    [svrAddressMgr.subscribeSvr] = 9,
    [svrAddressMgr.loginCacheSvr] = 9,
    [svrAddressMgr.crossBloodLadySvr] = 9,
    [svrAddressMgr.crossNiebelungenSvr] = 2,
    [svrAddressMgr.crossDragonNestSvr] = 9,
    [svrAddressMgr.crossNavigationSvr] = 9,
    [svrAddressMgr.crossPubPokerSvr] = 9,
    [svrAddressMgr.crossAthensSvr] = 9,
    [svrAddressMgr.crossDragonNestTeamActivitySvr] = 9,
    [svrAddressMgr.crossAllianceChessSvr] = 9,
    [svrAddressMgr.fortressSvr] = 9,
    [svrAddressMgr.crossCakeSvr] = 9,
    [svrAddressMgr.battleMineSvr] = 9,
    [svrAddressMgr.crossPropelSvr] = 9,
    [svrAddressMgr.crossArenaNewSvr] = 9,
    [svrAddressMgr.crossPetRunSvr] = 9,
    [svrAddressMgr.crossPersonRankActivitySvr] = 9,
    [svrAddressMgr.crossHalloweenCandySvr] = 9,
    [svrAddressMgr.crossCookingSvr] = 9,
    [svrAddressMgr.crossTurkeySvr] = 9,
    [svrAddressMgr.crossDetectiveSvr] = 9,
    [svrAddressMgr.crossSnowmanSvr] = 9,
    [svrAddressMgr.crossFireworkSvr] = 9,
    [svrAddressMgr.crossAllianceRankActivitySvr] = 9,
    [svrAddressMgr.crossMonsterSurroundSvr] = 9,
    [svrAddressMgr.crossRoseGardenSvr] = 9,
    [svrAddressMgr.crossDanceBattleSvr] = 9,
    [svrAddressMgr.monopolyCrossSvr] = 9,
    [svrAddressMgr.crossHolidaysSvr] = 9
    --#auto serviceNum end
}
svrAddressMgr.serviceNum = serviceNum
-- 配置名称对应的服务数
svrAddressMgr.serviceName2Num = {
    --#auto serviceName2Num begin
    statsService = serviceNum[svrAddressMgr.statsSvr],
    battleRoyaleService = serviceNum[svrAddressMgr.battleRoyaleSvr],
    crossChatService = serviceNum[svrAddressMgr.crossChatSvr],
    crossDataCenterService = serviceNum[svrAddressMgr.crossDataCenterSvr],
    playerInfoCacheService = serviceNum[svrAddressMgr.playerInfoCacheSvr],
    allianceInfoCacheService = serviceNum[svrAddressMgr.allianceInfoCacheSvr],
    subscribeService = serviceNum[svrAddressMgr.subscribeSvr],
    loginCacheService = serviceNum[svrAddressMgr.loginCacheSvr],
    crossBloodLadyService = serviceNum[svrAddressMgr.crossBloodLadySvr],
    crossNiebelungenService = serviceNum[svrAddressMgr.crossNiebelungenSvr],
    crossDragonNestService = serviceNum[svrAddressMgr.crossDragonNestSvr],
    crossNavigationService = serviceNum[svrAddressMgr.crossNavigationSvr],
    crossPubPokerService = serviceNum[svrAddressMgr.crossPubPokerSvr],
    crossAthensService = serviceNum[svrAddressMgr.crossAthensSvr],
    crossDragonNestTeamActivityService = serviceNum[svrAddressMgr.crossDragonNestTeamActivitySvr],
    crossAllianceChessService = serviceNum[svrAddressMgr.crossAllianceChessSvr],
    fortressService = serviceNum[svrAddressMgr.fortressSvr],
    crossCakeService = serviceNum[svrAddressMgr.crossCakeSvr],
    battleMineService = serviceNum[svrAddressMgr.battleMineSvr],
    crossPropelService = serviceNum[svrAddressMgr.crossPropelSvr],
    crossArenaNewService = serviceNum[svrAddressMgr.crossArenaNewSvr],
    crossPetRunService = serviceNum[svrAddressMgr.crossPetRunSvr],
    crossPersonRankActivityService = serviceNum[svrAddressMgr.crossPersonRankActivitySvr],
    crossHalloweenCandyService = serviceNum[svrAddressMgr.crossHalloweenCandySvr],
    crossCookingService = serviceNum[svrAddressMgr.crossCookingSvr],
    crossTurkeyService = serviceNum[svrAddressMgr.crossTurkeySvr],
    crossDetectiveService = serviceNum[svrAddressMgr.crossDetectiveSvr],
    crossSnowmanService = serviceNum[svrAddressMgr.crossSnowmanSvr],
    crossFireworkService = serviceNum[svrAddressMgr.crossFireworkSvr],
    crossAllianceRankActivityService = serviceNum[svrAddressMgr.crossAllianceRankActivitySvr],
    crossMonsterSurroundService = serviceNum[svrAddressMgr.crossMonsterSurroundSvr],
    crossRoseGardenService = serviceNum[svrAddressMgr.crossRoseGardenSvr],
    crossDanceBattleService = serviceNum[svrAddressMgr.crossDanceBattleSvr],
    monopolyCrossService = serviceNum[svrAddressMgr.monopolyCrossSvr],
    crossHolidaysService = serviceNum[svrAddressMgr.crossHolidaysSvr]
    --#auto serviceName2Num end
}
-----------end ！！！！！ 以上配置由脚本auto_service生成， 请勿手动修改！！！！！----------

-- 服务地址均衡id[例如:id==uid], svrNum服务实例数
local function genServiceId(id, svrNum)
    if type(id) == "number" and svrNum and svrNum > 1 then
        return (id % svrNum) + 1
    else
        return 1
    end
end
svrAddressMgr.genServiceId = genServiceId

function svrAddressMgr.getSvrBlanceId(id, svrName)
    local svrNum = serviceNum[svrName]
    return genServiceId(id, svrNum)
end

--------------------------服务地址操作 API START------------------------------
function svrAddressMgr.setSvrNew(address, key, nodeid, otherid)
    local server_name = key
    if nodeid and otherid then
        server_name = string.safeFormat(key, nodeid, otherid)
    elseif nodeid then
        server_name = string.safeFormat(key, nodeid)
    elseif otherid then
        server_name = string.safeFormat(key, otherid)
    end

    skynet.name(server_name, address)
    return server_name
end

--设置王国服务地址
function svrAddressMgr.setSvr(address, key, nodeid, otherid)
    -- log.Debug("old","address,key,kingdomid,otherid",string.safeFormat("[:%08x]",address),key,kingdomid,otherid)
    return svrAddressMgr.setSvrNew(address, key, nodeid, otherid)
end

--设置全局服务地址
function svrAddressMgr.setGlobalSvr(address, key, nodeid, otherid)
    -- log.Debug("old","address,key,kingdomid,otherid",string.safeFormat("[:%08x]",address),key,kingdomid,otherid)
    local server_name = key
    if nodeid and otherid then
        server_name = string.safeFormat(key, nodeid, otherid)
    elseif nodeid then
        server_name = string.safeFormat(key, nodeid)
    elseif otherid then
        server_name = string.safeFormat(key, otherid)
    end

    skynet.name(server_name, address)
end

-- 获取多服务节点的地址[需要均衡算法]
function svrAddressMgr.balanceSvr(key, nodeid, id)
    local svrNum = serviceNum[key]
    if not svrNum or not id then
        return svrAddressMgr.getSvrNew(key, nodeid)
    end

    local index = genServiceId(id, svrNum)
    return svrAddressMgr.getSvrNew(key, nodeid, index)
end

--获取服务地址
function svrAddressMgr.getSvrNew(key, nodeid, otherid)
    if nodeid and otherid then
        key = string.safeFormat(key, nodeid, otherid)
    elseif nodeid then
        key = string.safeFormat(key, nodeid)
    elseif otherid then
        key = string.safeFormat(key, otherid)
    end

    --获取本节点服务地址
    local address = skynet.localname(key)

    --如果本节点服务地址为nil，则跨节点获取服务地址
    if nodeid and not address then
        local nodeName = svrconf.getNodeNameByNodeId(nodeid)
        if not nodeName then
            log.ErrorStack("sys", "can not found nodeid:", nodeid, " nodeName")
            return
        end
        address = clusterExt.pack_cluster_address(nodeName, key)
    end

    return address
end
--------------------------服务地址操作 API END------------------------------

return svrAddressMgr
