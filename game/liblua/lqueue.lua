--------------------------------------------------------------------------------
-- 文件: lqueue.lua
-- 作者: zkb
-- 时间: 2020-01-17 14:08:42
-- 描述: 队列
--------------------------------------------------------------------------------
---@class lqueue
local _M = class("lqueue")

-- 加入队列
function _M:push(obj)
    local node = {obj = obj, next = nil}
    if not self.head then -- 空列表
        self.head = node
        self._size = 1
        return
    end

    if not self.last then -- 只有一个头节点
        self.last = node
        self.head.next = node
        self._size = self._size + 1
        return
    end

    self.last.next = node
    self.last = node
    self._size = self._size + 1
end

-- 弹出
function _M:pop()
    if not self.head then
        return nil
    end

    local node = self.head
    self.head = node.next
    if not self.head or not self.head.next then
        self.last = nil
    end
    self._size = self._size - 1
    return node.obj
end

-- 获取头数据
function _M:rawGetHeadDate()
    if not self.head then
        return nil
    end

    return self.head.obj
end

function _M:size()
    return self._size or 0
end

function _M:empty()
    return self:size() <= 0
end

return _M
