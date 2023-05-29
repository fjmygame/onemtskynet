--
-- Author: TQ
-- Date: 2015-06-13 15:27:18
--

--[[
	service 发送上来的消息请求格式
	发送给客户端的消息格式
	ret = {
	  cmd = xxx --模块的指令头
	  subcmd = xxx --模块的具体操作类型
	  data = {} --发送的数据
	  err = xxx --错误类型
	}
--]]
local skynet = require "skynet"
---@class cmdCtrl
local cmdCtrl = BuildOther("cmdCtrl")

local dispatch = CreateBlankTable(cmdCtrl, "dispatch")

-- 注册 cmd
function cmdCtrl.register(cmd, cb)
    assert("string" == type(cmd), "register the cmd failed! the cmd is nil")
    assert("function" == type(cb), "register the cmd failed! the callback is not a function.")
    assert(not dispatch[cmd], "register the cmd failed! cmd already registered.cmd=" .. tostring(cmd))

    --log.Debug("old",string.safeFormat("register the cmd:%s success!", cmd))
    dispatch[cmd] = cb
end

-- 移除 cmd
function cmdCtrl.remove(cmd)
    assert("string" == type(cmd), "register the cmd failed! the cmd is nil")
    if not dispatch[cmd] then
        skynet.error("warning: the cmd don't exist!")
    end

    dispatch[cmd] = nil
end

-- 清空 cmd
function cmdCtrl.clean()
    dispatch = {}
end

-- 分发处理
function cmdCtrl.handle(strcmd, ...)
    -- cmd 在 msgCenter 检查过，不会为nil
    local cmd = tostring(strcmd)
    local cb = dispatch[cmd]
    if "function" == type(cb) then
        cb(...)
        return true
    else
        -- log.Debug("old","handle the cmd failed! not found the cmd:", cmd)
        return false
    end
end

return cmdCtrl
