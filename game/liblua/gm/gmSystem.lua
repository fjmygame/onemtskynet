--------------------------------------------------------------------------------
-- 文件: gmSystem.lua
-- 作者: zkb
-- 时间: 2020-08-20 19:52:09
-- 描述: gm相关操作
--------------------------------------------------------------------------------
local svrconf = require("svrconf")
local confAPI = require("confAPI")
local accountUtil = require("accountUtil")
local batchDataAPI = require("batchDataAPI")

local _M = BuildOther("gmSystem")

-- 成功返回模板
function _M.successData(msg, data)
    msg = msg or "success"
    return {result = true, msg = msg, data = data}
end

-- 失败返回模板
function _M.failedData(msg, data)
    msg = msg or "failed"
    return {result = false, msg = msg, data = data}
end

--- func desc
-- @number bool 成功or失败
-- @number data 返回数据
-- @number msg 错误码or说明
-- @return return desc
-- @usage usage desc
function _M.resultData(ok, msg, data)
    msg = msg or (ok and "success" or "failed")
    return {result = ok, msg = msg, data = data}
end

function _M.newResult()
    return {success = {}, fail = {}}
end
--------------------------------------------------------------------------------
-- 参数相关处理

--- formatArray 检查uids kids, 确保是数字数组
-- @number ids id数组[可以为string数组]
-- @return ret 返回number数组
-- @usage usage desc
function _M.formatArray(ids)
    if not ids or #ids == 0 then
        return false
    end
    local ret = {}
    for _, v in ipairs(ids) do
        local id = tonumber(v)
        if not id or id == 0 then
            return false
        end
        table.insert(ret, id)
    end
    return true, ret
end

function _M.isNumber(val)
    if not val or "number" ~= type(val) then
        return false
    end
    return true
end

function _M.isString(val)
    if not val or "string" ~= type(val) then
        return false
    end
    return true
end

function _M.checkParamNumber(tb, fields)
    for _, field in ipairs(fields) do
        local val = tb[field]
        if not val then
            return false, "not param " .. field
        end
        if not _M.isNumber(val) then
            return false, string.safeFormat("param %s not a number", field)
        end
    end
    return true
end

function _M.checkParamString(tb, fields)
    for _, field in ipairs(fields) do
        local val = tb[field]
        if not val then
            return false, "not param " .. field
        end
        if not _M.isString(val) then
            return false, string.safeFormat("param %s not a string", field)
        end
    end
    return true
end

-- 根据kid获取所在的nodeid
function _M.checkParamKids(kids)
    local ret = {}
    local allKids = {}
    for _, kid in ipairs(kids) do
        local nodeid = svrconf.getNodeIDByKingdomID(kid)
        if not nodeid then
            return false, string.safeFormat("kid:%d is not exist!", kid)
        end
        local litKid = svrconf.getLitKingdomIDByNodeID(nodeid)
        if litKid ~= kid then
            return false, string.safeFormat("kid:%d have been merged to kid:%d!", kid, litKid)
        end
        ret[kid] = nodeid
        local nodeConf = confAPI.getGameNodeConfById(nodeid)
        table.insertto(allKids, nodeConf.kids)
    end
    if not next(ret) then
        return false, string.safeFormat("kids format error or empty")
    end
    return true, ret, allKids
end

function _M.checkParamKid(kid)
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

-- uid归类,根据nodeid
function _M.uidClassify(uids)
    local result = {}
    local errNode = {} -- 节点错
    local errUid = {} -- uid不在节点中
    for _, uid in ipairs(uids) do
        local nodeid = accountUtil.getNodeId(uid)
        if not nodeid then
            -- return false, string.safeFormat("uid:%d not find nodeid!", uid)
            errNode[#errNode + 1] = uid
        else
            if not batchDataAPI.isInThisNode(nodeid, uid) then
                errUid[#errUid + 1] = uid
            else
                if not result[nodeid] then
                    result[nodeid] = {}
                end
                local list = result[nodeid]
                list[#list + 1] = uid
            end
        end
    end

    if #errNode > 0 or #errUid > 0 then
        local errData = {}
        if #errNode > 0 then
            table.insert(errData, {uids = errNode, reason = "invalid nodeid"})
        end
        if #errUid > 0 then
            table.insert(errData, {uids = errUid, reason = "uid not in node or service maintain"})
        end
        return false, "invalid uid", errData
    end
    return true, result
end

-- uid归类,根据nodeid
function _M.uidClassifyLtid(uids)
    local result = {}
    local nodeIdMap = {}
    local errNode = {} -- 节点错
    local errUid = {} -- uid不在节点中
    for _, uid in ipairs(uids) do
        local nodeid = accountUtil.getNodeId(uid)
        if not nodeid then
            -- return false, string.safeFormat("uid:%d not find nodeid!", uid)
            errNode[#errNode + 1] = uid
        else
            local list = nodeIdMap[nodeid]
            if not list then
                list = {}
                nodeIdMap[nodeid] = list
            end
            list[#list + 1] = uid
        end
    end

    local errData = {}
    if #errNode > 0 then
        table.insert(errData, {uids = errNode, reason = "invalid nodeid"})
    end

    if #errUid > 0 then
        table.insert(errData, {uids = errUid, reason = "uid not in node or service maintain"})
    end

    for nodeid, list in pairs(nodeIdMap) do
        local ltidMap, unFoundList = batchDataAPI.queryLTIDs(nodeid, list)
        result[nodeid] = ltidMap
        if #unFoundList > 0 then
            table.insert(errData, {uids = errUid, reason = "uid not in node or service maintain"})
        end
    end

    if #errData > 0 then
        return false, "invalid uid", errData
    end

    return true, result, nodeIdMap
end

--------------------------------------------------------------------------------
-- 返回值处理
function _M.addSucessLog(success, kid)
    success[#success + 1] = kid
end

function _M.addFailLog(fail, kid, reason)
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

function _M.classifyResult(result, kid, ok, err)
    local success = result.success
    local fail = result.fail
    if ok then
        _M.addSucessLog(success, kid)
    else
        _M.addFailLog(fail, kid, err)
    end
end

function _M.failReasonFill(fail)
    for _, v in ipairs(fail) do
        if not v.reason then
            v.reason = "server exception"
        end
    end
end

function _M.finalResult(result)
    local ok = true
    local msg = "partial request failed"
    if not next(result.success) then
        result.success = nil
        msg = "all failed"
    end
    if not next(result.fail) then
        result.fail = nil
        msg = "success"
    else
        ok = false
        _M.failReasonFill(result.fail)
    end
    return ok, msg
end

return _M
