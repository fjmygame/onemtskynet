-- --------------------------------------
-- Create Date:2021-07-12 10:59:28
-- Author  : Happy Su
-- Version : 1.0
-- Filename: tzset.lua
-- Introduce  : 类介绍
-- --------------------------------------
local timeskiplist = require "timeskiplist.c"
---@class tzset
local mt = {}
mt.__index = mt

---@param b_ignore_repeat_check boolean 是否忽略重复验证
function mt:add(score, member, timestamp, b_ignore_repeat_check)
    assert("number" == type(score), "score need number")
    assert("string" == type(member), "member need string")
    assert("number" == type(timestamp), "timestamp need number")
    local old = self.tbl[member]
    if old then
        local old_timestamp = self.ts[member]
        -- 初始化不必判断
        if not b_ignore_repeat_check and old == score and old_timestamp == timestamp then
            log.debugErrorStack("sys", "tzset add score not change!!!", member, timestamp, score)
            return
        end
        local bok = self.sl:delete(old, member, self.ts[member])
        if bok then
            self.tbl[member] = nil
            self.ts[member] = nil
        else
            log.Error("sys", "tzset rem err 1~", member, score, timestamp)
            self.tbl[member] = score
            self.ts[member] = timestamp
            return
        end
    end
    self.sl:insert(score, member, timestamp)
    self.tbl[member] = score
    self.ts[member] = timestamp
end

function mt:rem(member)
    local score = self.tbl[member]
    if score then
        local timestamp = self.ts[member]
        local bok = self.sl:delete(score, member, timestamp)
        if bok then
            self.tbl[member] = nil
            self.ts[member] = nil
        else
            log.Warn("sys", "tzset rem err 2~", member, score, timestamp)
        end
    end
end

function mt:count()
    return self.sl:get_count()
end

function mt:_reverse_rank(r)
    return self.sl:get_count() - r + 1
end

function mt:limit(count)
    local total = self.sl:get_count()
    if total <= count then
        return 0
    end
    return self.sl:delete_by_rank(
        count + 1,
        total,
        function(member)
            self.tbl[member] = nil
        end
    )
end

function mt:rev_limit(count)
    local total = self.sl:get_count()
    if total <= count then
        return 0
    end
    local from = self:_reverse_rank(count + 1)
    local to = self:_reverse_rank(total)
    return self.sl:delete_by_rank(
        from,
        to,
        function(member)
            self.tbl[member] = nil
        end
    )
end

function mt:rev_range(r1, r2)
    if r1 > self.sl:get_count() then
        return {}
    end
    r1 = self:_reverse_rank(r1)
    r2 = self:_reverse_rank(r2)
    return self:range(r1, r2)
end

function mt:range(r1, r2)
    if r1 < 1 then
        r1 = 1
    end

    if r2 < 1 then
        r2 = 1
    end
    return self.sl:get_rank_range(r1, r2)
end

function mt:rangeOne(r)
    local memlist = self:range(r, r)
    return memlist and memlist[1]
end

function mt:rev_rank(member)
    local r = self:rank(member)
    if r then
        return self:_reverse_rank(r)
    end
    return r
end

function mt:rank(member)
    local score = self.tbl[member]
    if not score then
        return nil
    end
    local timestamp = self.ts[member]
    return self.sl:get_rank(score, member, timestamp)
end

function mt:range_by_score(s1, s2)
    return self.sl:get_score_range(s1, s2)
end

function mt:score(member)
    return self.tbl[member]
end

function mt:dump()
    self.sl:dump()
end

function mt:dumpOut(func)
    func = func or function(...)
            print("dumpOut", ...)
        end
    self.sl:dump_out(func)
end

local M = {}
function M.new()
    local obj = {}
    obj.sl = timeskiplist()
    obj.tbl = {}
    obj.ts = {}
    return setmetatable(obj, mt)
end
return M
