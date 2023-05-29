-- --------------------------------------
-- Create Date:2020-03-14 09:43:51
-- Author  : Happy Su
-- Version : 1.0
-- Filename: clusterExt.lua
-- Introduce  : 服务调用封装
-- --------------------------------------
local skynet = require "skynet"
local cluster
local clusterNodeName = skynet.getenv "cluster_nodename"
if clusterNodeName then
    cluster = require "cluster"
end

---@class clusterExt
local clusterExt = class("clusterExt")

--开启集群节点
function clusterExt.open(nodeName)
    clusterNodeName = nodeName
    skynet.setenv("cluster_nodename", clusterNodeName)
    if clusterNodeName then
        cluster = require "cluster"
    end
    log.InfoFormat("clusterext", "cluster %s open", clusterNodeName)
    cluster.open(clusterNodeName)
end

--获取节点名称
function clusterExt.self()
    return clusterNodeName or ""
end

--获取本节点id
function clusterExt.getNodeId()
    return skynet.getenv("node_id")
end

--打包远程节点地址
function clusterExt.pack_cluster_address(nodeName, serviceName)
    return {nodeName = nodeName, serviceName = serviceName}
end

--请求远程服务
function clusterExt.queryservice(nodeName, serviceName)
    if clusterNodeName and nodeName and clusterNodeName ~= nodeName then
        return clusterExt.pack_cluster_address(nodeName, serviceName)
    else
        return skynet.localname(serviceName)
    end
end

local function processCallResult_ok(command, ok, result, ...)
    if not ok then
        log.ErrorFormat(
            "clusterext",
            "clusterExt.call failed command %s error:%s",
            command,
            dumpTable(result, "result", 10)
        )
    else
        return result, ...
    end
end

--远程服务请求
function clusterExt.call(address, msgtype, command, ...)
    if not address then
        log.ErrorStack("clusterext", "err address is nil:", dumpTable({msgtype, command, ...}, "param", 10))
        return
    end

    if type(address) == "table" then
        return processCallResult_ok(
            command,
            xpcall(cluster.call, debug.traceback, address.nodeName, address.serviceName, ...)
        )
    else
        return processCallResult_ok(command, xpcall(skynet.call, debug.traceback, address, msgtype, ...))
    end
end

local function clusterxt_callback(address, msgtype, param, cb, cbparam)
    local ok, result =
        xpcall(
        cb,
        debug.traceback,
        clusterExt.call(address, msgtype, table.unpack(param, 1, param.n)),
        table.unpack(cbparam, 1, cbparam.n)
    )
    if not ok then
        log.Error("sys", "clusterxt_callback err:", result)
    end
end

local function clusterxt_timeout_callback(address, msgtype, timeout, timeout_call, param, cb, cbparam)
    --是否超时了
    local isTimeout = false
    --是否已经回调了
    local hasCallBack = false
    local co = coroutine.running()
    skynet.fork(
        function()
            local function f(...)
                --超时不做处理
                if not isTimeout then
                    hasCallBack = true
                    skynet.wakeup(co)
                    xpcall(cb, debug.traceback, ..., table.unpack(cbparam, 1, cbparam.n))
                end
            end

            f(clusterExt.call(address, msgtype, table.unpack(param, 1, param.n)))
        end,
        address,
        msgtype,
        timeout,
        param,
        cb,
        cbparam
    )

    skynet.sleep(timeout * 100)

    if not hasCallBack then
        isTimeout = true
        timeout_call(table.unpack(cbparam, 1, cbparam.n))
    end
end

local function callback_param(...)
    local param = {}
    local cbparam = {}
    local cb = nil
    local t = table.pack(...)
    for i = 1, t.n do
        local v = t[i]
        if type(v) == "function" and not cb then
            cb = v
            param = table.pack(table.unpack(t, 1, i - 1))
            cbparam = table.pack(table.unpack(t, i + 1, t.n))
            break
        end
    end
    if not cb then
        param = t
    end
    return param, cb, cbparam
end

--远程服务请求
--设计思路参考 https://blog.codingnow.com/2014/07/skynet_response.html
function clusterExt.callback(address, msgtype, ...)
    local param, cb, cbparam = callback_param(...)

    if not address then
        log.Warn("sys", "err address is nil", dumpTable({msgtype, ...}))
        cb(nil, table.unpack(cbparam, 1, cbparam.n))
        return
    end
    if not cb then
        log.Error("sys", "err clusterxt_callback cb is nil")
    end

    skynet.fork(clusterxt_callback, address, msgtype, param, cb, cbparam)
end

--远程服务请求，超时回调
function clusterExt.timeout_callback(address, msgtype, timeout, timeout_call, ...)
    local param, cb, cbparam = callback_param(...)

    if not cb then
        log.ErrorStack("sys", "err timeout_callback cb is nil", dumpTable({msgtype, ...}, "param", 10))
        return
    end
    if not address then
        log.ErrorStack("sys", "err address is nil", dumpTable({msgtype, ...}, "param", 10))
        cb(nil, table.unpack(cbparam, 1, cbparam.n))
        return
    end

    skynet.fork(clusterxt_timeout_callback, address, msgtype, timeout, timeout_call, param, cb, cbparam)
end

-- send: 返回值 false表示发送失败，一般为地址不存在或者节点挂了，不做业务成功失败判断
function clusterExt.send(address, msgtype, ...)
    if not address then
        log.ErrorStack("sys", "err address is nil", dumpTable({msgtype, ...}, "param", 10))
        return false
    end
    if type(address) == "table" then
        local ok, result = xpcall(cluster.send, debug.traceback, address.nodeName, address.serviceName, ...)
        if not ok then
            log.ErrorStack("sys", "clusterExt.send err:", dumpTable(result, "result", 10), ...)
        end
        return ok
    else
        local ok, result = xpcall(skynet.send, debug.traceback, address, msgtype, ...)
        if not ok then
            log.ErrorStack("sys", "skynet.send err:", dumpTable(result, "result", 10), ...)
        end
        return ok
    end
end

return clusterExt
