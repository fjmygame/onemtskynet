--------------------------------------------------------------------------------
-- 文件: crossNotify.lua
-- 作者: zkb
-- 时间: 2020-09-27 21:32:02
-- 描述: 跨服通知
--      使用redis的pub/sub通知
--------------------------------------------------------------------------------
local skynet = require("skynet")
local json = require("json")
local notify = require("notify.notify")
local redis = require "redis"
local customRedisLib = require("customRedisLib")
local confAPI = require("confAPI")
local rtype = gCustomRedisType.share -- redis类型

---@class crossNotify
local _M = BuildOther("crossNotify")

local watchlist = CreateBlankTable(_M, "_watchlist")

-- 时间推送
-- name: 事件名字
-- data: 数据
function _M.publish(name, data)
    if not data then
        log.Error("sys", "crossNotify not data->", name)
        return
    end
    if "table" == type(data) then
        data = json.encode(data)
        if not data then
            log.Error("sys", "crossNotify json encode err->", name)
            return
        end
    end
    customRedisLib.publish(rtype, name, data)
end

-- 注册事件
function _M.subscribe(name, handle)
    _M.watch(name)
    return notify.subscribe(name, handle)
end

-- 取消注册[只取消本地监听，redis不做取消操作]
function _M.unsubscribe(name, index)
    notify.unsubscribe(name, index)
end

-- 从redis读取MQ消息
function _M.readRedisMQ(shareRedis, name, wObj)
    if not wObj then
        local bok, w = xpcall(redis.watch, debug.traceback, shareRedis)
        if bok then
            w:subscribe(name)
            wObj = w
            log.Debug("sys", "shareRedis subscribe key success!", name)
        end
    end
    if wObj then
        local bok, jsdata = xpcall(wObj.message, debug.traceback, wObj)
        if bok then
            local data = json.decode(jsdata)
            if not data then
                log.Error("sys", "watching event not data->", jsdata)
            else
                log.Debug("gg", "watch ->", name, jsdata)
                notify.publish(name, data)
            end
        elseif jsdata then
            log.Error("sys", string.safeFormat("redis watch:%s is disconnect", name), jsdata)
            wObj = nil
        end
    end
    --  是否中断协程
    local isBreak = false
    return wObj, isBreak
end

-- 订阅
local function watching(name)
    local shareRedis = confAPI.getRedisConfByKey(gRedisType.share)
    -- print("shareRedis:", dumpTable(shareRedis))
    local wObj
    local isBreak = false
    while not isBreak do
        wObj, isBreak = _M.readRedisMQ(shareRedis, name, wObj)
        if not wObj then
            skynet.sleep(100)
        end
    end
end

function _M.watch(name)
    if watchlist[name] then
        return -- 已经监听了
    end
    watchlist[name] = true
    skynet.fork(watching, name)
end

return _M
