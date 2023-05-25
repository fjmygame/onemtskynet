-- --------------------------------------
-- Create Date:2023-02-25 11:39:51
-- Author  : Happy Su
-- Version : 1.0
-- Filename: agentAchieveCom.lua
-- Introduce  : 玩家模块的成就封装
-- --------------------------------------
local progressHandle = require("progressHandle")
local questSystem = require("questSystem")
---@type activityAchieveConfltInst
local activityAchieveConfltInst = require("activityAchieveConfltInst")
---@class agentAchieveCom
local _M = class("agentAchieveCom")

local logActionType = gLogDef.logActionType

function _M:ctor(logic, actData, subGroup)
    assert(logic.getAchieveData, "logic.getAchieveData is nil")
    assert(logic.update, "logic.update is nil")
    self._logic = logic
    self._actData = actData
    self._subGroup = subGroup
end

function _M:getLogic()
    return self._logic
end

-- --------------------------------------

function _M:getActivityType()
    local actData = self._actData
    return actData.type, actData.subType
end

function _M:getId()
    return self._actData.id
end

function _M:getPid()
    return self._actData.pid
end

-- --------------------------------------
-- 检查子集
function _M:checkSubGroupMatch(questCfg)
    if self._subGroup then
        return questCfg["subgroup"] == self._subGroup
    end

    return true
end
-- --------------------------------------

function _M:getAchieveDefault(id, type)
    return {
        id = id,
        qType = type,
        gots = {},
        progress = 0
    }
end

function _M:checkDailyQuest(achieves)
    -- 统一初始化一个刷新时间戳
    local nextTime = achieves.nextTime
    if not nextTime then
        achieves.nextTime = timeUtil.getTomorrowZeroHourUTC() -- 明天0点
    else
        -- 判断是否需要重置
        if timeUtil.systemTime() >= nextTime then
            local actType, actSubType = self:getActivityType()
            local questList = activityAchieveConfltInst:getQuestList(actType, actSubType)
            for curQuestId, curQuestCfg in pairs(questList) do
                if self:checkSubGroupMatch(curQuestCfg) then
                    local isDaily = curQuestCfg.isDaily
                    if isDaily and isDaily == 1 then
                        achieves[tostring(curQuestId)] = self:getAchieveDefault(curQuestId, curQuestCfg.type)
                    end
                end
            end
            achieves.nextTime = timeUtil.getTomorrowZeroHourUTC() -- 明天0点
        end
    end
end

-- 获取单个成就数据
function _M:getAchieveDataByQuestId(questId, questCfg)
    local logic = self:getLogic()
    local achieves = logic:getAchieveData()
    -- 检查是否跨天重置
    self:checkDailyQuest(achieves)

    local questIdStr = tostring(questId)
    if not achieves[questIdStr] then
        if not questCfg then
            local actType, actSubType = self:getActivityType()
            questCfg = activityAchieveConfltInst:getQuest(actType, actSubType, questId)
        end
        achieves[questIdStr] = self:getAchieveDefault(questId, questCfg.type)
    end

    return achieves[questIdStr]
end

-- 直接添加成就进度
function _M:addAchieveProgress(type, value, bNotDB)
    local actType, actSubType = self:getActivityType()
    local quests = activityAchieveConfltInst:getQuestsByType(actType, actSubType, type)
    local syncDatas = {}
    local bChangeTag = false
    for k, questCfg in pairs(quests) do
        if self:checkSubGroupMatch(questCfg) then
            bChangeTag = true
            local data = self:getAchieveDataByQuestId(k, questCfg)
            --- 增加进度
            data.progress = data.progress + value
            syncDatas[#syncDatas + 1] = data
        end
    end
    if bChangeTag and not bNotDB then
        local logic = self:getLogic()
        logic:update()
    end
    return syncDatas
end

-- 设置成就进度
function _M:setAchieveProgress(type, value, bNotDB)
    local actType, actSubType = self:getActivityType()
    local quests = activityAchieveConfltInst:getQuestsByType(actType, actSubType, type)
    local syncDatas = {}
    local bChangeTag = false
    for k, questCfg in pairs(quests) do
        if self:checkSubGroupMatch(questCfg) then
            bChangeTag = true
            local data = self:getAchieveDataByQuestId(k, questCfg)
            --- 增加进度
            data.progress = value
            syncDatas[#syncDatas + 1] = data
        end
    end
    if bChangeTag and not bNotDB then
        local logic = self:getLogic()
        logic:update()
    end
    return syncDatas
end

-- 处理成就事件
function _M:doAchieveEvent(type, eventData, bNotDB)
    local actType, actSubType = self:getActivityType()
    local quests = activityAchieveConfltInst:getQuestsByType(actType, actSubType, type)
    local syncDatas = {}
    local bChangeTag = false
    for k, questCfg in pairs(quests) do
        if self:checkSubGroupMatch(questCfg) then
            bChangeTag = true
            local data = self:getAchieveDataByQuestId(k, questCfg)

            local func = progressHandle.getEventFunc(type)
            local ok, ret = xpcall(func, debug.traceback, eventData, questCfg.condition, data)
            if not ok then
                log.Error("sys", "activityAchieveCom.doAchieveEvent", ret, type)
                log.ErrorDump("sys", eventData, "activityAchieveCom.doEvent.eventData", 10)
                log.ErrorDump("sys", questCfg, "activityAchieveCom.doEvent.questCfg", 10)
                log.ErrorDump("sys", data, "activityAchieveCom.doEvent.data", 10)
            end
            if ret then
                syncDatas[#syncDatas + 1] = data
            end
        end
    end
    if bChangeTag and not bNotDB then
        local logic = self:getLogic()
        logic:update()
    end
    return syncDatas
end

-- 打包客户端成就数据
function _M:getClientAchieves()
    local achieves = {}
    local actType, actSubType = self:getActivityType()
    local questList = activityAchieveConfltInst:getQuestList(actType, actSubType)
    for questId, questCfg in pairs(questList) do
        if self:checkSubGroupMatch(questCfg) then
            achieves[#achieves + 1] = self:getAchieveDataByQuestId(questId, questCfg)
        end
    end
    return achieves
end

-- 获取成就奖励
function _M:getAchieveReward(questId, index)
    local actType, actSubType = self:getActivityType()
    local questCfg = activityAchieveConfltInst:getQuest(actType, actSubType, questId)
    if not questCfg then
        return gErrDef.Err_LOCAL_CONFIG_ERROR
    end

    if not self:checkSubGroupMatch(questCfg) then
        return gErrDef.Err_ILLEGAL_PARAMS
    end

    local targetId = questCfg.task[index]
    if not targetId then
        return gErrDef.Err_ILLEGAL_PARAMS
    end

    local target = activityAchieveConfltInst:getTarget(actType, actSubType, targetId)
    if not target then
        return gErrDef.Err_ILLEGAL_PARAMS
    end

    local achieveData = self:getAchieveDataByQuestId(questId, questCfg)
    if not achieveData then
        return gErrDef.Err_SERVICE_EXCEPTION
    end
    local progress = achieveData.progress
    local aim = target.aim
    if progress < aim then
        return gErrDef.Err_Act_Achieve_Progress_Not_Enough
    end

    if questSystem.isGot(achieveData, index) then
        return gErrDef.Err_Act_Achieve_Box_Has_Got_Index
    end

    local ok = questSystem.got(achieveData, index)
    if not ok then
        return gErrDef.Err_Act_Achieve_Box_Has_Got_Index
    end

    -- 存库
    local logic = self:getLogic()
    logic:update()

    local rewards = target.rewards

    local scxt = {
        type = actType,
        subtype = actSubType,
        actid = self:getId(),
        actpid = self:getPid(),
        aim = aim,
        progress = progress,
        rewards = rewards,
        questid = questId,
        inx = index
    }
    local uid = logic:getUid()
    dataCenterLogAPI.writeUserDataLog(uid, logActionType.act_achieve_reward, scxt)

    return gErrDef.Err_None, rewards
end

return _M
