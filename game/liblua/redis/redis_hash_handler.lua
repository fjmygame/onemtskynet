-- --------------------------------------
-- Create Date:2022-04-18 10:31:08
-- Author  : sgys
-- Version : 1.0
-- Filename: redis_hash_handler.lua
-- Introduce  : 类介绍
-- --------------------------------------

local json = require "json"
local dbDef = require "dbDef"

---@class redisHashHandle
local redisHashHandle = class("redisHashHandle")

local tinsert = table.insert
local tremove = table.remove
local tconcat = table.concat
local tunpack = table.unpack

local TableStorageMode = dbDef.TableStorageMode
local strformat = string.format

local function to_redis_value(v)
    if "table" == type(v) then
        return json.encode(v)
    else
        return v
    end
end

function redisHashHandle:ctor(_nodeid, _cache, _persistence, _redisPersistence, _pri_key, _setting)
    self.cacheKey = strformat(_setting.table_fmt, tostring(_pri_key))
    self.redis_key = self.cacheKey
    -- self.redis_key = strformat("%s:%s", gGameName, self.cacheKey)
    self.setting = _setting
    self.cache = _cache
    self.nodeid = _nodeid
    self.pri_key = _pri_key
    self.persistence = _persistence
    self.redisPersistence = _redisPersistence
end

function redisHashHandle:getCacheKey()
    return self.cacheKey
end

function redisHashHandle:query(count, db, key, ...)
    if key == nil then
        return db
    else
        return self:query(count + 1, db[tostring(key)], ...)
    end
end

function redisHashHandle:update(db, value, key, ...)
    key = tostring(key)
    if select("#", ...) == 0 then
        db[key] = value
    else
        if db[key] == nil then
            db[key] = {}
        end
        self:update(db[key], value, ...)
    end
end

function redisHashHandle:cache_get(...)
    local value = self.cache:Get(self.cacheKey)
    if value ~= nil then
        local count = 0
        return self:query(count, value, ...)
    end
end

function redisHashHandle:cache_build(condition, value)
    local v = {}
    self:update(v, value, tunpack(condition))
    self.cache:Set(self.cacheKey, v)
end

-- 设置cache值
function redisHashHandle:cache_set(redis_value)
    local value = {}
    for i = 1, #redis_value, 2 do
        local condition = string.split(redis_value[i], "@")
        local v = json.decode(redis_value[i + 1]) or redis_value[i + 1]

        self:update(value, v, tunpack(condition))
    end
    self.cache:Set(self.cacheKey, value)
end

function redisHashHandle:cache_update(condition, value)
    --更新子key需要完整的表
    if self.cache:Check(self.cacheKey) then
        local cache_value = self.cache:Get(self.cacheKey)
        self:update(cache_value, value, tunpack(condition))
    end
end

function redisHashHandle:delete(db, key, ...)
    key = tostring(key)
    if select("#", ...) == 0 then
        db[key] = nil
    else
        if db[key] then
            return self:delete(db[key], ...)
        end
    end
end

function redisHashHandle:cache_delete(condition)
    if condition then
        if self.cache:Check(self.cacheKey) then
            local cache_value = self.cache:Get(self.cacheKey)
            self:delete(cache_value, tunpack(condition))
        end
    else
        self.cache:Remove(self.cacheKey)
    end
end

function redisHashHandle:redis_get()
    local ok, redis_value = self.redisPersistence.getAll(self.redis_key)
    if ok and redis_value then
        -- self.cache:Set(self.cacheKey, redis_value)
        self:cache_set(redis_value)
    end
    return ok, redis_value
end

function redisHashHandle:build_redis_field(field_arrary)
    return tconcat(field_arrary, "@")
end

--设置一个key的值（hash完整表）
function redisHashHandle:redis_set(persistent_value)
    local setting = self.setting
    local key_column_name = setting.keyColumnName
    local key_column_num = #key_column_name
    local redis_value = {} -- { k1, v1, k2, v2, ..., kn, vn}
    local kv = {}
    for i = 1, #persistent_value do
        local v = persistent_value[i]
        local field_arrary = {}
        for c_i = 2, key_column_num do
            local column_name = key_column_name[c_i]
            field_arrary[#field_arrary + 1] = v[column_name]
        end

        local mode = setting.mode
        local v_str
        if mode == TableStorageMode.pack then
            v_str = to_redis_value(v[setting.column])
        elseif mode == TableStorageMode.normal then
            --根据每个字段的类型还原
            local temp = {} --
            for _, column in ipairs(setting.column) do
                temp[column] = json.decode(v[column]) or v[column]
            end
            v_str = to_redis_value(temp)
            if not v_str then
                log.Warn("playerdatacenter", "cachedata encode err", self.redis_key)
                return
            end
        end

        local field = self:build_redis_field(field_arrary)
        redis_value[2 * i - 1] = field
        redis_value[2 * i] = v_str
        kv[field] = v_str
    end

    self.redisPersistence.pushHash(self.redis_key, kv)
    self:cache_set(redis_value)
    return true, redis_value
end

--更新hash field
function redisHashHandle:redis_update(field_arrary, value)
    local field = self:build_redis_field(field_arrary)
    self.redisPersistence.pushHash(self.redis_key, {[field] = value})
    return true
end

function redisHashHandle:redis_delete(field_arrary)
    if field_arrary then
        --移除hash field
        local field = self:build_redis_field(field_arrary)
        self.redisPersistence.deleteHash(self.redis_key, field)
        return true
    else
        self.redisPersistence.deleteHash(self.redis_key)
    end
end

--------------------MYSQL--------------------
function redisHashHandle:persistence_query()
    return self.persistence.query(self.setting, self.pri_key)
end

function redisHashHandle:persistence_insert(condition, data)
    tinsert(condition, 1, self.pri_key)
    self.persistence.add_queue_union(self.setting, data, condition, true)
end

function redisHashHandle:persistence_update(condition, data)
    tinsert(condition, 1, self.pri_key)
    self.persistence.add_queue_union(self.setting, data, condition)
end

function redisHashHandle:persistence_delete(condition)
    if condition then
        tinsert(condition, 1, self.pri_key)
        self.persistence.delete_union(self.setting, condition)
    else
        self.persistence.delete(self.setting, self.pri_key)
    end
end

function redisHashHandle:check_update(...)
    if select("#", ...) ~= #self.setting.keyColumnName then --参数数量=字段数+1, keyColumnName数量为字段数+1
        log.Error(
            "playerdatacenter",
            "redis hash update field num error",
            self.redis_key,
            dumpTable({...}, "param", 10),
            dumpTable(self.setting.keyColumnName, "keyColumnName", 10)
        )
        return false
    end
    local args = {...}
    local data = tremove(args)
    return true, args, data
end

function redisHashHandle:check_delete(...)
    local args_num = select("#", ...)
    if args_num == 0 then
        log.Warn("playerdatacenter", "redis hash delete key", self.redis_key)
        return true
    elseif args_num ~= #self.setting.keyColumnName - 1 then
        log.Warn("playerdatacenter", "redis hash delete field num error", self.redis_key)
        return false
    end

    return true, {...}
end

return redisHashHandle
