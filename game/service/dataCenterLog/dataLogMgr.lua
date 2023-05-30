-- --------------------------------------
-- Create Date:2020-08-28 15:45:34
-- Author  : Happy Su
-- Version : 1.0
-- Filename: dataLogMgr.lua
-- Introduce  : 类介绍
-- --------------------------------------
local skynet = require "skynet"
local cmdCtrl = require "cmdCtrl"
local queue = require "skynet.queue"
local csUtil = require "util.csUtil"
local json = require "json"
---@type accountUtil
local accountUtil = require("util.accountUtil")
-- local batchDataAPI = require "batchDataAPI"
local delayTimer = require("delayTimer")
---@type dataLogInst
local dataLogInst = require("dataCenterLog.dataLogInst")
---@class dataLogMgr
local _M = class("dataLogMgr")

function _M:ctor()
    self.baseData = {} --数据中心日志用，临时存玩家通用数据
    self.releaseHandles = {} -- 玩家数据释放计时器句柄
end

function _M:init()
    cmdCtrl.register("start", retpackHandlerName(self, "start"))
    cmdCtrl.register("close", handlerName(self, "close"))
    cmdCtrl.register("writeDataLog", handlerName(self, "writeDataLog"))
    cmdCtrl.register("changeltID", handlerName(self, "changeltID"))
    cmdCtrl.register("changeAid", handlerName(self, "changeAid"))
    cmdCtrl.register("changePower", handlerName(self, "changePower"))
    cmdCtrl.register("changeVipLv", handlerName(self, "changeVipLv"))
    cmdCtrl.register("changeLevel", handlerName(self, "changeLevel"))
    cmdCtrl.register("writeUserDataLog", handlerName(self, "writeUserDataLog"))
    cmdCtrl.register("writeCommonDataLog", handlerName(self, "writeCommonDataLog"))
    cmdCtrl.register("writeSpecialDataLog", handlerName(self, "writeSpecialDataLog"))
end

function _M:start()
    return true
end

-- 更新下释放计时器
function _M:updateReleaseTimer(uid)
    local handle = self.releaseHandles[uid]
    local releaseTime = timeUtil.systemTime() + 3600
    self.releaseHandles[uid] =
        delayTimer:uniqueDelay(
        releaseTime,
        function()
            self.baseData[uid] = nil
        end,
        nil,
        handle
    )
end

--获取玩家通用数据
function _M:getBaseData(uid, sourceData)
    -- 不是本节点的玩家信息，不缓存
    local playerNodeId = accountUtil.getNodeId(uid)
    -- local litkid = svrconf.getLitKingdomIDByNodeID(playerNodeId)
    local bCache = (gNodeId == playerNodeId)
    local baseData = self.baseData
    local data = baseData[uid]

    return {}

    -- if not data then
    --     data =
    --         csUtil.lock(
    --         uid,
    --         function()
    --             -- 本节点的信息走缓存，其它节点的立刻获取，获取失败给默认
    --             if bCache then
    --                 if baseData[uid] then
    --                     return baseData[uid]
    --                 end
    --             end
    --             local ok, lordData = xpcall(batchDataAPI.queryInfo, debug.traceback, playerNodeId, "user_lord", uid)
    --             if ok and lordData then
    --                 baseData[uid] = {
    --                     uid = uid,
    --                     ltid = lordData.ltid,
    --                     kid = litkid, -- 取节点最小kid
    --                     aid = lordData.aid,
    --                     level = lordData.level,
    --                     fighting = lordData.nationalPower,
    --                     viplvl = lordData.vipLevel,
    --                     deviceid = lordData.deviceid
    --                 }
    --             else
    --                 local ptype = sourceData and sourceData.ptype
    --                 if not ok then
    --                     log.Warn("log", "call lordData fail: ", uid, ptype, dumpTable(sourceData), lordData)
    --                 end
    --                 -- return
    --                 -- 没有默认值，才给默认，否则用旧数据
    --                 if not baseData[uid] then
    --                     baseData[uid] = {
    --                         uid = uid,
    --                         ltid = "",
    --                         kid = litkid, -- 取节点最小kid
    --                         aid = 0,
    --                         level = 1,
    --                         fighting = 0,
    --                         viplvl = 0,
    --                         deviceid = ""
    --                     }
    --                 end

    --                 log.Warn("log", "can not found lordData:uid:", uid, ptype, dumpTable(sourceData))
    --             end
    --             return baseData[uid]
    --         end
    --     )
    -- end
    -- 要释放的
    -- if data then
    --     self:updateReleaseTimer(uid)
    -- end
    -- return data
end

function _M:writeDataLog(param, uid, data)
    local basic
    if uid then
        ---- param 在这里为Nodeid
        basic = self:getBaseData(uid, data)
    else
        ---- param 这里为kid
        basic = {
            kid = param
        }
    end

    data.basic = basic
    local ok, errMsg = dataLogInst:writeFile("data", data)
    if not ok then
        log.Info("gg", errMsg)
        return
    end
end

function _M:writeUserDataLog(uid, data)
    if not data then
        log.Warn("sys", "writeUserDataLog data is nil uid:", uid)
        return
    end

    -- 补足数据
    data.basic = self:getBaseData(uid, data)
    local ok, errMsg = dataLogInst:writeFile("data", data)
    if not ok then
        log.Info("gg", errMsg)
        return
    end
end

----- 通用日志，传kid的
function _M:writeCommonDataLog(kid, data)
    data.basic = {kid = kid}
    local ok, errMsg = dataLogInst:writeFile("data", data)
    if not ok then
        log.Info("gg", errMsg)
        return
    end
end

function _M:writeSpecialDataLog(data)
    assert(data, "writeSpecialDataLog data is nil")
    local ok, errMsg = dataLogInst:writeFile("data", data)
    if not ok then
        log.Info("gg", errMsg)
        return
    end
end

function _M:changeltID(uid, ltid)
    if self.baseData[uid] then
        self.baseData[uid].ltid = ltid
    end
end

function _M:changeAid(uid, aid)
    if self.baseData[uid] then
        self.baseData[uid].aid = aid
    end
end

function _M:changePower(uid, fighting)
    -- print("_M:changePower(uid, fighting)", uid, fighting)
    if self.baseData[uid] then
        self.baseData[uid].fighting = fighting
    end
end

function _M:changeVipLv(uid, viplv)
    if self.baseData[uid] then
        self.baseData[uid].viplvl = viplv
    end
end

function _M:changeLevel(uid, level)
    if self.baseData[uid] then
        self.baseData[uid].level = level
    end
end

function _M:close()
    dataLogInst:close()
end

return _M
