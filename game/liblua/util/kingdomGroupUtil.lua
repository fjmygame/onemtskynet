-- --------------------------------------
-- Create Date:2021-09-18 15:15:00
-- Author  : sgys
-- Version : 1.0
-- Filename: kingdomGroupUtil.lua
-- Introduce  : 类介绍
-- --------------------------------------

local json = require("json")
local confAPI = require("confAPI")
local clusterExt = require("clusterExt")
local svrAddressMgr = require("svrAddressMgr")
local randomUtil = require("randomUtil")
local accountUtil = require("accountUtil")
---@class kingdomGroupUtil
local _M = BuildUtil("kingdomGroupUtil")

function _M.getTableName()
    return "conf_kingdom_group"
end

function _M:query()
    local sql = string.safeFormat("SELECT * FROM %s;", _M.getTableName())
    return clusterExt.call(svrAddressMgr.getSvr(svrAddressMgr.confDBSvr), "lua", "execute", sql)
end

function _M:getUpdateSql(conf)
    return string.safeFormat(
        "UPDATE %s SET `groups`='%s', nodes='%s', maxId=%d, maxKidIndex=%d WHERE id=%d",
        _M.getTableName(),
        json.encode(conf.groups),
        json.encode(conf.nodes),
        conf.maxId,
        conf.maxKidIndex,
        conf.id
    )
end

-- 更新分组数据
function _M:update(conf)
    local sql = self:getUpdateSql(conf)
    clusterExt.send(svrAddressMgr.getSvr(svrAddressMgr.confDBSvr), "lua", "execute", sql)
end

-- 同步更新数据
function _M:syn_update(conf)
    local sql = self:getUpdateSql(conf)
    clusterExt.call(svrAddressMgr.getSvr(svrAddressMgr.confDBSvr), "lua", "execute", sql)
end

-- 初始化检查
function _M:initCheck()
    local ret = self:query()
    if ret and next(ret) then
        local retGroups = {}
        for _, v in ipairs(ret) do
            local id = v.id
            local nodes = json.decode(v.nodes)
            local groups = json.decode(v.groups)
            if nodes and groups then
                v.nodes = nodes
                v.groups = groups
                -- 分配跨服节点
                if self:autoSetCrossNode(v) then
                    self:update(v)
                end
                retGroups[id] = {
                    maxId = v.maxId,
                    maxKidIndex = v.maxKidIndex,
                    groups = groups,
                    nodes = nodes,
                    size = v.size
                }
            else
                log.Error("sys", "(initCheck)The kingdom group nodes is err!!!", id, nodes, groups)
            end
        end
        return retGroups
    end
end

-- 新增王国，自动分配
function _M:autoAddKidCheck(newkid)
    local bok = false
    local newKidIndex = accountUtil.getKidIndex(newkid)
    local ret = self:query()
    if ret and next(ret) then
        for _, v in ipairs(ret) do
            local id = v.id
            local size = v.size
            local nodes = json.decode(v.nodes)
            if nodes then
                v.nodes = nodes
                v.groups = json.decode(v.groups)
                if newKidIndex > v.maxKidIndex then
                    log.Info("gg", "auto set kingdom group =======>>>")
                    bok = true
                    -- 自动分配分组
                    local maxId = v.maxId + 1
                    v.maxId = maxId
                    local beginKidIndex = v.maxKidIndex + 1
                    local maxKidIndex = v.maxKidIndex + size
                    v.maxKidIndex = maxKidIndex
                    v.groups[tostring(maxId)] = {beginKidIndex, maxKidIndex}
                    self:autoSetCrossNode(v)
                    -- 存库
                    self:syn_update(v)
                end
            else
                log.Error("sys", "(autoAddKidCheck)The kingdom group nodes is err!!!", id, newkid)
            end
        end
    end
    return bok
end

-- 自动分配跨服节点
function _M:autoSetCrossNode(conf)
    local id, groups, nodes = conf.id, conf.groups, conf.nodes
    -- 统计每个跨服节点被分配次数
    local nodeMap = {}
    local nogroup = {}
    for k, _ in pairs(groups) do
        local nodeid = nodes[k]
        if nodeid then
            nodeMap[nodeid] = nodeMap[nodeid] and nodeMap[nodeid] + 1 or 1
        else
            table.insert(nogroup, k)
        end
    end

    if next(nogroup) then
        local tempMap = {}
        local nodeids = self:getCrossNodeidsLib(id)
        for _, k in ipairs(nogroup) do
            local nodeid = self:balanceCrossNodeId(nodeids, nodeMap)
            nodes[k] = nodeid
            tempMap[k] = nodeid
        end
        log.Error("sys", "autoSetCrossNode success!!!", dumpTable(tempMap, "newSetMap", 10))
        return true
    end
    return false
end

-- 均衡分配跨服节点
function _M:balanceCrossNodeId(nids, nodeMap)
    local t = {}
    for _, id in ipairs(nids) do
        table.insert(t, {id = id, num = nodeMap[id] or 0})
    end
    table.sort(
        t,
        function(a, b)
            return a.num > b.num
        end
    )
    -- 最少分配的节点
    local nodeid = t[#t].id
    if not nodeMap[nodeid] then
        nodeMap[nodeid] = 1
    else
        nodeMap[nodeid] = nodeMap[nodeid] + 1
    end
    return nodeid
end

-- 去跨服节点
function _M:getCrossNodeidsLib(groupType)
    local kidGroupDef = gKidGroupDef or require("sharedef.kidGroupDef")
    local getFuncs = {
        [kidGroupDef.Chat] = confAPI.getChatNodeIds,
        [kidGroupDef.DragonNest] = confAPI.getCrossNodeIds
    }
    -- 默认都用跨服节点
    local f = getFuncs[groupType] or confAPI.getCrossNodeIds
    return f()
end

------------------- 分组合并 -------------------
-- 王国区间合并【相连的区间合并起来】
function _M:kidRangeMerge(range1, range2)
    local array = table.format(range1, {"min", "max"})
    local tmp = table.format(range2, {"min", "max"})
    for i = 1, #tmp do
        array[#array + 1] = tmp[i]
    end
    table.sort(
        array,
        function(t1, t2)
            return t1.min < t2.min
        end
    )
    local range
    for i = 1, #array do
        local v = array[i]
        if not range then
            range = {v.min, v.max}
        else
            if range[#range] + 1 == v.min then
                range[#range] = v.max
            else
                range[#range + 1] = v.min
                range[#range + 1] = v.max
            end
        end
    end
    return range
end

-- 配置合并分组
--[[
    gidsArr = {
        [1] = [1, 2, 3], -- 3组合并
        [2] = [4,5] --2组合并
    }
]]
function _M:combineGroup(id, gidsArr)
    local ret = self:query()
    if ret and next(ret) then
        for _, v in ipairs(ret) do
            if v.id == id then
                v.nodes = json.decode(v.nodes) or {}
                v.groups = json.decode(v.groups)
                for j = 1, #gidsArr do
                    local groupids = gidsArr[j]
                    local range = {}
                    local litGid
                    for i = 1, #groupids do
                        local groupid = groupids[i]
                        if not litGid or groupid < litGid then
                            litGid = groupid
                        end
                        local currange = v.groups[tostring(groupid)]
                        if currange then
                            range = self:kidRangeMerge(range, currange)
                        else
                            log.Error("sys", "The kingdom group is no found!", groupid)
                        end
                    end
                    -- 保留最小的分组id
                    v.groups[tostring(litGid)] = range
                    for i = 1, #groupids do
                        local groupid = groupids[i]
                        if groupid ~= litGid then
                            local idstr = tostring(groupid)
                            v.groups[idstr] = nil
                            v.nodes[idstr] = nil
                        end
                    end
                end
                log.ddNotify(string.safeFormat("combineGroup ret==>:%s", dumpTable(v)))
                self:update(v)
                return true
            end
        end
    end
    return false
end

-- 合服检查【同组才能合】--业务放到功能服去做
function _M:checkComineServer(kids)
    local globalNodeId = confAPI.getGlobalNodeId()
    local crossRankAddr = svrAddressMgr.getSvr(svrAddressMgr.crossRankSvr, globalNodeId)
    -- 1、跨服冲榜分组
    local bok = clusterExt.call(crossRankAddr, "lua", "checkComineServer", kids)
    if not bok then
        return false, string.safeFormat("checkComineServer fail. kids:%s is not in same Rank group!", json.encode(kids))
    end

    log.Info("gm", "checkComineServer check crossRank complete")
    -- 2、跨服聊天分组
    local crossChatRoomAddr = svrAddressMgr.getSvr(svrAddressMgr.crossChatRoomSvr, globalNodeId)
    bok = clusterExt.call(crossChatRoomAddr, "lua", "checkComineServer", kids)
    if not bok then
        return false, string.safeFormat("checkComineServer fail. kids:%s is not in same Chat group!", json.encode(kids))
    end

    log.Info("gm", "checkComineServer check crossChatRoom complete")
    -- 3、龙岛分组（随机找个服务验证即可）
    local snum = svrAddressMgr.serviceNum[svrAddressMgr.crossDragonNestSvr]
    local nodeids = confAPI.getCrossNodeIds()
    local nodeid = nodeids[randomUtil.random(1, #nodeids)]
    local slaveid = randomUtil.random(1, snum)
    local address = svrAddressMgr.getSvr(svrAddressMgr.crossDragonNestSvr, nodeid, slaveid)
    bok = clusterExt.call(address, "lua", "checkComineServer", kids)
    if not bok then
        return false, string.safeFormat(
            "checkComineServer fail. kids:%s is not in same DragonNest group!",
            json.encode(kids)
        )
    end

    log.Info("gm", "checkComineServer check crossDragonNest complete")
    return true
end

-- 重新划分分组
--[[
    newKidRangeList = {
        [1] = [1, 3],
        [2] = [4, 5]
    }
]]
function _M:resetGroup(id, oldGids, newKidRangeList)
    local ret = self:query()
    if ret and next(ret) then
        for _, v in ipairs(ret) do
            if v.id == id then
                v.nodes = json.decode(v.nodes) or {}
                v.groups = json.decode(v.groups)
                for i = 1, #oldGids do
                    local groupidstr = tostring(oldGids[i])
                    v.groups[groupidstr] = nil
                end
                -- 新的分组设置
                local gindex = 0
                local bNewG = false
                for _, range in ipairs(newKidRangeList) do
                    gindex = gindex + 1
                    local groupid
                    if gindex <= #oldGids then
                        -- 优先回收旧的groupid
                        groupid = oldGids[gindex]
                    else
                        -- 自动分配分组
                        local maxId = v.maxId + 1
                        v.maxId = maxId
                        groupid = maxId
                        bNewG = true
                    end
                    v.groups[tostring(groupid)] = range
                end
                -- 多余分组的节点分配信息删掉
                if gindex < #oldGids then
                    for i = gindex, #oldGids do
                        v.nodes[tostring(oldGids[i])] = nil
                    end
                end
                -- 如果有新分配的组则需要分配节点
                if bNewG then
                    self:autoSetCrossNode(v)
                end
                log.ddNotify(string.safeFormat("resetGroup ret==>:%s", dumpTable(v)))
                self:syn_update(v)
                return true
            end
        end
    end
    return false
end

return _M
