-- --------------------------------------
-- Create Date:2021-05-20 22:53:39
-- Author  : Happy Su
-- Version : 1.0
-- Filename: serviceCenterBase.lua
-- Introduce  : 类介绍
-- --------------------------------------
local skynet = require("skynet")
---@type notify
local notify = require("notify")
---@type msgCtrl
local msgCtrl = require("msgCtrl")
---@type cmdCtrl
local cmdCtrl = require("cmdCtrl")
local confAPI = require("confAPI")
local svrAddressMgr = require("svrAddressMgr")
local schedulerGlobal = require("schedulerGlobal")
local profile = require("profile")
---@class serviceCenterBase
local _M = class("serviceCenterBase")

local logActionType = gLogDef.logActionType

------------------Interface-------------------
-- 获取单例
function _M.sharedInstance(center)
    if not center.instance then
        center.instance = center.new()
    end

    return center.instance
end
-----------------Interface END----------------

----------------指令分发----------------

-- 一些特殊的指令
local Base_CMD = CreateBlankTable(_M, "Base_CMD")
local Service_CMD = CreateBlankTable(_M, "Service_CMD")
local Service_retpack_CMD = CreateBlankTable(_M, "Service_retpack_CMD")

-- 初始化
function Base_CMD.init(self, ...)
    local retValue = self:init(...)
    if nil == retValue then
        retValue = true
    end
    skynet.retpack(retValue)
end

-- 开始服务
function Base_CMD.start(self, ...)
    self:start(...)
    self:notifyStartComplete()
    skynet.retpack(true)
end

-- 停止服务
function Base_CMD.stop(self)
    self:stop()
    skynet.retpack(true)
end

function Base_CMD.reloadltClass(self, ltClasses)
    log.Info("sys", "serviceCenterBase CMD.reloadltClass")
    for _, ltClass in pairs(ltClasses) do
        local lt = require(ltClass)
        if lt then
            lt:init()
        else
            log.Error("sys", "serviceCenterBase reloadltClass error", SERVICE_NAME, ltClass)
            skynet.ret(skynet.pack(false))
            return
        end
    end

    skynet.ret(skynet.pack(true))
end

-- publish: 事件publish
function Base_CMD.publish(self, eventName, event)
    notify.publish(eventName, event)
end

function Base_CMD.publish_call(self, eventName, event)
    notify.publish(eventName, event)
    skynet.ret(skynet.pack(true))
end

-- 分发客户端的指令
function Base_CMD.dispatchSprotoMsg(self, name, req)
    skynet.ret(skynet.pack(self:dispatchSproto(name, req)))
end

function Base_CMD.cleanServiceStat(instance)
    instance.cmdMap = {}
    return skynet.retpack(gErrDef.Err_None)
end

function Base_CMD.queryServiceStat(instance)
    return skynet.retpack(gErrDef.Err_None, instance.cmdMap)
end

-- 查询延时的命令信息
function Base_CMD.queryDelayServiceStat(instance)
    local cmdMap = instance.cmdMap
    if not cmdMap then
        log.Error("sys", "queryDelayServiceStat cmdMap is nil", instance.__cname)
        return skynet.retpack()
    end

    local retMap = {}
    for cmd, detail in pairs(instance.cmdMap) do
        if (detail.maxCostTime and detail.maxCostTime > 100) or (detail.maxProfileTime and detail.maxProfileTime > 0.5) then
            retMap[cmd] = detail
        end
    end

    if next(retMap) then
        skynet.retpack(retMap)
    else
        skynet.retpack()
    end
end

-- 分发客户端发送上来的指令
function _M:dispatchSproto(name, req)
    return msgCtrl.handleSproto(name, req)
end

-- 分发服务之间的 lua 命令
function _M:dispatchcmd(session, source, command, ...)
    local f = (Base_CMD[command])
    if f then
        f(self, ...)
        return true
    else
        f = (Service_CMD[command])
        if f then
            f(...)
            return true
        else
            f = Service_retpack_CMD[command]
            if f then
                skynet.retpack(f(...))
                return true
            else
                return cmdCtrl.handle(command, ...)
            end
        end
    end
end

----------------指令分发 END----------------
function _M:ctor()
    self.statId = 0
    self.cmdMap = {}
    self.waitCmdMap = {}
end

-- 初始化本服务，不和其他服务交互
function _M:init(nodeId, ...)
    confAPI.initAll()
    assert(gNodeId, "serviceCenterBase init err nodeId is nil serviceName:" .. SERVICE_NAME)
    log.Info("sys", string.safeFormat("The service %s init, addr %s nodeId %s", SERVICE_NAME, gAddrSvr, nodeId), ...)
    self:initltClass()
end

function _M:initltClass()
    -- local activityConfigUtil = require("activityConfigUtil")
    -- activityConfigUtil.init()
    -- local configLoadUtil = require("configLoadUtil")
    -- configLoadUtil.initByShareTable()
    -- local ltClasses = configLoadUtil.getServiceltClasses(SERVICE_NAME)
    -- if next(ltClasses) then
    --     log.Dump("sys", ltClasses, "serviceCenterBase:initltClass serviceName:" .. SERVICE_NAME .. " ltClasses")
    -- end
    -- for _, ltClass in pairs(ltClasses) do
    --     local lt = require(ltClass)
    --     if lt then
    --         lt:init()
    --     else
    --         log.Error("sys", "serviceCenterBase initltClass error", SERVICE_NAME, ltClass)
    --     end
    -- end
end

-- 通知start完成
function _M:notifyStartComplete()
    local clusterInfSvr = svrAddressMgr.getSvr(svrAddressMgr.clusterInfSvr, gNodeId)
    skynet.send(clusterInfSvr, "lua", "registerService", SERVICE_NAME, skynet.self(), gSlaveId, true)
end

-- 所有配置的服务初始化完成后，本服务可以开始和其他服务交互了
-- 该函数是在所有配置的服务初始化完成后自动调用的
function _M:start()
    log.Info("sys", string.safeFormat("The service %s start, addr %s", SERVICE_NAME, gAddrSvr))
end

-- 所有服务都要重写关服执行的逻辑，主要为数据落地
function _M:stop()
    -- assert(false, "Please overwrite stop function! serviceName:" .. SERVICE_NAME)
    -- self:stopGlobalTimer()
end

---------------timer--------------
-- 开启全局定时器
function _M:startGlobalTimer(block)
    local time = timeUtil.systemTime()
    self.day = os.date("%d", time)
    self.week = os.date("%W", time)

    local function update()
        local curTime = timeUtil.systemTime()
        local curDay = os.date("%d", curTime)
        if curDay ~= self.day then
            self.day = curDay
            notify.publish(gEventName.event_new_day, {curTime = curTime}) -- 本地推
        end
        local curWeek = os.date("%W", curTime)
        if curWeek ~= self.week then
            self.week = curWeek
            notify.publish(gEventName.event_new_week, {curTime = curTime}) -- 本地推
        end
        if block then
            block()
        end
    end

    schedulerGlobal.scheduleUpdate(update)
    schedulerGlobal.start()
end

-- 停止全局定时器
function _M:stopGlobalTimer()
    schedulerGlobal.stop()
end

-- service stat
function _M:genStatId()
    local newStatId = self.statId + 1
    self.statId = newStatId
    return tostring(newStatId)
end

function _M:getCmdMap()
    return self.cmdMap
end

-- 不需要统计的命令
local withoutCommand = {
    cleanServiceStat = true,
    queryServiceStat = true
}

function _M:commandStatStart(cmd)
    if not withoutCommand[cmd] then
        profile.start()
        local statId = self:genStatId()
        self.waitCmdMap[statId] = skynet.now()
        return statId
    end
end

function _M:getStatDefaultData()
    return {
        totalExecCount = 0, -- 总执行次数
        totalCostTime = 0, -- 总耗时
        totalProfileTime = 0, -- 总逻辑时间
        maxCostTime = 0, -- 最大耗时
        maxProfileTime = 0, -- 最大逻辑时间
        -- maxCostParam = {},  -- 最大耗时参数
        -- maxProfileParam = {}, -- 最大逻辑时间参数
        overTimeExecCount = 0 -- 超时执行次数
    }
end

local overTimeStandard = 100
function _M:commandStatStop(cmd, statId, ...)
    if statId == nil then
        -- this command is withoutCommand
        return
    end
    local startTime = self.waitCmdMap[statId]
    if not startTime then
        log.Error("sys", "serviceCenterBase can not find statId", cmd, statId)
        return
    end
    -- remove wait info
    self.waitCmdMap[statId] = nil
    -- costTime
    local costTime = skynet.now() - startTime
    --profileTime
    local originalProfileTime = profile.stop()
    local profileTime = originalProfileTime - originalProfileTime % 0.000001
    -- default data
    local cmdData = self.cmdMap[cmd]
    if not cmdData then -- CreateBlankTable will always generate default data
        cmdData = self:getStatDefaultData()
        self.cmdMap[cmd] = cmdData
    end
    -- add val
    cmdData.totalExecCount = cmdData.totalExecCount + 1
    cmdData.totalCostTime = cmdData.totalCostTime + costTime
    cmdData.totalProfileTime = cmdData.totalProfileTime + profileTime
    -- compare max
    if costTime > cmdData.maxCostTime then
        cmdData.maxCostTime = costTime
    -- cmdData.maxCostParam = {..., timeUtil.systemTime()}
    end
    -- profile time
    if profileTime > cmdData.maxProfileTime then
        cmdData.maxProfileTime = profileTime
    -- cmdData.maxProfileParam = {..., timeUtil.systemTime()}
    end
    -- over time
    if costTime > overTimeStandard then
        cmdData.overTimeExecCount = cmdData.overTimeExecCount + 1
        -- 统计日志
        dataCenterLogAPI.writeCommonDataLog(
            gNodeId,
            logActionType.cmd_cost_time_stat,
            {
                cmd = cmd,
                cost_time = costTime,
                profile_time = profileTime,
                param = {...}
            }
        )
    end
end

return _M
