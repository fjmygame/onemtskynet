---------------------------------------------------------------------------------
-- 作者: zkb
-- 时间: 2019-06-27
-- 描述: 延迟回调
-- 注意: 如果同一个调用需要过滤自己外部处理
--------------------------------------------------------------------------------
local skynet = require("skynet")
local zset = require("zset")

---@class delayTimer
local delayTimer = BuildOther("delayTimer")

function delayTimer:init()
    if self.initTag then
        return
    end

    self.initTag = true
    self.auto = 1
    self.set = zset.new() -- {time, "node.id"}
    self.nodeList = {} -- 保存node, 索引用time
    self:run()
end

--- func 唯一延迟回调
-- @number time 定时触发时间
-- @number member 唯一值
-- @number cb 回调
-- @return node定时的节点 [用来更新和删除用]
function delayTimer:uniqueDelay(time, cb, content, member)
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
function delayTimer:delay(time, cb, content)
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
function delayTimer:hasNode(member)
    return self.nodeList[member] ~= nil
end

-- 删除
function delayTimer:removeNode(member)
    local node = self.nodeList[member]
    self.set:rem(member) --  删除
    self.nodeList[member] = nil
    return node
end

function delayTimer:update()
    if self.set:count() > 0 then
        local curTime = timeUtil.systemTime()
        local rank = self.set:range_by_score(0, curTime)
        for _, member in ipairs(rank) do
            -- callback
            local node = self.nodeList[member]
            if node then
                local ok, err = xpcall(node.cb, debug.traceback, node)
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
function delayTimer:run()
    skynet.timeout(100, handlerName(self, "update"))
end

function delayTimer:isRun()
    return true
end

delayTimer:init()

return delayTimer
