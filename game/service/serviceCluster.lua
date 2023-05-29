-- --------------------------------------
-- Create Date:2021-05-13 16:06:37
-- Author  : sgys
-- Version : 1.0
-- Filename: serviceCluster.lua
-- Introduce  : 服务集群（需要全部初始化完成才能开始）
-- --------------------------------------
local skynet = require("skynet")
local clusterExt = require("clusterExt")
local svrAddressMgr = require("svrAddressMgr")
local asynTaskUtil = require("asynTaskUtil")
---@class serviceCluster
local _M = BuildOther("serviceCluster")

local function newService(serviceName, ...)
    local addr = skynet.newservice(serviceName, ...)
    local bok = clusterExt.call(addr, "lua", "init", ...)
    if not bok then
        log.Fatal("sys", string.safeFormat("serviceCluster new serviceName:%s init err", serviceName))
    end
    return addr
end

-- 启动
function _M.start(serviceGroupList, bAsyn)
    local startBegin = skynet.now()
    -- 启动服务
    local nodeId = tonumber(skynet.getenv("node_id"))
    local serviceName2Num = svrAddressMgr.serviceName2Num
    local startServerAddrMap = {}
    for _, serviceList in pairs(serviceGroupList) do
        local taskMap = {}
        for _, serviceName in ipairs(serviceList) do
            local startAddrMap = {}
            local serviceNum = serviceName2Num[serviceName] or 1
            for j = 1, serviceNum do
                if serviceNum > 1 then
                    if bAsyn then
                        taskMap[serviceName .. j] = function()
                            local addr = newService(serviceName, nodeId, j)
                            startAddrMap[#startAddrMap + 1] = addr
                        end
                    else
                        local addr = newService(serviceName, nodeId, j)
                        startAddrMap[#startAddrMap + 1] = addr
                    end
                else
                    if bAsyn then
                        taskMap[serviceName .. j] = function()
                            local addr = newService(serviceName, nodeId)
                            startAddrMap[#startAddrMap + 1] = addr
                        end
                    else
                        local addr = newService(serviceName, nodeId)
                        startAddrMap[#startAddrMap + 1] = addr
                    end
                end
            end
            startServerAddrMap[serviceName] = startAddrMap
        end

        if bAsyn then
            asynTaskUtil.doAsynTasks(taskMap)
        end
    end

    --log.Info("sys", "serviceCluster start begin", dumpTable(startServerAddrMap))
    -- 服务start
    local taskMap = {}
    for _, serviceList in pairs(serviceGroupList) do
        for _, serviceName in ipairs(serviceList) do
            local list = startServerAddrMap[serviceName]
            --log.Info("sys", "serviceCluster start #list", serviceName, #list)
            for _, addr in ipairs(list) do
                if bAsyn then
                    taskMap[addr] = function()
                        local bok = clusterExt.call(addr, "lua", "start")
                        if not bok then
                            log.Fatal(
                                "sys",
                                string.safeFormat("serviceCluster new serviceName:%s start err", serviceName)
                            )
                        end
                    end
                else
                    local bok = clusterExt.call(addr, "lua", "start")
                    if not bok then
                        log.Fatal("sys", string.safeFormat("serviceCluster new serviceName:%s start err", serviceName))
                    end
                end
            end
        end
    end

    if bAsyn then
        asynTaskUtil.doAsynTasks(taskMap)
    end

    log.Info("sys", "serviceCluster start costTime", skynet.now() - startBegin)
    return startServerAddrMap
end

return _M
