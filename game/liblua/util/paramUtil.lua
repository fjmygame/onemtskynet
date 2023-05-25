-- --------------------------------------
-- Create Date:2023-03-20 09:40:35
-- Author  : Happy Su
-- Version : 1.0
-- Filename: paramUtil.lua
-- Introduce  : 参数检查
-- --------------------------------------
---@type confAPI
local confAPI = require("confAPI")
local svrconf = require("svrconf")
---@class paramUtil
local paramUtil = BuildUtil("paramUtil")

--[[返回值规范
{
	result = true, 	-- 成功或者失败
	msg = "xxxx",	-- 消息 失败消息
	data = "",		-- 参数
}
]]
-- 成功返回模板
function paramUtil.successData(data, msg)
    msg = msg or "success"
    return {result = true, msg = msg, data = data}
end

-- 失败返回模板
function paramUtil.failedData(errMsg, data)
    errMsg = errMsg or "failed"
    return {result = false, msg = errMsg, data = data}
end

-- 转换numList值为数值数组
-- {"20", 30, 5} --> {20, 30, 5}
function paramUtil.formatArray(numList)
    if not numList or #numList == 0 then
        return false
    end
    local ret = {}
    for _, v in ipairs(numList) do
        local uid = tonumber(v)
        if not uid or uid == 0 then
            return false
        end
        table.insert(ret, uid)
    end
    return true, numList
end

-- 判断参数是否是数值
function paramUtil.isNumber(val)
    if not val or "number" ~= type(val) then
        return false
    end
    return true
end

-- 判断参数是否是字符串
function paramUtil.isString(val)
    if not val or "string" ~= type(val) then
        return false
    end
    return true
end

function paramUtil.isStrArray(datas)
    if not datas or #datas == 0 then
        return false
    end

    for _, v in ipairs(datas) do
        if "string" ~= type(v) then
            return false
        end
    end
    return true
end

function paramUtil.checkParamNumber(tb, fields)
    for _, field in ipairs(fields) do
        local val = tb[field]
        if not val then
            return false, "not param " .. field
        end
        if not paramUtil.isNumber(val) then
            return false, string.safeFormat("param %s not a number", field)
        end
    end
    return true
end

-- 判断tb是否包含fields中的字段，并且值类型是字符串
function paramUtil.checkParamString(tb, fields)
    for _, field in ipairs(fields) do
        local val = tb[field]
        if not val then
            return false, "not param " .. field
        end
        if not paramUtil.isString(val) then
            return false, string.safeFormat("param %s not a string", field)
        end
    end
    return true
end

-- 根据kid获取所在的nodeid
function paramUtil.checkParamKids(kids)
    local ret = {}
    for _, kid in ipairs(kids) do
        local nodeid = svrconf.getNodeIDByKingdomID(kid)
        if not nodeid then
            return false, string.safeFormat("kid:%d is not exist!", kid)
        end
        local litKid = svrconf.getLitKingdomIDByNodeID(nodeid)
        if litKid ~= kid then
            return false, string.safeFormat("kid:%d have been merged to kid:%d!", kid, litKid)
        end
        ret[litKid] = nodeid
    end
    if not next(ret) then
        return false, string.safeFormat("kids format error or empty")
    end
    return true, ret
end

-- 确保kid是正确的主服id
function paramUtil.checkParamKid(kid)
    local nodeid = svrconf.getNodeIDByKingdomID(kid)
    if not nodeid then
        return false, string.safeFormat("kid:%d is not exist!", kid)
    end
    local litKid = svrconf.getLitKingdomIDByNodeID(nodeid)
    if litKid ~= kid then
        return false, string.safeFormat("kid:%d have been merged to kid:%d!", kid, litKid)
    end
    local nodeConf = confAPI.getGameNodeConfById(nodeid)
    return true, nodeid, nodeConf.kids
end

-- 道具检查
function paramUtil.checkParamItems(items)
    if not items or not next(items) then
        return false, string.safeFormat("items nil")
    end
    for _, v in ipairs(items) do
        local id, count = v.id, v.count
        if not id or not count or type(id) ~= "number" or type(count) ~= "number" then
            return false, string.safeFormat("items format error")
        end
    end
    return true
end

-- 解析王国范围格式
---@param kidStr string {"10001","10002-10020"}
---@return boolean, string/table bok,err/{min_kid_1,max_kid_1,min_kid_2,max_kid_2...}
function paramUtil.decodeKidRange(kidStr)
    local kidRange = {}
    local strArr = string.split(kidStr, ",")
    for _, strItem in ipairs(strArr) do
        local arr2 = string.split(strItem, "-")
        if #arr2 == 1 then
            kidRange[#kidRange + 1] = tonumber(arr2[1])
            kidRange[#kidRange + 1] = tonumber(arr2[1])
        elseif #arr2 == 2 then
            kidRange[#kidRange + 1] = tonumber(arr2[1])
            kidRange[#kidRange + 1] = tonumber(arr2[2])
        else
            return false, "kidStr err"
        end
    end
    -- 检查kid是否正确
    for _, kid in ipairs(kidRange) do
        local bok, err = paramUtil.checkParamKid(kid)
        if not bok then
            return bok, err
        end
    end
    return true, kidRange
end

-- 根据kid列表，返回nodeidMap
function paramUtil.kidsToNodeIdMap(kids)
    local nodeIdMap = {}
    for _, kid in ipairs(kids) do
        local nodeid = svrconf.getNodeIDByKingdomID(kid)
        if nodeid then
            nodeIdMap[nodeid] = true
        else
            return false, string.safeFormat("kids error kid:%s", tostring(kid))
        end
    end

    return true, nodeIdMap
end

-- 根据nodeids列表，返回nodeidMap
function paramUtil.nodeidsToNodeIdMap(nodeids)
    local nodeidMap = {}
    for _, v in ipairs(nodeids) do
        local nodeid = tonumber(v)
        local nodeCfg = confAPI.getClusterConf(nodeid)
        if not nodeCfg then
            return false, string.safeFormat("nodeid:%d is not exist!", nodeid)
        end
        nodeidMap[nodeid] = nodeCfg.nodename
    end

    return true, nodeidMap
end

-- 根据服务器类型，获取nodeidMap
function paramUtil.serverTypeToNodeIdMap(serverType)
    local nodeidMap = {}
    local clusterConfMap = confAPI.getClusterConf()
    for nodeid, nodeCfg in pairs(clusterConfMap) do
        if nodeCfg and serverType == nodeCfg.serverType then
            local nodename = nodeCfg.nodename
            nodeidMap[nodeid] = nodename
        end
    end

    return nodeidMap
end

-- 根据服务器类型，获取nodeidMap
function paramUtil.serverTypeStrToNodeIdMap(serverTypeStr)
    local destServerTypeList = string.splitTrim(serverTypeStr, ",")
    local destSTypeMap = {}
    for _, stype in pairs(destServerTypeList) do
        destSTypeMap[stype] = true
    end
    local nodeidMap = {}
    local clusterConfMap = confAPI.getClusterConf()
    for nodeid, nodeCfg in pairs(clusterConfMap) do
        if nodeCfg and destSTypeMap[nodeCfg.serverType] then
            local nodename = nodeCfg.nodename
            nodeidMap[nodeid] = nodename
        end
    end

    return nodeidMap
end

-- 获取所有的节点NodeidMap
function paramUtil.getAllNodeidMap()
    local nodeidMap = {}
    local clusterConfMap = confAPI.getClusterConf()
    for nodeid, nodeCfg in pairs(clusterConfMap) do
        if nodeCfg then
            local nodename = nodeCfg.nodename
            nodeidMap[nodeid] = nodename
        end
    end

    return nodeidMap
end

-- 获取nodeidMap
function paramUtil.getNodeidMapByNodeIdsServerTyps(nodeids, serverType, serverTypeStr)
    local nodeidMap
    if nodeids and #nodeids > 0 then
        local bok, err = paramUtil.nodeidsToNodeIdMap(nodeids)
        if not bok then
            return false, err
        end
        nodeidMap = err
    elseif serverType then
        nodeidMap = paramUtil.serverTypeToNodeIdMap(serverType)
    elseif serverTypeStr then
        nodeidMap = paramUtil.serverTypeStrToNodeIdMap(serverTypeStr)
    else
        nodeidMap = paramUtil.getAllNodeidMap()
    end

    if not next(nodeidMap) then
        return false, "nodeidMap is empty"
    end

    return true, nodeidMap
end

local function addSucessLog(success, kid)
    success[#success + 1] = kid
end

local function addFailLog(fail, kid, reason)
    if not next(fail) then
        fail[#fail + 1] = {kids = {kid}, reason = reason}
        return
    end

    for _, v in ipairs(fail) do
        if v.reason == reason then
            v.kids[#v.kids + 1] = kid
            return
        end
    end
    -- 没有一样的则自成一派
    fail[#fail + 1] = {kids = {kid}, reason = reason}
end

-- 收集王国列表执行结果
function paramUtil.classifyKidListResult(result, kid, ok, err)
    local success = result.success
    local fail = result.fail
    if ok then
        addSucessLog(success, kid)
    else
        addFailLog(fail, kid, err)
    end
end

return paramUtil
