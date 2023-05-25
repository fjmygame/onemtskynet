-- --------------------------------------
-- Create Date:2021-06-08 14:47:35
-- Author  : sgys
-- Version : 1.0
-- Filename: questTypeListener.lua
-- Introduce  : 任务类型监听器
-- --------------------------------------

local gameLib = require("gameLib")
local progressSystem = require("progressSystem")
local serviceNotify = require("serviceNotify")
--- @class questTypeListener
local _M = class("questTypeListener")

function _M:ctor(questId, etype, condition, logicMgrInst)
    self.questId = questId
    self.etype = etype
    self.condition = condition

    self.logicMgrInst = logicMgrInst

    -- 事件名
    self.eventName = gameLib.getQuestEventName(etype, condition)
    assert(
        self.eventName,
        string.safeFormat(
            "questListener eventName not found!!!questId=%s, etype=%s, condition=%s",
            questId,
            etype,
            dumpTable(condition)
        )
    )
end

-- 开启订阅
function _M:subscribe()
    self:unsubscribe()
    self.index = serviceNotify.subscribe(self.eventName, handlerName(self, "onQuestEventHandle"))
end

-- 取消订阅
function _M:unsubscribe()
    if self.index then
        serviceNotify.unsubscribe(self.eventName, self.index)
        self.index = nil
    end
end

function _M:getQuestId()
    return self.questId
end

function _M:onQuestEventHandle(eventName, event)
    log.Dump("gg", event, "onQuestEventHandle-->" .. eventName, 10)
    local uid = event.uid
    local questId = self.questId
    local logic = self.logicMgrInst:getLogic(uid)
    if logic:isFinish(questId) then
        return
    end

    -- 战令状态验证
    if logic.getState then
        ---@type battlepassDef
        local battlepassDef = require("battlepassDef")
        if logic:getState() ~= battlepassDef.StateType.doing then
            return
        end
    end

    local progressData = logic:getProgressData(questId)
    if not progressData then
        return
    end
    local qType = progressData.qType
    -- 如果任务类型配置被修改了，直接报错吧
    if qType ~= self.etype then
        return log.ErrorStack(
            "quest",
            string.safeFormat(
                "(uid:%s)questTypeListener.onQuestEventHandle ---> The quest:%s type is err!!!",
                uid,
                questId
            ),
            qType,
            self.etype
        )
    end
    local ok = progressSystem.doEvent(qType, event.data, self.condition, progressData)
    if ok then
        logic:onProgressUpdate(questId, progressData.progress)
    end
end

return _M
