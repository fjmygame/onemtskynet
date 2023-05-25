--------------------------------------------------------------------------------
-- 文件: accountUtil.lua
-- 作者: zkb
-- 时间: 2020-04-17 11:46:31
-- 描述: 账号协助
-- user和account表关系: 字符串ascii码累加取模10
-- uid规则:
--      个,十,百,千,万位: 5位表示服务器kid
--      万位:         0-9 大区
--------------------------------------------------------------------------------
local svrconf = require("svrconf")
local json = require("json")
---@class accountUtil
local accountUtil = BuildUtil("accountUtil")

function accountUtil.userToIndex(user)
    local index = string.byteSum(user) % 10 -- 账号分表
    return index
end

-- 根据玩家名字获取account表名
function accountUtil.sqlNameByUser(user)
    local index = accountUtil.userToIndex(user)
    return string.safeFormat("account_%d", index)
end

-- 根据kid计算zone
function accountUtil.getZoneByKid(kid)
    return math.floor(kid / 10000)
end

-- 根据uid获取大区
function accountUtil.getZone(uid)
    return accountUtil.getZoneByKid(accountUtil.getKid(uid))
end

-- 根据uid获取kid
function accountUtil.getKid(uid)
    if type(uid) ~= "number" then
        log.ErrorStack("sys", "uid type err", type(uid), uid)
    end

    return math.floor(uid % 100000)
end
-- 合服后的kid
function accountUtil.getLitKid(uid)
    return svrconf.getLitKingdomIDByNodeID(accountUtil.getNodeId(uid))
end
-- 获取kid的自增长值
function accountUtil.getKidIndex(kid)
    return kid % 10000
end

-- 获取玩家所在的节点
function accountUtil.getNodeId(uid)
    return svrconf.getNodeIDByKingdomID(accountUtil.getKid(uid))
end

-- uid归类,根据nodeid
function accountUtil.uidClassify(uids)
    local result = {}
    local errNode = {} -- 节点错
    for _, uid in ipairs(uids) do
        local kid = accountUtil.getKid(uid)
        local nodeid = svrconf.getNodeIDByKingdomID(kid)
        if not nodeid then
            errNode[#errNode + 1] = uid
        else
            if not result[nodeid] then
                result[nodeid] = {}
            end
            local list = result[nodeid]
            list[#list + 1] = uid
        end
    end
    -- 报错
    if #errNode > 0 then
        log.ErrorStack("account", "invalid nodeid", json.encode(errNode), json.encode(uids))
    end
    return result
end

-- uid归类,根据nodeid
---@param uidMap table<integer, table> <uid, data>
function accountUtil.uidMapClassify(uidMap)
    local result = {}
    local errNode = {} -- 节点错
    for uid, info in pairs(uidMap) do
        local kid = accountUtil.getKid(uid)
        local nodeid = svrconf.getNodeIDByKingdomID(kid)
        if not nodeid then
            errNode[uid] = info
        else
            local map = CreateBlankTable(result, nodeid)
            map[uid] = info
        end
    end
    -- 报错
    if next(errNode) then
        log.ErrorStack("account", "invalid nodeid", json.encode(errNode), json.encode(uidMap))
    end
    return result
end

-- uid归类,根据nodeid
---@param uidMap table<string, table> <uidStr, data>
function accountUtil.uidStrMapClassify(uidMap)
    local result = {}
    local errNode = {} -- 节点错
    for uidStr, info in pairs(uidMap) do
        local uid = tonumber(uidStr)
        local kid = accountUtil.getKid(uid)
        local nodeid = svrconf.getNodeIDByKingdomID(kid)
        if not nodeid then
            errNode[uid] = info
        else
            local map = CreateBlankTable(result, nodeid)
            map[uid] = info
        end
    end
    -- 报错
    if next(errNode) then
        log.ErrorStack("account", "invalid nodeid", json.encode(errNode), json.encode(uidMap))
    end
    return result
end

function accountUtil.getAutoId(uid)
    return math.floor(uid / 100000)
end

return accountUtil
