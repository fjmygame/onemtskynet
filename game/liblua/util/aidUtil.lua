-- @Author: sgys
-- @Date:   2020-07-30 09:05:31
-- @Last Modified by:   sgys
-- @Last Modified time: 2020-07-30 09:25:08
-- @Desc:   uid规则【个,十,百,千,万位: 5位表示服务器kid ；万位以上：根据不同的kid自增】

local svrconf = require("svrconf")
local json = require("json")
---@class aidUtil
local aidUtil = BuildUtil("aidUtil")

-- 根据aid获取kid
function aidUtil.getKid(aid)
    return aid % 100000
end
-- 合服后的kid
function aidUtil.getLitKid(aid)
    return svrconf.getLitKingdomIDByNodeID(aidUtil.getNodeId(aid))
end
-- 获取玩家所在的节点
function aidUtil.getNodeId(aid)
    return svrconf.getNodeIDByKingdomID(aidUtil.getKid(aid))
end

-- aid归类,根据nodeid
function aidUtil.classify(aids)
    local result = {}
    local errNode = {} -- 节点错
    for _, aid in ipairs(aids) do
        local nodeid = aidUtil.getNodeId(aid)
        if not nodeid then
            errNode[#errNode + 1] = aid
        else
            if not result[nodeid] then
                result[nodeid] = {}
            end
            local list = result[nodeid]
            list[#list + 1] = aid
        end
    end
    if #errNode > 0 then
        -- 报错
        log.ErrorStack("sys", "invalid nodeid", json.encode(errNode), json.encode(aids))
    end
    return result
end

function aidUtil.getAutoId(aid)
    return math.floor(aid / 100000)
end

return aidUtil
