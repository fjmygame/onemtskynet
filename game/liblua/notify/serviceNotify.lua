--------------------------------------------------------------------------------
-- 文件: serviceNotify.lua
-- 作者: zkb
-- 时间: 2020-04-03 09:42:55
-- 描述: 跨服务事件通知和监听
--------------------------------------------------------------------------------
local notify = require("notify")
local skynet = require("skynet")
local clusterExt = require("clusterExt")
---@class serviceNotify
local serviceNotify = BuildOther("serviceNotify")

local _addr
local function getAddr()
    if not _addr then
        _addr = skynet.uniqueservice("multiNotifyService")
    end
    return _addr
end

-- 注册监听
-- eventName: 事件名
-- handle: 事件回调
-- 返回index: 本地监听的index
function serviceNotify.subscribe(eventName, handle)
    assert(gAddrSvr, "serviceNotify.subscribe err, " .. tostring(eventName))
    clusterExt.send(getAddr(), "lua", "subscribe", eventName, gAddrSvr)
    return notify.subscribe(eventName, handle)
end

-- 注销监听,只针服务内派发注销
function serviceNotify.unsubscribe(eventName, index)
    notify.unsubscribe(eventName, index)
end

-- 跨服务通知
-- 1.发布本地 2.发布跨服务
function serviceNotify.publish(id, eventName, data)
    -- 本地
    notify.publish(eventName, data)
    -- 跨服务
    clusterExt.send(getAddr(), "lua", "publish", id, eventName, data, skynet.self())
end

-- 阻塞的通知方法（除非特殊业务需求 一般不用此方法）
function serviceNotify.publish_call(id, eventName, data)
    -- 本地
    notify.publish(eventName, data)
    -- 跨服务
    clusterExt.call(getAddr(), "lua", "publish_call", id, eventName, data, skynet.self())
end

-- 跨节点事件[global目前不可以用以下接口]
function serviceNotify.openClusterPub(eventName, groupId)
    clusterExt.send(getAddr(), "lua", "openClusterPub", eventName, groupId)
end

function serviceNotify.closeClusterPub(eventName, groupId)
    clusterExt.send(getAddr(), "lua", "closeClusterPub", eventName, groupId)
end

return serviceNotify
