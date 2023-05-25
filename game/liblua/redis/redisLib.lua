local clusterExt = require "clusterExt"

local svrAddressMgr = require "svrAddressMgr"

---@class redisLib
local redisLib = BuildOther("redisLib")

local byteSum = string.byteSum
--
local instance = gRedisInstance
local function getSubIndex(key)
    local sum = byteSum(key)
    return sum % instance + 1
end

local function getAddr(nodeid, key)
    local index = getSubIndex(key)
    return svrAddressMgr.getSvrNew(svrAddressMgr.redisSubSvr, nodeid, index)
end

--[[
根据key是否存在value
]]
function redisLib.exists(nodeid, key)
    return clusterExt.call(getAddr(nodeid, key), "lua", "exists", key)
end

--[[
 设置key=》value
]]
function redisLib.set(nodeid, key, value)
    return clusterExt.call(getAddr(nodeid, key), "lua", "set", key, value)
end

function redisLib.send_set(nodeid, key, value)
    clusterExt.send(getAddr(nodeid, key), "lua", "set", key, value)
end
--[[
根据key获得value
]]
function redisLib.get(nodeid, key)
    return clusterExt.call(getAddr(nodeid, key), "lua", "get", key)
end

--[[
setex 带生存时间的写入值
]]
function redisLib.setex(nodeid, key, seconds, value)
    return clusterExt.call(getAddr(nodeid, key), "lua", "setex", key, seconds, value)
end

function redisLib.send_setex(nodeid, key, seconds, value)
    clusterExt.send(getAddr(nodeid, key), "lua", "setex", key, seconds, value)
end

--[[
    判断是否重复的，写入值 如果已经写入则不修改
]]
function redisLib.setnx(nodeid, key, value)
    return clusterExt.call(getAddr(nodeid, key), "lua", "setnx", key, value)
end

--[[
删除指定的key
key 可以是单个也可以是一个table 返回被删除的个数
]]
function redisLib.delete(nodeid, key)
    return clusterExt.call(getAddr(nodeid, key), "lua", "delete", key)
end

function redisLib.send_delete(nodeid, key)
    clusterExt.send(getAddr(nodeid, key), "lua", "delete", key)
end

function redisLib.decr(nodeid, key)
    return clusterExt.call(getAddr(nodeid, key), "lua", "decr", key)
end
--[[
名称为key的集合中查找是否有value元素，有ture 没有 false
]]
function redisLib.sismember(nodeid, key, value)
    return clusterExt.call(getAddr(nodeid, key), "lua", "sismember", key, value)
end

--[[
向名称为key的set中添加元素value,如果value存在，不写入，return false
]]
function redisLib.sAdd(nodeid, key, value)
    return clusterExt.call(getAddr(nodeid, key), "lua", "sAdd", key, value)
end

--[[
删除名称为key的set中的元素value
]]
function redisLib.sRem(nodeid, key, value)
    return clusterExt.call(getAddr(nodeid, key), "lua", "sRem", key, value)
end

--[[
删除名称为key的set中的元素value
]]
function redisLib.sMove(nodeid, seckey, dstkey, value)
    return clusterExt.call(getAddr(nodeid, seckey), "lua", "sMove", seckey, dstkey, value)
end

--[[
返回名称为key的set的所有元素
]]
function redisLib.sMembers(nodeid, key)
    return clusterExt.call(getAddr(nodeid, key), "lua", "sMembers", key)
end

-->>>>>>>>>>>>>>>>>>>>list相关操作>>>>>>>>>>>>>>>>>>>>

--[[
在名称为key的list左边（头）添加一个值为value的 元素
]]
function redisLib.lPush(nodeid, key, value)
    return clusterExt.call(getAddr(nodeid, key), "lua", "lPush", key, value)
end

function redisLib.send_lPush(nodeid, key, value)
    clusterExt.send(getAddr(nodeid, key), "lua", "lPush", key, value)
end

--[[
在名称为key的list右边（尾）添加一个值为value的 元素
]]
function redisLib.rPush(nodeid, key, value)
    return clusterExt.call(getAddr(nodeid, key), "lua", "rPush", key, value)
end

--[[
在名称为key的list左边（头）添加一个值为value的 元素
]]
function redisLib.lPushx(nodeid, key, value)
    return clusterExt.call(getAddr(nodeid, key), "lua", "lPushx", key, value)
end

--[[
在名称为key的list右边（尾）添加一个值为value的 元素
]]
function redisLib.rPushx(nodeid, key, value)
    return clusterExt.call(getAddr(nodeid, key), "lua", "rPushx", key, value)
end

--[[
输出名称为key的list左(头)起/右（尾）起的第一个元素，删除该元素
]]
function redisLib.lPop(nodeid, key)
    return clusterExt.call(getAddr(nodeid, key), "lua", "lPop", key)
end

--[[
输出名称为key的list左(头)起/右（尾）起的第一个元素，删除该元素
]]
function redisLib.rPop(nodeid, key)
    return clusterExt.call(getAddr(nodeid, key), "lua", "rPop", key)
end

function redisLib.send_rPop(nodeid, key)
    clusterExt.send(getAddr(nodeid, key), "lua", "rPop", key)
end
-- --[[
-- 返回名称为key的list有多少个元素
-- ]]
-- function redisLib.lSize(key)
--     assertParameters(self.db,key)
--     return self.db:lsize(key)
-- end

--[[
返回名称为key的list中index位置的元素
]]
function redisLib.lIndex(nodeid, key, index)
    return clusterExt.call(getAddr(nodeid, key), "lua", "lIndex", key, index)
end

--[[
返回名称为key的list中index位置的元素
]]
function redisLib.lSet(nodeid, key, index, value)
    return clusterExt.call(getAddr(nodeid, key), "lua", "lSet", key, index, value)
end

--[[
返回名称为key的list中start至end之间的元素（end为 -1 ，返回所有）
]]
function redisLib.lRange(nodeid, key, startIndex, endIndex)
    return clusterExt.call(getAddr(nodeid, key), "lua", "lRange", key, startIndex, endIndex)
end

--[[
返回key所对应的list元素个数
]]
function redisLib.lLen(nodeid, key)
    return clusterExt.call(getAddr(nodeid, key), "lua", "lLen", key)
end

--[[
截取名称为key的list，保留start至end之间的元素
]]
function redisLib.lTrim(nodeid, key, startIndex, endIndex)
    return clusterExt.call(getAddr(nodeid, key), "lua", "lTrim", key, startIndex, endIndex)
end

--[[
删除count个名称为key的list中值为value的元素。count为0，删除所有值为value的元素，count>0从头至尾删除count个值为value的元素，count<0从尾到头删除|count|个值为value的元素
]]
function redisLib.lRem(nodeid, key, value, count)
    return clusterExt.call(getAddr(nodeid, key), "lua", "lRem", key, value, count)
end

--[[
在名称为为key的list中，找到值为pivot 的value，并根据参数Redis::BEFORE | Redis::AFTER，来确定，newvalue 是放在 pivot 的前面，或者后面。如果key不存在，不会插入，如果 pivot不存在，return -1

]]
function redisLib.lInsert(nodeid, key, insertMode, value, newValue)
    return clusterExt.call(getAddr(nodeid, key), "lua", "lInsert", key, insertMode, value, newValue)
end

-->>>>>>>>>>>>>>hash操作>>>>>>>>>>>>>>>>

--[[
向名称为h的hash中添加元素key—>value
]]
function redisLib.hSet(nodeid, h, key, value)
    return clusterExt.call(getAddr(nodeid, h), "lua", "hSet", h, key, value)
end

function redisLib.hSetNX(nodeid, h, key, value)
    return clusterExt.call(getAddr(nodeid, h), "lua", "hSetNX", h, key, value)
end

function redisLib.send_hSet(nodeid, h, key, value)
    clusterExt.send(getAddr(nodeid, h), "lua", "hSet", h, key, value)
end

function redisLib.send_hMset(nodeid, h, values)
    clusterExt.send(getAddr(nodeid, h), "lua", "hMset", h, values)
end

function redisLib.send_hMdel(nodeid, h, ids)
    clusterExt.send(getAddr(nodeid, h), "lua", "hMdel", h, ids)
end
--[[
返回名称为h的hash中key对应的value
]]
function redisLib.hGet(nodeid, h, key)
    return clusterExt.call(getAddr(nodeid, h), "lua", "hGet", h, key)
end
--[[
返回名称为h的hash中元素个数
]]
function redisLib.hLen(nodeid, h)
    return clusterExt.call(getAddr(nodeid, h), "lua", "hLen", h)
end
--[[
删除名称为h的hash中键为key的域
]]
function redisLib.hDel(nodeid, h, key)
    return clusterExt.call(getAddr(nodeid, h), "lua", "hDel", h, key)
end

function redisLib.send_hDel(nodeid, h, key)
    clusterExt.send(getAddr(nodeid, h), "lua", "hDel", h, key)
end

--[[
  返回名称为key的hash中所有键
]]
function redisLib.hKeys(nodeid, h)
    return clusterExt.call(getAddr(nodeid, h), "lua", "hKeys", h)
end
--[[
返回名称为h的hash中所有键对应的value
]]
function redisLib.hVals(nodeid, h)
    return clusterExt.call(getAddr(nodeid, h), "lua", "hVals", h)
end

--[[
返回名称为h的hash中所有的键（key）及其对应的value
]]
function redisLib.hGetAll(nodeid, h)
    return clusterExt.call(getAddr(nodeid, h), "lua", "hGetAll", h)
end

--[[
名称为h的hash中是否存在键名字为key的域
]]
function redisLib.hExists(nodeid, h, key)
    return clusterExt.call(getAddr(nodeid, h), "lua", "hExists", h, key)
end

--[[
将名称为h的hash中key的value增加number
]]
function redisLib.hIncrBy(nodeid, h, key, number)
    return clusterExt.call(getAddr(nodeid, h), "lua", "hIncrBy", h, key, number)
end
--[[
向名称为key的hash中批量添加元素
]]
function redisLib.hMset(nodeid, h, table)
    return clusterExt.call(getAddr(nodeid, h), "lua", "hMset", h, table)
end
--[[
返回名称为h的hash中keytable中key对应的value
]]
function redisLib.hMGet(nodeid, h, keyTable)
    return clusterExt.call(getAddr(nodeid, h), "lua", "hMGet", h, keyTable)
end

--[[
给key重命名
]]
function redisLib.rename(nodeid, key, newKey)
    return clusterExt.call(getAddr(nodeid, key), "lua", "rename", key, newKey)
end

--[[
设定一个key的活动时间（s）
]]
function redisLib.setTimeout(nodeid, key, time)
    return clusterExt.call(getAddr(nodeid, key), "lua", "setTimeout", key, time)
end
--[[
    EXPlRE <key> <ttl> 命令用于将键key 的生存时间设置为ttl 秒
]]
function redisLib.expire(nodeid, key, seconds)
    return clusterExt.call(getAddr(nodeid, key), "lua", "expire", key, seconds)
end
function redisLib.send_expire(nodeid, key, seconds)
    clusterExt.send(getAddr(nodeid, key), "lua", "expire", key, seconds)
end
--[[
key存活到一个unix时间戳时间
]]
function redisLib.expireAt(nodeid, key, time)
    return clusterExt.call(getAddr(nodeid, key), "lua", "expireAt", key, time)
end

--[[
返回满足给定pattern的所有key
]]
function redisLib.keys(nodeid, key)
    return clusterExt.call(getAddr(nodeid, key), "lua", "keys", key)
end

function redisLib.dbSize(nodeid)
    return clusterExt.call(getAddr(nodeid, 1), "lua", "dbSize")
end

--[[
根据条件获取结果集
]]
function redisLib.queryResult(nodeid, conditions, key)
    return clusterExt.call(getAddr(nodeid, key), "lua", "queryResult", conditions, key)
end

--[[
把数据放在redisf
]]
function redisLib.setResult(nodeid, key, result)
    return clusterExt.call(getAddr(nodeid, key), "lua", "setResult", key, result)
end

function redisLib.encryptKey(nodeid, conditions)
    return clusterExt.call(getAddr(nodeid, conditions), "lua", "encryptKey", conditions)
end

--zset begin
--添加一个成员到有序集合,或者如果它已经存在更新其分数
function redisLib.zAdd(nodeid, key, score, member, ...)
    return clusterExt.call(getAddr(nodeid, key), "lua", "zAdd", key, score, member, ...)
end

function redisLib.send_zAdd(nodeid, key, score, member, ...)
    clusterExt.send(getAddr(nodeid, key), "lua", "zAdd", key, score, member, ...)
end
--[[
    values = { score1,member1, score2,member2, ... }
]]
function redisLib.zMAdd(nodeid, key, values)
    return clusterExt.call(getAddr(nodeid, key), "lua", "zMAdd", key, values)
end
function redisLib.send_zMAdd(nodeid, key, values)
    clusterExt.send(getAddr(nodeid, key), "lua", "zMAdd", key, values)
end

--得到的有序集合成员的数量
function redisLib.zCard(nodeid, key)
    return clusterExt.call(getAddr(nodeid, key), "lua", "zCard", key)
end

--计算一个有序集合成员与给定值范围内的分数
function redisLib.zCount(nodeid, key, min, max)
    return clusterExt.call(getAddr(nodeid, key), "lua", "zCount", key, min, max)
end

--获取给定成员相关联的分数在一个有序集合
function redisLib.zScore(nodeid, key, member)
    return clusterExt.call(getAddr(nodeid, key), "lua", "zScore", key, member)
end

--确定一个有序集合成员的索引，以分数排序，从高分到低分
function redisLib.zRevRank(nodeid, key, member)
    return clusterExt.call(getAddr(nodeid, key), "lua", "zRevRank", key, member)
end

--确定成员的索引中有序集合
function redisLib.zRank(nodeid, key, member)
    return clusterExt.call(getAddr(nodeid, key), "lua", "zRank", key, member)
end

--从有序集合中删除一个
function redisLib.zRem(nodeid, key, member)
    return clusterExt.call(getAddr(nodeid, key), "lua", "zRem", key, member)
end
function redisLib.send_zRem(nodeid, key, member)
    clusterExt.send(getAddr(nodeid, key), "lua", "zRem", key, member)
end

--删除所有成员在给定的字典范围之间的有序集合
function redisLib.zRemRangeByLex(nodeid, key, min, max)
    return clusterExt.call(getAddr(nodeid, key), "lua", "zRemRangeByLex", key, min, max)
end

--由索引返回一个成员范围的有序集合。
function redisLib.zRange(nodeid, key, start, stop, isWithscores)
    return clusterExt.call(getAddr(nodeid, key), "lua", "zRange", key, start, stop, isWithscores)
end

--返回一个成员范围的有序集合，通过索引，以分数排序，从高分到低分
function redisLib.zRevRange(nodeid, key, start, stop, isWithscores)
    return clusterExt.call(getAddr(nodeid, key), "lua", "zRevRange", key, start, stop, isWithscores)
end

--在给定的索引之内删除所有成员的有序集合
function redisLib.zRemRangeByRank(nodeid, key, start, stop)
    return clusterExt.call(getAddr(nodeid, key), "lua", "zRemRangeByRank", key, start, stop)
end

--在给定的分数之内删除所有成员的有序集合
function redisLib.zRemRangeByScore(nodeid, key, start, stop)
    return clusterExt.call(getAddr(nodeid, key), "lua", "zRemRangeByScore", key, start, stop)
end

--按分数返回一个成员范围的有序集合。
function redisLib.zRangeByScore(nodeid, key, min, max, isWithscores)
    return clusterExt.call(getAddr(nodeid, key), "lua", "zRangeByScore", key, min, max, isWithscores)
end

--返回一个成员范围的有序集合，按分数，以分数排序从高分到低分
function redisLib.zRevRangeByScore(nodeid, key, max, min, isWithscores)
    return clusterExt.call(getAddr(nodeid, key), "lua", "zRevRangeByScore", key, max, min, isWithscores)
end

--计算一个给定的字典范围之间的有序集合成员的数量
function redisLib.zLexCount(nodeid, key, min, max)
    return clusterExt.call(getAddr(nodeid, key), "lua", "zLexCount", key, min, max)
end

--返回一个成员范围的有序集合（由字典范围）
function redisLib.zRangeByLex(nodeid, key, min, max)
    return clusterExt.call(getAddr(nodeid, key), "lua", "zRangeByLex", key, min, max)
end

--zset end

--关于事务的扩展 如果后期需要用到则继续封装

function redisLib.incr(nodeid, key)
    return clusterExt.call(getAddr(nodeid, key), "lua", "incr", key)
end

function redisLib.publish(nodeid, ch, msg)
    clusterExt.send(getAddr(nodeid, ch), "lua", "publish", ch, msg)
end

return redisLib
