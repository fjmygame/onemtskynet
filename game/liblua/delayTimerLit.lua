-- --------------------------------------
-- Create Date:2022-02-16 14:45:40
-- Author  : Happy Su
-- Version : 1.0
-- Filename: delayTimerLit.lua
-- Introduce  : 回调只会传content
-- --------------------------------------
local skynet = require("skynet")
local zset = require("zset")

---@class delayTimerLit
local _M = BuildOther("delayTimerLit")

function _M:init()
    if self.initTag then
        return
    end

    self.initTag = true
    self.auto = 1
    self.set = zset.new() -- {time, "node.id"}
    self.nodeList = {} -- 保存node, 索引用time
end

function _M:start()
    if self.startTag then
        return
    end

    self.startTag = true
    self:run()
end

--- func 唯一延迟回调
-- @number time 定时触发时间
-- @number member 唯一值
-- @number cb 回调
-- @return node定时的节点 [用来更新和删除用]
function _M:uniqueDelay(time, cb, content, member)
    if member then
        self:removeNode(member)
    end
    return self:delay(time, cb, content)
end

--- 延迟回调
-- @number time 定时触发时间
-- @number key 唯一值
-- @number cb 回调
-- @return node定时的节点 [用来更新和删除用]
-- @usage usage desc
function _M:delay(time, cb, content)
    local node = {
        id = self.auto,
        time = time,
        content = content,
        cb = cb
    }
    self.auto = self.auto + 1

    -- node.id做为member
    local member = tostring(node.id)
    if not self.nodeList[member] then
        self.nodeList[member] = {}
    end
    self.set:add(time, member)
    self.nodeList[member] = node
    return member
end

-- 是否存在节点
function _M:hasNode(member)
    return self.nodeList[member] ~= nil
end

-- 删除
function _M:removeNode(member)
    local node = self.nodeList[member]
    self.set:rem(member) --  删除
    self.nodeList[member] = nil
    return node
end

function _M:update()
    if self.set:count() > 0 then
        local curTime = timeUtil.systemTime()
        local rank = self.set:range_by_score(0, curTime)
        for _, member in ipairs(rank) do
            -- callback
            local node = self.nodeList[member]
            if node then
                local ok, err = xpcall(node.cb, debug.traceback, node.content)
                if not ok then
                    log.Error("sys", "delayTimer timeout err->", member, err, dumpTable(node.content))
                end
            else
                log.Warn("sys", "delayTimer timeout no node->", member)
            end
            self:removeNode(member)
        end
    end

    self:run() -- 继续定时
end

-- 每秒检查一次
function _M:run()
    skynet.timeout(100, handlerName(self, "update"))
end

function _M:isRun()
    return true
end

_M:init()

return _M
