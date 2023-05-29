-- --------------------------------------
-- Create Date:2021-05-18 17:46:01
-- Author  : sgys
-- Version : 1.0
-- Filename: activityNotify.lua
-- Introduce  : 类介绍
-- --------------------------------------

local niebelungenAPI = require("niebelungenAPI")
local crossNiebelungenAPI = require("crossNiebelungenAPI")
local crossBloodLadyAPI = require("crossBloodLadyAPI")
local crossBloodLadySlaveAPI = require("crossBloodLadySlaveAPI")
local crossArenaNewAPI = require("crossArenaNewAPI")
local battleRoyaleApi = require("battleRoyaleApi")
local chariotAPI = require("chariotAPI")
local usePropAPI = require("usePropAPI")
local bloodLadyAPI = require("bloodLadyAPI")
local rankActivityAPI = require("rankActivityAPI")
local crossNavigationAPI = require("crossNavigationAPI")
local battlepassAPI = require("battlepassAPI")
local allianceChessAPI = require("allianceChessAPI")
local miniGameAPI = require("miniGameAPI")
local festivalActivityAPI = require("festivalActivityAPI")
local navigationAPI = require("navigationAPI")
local athensAPI = require("athensAPI")
local crossAthensAPI = require("crossAthensAPI")
local crossPubPokerAPI = require("crossPubPokerAPI")
local crossAllianceChessAPI = require("crossAllianceChessAPI")
local pubPokerAPI = require("pubPokerAPI")
local festivalPackAPI = require("festivalPackAPI")
local battleMineAPI = require("battleMineAPI")
local crossDragonNestTeamActivityAPI = require("crossDragonNestTeamActivityAPI")
local fortressAPI = require("fortressAPI")
local crossPropelAPI = require("crossPropelAPI")
local propelAPI = require("propelAPI")
local crossPetRunAPI = require("crossPetRunAPI")
local petRunAPI = require("petRunAPI")
local crossHalloweenCandyAPI = require("crossHalloweenCandyAPI")
local crossPersonRankActivityAPI = require("crossPersonRankActivityAPI")
local crossAllianceRankActivityAPI = require("crossAllianceRankActivityAPI")
local crossTurkeyAPI = require("crossTurkeyAPI")
local cookingAPI = require("cookingAPI")
local crossCookingAPI = require("crossCookingAPI")
local detectiveAPI = require("detectiveAPI")
local crossDetectiveAPI = require("crossDetectiveAPI")
local crossSnowmanAPI = require("crossSnowmanAPI")
local crossFireworkAPI = require("crossFireworkAPI")
local crossMonsterSurroundAPI = require("crossMonsterSurroundAPI")
local monsterSurroundAPI = require("monsterSurroundAPI")
local crossRoseGardenAPI = require("crossRoseGardenAPI")
local danceBattleAPI = require("danceBattleAPI")
local crossDanceBattleAPI = require("crossDanceBattleAPI")
local monopolyAPI = require("monopolyAPI")
local monopolyCrossAPI = require("monopolyCrossAPI")
-- local activityPlayControlAPI = require("activityPlayControlAPI")
local crossCakeAPI = require("crossCakeAPI")
local crossHolidaysAPI = require("crossHolidaysAPI")
---@class activityNotify
local _M = BuildUtil("activityNotify")

local ActivityType = gActivityDef.ActivityType
local AlliancePlaySubType = gActivityDef.AlliancePlaySubType
local AreaRankSubType = gActivityDef.AreaRankSubType
local TeamRankSubType = gActivityDef.TeamRankSubType
local UsePropSubType = gActivityDef.UsePropSubType
local PersonRankSubType = gActivityDef.PersonRankSubType
local MiniGameSubType = gActivityDef.MiniGameSubType
local FestivalSubType = gActivityDef.FestivalSubType
local AreaAllianceRankSubType = gActivityDef.AreaAllianceRankSubType
local CrossActivityType = gActivityDef.CrossActivityType

-- api 接口配置
-- [[ !!!! 注意：所有api都必须实现 publishActivityEvent 接口 ]]
-- 跨服
local _apiCrossConf =
    CreateBlankTable(
    _M,
    "_apiCrossConf",
    {
        [ActivityType.CrossAlliancePlay] = {
            [AlliancePlaySubType.Blood] = crossBloodLadyAPI,
            [AlliancePlaySubType.Niebelungen] = crossNiebelungenAPI,
            [AlliancePlaySubType.Navigation] = crossNavigationAPI,
            [AlliancePlaySubType.chess] = crossAllianceChessAPI,
            [AlliancePlaySubType.Poker] = crossPubPokerAPI,
            [AlliancePlaySubType.BattleMine] = battleMineAPI,
            [AlliancePlaySubType.Propel] = crossPropelAPI,
            [AlliancePlaySubType.PetRun] = crossPetRunAPI,
            [AlliancePlaySubType.HalloweenCandy] = crossHalloweenCandyAPI,
            [AlliancePlaySubType.Cooking] = crossCookingAPI,
            [AlliancePlaySubType.Detective] = crossDetectiveAPI,
            [AlliancePlaySubType.SaintPatrick] = crossHalloweenCandyAPI,
            [AlliancePlaySubType.MonsterSurround] = crossMonsterSurroundAPI,
            [AlliancePlaySubType.DanceBattle] = crossDanceBattleAPI,
            [AlliancePlaySubType.Monopoly] = monopolyCrossAPI
        },
        [ActivityType.TwoAreaRank] = {
            [AreaRankSubType.IntimacyAdd] = crossPersonRankActivityAPI,
            [AreaRankSubType.NationalPower] = crossPersonRankActivityAPI,
            [AreaRankSubType.AptitudeAdd] = crossPersonRankActivityAPI,
            [AreaRankSubType.CharmAdd] = crossPersonRankActivityAPI,
            [AreaRankSubType.ArenaScoreChange] = crossArenaNewAPI,
            [AreaRankSubType.BattleRoyale] = battleRoyaleApi
        },
        [ActivityType.MultiAreaRank] = {
            [AreaRankSubType.IntimacyAdd] = crossPersonRankActivityAPI,
            [AreaRankSubType.NationalPower] = crossPersonRankActivityAPI,
            [AreaRankSubType.AptitudeAdd] = crossPersonRankActivityAPI,
            [AreaRankSubType.CharmAdd] = crossPersonRankActivityAPI,
            [AreaRankSubType.ArenaScoreChange] = crossArenaNewAPI,
            [AreaRankSubType.BattleRoyale] = battleRoyaleApi,
            [AreaRankSubType.Fortress] = fortressAPI
        },
        [ActivityType.CrossTeamRank] = {
            [TeamRankSubType.Athens] = crossAthensAPI,
            [TeamRankSubType.DragonNest_1] = crossDragonNestTeamActivityAPI,
            [TeamRankSubType.DragonNest_2] = crossDragonNestTeamActivityAPI,
            [TeamRankSubType.DragonNest_3] = crossDragonNestTeamActivityAPI
        },
        [ActivityType.Cross_Festival] = {
            [FestivalSubType.Cake] = crossCakeAPI,
            [FestivalSubType.Turkey] = crossTurkeyAPI,
            [FestivalSubType.Snowman] = crossSnowmanAPI,
            [FestivalSubType.Firework] = crossFireworkAPI,
            [FestivalSubType.Drink] = crossCakeAPI,
            [FestivalSubType.Fishing] = crossTurkeyAPI,
            [FestivalSubType.RoseGarden] = crossRoseGardenAPI,
            [FestivalSubType.BlockCastle] = crossSnowmanAPI,
            [FestivalSubType.Kite] = crossHolidaysAPI,
            [FestivalSubType.SkyLantern] = crossHolidaysAPI,
            [FestivalSubType.BlockCastle] = crossSnowmanAPI,
            [FestivalSubType.Kite] = crossHolidaysAPI,
            [FestivalSubType.SkyLantern] = crossHolidaysAPI
        },
        [ActivityType.CrossAllianceRank] = {
            [AreaAllianceRankSubType.AlliancePowerAdd] = crossAllianceRankActivityAPI,
            [AreaAllianceRankSubType.AllianceIntimacyAdd] = crossAllianceRankActivityAPI,
            [AreaAllianceRankSubType.AllianceAptitudeAdd] = crossAllianceRankActivityAPI
        }
    }
)

-- 单服
local _apiConf =
    CreateBlankTable(
    _M,
    "_apiConf",
    {
        [ActivityType.AlliancePlay] = {
            [AlliancePlaySubType.Blood] = bloodLadyAPI,
            [AlliancePlaySubType.Niebelungen] = niebelungenAPI,
            [AlliancePlaySubType.chess] = allianceChessAPI,
            [AlliancePlaySubType.Navigation] = navigationAPI,
            [AlliancePlaySubType.Poker] = pubPokerAPI,
            [AlliancePlaySubType.Propel] = propelAPI,
            [AlliancePlaySubType.PetRun] = petRunAPI,
            [AlliancePlaySubType.Cooking] = cookingAPI,
            [AlliancePlaySubType.Detective] = detectiveAPI,
            [AlliancePlaySubType.MonsterSurround] = monsterSurroundAPI,
            [AlliancePlaySubType.DanceBattle] = danceBattleAPI,
            [AlliancePlaySubType.Monopoly] = monopolyAPI
        },
        [ActivityType.CrossAlliancePlay] = {
            [AlliancePlaySubType.Blood] = crossBloodLadySlaveAPI
        },
        [ActivityType.TeamRank] = {
            [TeamRankSubType.Chariot] = chariotAPI,
            [TeamRankSubType.Athens] = athensAPI
        },
        [ActivityType.UseProp] = {
            [UsePropSubType.Fishing] = usePropAPI,
            [UsePropSubType.Cure] = usePropAPI,
            [UsePropSubType.Army] = usePropAPI,
            [UsePropSubType.Treasure] = usePropAPI,
            [UsePropSubType.Conscription] = usePropAPI,
            [UsePropSubType.Alchemy] = usePropAPI,
            [UsePropSubType.Wish] = usePropAPI,
            [UsePropSubType.Bonfire] = usePropAPI,
            [UsePropSubType.Wish] = usePropAPI
        },
        [ActivityType.PersonRank] = {
            [PersonRankSubType.IntimacyAdd] = rankActivityAPI, -- 100, -- 亲密度增加排行
            [PersonRankSubType.MoraleConsume] = rankActivityAPI, -- 101, -- 士兵消耗排行
            [PersonRankSubType.NationalPower] = rankActivityAPI, -- 102, -- 国力冲榜
            [PersonRankSubType.AptitudeAdd] = rankActivityAPI, -- 103, -- 英雄总资质提升排行
            [PersonRankSubType.FeastScoreAdd] = rankActivityAPI, -- 104, -- 宴会积分排行榜
            [PersonRankSubType.SilverConsume] = rankActivityAPI, -- 105, -- 银币消耗排行榜
            [PersonRankSubType.ArenaScoreChange] = rankActivityAPI, -- 106, -- 竞技场
            [PersonRankSubType.FoodConsume] = rankActivityAPI, -- 108, -- 粮食消耗排行榜
            [PersonRankSubType.CopyPass] = rankActivityAPI, -- 109, -- 副本过关排行榜
            [PersonRankSubType.CharmAdd] = rankActivityAPI -- 117 -- 魅力增加排行
        },
        [ActivityType.MiniGame] = {
            [MiniGameSubType.HeroRoad] = miniGameAPI,
            [MiniGameSubType.BoatTreasure] = miniGameAPI,
            [MiniGameSubType.AncientGoldCountry] = miniGameAPI,
            [MiniGameSubType.Zuma] = miniGameAPI,
            [MiniGameSubType.HorseRace] = miniGameAPI
        },
        [ActivityType.Festival] = {
            [FestivalSubType.Carnival] = festivalActivityAPI,
            [FestivalSubType.Oktoberfest] = festivalActivityAPI,
            [FestivalSubType.Halloween] = festivalActivityAPI,
            [FestivalSubType.Christmas] = festivalActivityAPI,
            [FestivalSubType.Thanksgiving] = festivalActivityAPI,
            [FestivalSubType.Kitchen] = festivalActivityAPI,
            [FestivalSubType.Easter] = festivalActivityAPI,
            [FestivalSubType.Arbor] = festivalActivityAPI,
            [FestivalSubType.FlowerLottery] = festivalActivityAPI,
            [FestivalSubType.Maze] = festivalActivityAPI,
            [FestivalSubType.ChildrenDayLottery] = festivalActivityAPI,
            [FestivalSubType.Weave] = festivalActivityAPI,
            [FestivalSubType.Anniversary] = festivalActivityAPI,
            -- [FestivalSubType.Kite] = festivalActivityAPI,
            -- [FestivalSubType.Kite] = festivalActivityAPI,
            [FestivalSubType.Flame] = festivalActivityAPI,
            [FestivalSubType.Book] = festivalActivityAPI,
            -- [FestivalSubType.SkyLantern] = festivalActivityAPI,
            -- [FestivalSubType.SkyLantern] = festivalActivityAPI,
            [FestivalSubType.SkinTreasure] = festivalActivityAPI,
            [FestivalSubType.Gashapon] = festivalActivityAPI
        },
        [ActivityType.Cross_Festival] = {
            [FestivalSubType.Cake] = festivalActivityAPI,
            [FestivalSubType.Turkey] = festivalActivityAPI,
            [FestivalSubType.Snowman] = festivalActivityAPI,
            [FestivalSubType.Firework] = festivalActivityAPI,
            [FestivalSubType.Drink] = festivalActivityAPI,
            [FestivalSubType.Fishing] = festivalActivityAPI,
            [FestivalSubType.RoseGarden] = festivalActivityAPI,
            [FestivalSubType.BlockCastle] = festivalActivityAPI,
            [FestivalSubType.Kite] = festivalActivityAPI,
            [FestivalSubType.SkyLantern] = festivalActivityAPI,
            [FestivalSubType.BlockCastle] = festivalActivityAPI,
            [FestivalSubType.Kite] = festivalActivityAPI,
            [FestivalSubType.SkyLantern] = festivalActivityAPI
        }
    }
)

do
    -- 检查配置是否正确
    for type, apiMap in pairs(_apiCrossConf) do
        for subType, api in pairs(apiMap) do
            assert(
                api.publishActivityEvent,
                string.safeFormat(
                    "activityNotify.publish fail!!![api.publishActivityEvent not exist.] type:%s subType:%s",
                    type,
                    subType
                )
            )
        end
    end

    -- 检查配置是否正确
    for type, apiMap in pairs(_apiConf) do
        for subType, api in pairs(apiMap) do
            assert(
                api.publishActivityEvent,
                string.safeFormat(
                    "activityNotify.publish fail!!![api.publishActivityEvent not exist.] type:%s subType:%s",
                    type,
                    subType
                )
            )
        end
    end
end

-- 活动api接口
function _M.getApi(type, subType)
    local isCrossApi = CrossActivityType[type]
    if isCrossApi then
        return _apiCrossConf[type] and _apiCrossConf[type][subType], isCrossApi
    else
        return _apiConf[type] and _apiConf[type][subType], isCrossApi
    end
end

-- 活动api接口调用
function _M.callActivityApi_callActivityFunc(actData, funcName, ...)
    local api, isCrossApi = _M.getApi(actData.type, actData.subType)
    if isCrossApi then
        return api.callActivityFunc(actData, funcName, ...)
    else
        return api.callActivityFunc(gNodeID, actData.id, funcName, ...)
    end
end

-- 发布活动变更信息
function _M.publish(type, subType, event, ...)
    -- 战令服务需要所有活动
    battlepassAPI.publishActivityEvent(event)
    festivalPackAPI.publishActivityEvent(event)
    local api = _apiConf[type] and _apiConf[type][subType]
    if not api then
        log.Info("sys", "activityNotify.publish fail!!![The type is not config.]", type, subType)
        return -- log.ErrorStack("sys", "activityNotify.publish fail!!![The type is not config.]", type, subType)
    end
    -- activityPlayControlAPI.publishActivityEvent(event)
    api.publishActivityEvent(event, ...)
end

-- 发布活动变更信息
function _M.crossPublish(type, subType, event, ...)
    local api = _apiCrossConf[type] and _apiCrossConf[type][subType]
    if not api then
        log.Info("sys", "activityNotify.cross publish fail!!![The type is not config.]", type, subType)
        return -- log.ErrorStack("sys", "activityNotify.publish fail!!![The type is not config.]", type, subType)
    end
    -- activityPlayControlAPI.publishActivityEvent(event)
    api.publishActivityEvent(event, ...)
end

-- 重新触发资格加载
function _M.reTriggerCertificateInit(type, subType, actid)
    local api = _apiCrossConf[type] and _apiCrossConf[type][subType]

    if not api then
        return
    end

    -- 如果支持，就触发下
    if api.reTriggerCertificateInit then
        api.reTriggerCertificateInit(actid)
    else
        log.Error("sys", "api.reTriggerCertificateInit is nil", type, subType, actid)
    end
end

return _M
