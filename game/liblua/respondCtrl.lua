--
-- Author: TQ
-- Date: 2015-06-11 16:31:58
--

local skynet = require "skynet"
local json = require "json"
local respondCtrl = {}
------------------service----------------

-- 构造一个针对当前服务请求的延迟发送的回应闭包, 可以在后续任务中
-- 再处理这个回应
function respondCtrl.createCmdResponseClosure()
    return skynet.response()
end

-- 回应当前的请求
function respondCtrl.respondtocmd(...)
    skynet.ret(skynet.pack(...))
end

-- 延时向 service 发送通知
function respondCtrl.notifyservice(responseclosure, ...)
    responseclosure(true, ...)
end

-----------------msg---------------

-- 构造一个针对当前客户端请求的延迟发送的回应闭包, 可以在后续任务中
-- 再处理这个回应
function respondCtrl.createMsgResponseClosure()
    return skynet.response(
        function(m)
            return tostring(m)
        end
    )
end

function respondCtrl.encode_msg(msg)
    local gZlibDef = require "zlibMsgDef"
    local rsp = json.encode(msg)

    local a = string.len(rsp)
    if a > 1024 * 100 then
        log.Info("msg", rsp, "respondCtrl.respondCtrl exceed 100k", 10)
    end

    -- local crypt = require "crypt"
    -- rsp = crypt.desencode(agentCenter:sharedInstance().secret, rsp)
    -- rsp = crypt.base64encode(rsp)
    if rsp == nil or "" == rsp then
        log.DumpError("msg", msg, "respondCtrl.respondtoclient", 10)
    end
    local b = string.len(rsp)
    -- add by vincent
    local tmpIsZip = 0
    if nil ~= msg.cmd and nil ~= msg.subcmd and nil ~= gZlibDef[msg.cmd] and nil ~= gZlibDef[msg.cmd][msg.subcmd] then
        tmpIsZip = 1
    end
    if nil ~= gMsgMaxSize and string.len(rsp) > gMsgMaxSize then
        tmpIsZip = 1
    end

    rsp = tostring(tmpIsZip) .. respondCtrl.compress(rsp, tmpIsZip)
    local c = string.len(rsp)
    if c > 10 * 1024 then
        log.Warn(
            "msg",
            string.safeFormat(
                "encode_msg > 10k, cmd %d, subcmd %d, size %d, %d, %d(%s)",
                msg.cmd,
                msg.subcmd,
                a,
                b,
                c,
                tmpIsZip == 1 and "zip" or "not zip"
            )
        )
    end
    return rsp
end
-- 向客户端直接回应当前的请求, 此处要求一个 lua table 作为参数
-- 本函数将 lua table 编码成 json 串
function respondCtrl.respondtoclient(msg)
    local rsp = respondCtrl.encode_msg(msg)
    skynet.ret(rsp)
end

function respondCtrl.compress(msg, flag)
    if nil == flag then
        flag = 0
    end
    if 0 == flag then
        return msg
    end
    local zlib = require("zlib")
    local compress = zlib.deflate()
    -- deflated, eof, bytes_in, bytes_out
    local deflated = compress(msg, "finish")
    return deflated
end

-- 延时向客户端发送通知(客户端要预先发送 request 上来)
function respondCtrl.notifyclient(responseclosure, msg)
    local rsp = respondCtrl.encode_msg(msg)
    responseclosure(true, rsp)
end

-- 消息返回
-- 客户端发上来的req中会有一个key：source = "c"
function respondCtrl.respond(...)
    local req = ...
    if "table" == type(req) and "c" == req.source then
        respondCtrl.respondtoclient(req)
    else
        respondCtrl.respondtocmd(...)
    end
end

-- 常用的正常返回
-- req: table
-- ok: 正确或错误，true or false
-- 如果ok = true, ... 为返回的数据
-- 如果ok = false, ... 为错误码和数据（可选）
function respondCtrl.commonCmdRsp(req, ok, ...)
    req = req or {}
    if ok then
        req.err = gErrDef.Err_None
        if ... then
            req.data = ...
        end
    else
        local err, data = ...
        req.err = err
        if data then
            req.data = data
        end
    end

    respondCtrl.respond(req)
end

-- 常用的闭包返回
-- req: table
-- ok: 正确或错误，true or false
-- 如果ok = true, ... 为返回的数据
-- 如果ok = false, ... 为错误码和数据（可选）
function respondCtrl.commonCmdRspClosure(responseclosure, req, data)
    req = req or {}
    local source = req.source
    req.err = gErrDef.Err_None
    req.data = data

    if "c" == source then
        respondCtrl.notifyclient(responseclosure, req)
    else
        respondCtrl.notifyservice(responseclosure, req)
    end
end

-- 创建闭包
function respondCtrl.commonCreateCmdClosure(cmdSource)
    if "c" == cmdSource then
        return respondCtrl.createMsgResponseClosure()
    else
        return respondCtrl.createCmdResponseClosure()
    end
end

-- 错误返回
function respondCtrl.errReturn(req, err, info, ...)
    log.Warn("base", info, err, ...)
    req.err = err
    respondCtrl.respond(req)
end

function respondCtrl.error(err, info, ...)
    log.Warn("base", info, err, ...)
    return {err = err}
end

function respondCtrl.ok(data)
    if not data then
        data = {err = gErrDef.Err_None}
    else
        data.err = gErrDef.Err_None
    end
    return data
end

return respondCtrl
