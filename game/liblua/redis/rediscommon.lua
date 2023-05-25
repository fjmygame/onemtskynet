-- --------------------------------------
-- Create Date:2020-04-09 14:18:05
-- Author  : Happy Su
-- Version : 1.0
-- Filename: rediscommon.lua
-- Introduce  :
-- --------------------------------------

---@class rediscommon
local rediscommon = BuildOther("rediscommon")

-- 默认60天过期
rediscommon.defaultExpireSec = 3600 * 24 * 60

local keyExpireSec = dbconf.redisExpireSec or rediscommon.defaultExpireSec
-- 处理key的过期时间更新
function rediscommon.processExpire(redisLib, nodeid, redisKey)
    if dbconf.setRedisExpire then
        local ok, err = xpcall(redisLib.send_expire, debug.traceback, nodeid, redisKey, keyExpireSec)

        if not ok then
            log.Error("database", "processExpire err:", err, redisKey)
        end
    end
end

-- 处理key的过期时间更新
function rediscommon.processCustomExpire(customRedisLib, customRedisType, redisKey)
    if dbconf.setRedisExpire then
        local ok, err = xpcall(customRedisLib.send_expire, debug.traceback, customRedisType, redisKey, keyExpireSec)

        if not ok then
            log.Error("database", "processExpire err:", err, redisKey)
        end
    end
end

return rediscommon
