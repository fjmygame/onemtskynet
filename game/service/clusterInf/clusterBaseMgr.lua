-- --------------------------------------
-- Create Date:2020-12-07 16:47:29
-- Author  : Happy Su
-- Version : 1.0
-- Filename: clusterBaseMgr.lua
-- Introduce  : 节点管理类基础逻辑
-- --------------------------------------
local skynet = require "skynet"
local sharedata = require "sharedata"
local clusterExt = require "clusterExt"
-- local initDBConf = require "initDBConf"
local confAPI = require "conf.confAPI"
require "wholeDef"
local json = require("json")
local reloadServiceFileHelp = require "clusterInf.reloadServiceFileHelp"
local codecache = require "skynet.codecache"
local svrAddressMgr = require("svrAddressMgr")
local asynTaskUtil = require("util.asynTaskUtil")

---@class clusterBaseMgr
local _M = class("clusterBaseMgr")

local retPack = skynet.retpack

function _M:ctor()
    self.serviceAddrMap = {}
    self.serviceNameMap = {}
    self.dbServiceMap = {}
end

-- 初始化
function _M:init()
    -- log.Info("sys", "clusterBaseMgr init complete")
    -- -- get time
    -- local address = svrAddressMgr.getSvr(svrAddressMgr.systimeSvr, confAPI.getLoginNodeId())
    -- local time = clusterExt.call(address, "lua", "getCurtime")
    -- assert(time, "init systime fail ~")
    -- sharedata.new("systime", {starttime = time})

    -- -- 订阅
    -- local function watching()
    --     local redis = require "redis"
    --     local shareRedis = confAPI.getRedisConfByKey(gRedisType.share)
    --     local w = redis.watch(shareRedis)
    --     w:subscribe "SYS_TIME_CHANNEL"
    --     while true do
    --         local ctime = w:message()
    --         local starttime = tonumber(ctime) - math.floor(skynet.now() / 100)
    --         log.Debug("gg", "gm update systime:", starttime)
    --         sharedata.update("systime", {starttime = starttime})
    --     end
    -- end
    -- skynet.fork(watching)
end

-- 检查节点是否完成
function _M:queryNodeComplete()
    retPack(self._completeTag)
end

-- 调用gameConf配置接口
function _M:callGameConfAPI(apiName)
    log.Debug("sys", string.safeFormat("========CMD.callGameConfAPI:%s=========", apiName))
    local func = initDBConf[apiName]
    if not func then
        retPack(false, string.safeFormat("can not found func:%s", apiName))
        return
    end
    -- 调用接口
    func(true)
    retPack(true)
end

--刷新gameconf配置
function _M:reloadGameConfForNewGameNode()
    log.Debug("sys", "========gateserverlt CMD.refreshDBConf=========")
    initDBConf.reloadForNewGameNode(true)
    retPack(true)
end

-- 刷新服务器分组配置
function _M:reloadKingdomGroupConf()
    log.Debug("sys", "========gateserverlt CMD.reloadKingdomGroupConf=========")
    initDBConf.set_kingdom_group(true)
    retPack(true)
end

--注入脚本
function _M:injectScript(nodeid, injectSvrName, fileName)
    log.Info(
        "sys",
        string.safeFormat("injectScript nodeid:%s, injectSvrName:%s, fileName:%s", nodeid, injectSvrName, fileName)
    )

    local path = "game/hotfix/"
    local fileNameAll = path .. fileName

    local bSuccessRet, injectDesc, injectRet = reloadServiceFileHelp.inject_common(injectSvrName, fileNameAll)
    retPack(bSuccessRet, injectDesc, injectRet)
end

-- 重载文件
function _M:reloadFileToService(serviceName, fileFullPath)
    -- 重载文件
    local reload_func = reloadServiceFileHelp.getInjectFunc(serviceName)
    retPack(reload_func(serviceName, fileFullPath))
end

function _M:reloadShareTableKeys(keys)
    log.Dump("sys", keys, "reloadShareTableKeys keys")
    ---@type configLocalData
    local configLocalData = require "configLocalData"
    local configLoadUtil = require("configLoadUtil")
    configLoadUtil.initByShareTable()
    local retData = {}
    local bSuc = true
    for _, key in ipairs(keys) do
        local cfg = configLoadUtil.getLoadCfg(key)
        if not cfg then
            bSuc = false
            log.Error("sys", "reloadShareTableKeys not find, key:", key)
            retData[key] = false
        else
            configLocalData.loadCfg(cfg)

            if cfg.serviceMap then
                for name, ltClasses in pairs(cfg.serviceMap) do
                    local addMap = reloadServiceFileHelp.callServiceAddrList(name)
                    for _, addr in pairs(addMap) do
                        local ret = clusterExt.call(addr, "lua", "reloadltClass", ltClasses)
                        if not retData[key] then
                            retData[key] = {
                                {
                                    bok = ret or false,
                                    addr = addr,
                                    name = name
                                }
                            }
                        else
                            table.insert(
                                retData[key],
                                {
                                    bok = ret or false,
                                    addr = addr,
                                    name = name
                                }
                            )
                        end
                    end
                end
            end

            if cfg.agentltClasses then
                log.Dump("sys", cfg.agentltClasses, "reloadShareTableKeys cfg.agentltClasses")
                local agentPoolSvrAdd = svrAddressMgr.getSvr(svrAddressMgr.playerAgentPoolSvr, dbconf.curnodeid)
                clusterExt.send(agentPoolSvrAdd, "lua", "sendAllExistAgent", "lua", "reloadltClass", cfg.agentltClasses)
            end
        end
    end

    log.Dump("sys", retData, "reloadShareTableKeys.retData")
    retPack(bSuc, retData)
end

-- 先检查一遍是否需要热更
function _M:hotfixCheck(servcieFileTable)
    local faildFileMap = {}
    -- 指定服务
    local faildCount = 0
    local taskMap = {}
    for serviceName, fileList in pairs(servcieFileTable) do
        taskMap[serviceName] = function()
            local addrList = reloadServiceFileHelp.callServiceAddrList(serviceName)
            log.Dump("sys", addrList, "hotfixFile addrList:" .. tostring(serviceName))
            -- 找不到服务，返回失败(agentlt除外，可能并没有玩家在线)
            if #addrList <= 0 and "agentlt" ~= serviceName then
                faildFileMap[serviceName] = "addrList is empty" .. tostring(serviceName)
                faildCount = faildCount + 1
                return false
            end

            for _, addr in pairs(addrList) do
                local faildFileStr = clusterExt.call(addr, "debug", "checkNeedHotfix", fileList)
                if faildFileStr then
                    faildFileMap[serviceName .. ":" .. tostring(addr)] = faildFileStr
                    faildCount = faildCount + 1
                end
            end
        end
    end

    -- 异步执行检查
    local bSuc, doResultMap, doFail = asynTaskUtil.doAsynTasks(taskMap)
    log.Info("sys", "hotfixCheck.doResultMap:", json.encode(doResultMap), "doFail:", json.encode(doFail))
    log.Info("sys", "hotfixCheck.faildFileMap:", json.encode(faildFileMap))
    -- 必须确保所有文件的热更都是成功的，否则返回失败
    if (not bSuc) or faildCount > 0 then
        return false, faildFileMap
    else
        return true
    end
end

-- 单纯热更处理
function _M:rawHotfixFile(servcieFileTable)
    -- 清理代码缓存
    codecache.clear()
    local faildFileMap = {}
    -- 指定服务
    local faildCount = 0
    local taskMap = {}
    for serviceName, fileList in pairs(servcieFileTable) do
        -- 搜集异步协程
        taskMap[serviceName] = function()
            local addrList = reloadServiceFileHelp.callServiceAddrList(serviceName)
            log.Dump("sys", addrList, "hotfixFile addrList:" .. tostring(serviceName))
            -- 找不到服务，返回失败(agentlt除外，可能并没有玩家在线)
            if #addrList <= 0 and "agentlt" ~= serviceName then
                faildFileMap[serviceName] = "addrList is empty" .. tostring(serviceName)
                faildCount = faildCount + 1
                return false
            end

            for _, addr in pairs(addrList) do
                local faildFileStr = clusterExt.call(addr, "debug", "hotfixByFileList", fileList)
                if faildFileStr then
                    -- faildCount = faildCount + 1 这里不统计失败了
                    faildFileMap[serviceName .. ":" .. tostring(addr)] = faildFileStr
                end
            end
            return true
        end
    end

    -- 异步执行热更
    local _, doResultMap, doFail = asynTaskUtil.doAsynTasks(taskMap)
    log.Info("sys", "hotfixCheck.doResultMap:", json.encode(doResultMap), "xpcallFail", json.encode(doFail))
    log.Info("sys", "hotfixFile.faildFileMap:", json.encode(faildFileMap))
    -- 只要有一个成功都算
    if next(doResultMap) then
        return true
    else
        return false
    end
end

-- 热更文件
function _M:hotfixFile(servcieFileTable)
    if not servcieFileTable or not next(servcieFileTable) then
        retPack(false, "servcieFileTable table error")
        return
    end

    -- 处理热更
    local bok, errInfo = self:rawHotfixFile(servcieFileTable)
    retPack(bok, errInfo)
end

-- 热更文件，自己指定服务
function _M:hotfixFileClear(skipCheck, servcieFileTable)
    if not servcieFileTable or not next(servcieFileTable) then
        retPack(false, "servcieFileTable table error")
        return
    end

    local bok, errInfo
    -- 检查热更是否合法
    if not skipCheck then
        bok, errInfo = self:hotfixCheck(servcieFileTable)
        if not bok then
            retPack(false, errInfo)
            return
        end
    end

    -- 处理热更
    bok, errInfo = self:rawHotfixFile(servcieFileTable)
    retPack(bok, errInfo)
end

-- 重载lua文件路径配置
function _M:hotfixLuaFilePathCfg()
    local bok = gLuaPathCfg.reload()
    retPack(bok)
end

function _M:queryDelayServiceStat()
    local infoMap = {}
    local serviceAddrMap = self.serviceAddrMap
    for addr, sinfo in pairs(serviceAddrMap) do
        if sinfo.bSupportCheckStat then
            local detail = clusterExt.call(addr, "lua", "queryDelayServiceStat")
            if detail then
                local key = string.safeFormat("%s_%s", sinfo.serviceName, sinfo.slaveId)
                infoMap[key] = detail
            end
        end
    end
    if next(infoMap) then
        retPack(true, infoMap)
    else
        retPack(true)
    end
end

-- 获取服务端地址map
function _M:getServiceMap()
    return self.serviceAddrMap
end

-- 根据服务名字获取地址列表
function _M:getAddrListByServiceName(serviceName)
    return self.serviceNameMap[serviceName]
end

function _M:registerService(serviceName, addr, slaveId, bSupportCheckStat)
    local serviceAddrMap = self.serviceAddrMap
    local serviceNameMap = self.serviceNameMap
    slaveId = slaveId or 1
    serviceAddrMap[addr] = {
        serviceName = serviceName,
        addr = addr,
        slaveId = slaveId,
        bSupportCheckStat = bSupportCheckStat -- 是否支持查询服务执行状态
    }

    local nameInfo = serviceNameMap[serviceName]
    if not nameInfo then
        nameInfo = {
            [slaveId] = addr
        }
        serviceNameMap[serviceName] = nameInfo
    else
        nameInfo[slaveId] = addr
    end
    log.Dump("sys", serviceAddrMap[addr], "clusterBaseMgr.registerService")
    log.Dump("sys", nameInfo, "clusterBaseMgr.registerService.nameInfo")
end

function _M:closeNormalService(step)
    -- 关普通服务
    local serviceMap = self:getServiceMap()
    for _, serInfo in pairs(serviceMap) do
        local ret = clusterExt.call(serInfo.addr, "lua", "stop")
        log.Info("sys", "closeNormalService step", step, serInfo.serviceName, tostring(ret))
    end
end

function _M:getDBServiceMap()
    return self.dbServiceMap
end

function _M:registerDBService(serviceName, addr, slaveId)
    local dbServiceMap = self.dbServiceMap
    dbServiceMap[addr] = {
        serviceName = serviceName,
        addr = addr,
        slaveId = slaveId
    }
    log.Dump("sys", dbServiceMap[addr], "clusterBaseMgr.registerDBService")
end

function _M:closeDBService(step)
    -- 关数据服务
    local dbServiceMap = self:getDBServiceMap()
    for _, serInfo in pairs(dbServiceMap) do
        local ret = clusterExt.call(serInfo.addr, "lua", "stop")
        log.Info("sys", "closeDBService step", step, serInfo.serviceName, serInfo.slaveId, tostring(ret))
    end

    -- 关闭mysqlt
    -- confDBSvr是都有的
    local addr = svrAddressMgr.getSvr(svrAddressMgr.confDBSvr)
    if addr then
        local ret = clusterExt.call(addr, "lua", "stop")
        log.Info("sys", "close confDBSvr mysqllt Service step", step, tostring(ret))
    end
    -- globalDBSvr是都有的
    addr = svrAddressMgr.getSvr(svrAddressMgr.globalDBSvr)
    if addr then
        local ret = clusterExt.call(addr, "lua", "stop")
        log.Info("sys", "close globalDBSvr mysqllt Service step", step, tostring(ret))
    end
end

function _M:openAllModuleLog()
    local addrList = reloadServiceFileHelp.callAllServiceAddrMap()
    for _, addr in pairs(addrList) do
        clusterExt.send(addr, "debug", "openAllModuleLog")
    end
    retPack(true)
end

function _M:closeAllModuleLog()
    local addrList = reloadServiceFileHelp.callAllServiceAddrMap()
    for _, addr in pairs(addrList) do
        clusterExt.send(addr, "debug", "closeAllModuleLog")
    end
    retPack(true)
end

function _M:openModuleLog(logModuleNames)
    local addrList = reloadServiceFileHelp.callAllServiceAddrMap()
    for _, addr in pairs(addrList) do
        clusterExt.send(addr, "debug", "openModuleLog", logModuleNames)
    end
    retPack(true)
end

function _M:closeModuleLog(logModuleNames)
    local addrList = reloadServiceFileHelp.callAllServiceAddrMap()
    for _, addr in pairs(addrList) do
        clusterExt.send(addr, "debug", "closeModuleLog", logModuleNames)
    end
    retPack(true)
end

return _M
