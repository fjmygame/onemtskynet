-- --------------------------------------
-- Create Date:2020-12-07 16:39:27
-- Author  : Happy Su
-- Version : 1.0
-- Filename: clusterMgr.lua
-- Introduce  : 类介绍
-- --------------------------------------
local skynet = require "skynet"
local initDBConf = require "initDBConf"
local sharedata = require "sharedata"
local clusterExt = require "clusterExt"
local clusterDef = require "clusterDef"
local svrAddressMgr = require "svrAddressMgr"
local serverdef = require "constDef.serverdef"
local clusterBaseMgr = require "clusterBaseMgr"
local loginAPI = require "loginAPI"

---@class clusterMgr : clusterBaseMgr
local _M = instanceClass("clusterMgr", clusterBaseMgr)

local gServerType = serverdef.gServerType
local close_step = clusterDef.close_step
local retPack = skynet.retpack

function _M:ctor()
    _M.super.ctor(self)
    self.clusterMap = {}
end

-- 初始化
function _M:init()
    -- _M.super.init(self)
end

function _M:update()
    -- _M.super.update(self)

    if self.closeExpireTime and self.closeExpireTime < skynet.time() then
        self:checkCloseProgram()
    end
end

-- 节点启动完成
function _M:nodeStartComplete(successFileName)
    self._completeTag = true
    -- 开服成功的文件名
    self._successFileName = successFileName
    -- 根据节点不同，处理不同
    retPack(true)
end

local CLUSTER_STATUS = {
    INACTIVE = 0,
    ACTIVE = 1
}

function _M:updateCluster(nodeType, curNodeId, nodeName, clusterInfAddr)
    if not self._completeTag then --等节点启动完毕，再缓存其它节点数据
        return
    end

    local nodeStatus = self:getClusterStatusSub(curNodeId) --handle expireTime
    local clusterMap = self.clusterMap
    local nodeInfo = clusterMap[curNodeId]
    if not nodeInfo then
        clusterMap[curNodeId] = {
            nodeType = nodeType, -- 节点类型 gameserver/chatserver
            curNodeId = curNodeId, -- 节点id
            nodeName = nodeName, -- 节点名字 gameserver_1
            address = clusterInfAddr, -- 港口地址
            expireTime = skynet.time() + clusterDef.cluster_expire_seconds * 100
        }
    else
        nodeInfo.expireTime = skynet.time() + clusterDef.cluster_expire_seconds * 100
    end

    -- 发送login restart检查
    if nodeStatus == CLUSTER_STATUS.INACTIVE and nodeType and nodeType == "gameserver" then -- restart or expireTime
        -- in checkGameServerRegister will check server_list if exist
        loginAPI.sendCmd("checkGameServerRegister", curNodeId, nodeName)
    end
end

-- 中心节点处理子节点注册
function _M:registerCluster(nodeType, curNodeId, nodeName, clusterInfAddr)
    log.Info("sys", "registerCluster", nodeType, curNodeId, nodeName, clusterInfAddr)
    self:updateCluster(nodeType, curNodeId, nodeName, clusterInfAddr)
    retPack(true)
end

function _M:keepCluster(nodeType, curNodeId, nodeName, clusterInfAddr)
    self:updateCluster(nodeType, curNodeId, nodeName, clusterInfAddr)
end

-- 检查节点是否都准备完成
function _M:checkNodeList(nodeIdList)
    local allComplete = true
    local unCompleteNodeList = {}
    local INACTIVE = CLUSTER_STATUS.INACTIVE
    for _, nodeid in ipairs(nodeIdList) do
        if INACTIVE == self:getClusterStatusSub(nodeid) then
            allComplete = false
            unCompleteNodeList[#unCompleteNodeList + 1] = nodeid
        end
    end

    retPack(allComplete, unCompleteNodeList)
end

function _M:getClusterStatus(nodeid)
    retPack(self:getClusterStatusSub(nodeid))
end

function _M:getClusterStatusSub(nodeid)
    local nodeInfo = self.clusterMap[nodeid]
    if nodeInfo and nodeInfo.expireTime > skynet.time() then
        return CLUSTER_STATUS.ACTIVE
    end
    return CLUSTER_STATUS.INACTIVE
end

local cluster_close_level = {
    -- 第一步关闭对外的web服务
    [gServerType.webServer] = 1, -- 游服
    -- 第二步关闭游服
    [gServerType.gameServer] = 2, -- 游服
    -- 第三步关闭公共服
    [gServerType.chatServer] = 3, -- 全服排行
    [gServerType.infoServer] = 3, -- 联盟服
    [gServerType.crossServer] = 3, -- 聊天室服务器
    [gServerType.globalServer] = 3, -- 全局中心
    -- 第四步
    [gServerType.loginServer] = 4 -- 登录服
}

function _M:closeCluster()
    if self.curCloseLevel then
        return retPack(false)
    end
    self.curCloseLevel = 0

    -- DD通知
    log.ddNotify("开始关服")

    -- 通知所有服务关闭
    self.closeTagMap = {}
    -- 分层级关服
    self:checkCloseProgram()

    return retPack(true)
end

local function process_close_node(self, nodeName, address, step, bResponse, tagMap)
    local destAddr = clusterExt.pack_cluster_address(nodeName, address)
    log.Info("sys", "process_close_node start:", nodeName, step, tostring(destAddr))

    -- 标记进行中
    tagMap[nodeName] = true
    local closeRet =
        clusterExt.call(clusterExt.pack_cluster_address(nodeName, address), "lua", "closeClusterLogic", step, bResponse)

    log.Info("sys", "process_close_node closeRet:", closeRet, nodeName, step)

    -- 标记完成
    tagMap[nodeName] = nil
    self:checkCloseProgram()
end

function _M:checkCloseProgram()
    if not self.curCloseLevel then
        return
    end

    if self.curCloseLevel > 100 then
        -- 大于100直接退出，避免死循环
        log.Error("sys", "close cluster err checkCloseProgram curCloseLevel:", self.curCloseLevel)
        return
    end

    if self.closeExpireTime then
        -- 没有超时，也没有完成目前的任务
        log.Info(
            "sys",
            "checkCloseProgram can stop ",
            skynet.time() < self.closeExpireTime,
            table.nums(self.closeTagMap) > 0
        )
        if skynet.time() < self.closeExpireTime and table.nums(self.closeTagMap) > 0 then
            log.Dump("sys", self.closeTagMap, "checkCloseProgram stop")
            return
        end
    else
        self.closeExpireTime = skynet.time() + 60 * 100
    end

    local isEmpty = true
    local curCloseLevel = self.curCloseLevel
    if not self.curCloseStep or self.curCloseStep == close_step.step_close then
        -- 开始新的一个级别的关服
        curCloseLevel = curCloseLevel + 1
        self.curCloseLevel = curCloseLevel
        self.closeTagMap = {}
        self.curCloseStep = close_step.step_pre
        log.Info("sys", "checkCloseProgram curCloseLevel:", curCloseLevel, "step:", self.curCloseStep)
        for nodeId, info in pairs(self.clusterMap) do
            local level = cluster_close_level[info.nodeType]
            if level == curCloseLevel then
                isEmpty = false
                log.Info(
                    "sys",
                    "checkCloseProgram curCloseLevel:",
                    curCloseLevel,
                    "level:",
                    level,
                    "close nodeName:",
                    info.nodeName
                )
                skynet.fork(
                    process_close_node,
                    self,
                    info.nodeName,
                    info.address,
                    close_step.step_pre,
                    true,
                    self.closeTagMap
                )
            end
        end
    else
        self.curCloseStep = close_step.step_close
        log.Info("sys", "checkCloseProgram curCloseLevel:", curCloseLevel, "step:", self.curCloseStep)
        for nodeId, info in pairs(self.clusterMap) do
            local level = cluster_close_level[info.nodeType]
            if level == curCloseLevel then
                isEmpty = false
                log.Info(
                    "sys",
                    "checkCloseProgram curCloseLevel:",
                    curCloseLevel,
                    "step:",
                    close_step.step_close,
                    "close nodeName:",
                    info.nodeName
                )
                skynet.fork(
                    process_close_node,
                    self,
                    info.nodeName,
                    info.address,
                    close_step.step_close,
                    true,
                    self.closeTagMap
                )
            end
        end
    end

    -- log.Dump("sys", self.clusterMap, "self.clusterMap")
    log.Dump("sys", self.closeTagMap, "closeTagMap")

    log.Info(
        "sys",
        "close server step:",
        self.curCloseLevel,
        self.curCloseLevel == cluster_close_level[gServerType.loginServer]
    )
    -- 到中心服了，关闭自己
    if self.curCloseLevel == cluster_close_level[gServerType.loginServer] then
        -- self.s_timemgr:savedb()

        -- if self._dbservice_addr then
        --     clusterExt.call(self._dbservice_addr, "lua", "safe_quit")
        -- end
        -- 删除文件
        local ret = os.remove(self._successFileName)

        -- 关服成功文件
        local stopFileName = string.safeFormat("./.stopsuccess_%s", self._nodeType)
        local file = io.open(stopFileName, "w+")
        file:close()

        log.ddNotify("关服完成 " .. tostring(ret or ""))

        --退出进程
        skynet.sleep(50)
        skynet.abort()
    end

    -- 如果这个级别没有服可关，直接进入下一步检查
    if isEmpty then
        self:checkCloseProgram()
        return
    end
end

-- 关闭单个节点
function _M:closeSingleCluster(nodeId)
    if self.curCloseLevel then
        return retPack(false)
    end

    local nodeInfo = self.clusterMap[nodeId]
    if not nodeInfo then
        return retPack(false)
    end

    -- 检查节点是否有效，判断有效的时候，放大点，以防误
    if nodeInfo.expireTime < skynet.time() then
        return retPack(false)
    end

    -- DD通知开始
    local nodeIdStr = tostring(nodeId)
    log.ddNotify("开始关闭节点：" .. nodeIdStr)
    -- 关闭节点
    clusterExt.call(
        clusterExt.pack_cluster_address(nodeInfo.nodeName, nodeInfo.address),
        "lua",
        "closeClusterLogic",
        close_step.step_pre,
        true
    )
    clusterExt.call(
        clusterExt.pack_cluster_address(nodeInfo.nodeName, nodeInfo.address),
        "lua",
        "closeClusterLogic",
        close_step.step_close,
        true
    )

    -- DD通知成功
    log.ddNotify("节点关闭完成:" .. nodeIdStr)

    return retPack(true)
end

return _M
