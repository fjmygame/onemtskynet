-- --------------------------------------
-- Create Date:2022-04-18 10:32:30
-- Author  : sgys
-- Version : 1.0
-- Filename: redis_string_handler.lua
-- Introduce  : 类介绍
-- --------------------------------------

local json = require "json"
local dbDef = require "dbDef"

---@class redisStringHandle
local redisStringHandle = class("redisStringHandle")

local strformat = string.format
local TableStorageMode = dbDef.TableStorageMode

function redisStringHandle:ctor(_nodeid, _cache, _persistence, _redisPersistence, _pri_key, _setting)
    self.cacheKey = strformat(_setting.table_fmt, tostring(_pri_key))
    self.redisKey = self.cacheKey
    -- self.cacheKey = strformat("%s:%s", _setting.table, tostring(_pri_key))
    -- self.redisKey = strformat("%s:%s", gGameName, self.cacheKey)
    self.setting = _setting
    self.cache = _cache
    self.nodeid = _nodeid
    self.pri_key = _pri_key
    self.persistence = _persistence
    self.redisPersistence = _redisPersistence
end

function redisStringHandle:getCacheKey()
    return self.cacheKey
end

function redisStringHandle:query(db, key, ...)
    if key == nil then
        return db
    else
        return self:query(db[key], ...)
    end
end

function redisStringHandle:cache_get(...)
    local value = self.cache:Get(self.cacheKey)
    if value ~= nil then
        return self:query(value, ...)
    end
end

function redisStringHandle:cache_build(_, value)
    self.cache:Set(self.cacheKey, value)
end

function redisStringHandle:cache_set(redis_value)
    local value = json.decode(redis_value) or redis_value
    if not redis_value then
        log.Warn("playerdatacenter", "cachedata cache_set encode err", self.nodeid, self.cacheKey)
        return
    end
    self.cache:Set(self.cacheKey, value)
end

function redisStringHandle:cache_update(_, value)
    self.cache:Set(self.cacheKey, value)
end

function redisStringHandle:cache_delete()
    self.cache:Remove(self.cacheKey)
end
--------------------REDIS--------------------
function redisStringHandle:redis_get()
    local ok, redis_value = self.redisPersistence.get(self.redisKey)
    if ok then
        self.cache:Set(self.cacheKey, redis_value)
    end
    if type(redis_value) == "string" then
        log.Error("sys", "redisStringHandle.redis_get", self.redisKey)
    end
    return ok, redis_value
end

function redisStringHandle:redis_set(persistent_value)
    local value = persistent_value[1]
    if value then
        local redis_value
        local mode = self.setting.mode
        if mode == TableStorageMode.pack then
            redis_value = json.decode(value[self.setting.column]) -- to_redis_value(value[self.setting.column])
        elseif mode == TableStorageMode.normal then
            --根据每个字段的类型还原
            local temp = {} --
            for _, column in ipairs(self.setting.column) do
                temp[column] = json.decode(value[column]) or value[column]
            end
            redis_value = temp -- to_redis_value(temp)
            if not redis_value then
                log.Warn("playerdatacenter", "cachedata encode err", self.redisKey)
                return
            end
        end

        self.redisPersistence.pushString(self.redisKey, redis_value)
        self.cache:Set(self.cacheKey, redis_value)
        return true, redis_value
    end
end

function redisStringHandle:redis_update(_, value)
    self.redisPersistence.pushString(self.redisKey, value)
end

function redisStringHandle:redis_delete()
    self.redisPersistence.deleteKey(self.redisKey)
end
--------------------MYSQL--------------------

function redisStringHandle:persistence_query()
    return self.persistence.query(self.setting, self.pri_key)
end

function redisStringHandle:persistence_insert(_, data)
    self.persistence.add_queue(self.setting, data, self.pri_key, true)
end

function redisStringHandle:persistence_update(_, data)
    self.persistence.add_queue(self.setting, data, self.pri_key)
end

function redisStringHandle:persistence_delete()
    self.persistence.delete(self.setting, self.pri_key)
end

function redisStringHandle:check_update(...)
    if select("#", ...) == 0 then
        log.Error("playerdatacenter", "check_update string redis #args = 0", self.redisKey)
        return false
    end
    local data = ...
    return true, nil, data
end

function redisStringHandle:check_delete(...)
    return true
end

return redisStringHandle
