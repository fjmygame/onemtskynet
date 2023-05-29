-- --------------------------------------
-- Create Date:2022-04-18 10:34:17
-- Author  : sgys
-- Version : 1.0
-- Filename: redisPersistence.lua
-- Introduce  : redis持久化
-- --------------------------------------

local json = require "json"
local redisLib = require("redisLib")
local rediscommon = require "rediscommon"
---@class redisPersistence
local redisPersistence = BuildOther("redisPersistence")

local processExpire = rediscommon.processExpire
local setRedisExpire = dbconf.setRedisExpire
local redisExpireSec = dbconf.redisExpireSec or rediscommon.defaultExpireSec

local queue = CreateBlankTable(redisPersistence, "queue", require("lqueue").new())
local mapValue = CreateBlankTable(redisPersistence, "mapValue") -- key, value

local TypeString = 1
local TypeHash = 2

local function process_xpcall(func, ...)
    local ok, err = xpcall(func, debug.traceback, ...)
    if not ok then
        log.Error("database", "database process_xpcall err:", err, ...)
    end
    return ok, err
end

local function json_encode(v)
    if "table" == type(v) then
        return json.encode(v)
    else
        return v
    end
end
------------------------------------------------------------------------------
-- string
function redisPersistence.pushString(key, value)
    local info = mapValue[key]
    if info then -- 存在刷新值
        info.value = value
        info.isAll = nil -- isAll表示整个key删除
        return
    end
    mapValue[key] = {rtype = TypeString, value = value, isAll = nil}
    queue:push(key)
end

function redisPersistence.deleteKey(key)
    local info = mapValue[key]
    if info then -- 存在刷新值
        info.value = nil
        info.isAll = true
        return
    end
    mapValue[key] = {rtype = TypeString, isAll = true}
    queue:push(key)
end

-- 对于字符串的处理
function redisPersistence.doString(key, info)
    if info.isAll then
        redisLib.send_delete(gNodeId, key)
    else
        redisPersistence.set(key, info.value)
    end
end

function redisPersistence.set(key, value)
    local result = json_encode(value)
    if not result then
        log.Dump("sys", value, "redisPersistence", 10)
        log.Error("sys", "redisPersistence.set error->", key)
        return
    end
    if setRedisExpire then
        return process_xpcall(redisLib.send_setex, gNodeId, key, redisExpireSec, result)
    else
        return process_xpcall(redisLib.send_set, gNodeId, key, result)
    end
end

function redisPersistence.get(key)
    local info = mapValue[key]
    if info then
        if info.isAll then
            return nil
        end
        return true, info.value
    end
    local ok, redis_value = process_xpcall(redisLib.get, gNodeId, key)
    local result
    if ok and redis_value then
        processExpire(redisLib, gNodeId, key)
        result = json.decode(redis_value)
    end
    return ok, result
end

function redisPersistence.getAll(key)
    -- TODOS:没有从缓存取，如果在取之前有更新，就会导致旧数据覆盖新数据！！！
    local ok, redis_value = process_xpcall(redisLib.hGetAll, gNodeId, key)
    if ok and redis_value then
        if not next(redis_value) then
            redis_value = nil
        else
            processExpire(redisLib, gNodeId, key)
        end
    end
    return ok, redis_value
end
------------------------------------------------------------------------------
-- hash
-- values={field, value}
function redisPersistence.pushHash(key, values)
    local info = mapValue[key] -- 是否已经存在
    if not info then
        mapValue[key] = {rtype = TypeHash, kv = values}
    else
        -- hash存在，整合key,value
        info.kv = info.kv or {}
        local kv = info.kv
        local delFields = info.delFields -- 删除的，再加回来，不用删了
        for field, v in pairs(values) do
            kv[field] = v
            if delFields then
                delFields[field] = nil
            end
        end
        return
    end
    queue:push(key)
end

-- field 一次一个
-- 如果内存删除了hash整个值，这里必然也是整值删除
-- 如果isAll=ture,并且kv有值，则为删除整个hash后新hash的值，这里是所有了
function redisPersistence.deleteHash(key, field)
    local isAll = not field and true or false
    local info = mapValue[key] -- 是否已经存在
    if not info then
        if isAll then
            mapValue[key] = {rtype = TypeHash, isAll = true}
        else
            mapValue[key] = {rtype = TypeHash, delFields = {[field] = true}}
        end
    else
        if isAll then -- 整个hash删除
            info.isAll = true
            info.kv = nil
            info.delFields = nil
        else
            if not info.isAll then
                -- hash存在，整合key,info[一般情况]
                if not info.delFields then
                    info.delFields = {[field] = true}
                else
                    info.delFields[field] = true
                end
            end

            local kv = info.kv -- 键值存在删除
            if kv then
                kv[field] = nil
            end
        end
        return
    end
    queue:push(key)
end

function redisPersistence.doHash(key, info)
    if info.isAll then -- 全部删除，如果还有kv则为后面加的
        redisLib.send_delete(gNodeId, key)
    else
        local delFields = info.delFields
        if delFields and next(delFields) then
            redisPersistence.hMdel(key, delFields)
        end
    end

    local kv = info.kv
    if kv and next(kv) then
        redisPersistence.hMset(key, kv)
    end
end

function redisPersistence.hMdel(key, fields)
    local dvalue = {}
    for k, _ in pairs(fields) do
        table.insert(dvalue, k)
    end
    local ok, err = process_xpcall(redisLib.send_hMdel, gNodeId, key, dvalue)
    return ok, err
end

function redisPersistence.hMset(key, value)
    local rvalue = {}
    for k, v in pairs(value) do
        local js = json_encode(v)
        if js then
            table.insert(rvalue, k)
            table.insert(rvalue, js)
        else
            log.Error("sys", "redis doHash json_encode error", key, dumpTable(v, "v", 10))
        end
    end
    local ok = process_xpcall(redisLib.send_hMset, gNodeId, key, rvalue)
    -- 更新过期时间
    if setRedisExpire then
        processExpire(redisLib, gNodeId, key)
    end
    return ok
end

-- hash不提供
-- function redisPersistence.hGetAll(key)
--     local ok, redis_value = process_xpcall(redisLib.hGetAll, gNodeId, key)
--     if ok and redis_value then
--         if not next(redis_value) then
--             redis_value = nil
--         else
--             processExpire(redisLib, gNodeId, key)
--         end
--         return redis_value
--     end
-- end
------------------------------------------------------------------------------------
-- run
function redisPersistence.run(count)
    if not count then -- 不传全部执行
        count = queue:size()
    end
    for i = 1, count do
        local key = queue:pop()
        if not key then
            return
        end
        local v = mapValue[key]
        mapValue[key] = nil
        local rtype = v.rtype
        if rtype == TypeString then
            redisPersistence.doString(key, v)
        elseif rtype == TypeHash then
            redisPersistence.doHash(key, v)
        end
    end
end

function redisPersistence.size()
    return queue:size()
end

return redisPersistence
