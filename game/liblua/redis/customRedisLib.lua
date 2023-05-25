local clusterExt = require "clusterExt"
local customRedisConf = require "customRedisConf"

---@class customRedisLib
local customRedisLib = BuildOther("customRedisLib")

local function getCustomRedisAddress(customRedisType)
    return customRedisConf.getCustomRedisAddress(customRedisType)
end

--[[
根据key是否存在value
]]
function customRedisLib.exists(customRedisType, key)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "exists", key)
end

--[[
 设置key=》value
]]
function customRedisLib.set(customRedisType, key, value)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "set", key, value)
end

function customRedisLib.send_set(customRedisType, key, value)
    clusterExt.send(getCustomRedisAddress(customRedisType), "lua", "set", key, value)
end
--[[
根据key获得value
]]
function customRedisLib.get(customRedisType, key)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "get", key)
end

--[[
setex 带生存时间的写入值
]]
function customRedisLib.setex(customRedisType, key, time, value)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "setex", key, time, value)
end

function customRedisLib.send_setex(customRedisType, key, seconds, value)
    clusterExt.send(getCustomRedisAddress(customRedisType), "lua", "setex", key, seconds, value)
end

--[[
    判断是否重复的，写入值 如果已经写入则不修改
]]
function customRedisLib.setnx(customRedisType, key, value)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "setnx", key, value)
end

--[[
删除指定的key
key 可以是单个也可以是一个table 返回被删除的个数
]]
function customRedisLib.delete(customRedisType, key)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "delete", key)
end
function customRedisLib.send_delete(customRedisType, key)
    clusterExt.send(getCustomRedisAddress(customRedisType), "lua", "delete", key)
end
--[[
    Redis Decr 命令将 key 中储存的数字值减一。

    如果 key 不存在，那么 key 的值会先被初始化为 0 ，然后再执行 DECR 操作。

    如果值包含错误的类型，或字符串类型的值不能表示为数字，那么返回一个错误。

    本操作的值限制在 64 位(bit)有符号数字表示之内。
--]]
function customRedisLib.decr(customRedisType, key)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "decr", key)
end

--[[
名称为key的集合中查找是否有value元素，有ture 没有 false
]]
function customRedisLib.sismember(customRedisType, key, value)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "sismember", key, value)
end

--[[
向名称为key的set中添加元素value,如果value存在，不写入，return false
]]
function customRedisLib.sAdd(customRedisType, key, value)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "sAdd", key, value)
end

--[[
删除名称为key的set中的元素value
]]
function customRedisLib.sRem(customRedisType, key, value)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "sRem", key, value)
end

--[[
删除名称为key的set中的元素value
]]
function customRedisLib.sMove(customRedisType, seckey, dstkey, value)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "sMove", seckey, dstkey, value)
end

--[[
返回名称为key的set的所有元素
]]
function customRedisLib.sMembers(customRedisType, key)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "sMembers", key)
end

-->>>>>>>>>>>>>>>>>>>>list相关操作>>>>>>>>>>>>>>>>>>>>

--[[
在名称为key的list左边（头）添加一个值为value的 元素
]]
function customRedisLib.lPush(customRedisType, key, value)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "lPush", key, value)
end
function customRedisLib.send_lPush(customRedisType, key, value)
    clusterExt.send(getCustomRedisAddress(customRedisType), "lua", "lPush", key, value)
end
--[[
在名称为key的list右边（尾）添加一个值为value的 元素
]]
function customRedisLib.rPush(customRedisType, key, value)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "rPush", key, value)
end

--[[
在名称为key的list左边（头）添加一个值为value的 元素
]]
function customRedisLib.lPushx(customRedisType, key, value)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "lPushx", key, value)
end

--[[
在名称为key的list右边（尾）添加一个值为value的 元素
]]
function customRedisLib.rPushx(customRedisType, key, value)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "rPushx", key, value)
end

--[[
输出名称为key的list左(头)起/右（尾）起的第一个元素，删除该元素
]]
function customRedisLib.lPop(customRedisType, key)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "lPop", key)
end

--[[
输出名称为key的list左(头)起/右（尾）起的第一个元素，删除该元素
]]
function customRedisLib.rPop(customRedisType, key)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "rPop", key)
end
function customRedisLib.send_rPop(customRedisType, key)
    clusterExt.send(getCustomRedisAddress(customRedisType), "lua", "rPop", key)
end

-- --[[
-- 返回名称为key的list有多少个元素
-- ]]
-- function customRedisLib.lSize(key)
--     assertParameters(self.db,key)
--     return self.db:lsize(key)
-- end

--[[
返回名称为key的list中index位置的元素
]]
function customRedisLib.lIndex(customRedisType, key, index)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "lIndex", key, index)
end

--[[
返回名称为key的list中index位置的元素
]]
function customRedisLib.lSet(customRedisType, key, index, value)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "lSet", key, index, value)
end

--[[
返回名称为key的list中start至end之间的元素（end为 -1 ，返回所有）
]]
function customRedisLib.lRange(customRedisType, key, startIndex, endIndex)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "lRange", key, startIndex, endIndex)
end

--[[
返回key所对应的list元素个数
]]
function customRedisLib.lLen(customRedisType, key)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "lLen", key)
end

--[[
截取名称为key的list，保留start至end之间的元素
]]
function customRedisLib.lTrim(customRedisType, key, startIndex, endIndex)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "lTrim", key, startIndex, endIndex)
end

--[[
删除count个名称为key的list中值为value的元素。count为0，删除所有值为value的元素，count>0从头至尾删除count个值为value的元素，count<0从尾到头删除|count|个值为value的元素
]]
function customRedisLib.lRem(customRedisType, key, value, count)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "lRem", key, value, count)
end

--[[
在名称为为key的list中，找到值为pivot 的value，并根据参数Redis::BEFORE | Redis::AFTER，来确定，newvalue 是放在 pivot 的前面，或者后面。如果key不存在，不会插入，如果 pivot不存在，return -1

]]
function customRedisLib.lInsert(customRedisType, key, insertMode, value, newValue)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "lInsert", key, insertMode, value, newValue)
end

-->>>>>>>>>>>>>>hash操作>>>>>>>>>>>>>>>>

--[[
向名称为h的hash中添加元素key—>value
]]
function customRedisLib.hSet(customRedisType, h, key, value)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "hSet", h, key, value)
end

function customRedisLib.hSetNX(customRedisType, h, key, value)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "hSetNX", h, key, value)
end

function customRedisLib.send_hSet(customRedisType, h, key, value)
    clusterExt.send(getCustomRedisAddress(customRedisType), "lua", "hSet", h, key, value)
end
--[[
返回名称为h的hash中key对应的value
]]
function customRedisLib.hGet(customRedisType, h, key)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "hGet", h, key)
end
--[[
返回名称为h的hash中元素个数
]]
function customRedisLib.hLen(customRedisType, h)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "hLen", h)
end
--[[
删除名称为h的hash中键为key的域
]]
function customRedisLib.hDel(customRedisType, h, key)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "hDel", h, key)
end
function customRedisLib.send_hDel(customRedisType, h, key)
    clusterExt.send(getCustomRedisAddress(customRedisType), "lua", "hDel", h, key)
end

function customRedisLib.send_hMset(customRedisType, h, values)
    clusterExt.send(getCustomRedisAddress(customRedisType), "lua", "hMset", h, values)
end

-- 删除哈希表 key 中的一个或多个指定域，不存在的域将被忽略
function customRedisLib.send_hMdel(customRedisType, h, keys)
    clusterExt.send(getCustomRedisAddress(customRedisType), "lua", "hMdel", h, keys)
end

--[[
  返回名称为key的hash中所有键
]]
function customRedisLib.hKeys(customRedisType, h)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "hKeys", h)
end
--[[
返回名称为h的hash中所有键对应的value
]]
function customRedisLib.hVals(customRedisType, h)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "hVals", h)
end

--[[
返回名称为h的hash中所有的键（key）及其对应的value
]]
function customRedisLib.hGetAll(customRedisType, h)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "hGetAll", h)
end

--[[
名称为h的hash中是否存在键名字为key的域
]]
function customRedisLib.hExists(customRedisType, h, key)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "hExists", h, key)
end

--[[
将名称为h的hash中key的value增加number
]]
function customRedisLib.hIncrBy(customRedisType, h, key, number)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "hIncrBy", h, key, number)
end
--[[
向名称为key的hash中批量添加元素
]]
function customRedisLib.hMset(customRedisType, h, table)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "hMset", h, table)
end
--[[
返回名称为h的hash中keytable中key对应的value
]]
function customRedisLib.hMGet(customRedisType, h, keyTable)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "hMGet", h, keyTable)
end

--[[
给key重命名
]]
function customRedisLib.rename(customRedisType, key, newKey)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "rename", key, newKey)
end

--[[
设定一个key的活动时间（s）
]]
function customRedisLib.setTimeout(customRedisType, key, time)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "setTimeout", key, time)
end

--[[
key存活到一个unix时间戳时间
]]
function customRedisLib.expireAt(customRedisType, key, time)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "expireAt", key, time)
end

function customRedisLib.expire(customRedisType, key, seconds)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "expire", key, seconds)
end

function customRedisLib.send_expire(customRedisType, key, seconds)
    clusterExt.send(getCustomRedisAddress(customRedisType), "lua", "expire", key, seconds)
end

--[[
返回满足给定pattern的所有key
]]
function customRedisLib.keys(customRedisType, key)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "keys", key)
end

function customRedisLib.dbSize(customRedisType)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "dbSize")
end

--[[
根据条件获取结果集
]]
function customRedisLib.queryResult(customRedisType, conditions, key)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "queryResult", conditions, key)
end

--[[
把数据放在redis
]]
function customRedisLib.setResult(customRedisType, key, result)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "setResult", key, result)
end

--[[
加密key
]]
function customRedisLib.encryptKey(customRedisType, conditions)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "encryptKey", conditions)
end

--关于事务的扩展 如果后期需要用到则继续封装
--zset begin
--添加一个成员到有序集合,或者如果它已经存在更新其分数
function customRedisLib.zAdd(customRedisType, key, score, member, ...)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "zAdd", key, score, member, ...)
end
function customRedisLib.send_zAdd(customRedisType, key, score, member, ...)
    clusterExt.send(getCustomRedisAddress(customRedisType), "lua", "zAdd", key, score, member, ...)
end
--[[
    values = { score1,member1, score2,member2, ... }
]]
function customRedisLib.zMAdd(customRedisType, key, values)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "zMAdd", key, values)
end
function customRedisLib.send_zMAdd(customRedisType, key, values)
    clusterExt.send(getCustomRedisAddress(customRedisType), "lua", "zMAdd", key, values)
end

--得到的有序集合成员的数量
function customRedisLib.zCard(customRedisType, key)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "zCard", key)
end

--计算一个有序集合成员与给定值范围内的分数
function customRedisLib.zCount(customRedisType, key, min, max)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "zCount", key, min, max)
end

--获取给定成员相关联的分数在一个有序集合
function customRedisLib.zScore(customRedisType, key, member)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "zScore", key, member)
end

--确定一个有序集合成员的索引，以分数排序，从高分到低分
function customRedisLib.zRevRank(customRedisType, key, member)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "zRevRank", key, member)
end

--确定成员的索引中有序集合
function customRedisLib.zRank(customRedisType, key, member)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "zRank", key, member)
end

--从有序集合中删除一个
function customRedisLib.zRem(customRedisType, key, member)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "zRem", key, member)
end
function customRedisLib.send_zRem(customRedisType, key, member)
    clusterExt.send(getCustomRedisAddress(customRedisType), "lua", "zRem", key, member)
end

--删除所有成员在给定的字典范围之间的有序集合
function customRedisLib.zRemRangeByLex(customRedisType, key, min, max)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "zRemRangeByLex", key, min, max)
end

--由索引返回一个成员范围的有序集合。
function customRedisLib.zRange(customRedisType, key, start, stop, isWithscores)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "zRange", key, start, stop, isWithscores)
end

--返回一个成员范围的有序集合，通过索引，以分数排序，从高分到低分
function customRedisLib.zRevRange(customRedisType, key, start, stop, isWithscores)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "zRevRange", key, start, stop, isWithscores)
end

--在给定的索引之内删除所有成员的有序集合
function customRedisLib.zRemRangeByRank(customRedisType, key, start, stop)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "zRemRangeByRank", key, start, stop)
end

--在给定的分数之内删除所有成员的有序集合
function customRedisLib.zRemRangeByScore(customRedisType, key, start, stop)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "zRemRangeByScore", key, start, stop)
end

--按分数返回一个成员范围的有序集合。
function customRedisLib.zRangeByScore(customRedisType, key, min, max, isWithscores)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "zRangeByScore", key, min, max, isWithscores)
end

--返回一个成员范围的有序集合，按分数，以分数排序从高分到低分
function customRedisLib.zRevRangeByScore(customRedisType, key, max, min, isWithscores)
    return clusterExt.call(
        getCustomRedisAddress(customRedisType),
        "lua",
        "zRevRangeByScore",
        key,
        max,
        min,
        isWithscores
    )
end

--计算一个给定的字典范围之间的有序集合成员的数量
function customRedisLib.zLexCount(customRedisType, key, min, max)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "zLexCount", key, min, max)
end

--返回一个成员范围的有序集合（由字典范围）
function customRedisLib.zRangeByLex(customRedisType, key, min, max)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "zRangeByLex", key, min, max)
end

--zset end

function customRedisLib.incr(customRedisType, key)
    return clusterExt.call(getCustomRedisAddress(customRedisType), "lua", "incr", key)
end

function customRedisLib.publish(customRedisType, ch, msg)
    clusterExt.send(getCustomRedisAddress(customRedisType), "lua", "publish", ch, msg)
end
return customRedisLib
