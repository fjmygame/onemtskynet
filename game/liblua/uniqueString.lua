---------------------------------------------------------------------------------
-- 文件: uniqueString.lua
-- 作者: zkb
-- 时间: 2019-10-12 15:10:04
-- 描述: 唯一字符串 [玩家名字，联盟名字等]
--------------------------------------------------------------------------------
local redisLib = require("redisLib")

local uniqueString = {}

-- 说明: 利用redis hsetnx
--     hsetnx :将哈希表 key 中的域 field 的值设置为 value ，当且仅当域 field 不存在。
--             若域 field 已经存在，该操作无效。

local userNameHash = gGameName .. ":user_name_nx"

--- 保存玩家name和uid对映关系，如果玩家名字已经存在则返回0
-- @number userName 玩家名字
-- @number uid 玩家id
-- @return 操作成功返回true 否则false[名字重复]
-- @usage uniqueString.userNameNX("userName", 1)
function uniqueString.userNameNX(nodeid, userName, uid)
    return redisLib.hSetNX(nodeid, userNameHash, userName, uid) == 1
end

-- 根据玩家名字查询uid
function uniqueString.getUidByName(nodeid, userName)
    local uid = redisLib.hGet(nodeid, userNameHash, userName)
    if not uid then
        return 0
    end
    return tonumber(uid)
end

--- 玩家重命名
-- @number number desc
-- @return return desc
-- @usage usage desc
function uniqueString.renameNX(nodeid, oldName, newName, uid)
    if not uniqueString.userNameNX(nodeid, newName, uid) then
        return false
    end
    redisLib.hDel(nodeid, userNameHash, oldName) -- 删掉旧的名字
    return true
end

return uniqueString
