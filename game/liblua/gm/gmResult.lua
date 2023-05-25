--------------------------------------------------------------------------------
-- 文件: gmResult.lua
-- 作者: zkb
-- 时间: 2020-08-20 20:38:41
-- 描述: gm操作返回对象
--------------------------------------------------------------------------------
---@class gmResult
local _M = class("gmResult")

function _M:ctor()
    self.success = {}
    self.fail = {}
    self.result = true
end

function _M:addSucessLog(kid)
    local success = self.success
    success[#success + 1] = kid
end

function _M:addFailLog(kid, reason)
    local fail = self.fail
    if not next(fail) then
        fail[#fail + 1] = {kids = {kid}, reason = reason}
        return
    end

    for _, v in ipairs(fail) do
        if v.reason == reason then
            v.kids[#v.kids + 1] = kid
            return
        end
    end
    -- 没有一样的则自成一派
    fail[#fail + 1] = {kids = {kid}, reason = reason}
end

--- classifyResult gm返回结果归类
-- @number kid 王国id
-- @number number desc
-- @return return desc
-- @usage usage desc
function _M:classifyResult(kid, ok, reason)
    if ok then
        self:addSucessLog(kid)
    else
        self:addFailLog(kid, reason)
    end
end

function _M:failReasonFill()
    local fail = self.fail
    for _, v in ipairs(fail) do
        if not v.reason then
            v.reason = "server exception"
        end
    end
end

function _M:finalResult()
    local ok = true
    local msg = "partial request failed"
    if not next(self.success) then
        self.success = nil
        msg = "all failed"
    end
    if not next(self.fail) then
        self.fail = nil
        self.success = nil
        msg = "success"
    else
        ok = false
        self:failReasonFill()
    end
    return {result = ok, msg = msg, data = {success = self.success, fail = self.fail}}
end

return _M
