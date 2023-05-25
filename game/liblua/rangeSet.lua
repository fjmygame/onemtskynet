--------------------------------------------------------------------------------
-- 文件: rangeSet.lua
-- 作者: zkb
-- 时间: 2020-08-07 15:16:11
-- 描述: 区间排序用来判断两个区间是否有重叠
-- 例如:
-- 重叠: [10,20],[19,30]
-- 重叠: [10,50],[19,30]
--------------------------------------------------------------------------------
local zset = require("zset")

local _M = class("rangeSet")

function _M:ctor()
    self.zs = zset.new()
end

function _M:genMemberKey(member)
    local m1 = string.safeFormat("%s_%d", member, 1)
    local m2 = string.safeFormat("%s_%d", member, 2)
    return m1, m2
end

function _M:decodeMember(member)
    if member then
        local tempArr = string.split(member, "_")
        return tempArr[1], tempArr[2]
    end
end

-- range:  [a, b]
-- member: 唯一标示
function _M:add(range, member)
    if not range then
        log.ErrorStack("activity", "The activity time range is nil!!")
        return false
    end

    if not next(range) or #range ~= 2 or range[1] > range[2] then
        log.ErrorStack("activity", "The activity time range is err!!", dumpTable(range))
        return false
    end

    local m1, m2 = self:genMemberKey(member)

    -- 排序
    local zs = self.zs
    zs:add(range[1], m1)
    local r1 = zs:rank(m1)
    if r1 % 2 ~= 1 then -- 不是奇数表示重叠了
        local conflit_subKey = zs:rangeOne(r1 - 1)
        zs:rem(m1)
        local conflit_key = self:decodeMember(conflit_subKey)
        log.Info("activity", "The activity time range is conflict!!!", member, dumpTable(range), conflit_key)
        return false, conflit_key
    end

    zs:add(range[2], m2)
    local r2 = zs:rank(m2)
    if r2 - r1 ~= 1 then -- 不连续
        local conflit_subKey = zs:rangeOne(r2 - 1)
        zs:rem(m1)
        zs:rem(m2)
        local conflit_key = self:decodeMember(conflit_subKey)
        log.Info("activity", "The activity time range is conflict!!!", member, dumpTable(range), conflit_key)
        return false, conflit_key
    end
    return true
end

-- 移除没用区间
function _M:rem(member)
    local m1, m2 = self:genMemberKey(member)
    self.zs:rem(m1)
    self.zs:rem(m2)
end

return _M
