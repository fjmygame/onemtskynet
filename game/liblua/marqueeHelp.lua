-- --------------------------------------
-- Create Date:2022-03-25 11:16:18
-- Author  : sgys
-- Version : 1.0
-- Filename: marqueeHelp.lua
-- Introduce  : 类介绍
-- --------------------------------------
local svrconf = require("svrconf")
local aidUtil = require("aidUtil")
local allianceAPI = require("allianceAPI")
local playerAgent = require("playerAgent")
---@type marqueeParamHelp
local marqueeParamHelp = require("marqueeParamHelp")
local accountUtil = require("accountUtil")
---@class marqueeHelp
local _M = BuildOther("marqueeHelp")

local ParamDef = marqueeParamHelp.ParamDef

local checkTimerMap = {}

local function checkTimerFunc(marqueeType)
    if not checkTimerMap[marqueeType] then
        checkTimerMap[marqueeType] = 0
    end
    if checkTimerMap[marqueeType] > timeUtil.systemTime() then
        log.Info("sys", "marqueeHelp too busy:", marqueeType)
        return
    end

    checkTimerMap[marqueeType] = timeUtil.systemTime() + 2
end

-- 打包数据
local function packParam(marqueeType, ...)
    local parList = {}
    local params = {...}
    local index = 0
    for i = 1, #params, 2 do
        local paramType, paramValue = params[i], params[i + 1]
        index = index + 1
        local key = string.safeFormat("%s_%s", ParamDef[paramType], index)
        parList[#parList + 1] = {key = key, value = paramValue or ""}
    end
    return {
        type = marqueeType,
        params = parList
    }
end

-- ---------------------活动场景跑马灯---------------------

-- 发送玩法功能内的跑马灯
function _M.sendFuncMarquee(nodeid, uidlist, marqueeType, ...)
    -- 太频繁检查
    checkTimerFunc(marqueeType)
    local data = packParam(marqueeType, ...)
    if uidlist then
        playerAgent.sendOnlineClientList(nodeid, uidlist, "synFuncMarquee", data)
    else
        playerAgent.sendAllOnlineClient(nodeid, "synFuncMarquee", data)
    end
end

-- 针对王国列表广播
function _M.sendFuncMarqueeByKidList(kidlist, marqueeType, ...)
    -- 太频繁检查
    checkTimerFunc(marqueeType)
    local data = packParam(marqueeType, ...)
    local nodeidMap = {}
    for _, kid in pairs(kidlist) do
        local nodeid = svrconf.getNodeIDByKingdomID(kid)
        if not nodeidMap[nodeid] then
            nodeidMap[nodeid] = true
            playerAgent.sendAllOnlineClient(nodeid, "synFuncMarquee", data)
        end
    end
end

-- 针对活动接口
function _M.sendActivityFuncMarquee(actid, nodeid, marqueeType, ...)
    checkTimerFunc(marqueeType)
    local data = packParam(marqueeType, ...)
    data.actid = actid
    playerAgent.sendAllOnlineClient(nodeid, "synFuncMarquee", data)
end

-- 针对活动接口
function _M.sendActivityFuncMarqueeByKidList(actid, kidlist, marqueeType, ...)
    -- 太频繁检查
    checkTimerFunc(marqueeType)
    local data = packParam(marqueeType, ...)
    data.actid = actid
    local nodeidMap = {}
    for _, kid in pairs(kidlist) do
        local nodeid = svrconf.getNodeIDByKingdomID(kid)
        if not nodeidMap[nodeid] then
            nodeidMap[nodeid] = true
            playerAgent.sendAllOnlineClient(nodeid, "synFuncMarquee", data)
        end
    end
end

function _M.sendActivityFuncMarqueeByUidMap(actid, uidMap, marqueeType, ...)
    -- 太频繁检查
    checkTimerFunc(marqueeType)
    local data = packParam(marqueeType, ...)
    data.actid = actid

    local uidClassMap = accountUtil.uidMapClassify(uidMap)
    for nodeid, playerMap in pairs(uidClassMap) do
        playerAgent.sendOnlineClientMap(nodeid, playerMap, "synFuncMarquee", data)
    end
end

-- ---------------------全场景跑马灯---------------------

-- 给联盟广播
function _M.sendActivityFuncMarquee2ByAid(actid, aid, marqueeType, ...)
    -- 太频繁检查
    checkTimerFunc(marqueeType)
    local data = packParam(marqueeType, ...)
    data.actid = actid

    local nodeid = aidUtil.getNodeId(aid)
    allianceAPI.publishSproto(nodeid, aid, "synFuncMarquee2", data)
end

return _M
