-- --------------------------------------
-- Create Date:2020-03-14 09:43:51
-- Author  : Happy Su
-- Version : 1.0
-- Filename: clusterExt.lua
-- Introduce  : 服务调用封装
-- --------------------------------------
local skynet = require "skynet"
local cluster
local cluster_node = skynet.getenv "cluster_node"
if cluster_node then
    cluster = require "cluster"
end

---@class clusterExt
local clusterExt = class("clusterExt")

function clusterExt.initcluster()
    cluster = require "cluster"
end

--开启集群节点
function clusterExt.open(node)
    skynet.setenv("cluster_node", node)
    cluster_node = node
    if cluster_node then
        cluster = require "cluster"
    end
    log.Info("clusterext", "cluster_node:", node)
    cluster.open(cluster_node)
end

--请求服务节点名字
function clusterExt.self()
    return cluster_node or ""
end

--
function clusterExt.iscluster()
    return cluster
end

--获取本节点id
function clusterExt.getnodeid()
    return dbconf.curnodeid
end

--打包远程节点地址
function clusterExt.pack_cluster_address(node, name)
    return {node = node, service = name}
end

--请求远程服务
function clusterExt.queryservice(node, name)
    -- local tempname = "." .. name
    local tempname = name
    -- local cnode = get_cluster_node()
    if cluster_node and node and cluster_node ~= node then
        return clusterExt.pack_cluster_address(node, tempname)
    else
        return skynet.localname(tempname)
    end
end

local function processCallResult_ok(ok, result, ...)
    if not ok then
        log.Error("sys", "clusterExt.call failed error:", dumpTable(result, "result", 10), ...)
    else
        return result, ...
    end
end

--远程服务请求
function clusterExt.call(address, msgtype, ...)
    if not address then
        log.ErrorStack("sys", "err address is nil:", dumpTable({msgtype, ...}, "param", 10))
        return
    end

    if type(address) == "table" then
        return processCallResult_ok(xpcall(cluster.call, debug.traceback, address.node, address.service, ...))
    else
        return processCallResult_ok(xpcall(skynet.call, debug.traceback, address, msgtype, ...))
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
        -- log.Info("sys", "cluster.send:", address, msgtype, ...)
        local ok, result = xpcall(cluster.send, debug.traceback, address.node, address.service, ...)
        if not ok then
            log.ErrorStack("sys", "clusterExt.send err:", dumpTable(result, "result", 10), ...)
        end
        return ok
    else
        -- log.Info("sys", "skynet.send:", address, msgtype, ...)
        local ok, result = xpcall(skynet.send, debug.traceback, address, msgtype, ...)
        if not ok then
            log.ErrorStack("sys", "skynet.send err:", dumpTable(result, "result", 10), ...)
        end
        return ok
    end
end

return clusterExt
