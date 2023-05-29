-- --------------------------------------
-- Create Date:2020-11-17 20:02:09
-- Author  : Happy Su
-- Version : 1.0
-- Filename: dataCenterLogAPI.lua
-- Introduce  : 数据日志服务接口
-- --------
-- Last Modified: Mon Mar 20 2023
-- Modified By: Happy Su
-- --------------------------------------
local skynet = require "skynet"
local svrAddressMgr = require "svrAddressMgr"
local clusterExt = require("clusterExt")
---@type accountUtil
local accountUtil = require("util.accountUtil")
---@class dataCenterLogAPI
local dataCenterLogAPI = {}

-- get服务地址
local function getAddress(nodeId)
    return svrAddressMgr.getSvr(svrAddressMgr.datacenterLogSvr, nodeId)
end

-- basic 玩家通用字段 {玩家ID,王国ID,龙腾id,玩家等级,设备id, 联盟Id,玩家国力}
-- createtime 完成事件的时间戳
-- action 行为
-- pcxt 积分变化数据，数组 "{aimid:金币id,change:+-金币数量,cur_num：当前数量}
-- scxt 事件内容，根据每个事件做具体的定义
-- log 0:行为，1:积分
function dataCenterLogAPI.writeUserDataLog(uid, action, scxt, pcxt)
    if not uid or not action then
        log.Warn("sys", "user write log action error", uid, action)
        return
    end
    if scxt then
        -- scxt：部分业务不关心type字段，为默认值1
        scxt.type = scxt.type or 1
    end
    local data = {
        createtime = timeUtil.systemTime(),
        ptype = action,
        pcxt = pcxt,
        scxt = scxt
    }
    local nodeid = accountUtil.getNodeId(uid)
    clusterExt.send(getAddress(nodeid), "lua", "writeUserDataLog", uid, data)
end

function dataCenterLogAPI.writeCommonDataLog(key, action, scxt, pcxt)
    if not key or not action then
        log.Warn("sys", "common write log action error", key, action)
        return
    end
    local data = {
        createtime = timeUtil.systemTime(),
        ptype = action,
        pcxt = pcxt,
        scxt = scxt
    }
    clusterExt.send(getAddress(dbconf.curnodeid), "lua", "writeCommonDataLog", key, data)
end

local gLogActionType
local function LogAction()
    if not gLogActionType then
        gLogActionType = gLogDef.logActionType
    end
    return gLogActionType
end

--- 积分（玩家身上某个对象的属性）日志
-- @number uid 玩家uid
-- @number pointid 积分ID（妃子亲密度|魅力值|技能点等）
-- @number targetid  英雄ID/妃子ID等
-- @number change 积分变化（正负值，负数表示消耗）
-- @number cur_num 当前积分值
-- @table sourceinfo = { source=0, extends = {} }
function dataCenterLogAPI.writePointLog(uid, pointid, targetid, change, cur_num, sourceinfo)
    local ptype = LogAction().consumer_point
    if change > 0 then
        ptype = LogAction().gain_point
    end
    local pcxt = {
        aimid = pointid,
        change = change,
        cur_num = cur_num
    }
    local scxt = {
        type = sourceinfo.source,
        extra = sourceinfo.extends,
        targetid = targetid,
        subtype = sourceinfo.sourceSubType
    }
    dataCenterLogAPI.writeUserDataLog(uid, ptype, scxt, pcxt)
end

--- 玩家属性日志
-- @number uid 玩家uid
-- @number attrid 属性ID
-- @number change 属性值变化（正负值，负数表示消耗）
-- @number cur_num 当前属性值
-- @table sourceinfo = { source=0, extends = {} }
function dataCenterLogAPI.writeAttrLog(uid, attrid, change, cur_num, sourceinfo)
    -- 默认是获取金币
    local action = LogAction().gain_res
    if change < 0 then
        action = LogAction().consumer_res
    end
    local pcxt = {
        aimid = attrid,
        change = change,
        cur_num = cur_num
    }
    local scxt = {
        type = sourceinfo.source,
        subtype = sourceinfo.sourceSubType,
        extra = sourceinfo.extends
    }
    dataCenterLogAPI.writeUserDataLog(uid, action, scxt, pcxt)
end

------------------------------------------------------------------------------------------------------------------

-- 特殊日志，直接指定basic值
function dataCenterLogAPI.writeSpecialDataLog(action, basic, scxt, pcxt, createtime)
    if not action then
        log.Warn("sys", "common write log action error")
        return
    end
    local data = {
        createtime = createtime or timeUtil.systemTime(),
        basic = basic,
        ptype = action,
        pcxt = pcxt,
        scxt = scxt
    }

    skynet.send(getAddress(gNodeId), "lua", "writeSpecialDataLog", data)
end

function dataCenterLogAPI.changeltIDToLog(uid, ltid)
    local nodeid = accountUtil.getNodeId(uid)
    skynet.send(getAddress(nodeid), "lua", "changeltID", uid, ltid)
end

function dataCenterLogAPI.changeAidToLog(uid, aid)
    local nodeid = accountUtil.getNodeId(uid)
    skynet.send(getAddress(nodeid), "lua", "changeAid", uid, aid)
end

function dataCenterLogAPI.changePowerToLog(uid, fighting)
    local nodeid = accountUtil.getNodeId(uid)
    skynet.send(getAddress(nodeid), "lua", "changePower", uid, fighting)
end

function dataCenterLogAPI.changeVipLvToLog(uid, vipLevel)
    local nodeid = accountUtil.getNodeId(uid)
    skynet.send(getAddress(nodeid), "lua", "changeVipLv", uid, vipLevel)
end

function dataCenterLogAPI.changeLevelToLog(uid, level)
    local nodeid = accountUtil.getNodeId(uid)
    skynet.send(getAddress(nodeid), "lua", "changeLevel", uid, level)
end

-- 写不带用户信息的积分日志
function dataCenterLogAPI.writeAttrLogNoUserInfo(uid, attrid, change, cur_num, sourceinfo)
    -- 默认是获取金币
    local action = LogAction().gain_res
    if change < 0 then
        action = LogAction().consumer_res
    end
    local pcxt = {
        aimid = attrid,
        change = change,
        cur_num = cur_num
    }
    local scxt = {
        type = sourceinfo.source or 1,
        subtype = sourceinfo.sourceSubType,
        extra = sourceinfo.extends
    }
    local data = {
        createtime = timeUtil.systemTime(),
        basic = {uid = uid},
        ptype = action,
        pcxt = pcxt,
        scxt = scxt
    }
    skynet.send(getAddress(dbconf.curnodeid), "lua", "writeSpecialDataLog", data)
end

return dataCenterLogAPI
