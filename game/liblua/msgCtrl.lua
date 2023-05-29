--[[
客户端发送上来的消息请求格式
req = {
  cmd = xxx --模块的指令头
  subcmd = xxx --模块的具体操作类型
  data = {} --发送的数据
}

发送给客户端的消息格式
ret = {
  cmd = xxx --模块的指令头
  subcmd = xxx --模块的具体操作类型
  data = {} --发送的数据
  err = xxx --错误类型
}
]]
---@class msgCtrl
local msgCtrl = {}

local dispatch = {}

--每个模块统一注册消息处理回调
function msgCtrl.register(cmd, subcmd, cb)
  assert(cmd, "register the msg failed! the cmd is nil")
  assert(subcmd, "register the msg failed! the subcmd is nil")
  assert("function" == type(cb), "register the msg failed! the callback is not a function.")

  dispatch[cmd] = dispatch[cmd] or {}

  assert(
    not dispatch[cmd][subcmd],
    "register the msg failed! cmd already registered.cmd=" .. tostring(cmd) .. ",subcmd=" .. tostring(subcmd)
  )

  -- log.Debug("old",string.safeFormat("register the msg: cmd = %s, subcmd = %s success!", cmd, subcmd))
  dispatch[cmd][subcmd] = cb
end

--移除消息
function msgCtrl.remove(cmd, subcmd)
  if dispatch[cmd] and dispatch[cmd][subcmd] then
    dispatch[cmd][subcmd] = nil
  end
end

--移除所有注册的消息
function msgCtrl.clean()
  dispatch = {}
end

function msgCtrl.registerSproto(name, cb)
  assert(name, "register the msg failed! the name is nil")
  assert("function" == type(cb), "register the msg failed! the callback is not a function.")
  assert(not dispatch[name], "register the msg failed! cmd already registered.cmd=" .. name)
  dispatch[name] = cb
end

--移除消息
function msgCtrl.removeSproto(name)
  if dispatch[name] then
    dispatch[name] = nil
  end
end

function msgCtrl.handleSproto(name, req)
  local cb = dispatch[name]
  if "function" ~= type(cb) then
    log.Warn("msg", "handle the msg failed! not found the sproto: name=", name)
    return
  end
  local result = cb(req)
  return result
end

return msgCtrl
