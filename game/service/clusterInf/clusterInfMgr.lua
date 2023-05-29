-- --------------------------------------
-- Create Date:2020-11-30 14:28:23
-- Author  : Happy Su
-- Version : 1.0
-- Filename: clusterInfMgr.lua
-- Introduce  : 接口服务管理类
-- --------------------------------------
local skynet = require "skynet"
local clusterExt = require "clusterExt"
local mc = require "multicast"
local confAPI = require "conf.confAPI"
local svrAddressMgr = require "svrAddressMgr"
local clusterDef = require "clusterInf.clusterDef"

---@type clusterBaseMgr
local clusterBaseMgr = require "clusterInf.clusterBaseMgr"
---@class clusterInfMgr : clusterBaseMgr
local _M = instanceClass("clusterInfMgr", clusterBaseMgr)

local gNodeType = gServerDef.gNodeType
local TickCode = gServerDef.TickCode
local retPack = skynet.retpack
local close_step = clusterDef.close_step
local gsFinishChannel = nil

function _M:init(nodeType)
    self._nodeType = nodeType
    self._curNodeId = gNodeId
    self._nodeName = nodeType .. "_" .. gNodeId
    _M.super.init(self)
    -- 创建一个游服启动完毕通知的组播频道
    gsFinishChannel = mc.new()
end

-- 5s触发一次
function _M:update()
    -- 重新注册节点
    self:keepCluster()
end

function _M:getFinishChannel()
    retPack(gsFinishChannel)
end

-- 获取游服启动完毕通知频道
function _M:getGameServerFinishChannelId()
    retPack(gsFinishChannel and gsFinishChannel.channel or nil)
end

-- 游服启动完毕
function _M:gameServerStartFinish()
    log.Info("sys", "=========== gameServerStartFinish ==============")
    gsFinishChannel:publish(true)
end

-- 刷新服务器分组配置
function _M:reloadKingdomGroupConf()
    local nodeid = self._curNodeId
    log.Debug(
        "sys",
        "========clusterInfMgr CMD.reloadKingdomGroupConf=========",
        self._nodeType,
        nodeid,
        self._nodeType == gServerType.gameServer
    )
    initDBConf.set_kingdom_group(true)
    -- 如果是游服，通知排行榜重载
    if self._nodeType == gServerType.gameServer then
        rankAPI.reloadKingdomGroupConf(nodeid)
        -- external服务龙岛分组配置
        local address = svrAddressMgr.getSvr(svrAddressMgr.externalSvr, nodeid)
        clusterExt.call(address, "lua", "reloadKingdomGroupConf")
        -- 跨服聊天室缓存需要清理
        address = svrAddressMgr.getSvr(svrAddressMgr.socialSvr, nodeid)
        clusterExt.call(address, "lua", "reloadKingdomGroupConf")
        -- agent服务龙岛分组配置
        local agentPoolSvrAdd = svrAddressMgr.getSvr(svrAddressMgr.playerAgentPoolSvr, nodeid)
        clusterExt.send(agentPoolSvrAdd, "lua", "sendAllExistAgent", "lua", "reloadKingdomGroupConf")
    end
    -- 全局服处理
    if self._nodeType == gServerType.globalServer then
        -- 皮肤榜
        local address = svrAddressMgr.getSvr(svrAddressMgr.crossSkinRankSvr, nodeid)
        clusterExt.call(address, "lua", "reloadKingdomGroupConf")
        -- 跨服分组榜
        address = svrAddressMgr.getSvr(svrAddressMgr.crossRankSvr, nodeid)
        clusterExt.call(address, "lua", "reloadKingdomGroupConf")
        -- 跨服聊天室
        address = svrAddressMgr.getSvr(svrAddressMgr.crossChatRoomSvr, nodeid)
        clusterExt.call(address, "lua", "reloadKingdomGroupConf")
    end
    -- 跨服
    if self._nodeType == gServerType.crossServer then
        -- 龙岛
        local dsnum = svrAddressMgr.serviceNum[svrAddressMgr.crossDragonNestSvr]
        for i = 1, dsnum do
            local address = svrAddressMgr.getSvr(svrAddressMgr.crossDragonNestSvr, nodeid, i)
            clusterExt.call(address, "lua", "reloadKingdomGroupConf")
        end
    end
    retPack(true)
end

-- 定时注册
function _M:keepCluster()
    -- 节点对象赋值之后，才开始心跳
    if not self._curNodeId then
        return
    end

    -- if not self._clusterInfoSvrAddr then
    --     self._clusterInfoSvrAddr = svrAddressMgr.getSvr(svrAddressMgr.clusterInfSvr, confAPI.getLoginNodeId())
    -- end

    -- clusterExt.send(
    --     self._clusterInfoSvrAddr,
    --     "lua",
    --     "keepCluster",
    --     self._nodeType,
    --     self._curNodeId,
    --     self._nodeName,
    --     skynet.self()
    -- )
end

-- 节点启动完成
function _M:nodeStartComplete(successFileName)
    self._completeTag = true
    -- 开服成功的文件名
    self._successFileName = successFileName
    retPack(true)
    -- 通知全局服务器自己启动成功
    -- local address = svrAddressMgr.getSvr(svrAddressMgr.clusterInfSvr, confAPI.getLoginNodeId())
    -- retPack(
    --     clusterExt.call(
    --         address,
    --         "lua",
    --         "registerCluster",
    --         self._nodeType,
    --         self._curNodeId,
    --         self._nodeName,
    --         skynet.self()
    --     )
    -- )
end

function _M:commonCloseLogic(step)
    if step == close_step.step_close then
        self:closeNormalService(step)

        self:closeDBService(step)
    end
end

function _M:gameserverCloseLogic(step)
    if step == close_step.step_pre then
        local agentPoolAddr = svrAddressMgr.getSvr(svrAddressMgr.playerAgentPoolSvr, self._curNodeId)
        -- 踢人
        local ret = clusterExt.call(agentPoolAddr, "lua", "kickAllPlayer", TickCode.maintenance)
        log.Info("sys", "gameserverCloseLogic step", step, "agentPoolAddr", tostring(ret))
    else
        self:closeNormalService(step)

        self:closeDBService(step)

        -- 游服还需要关闭game的mysqllt
        local addr = svrAddressMgr.getSvr(svrAddressMgr.gameDBSvr)
        if addr then
            local ret = clusterExt.call(addr, "lua", "stop")
            log.Info("sys", "close gameDBSvr mysqllt Service step", step, tostring(ret))
        end
    end
end

function _M:chatserverCloseLogic(step)
    if step == close_step.step_close then
        self:closeNormalService(step)

        self:closeDBService(step)

        local addr = svrAddressMgr.getSvr(svrAddressMgr.chatDBSvr)
        if addr then
            local ret = clusterExt.call(addr, "lua", "stop")
            log.Info("sys", "close chatDBSvr mysqllt Service step", step, tostring(ret))
        end
    end
end

local nodeCloseCfg = {
    -- [gNodeType.loginServer] = _M.commonCloseLogic,
    [gNodeType.gameserver] = _M.gameserverCloseLogic,
    [gNodeType.chatserver] = _M.chatserverCloseLogic,
    [gNodeType.globalserver] = _M.commonCloseLogic,
    [gNodeType.infoserver] = _M.commonCloseLogic,
    [gNodeType.crossserver] = _M.commonCloseLogic,
    [gNodeType.webserver] = _M.commonCloseLogic
}

-- 关服逻辑
function _M:closeClusterLogic(step, bResponse)
    log.Info(
        "sys",
        "clusterInfMgr:closeClusterLogic nodename:",
        self._nodeName,
        " step:",
        step,
        "bResponse:",
        bResponse
    )

    -- 标记节点关服
    self._closeTag = true
    if not self._nodeType then
        log.Error("sys", "closeServerLogic _nodeType is nil")
        return
    end

    local close_func = nodeCloseCfg[self._nodeType]
    if not close_func then
        log.Error("sys", "can not found close_func nodeType:", self._nodeType)
        return
    end

    close_func(self, step)

    if step == close_step.step_close then
        -- log.Info("sys", "clusterInfMgr:closeClusterLogic nodename:", self._nodename
        -- 	, " step_close dbservice_addr:", self._dbservice_addr)

        skynet.sleep(5)
    -- TODOS:数据库相关
    -- if self._dbservice_addr then
    -- 	clusterExt.call(self._dbservice_addr, "lua", "safe_quit")
    -- end
    end

    if bResponse then
        skynet.retpack(true)
    end

    if step == close_step.step_close then
        -- 删除文件
        local ret = os.remove(self._successFileName)

        -- if not ret then
        -- log.ddNotify("关服删文件失败" .. tostring(self._curNodeId) .. tostring(self._nodeName) .. tostring(self._successFileName))
        -- end

        -- 关服成功文件
        local stopFileName = string.safeFormat("./.stopsuccess_%s", self._nodeType)
        local file = io.open(stopFileName, "w+")
        file:close()

        skynet.sleep(5)
        skynet.abort()
    end
end

return _M
