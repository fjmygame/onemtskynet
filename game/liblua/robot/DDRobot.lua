--
-- Author: TQ
-- Date: 2017-03-21 11:07:09
--

local json = require("json")
local luacurl = require("luacurl")
local DDRobot = instanceClass("DDRobot")

-- 内容长度上限，超出后直接截断
local TEXT_LEN_LIMIT = 10000

function DDRobot:ctor()
    self.curl = luacurl.easy()
end

local function rawSendMsg(self, text, url)
    url = url or dbconf.notifyUrl
    if not url then
        return
    end

    -- 内容长度做个限制
    if string.len(text) > TEXT_LEN_LIMIT then
        text = string.sub(text, 1, TEXT_LEN_LIMIT)
    end

    local notifyData = {
        msgtype = "text",
        text = {
            content = text
        }
    }

    local form = json.encode(notifyData)

    local mybuffer = ""
    local mywritedata = {}

    local curl = self.curl
    -- 重置对象
    curl:reset()
    curl:setopt(luacurl.OPT_NOSIGNAL, true)
    curl:setopt(luacurl.OPT_CONNECTTIMEOUT, 3)
    curl:setopt(luacurl.OPT_TIMEOUT, 3)
    curl:setopt(luacurl.OPT_POST, true)
    curl:setopt(luacurl.OPT_HTTPHEADER, "Content-Type:application/json;charset=UTF-8")
    curl:setopt(luacurl.OPT_SSL_VERIFYPEER, false) --https
    curl:setopt(luacurl.OPT_SSL_VERIFYHOST, 0) --https
    curl:setopt(luacurl.OPT_URL, url)
    curl:setopt(luacurl.OPT_POSTFIELDS, form)
    curl:setopt(
        luacurl.OPT_WRITEFUNCTION,
        function(userparam, buffer)
            mybuffer = mybuffer .. buffer
            return string.len(buffer)
        end
    )
    curl:setopt(luacurl.OPT_WRITEDATA, mywritedata)
    local xpcallok, curlres, errmsg, errcode = xpcall(curl.perform, debug.traceback, curl)
    print("notifyJJIM======", xpcallok, curlres, errmsg, errcode, mybuffer)
    if nil == xpcallok or false == xpcallok then
        return false, mybuffer
    end

    return true, mybuffer
end

--[[
	通知丁丁服务器启动了
]]
function DDRobot:notifyServerRestart()
    if (not dbconf.DEBUG) or (not dbconf.notifyJJIM) then
        return false, "not DEBUG or not notifyJJIM"
    end

    local text = dbconf.notifyText
    if not text then
        return false, "notifyText unconfig"
    end

    return rawSendMsg(text)
end

-- 去重复
function DDRobot:disError(error)
    if nil == self.mapError then
        self.mapError = {}
    end

    if self.mapError[error] then
        return true
    end
    self.mapError[error] = true
    return false
end

-- 异常报错机器人通知
function DDRobot:notifyException(error)
    if not dbconf.notifyJJIM then
        return false, "not DEBUG or not notifyJJIM"
    end

    if self:disError(error) then
        return false, "err info repeat!"
    end

    local notifyText = dbconf.notifyText
    if not notifyText then
        return false, "notifyText unconfig"
    end

    local text = notifyText .. "出bug啦: " .. error
    return rawSendMsg(self, text)
end

-- 异常报错机器人通知
function DDRobot:notifyMsg(msg, url)
    if not dbconf.notifyJJIM then
        return false, "not DEBUG or not notifyJJIM"
    end

    local notifyText = dbconf.notifyText
    if not notifyText then
        return false, "notifyText unconfig"
    end

    local text = notifyText .. ":" .. msg
    return rawSendMsg(self, text, url)
end

return DDRobot.instance()
