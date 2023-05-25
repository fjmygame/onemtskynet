--[[
    双向链表
--]]

local linkList = class("linkList")

-- -- 首节点
-- linkList.first_ = nil
-- -- 末节点
-- linkList.last_ = nil
-- -- 链表的长度
-- linkList.size_ = 0
-- -- 排序算法
-- linkList.compare_ = nil

function linkList:ctor(datakey, comp)
    self.datakey = datakey or "data"
    self.compare_ = comp
    self.size_ = 0
end

-- 插入到节点前面
local function insertNodePre(self, newNode, node)
    newNode.pre = node.pre
    newNode.next = node
    local preNode = node.pre
    node.pre = newNode
    if preNode then
        preNode.next = newNode
    else
        self.first_ = newNode
    end
end

-- 插入到节点后面
local function insertNodeNext(self, newNode, node)

    newNode.pre = node
    local nextNode = node.next
    newNode.next = nextNode
    node.next = newNode

    if nextNode then
        nextNode.pre = newNode
    else
        self.last_ = newNode
    end
end

-- 比较
local function callCompare(self, newNode, oldNode)
    if "function" == type(self.compare_) then
        return self.compare_(newNode, oldNode)
    end
end

----------------API----------------

-- 创建新节点
function linkList.createNode( data, datakey )
    local key = datakey or "data"
    return { pre = nil, next = nil, [key] = data, tag = nil }
end

-- 创建新节点
function linkList:newNode(data, datakey)
    local key = datakey or self.datakey
    return { pre = nil, next = nil, [key] = data }
end

-- 设置排序算法
function linkList:setCompare(com)
    self.compare_ = com
end

-- 插入
function linkList:insert(node)
    if node.pre or node.next or node == self:front() then
        serviceFunctions.exception("linklist:insert: invalid node!")
        return
    end

    local isInsert = false
    local newNode = node
    -- 判断队列是否为空
    if not self:empty() then
        -- 如果不为空
        -- 当前节点
        local curNode = self:front()
        while curNode do
            -- 和当前节点比较
            if callCompare(self, newNode, curNode) then
                insertNodePre(self, newNode, curNode)
                self.size_ = self.size_ + 1
                isInsert = true
                break
            else
                if curNode.next then
                    curNode = curNode.next
                else
                    break
                end
            end
        end

        if not isInsert then
            insertNodeNext(self, newNode, curNode)
            self.size_ = self.size_ + 1
        end

    else
        -- 如果为空，插入到list中，self.first_
        self.first_ = newNode
        self.last_ = newNode
        self.size_ = 1
        return newNode
    end
end

-- 删除
function linkList:remove(node)
    local preNode = node.pre
    local nextNode = node.next
    node.pre = nil
    node.next = nil

    if preNode and nextNode then
        -- 该节点是中间节点
        preNode.next = nextNode
        nextNode.pre = preNode
        self.size_ = self.size_ - 1

    elseif preNode and not nextNode then
        -- 该节点是末尾节点
        preNode.next = nil
        self.last_ = preNode
        self.size_ = self.size_ - 1

    elseif not preNode and nextNode then
        -- 该节点是首节点，且有其他节点
        nextNode.pre = nil
        -- 重置firstNode
        self.first_ = nextNode
        self.size_ = self.size_ - 1

    else
        -- 只有首节点
        if self.first_ == node then
            self.first_ = nil
            self.last_ = nil
            self.size_ = self.size_ - 1
        else
            if not node.pre and not node.next then
                serviceFunctions.exception("linklist:remove: invalid node!")
                return
            end
        end
    end
end

-- 清空链表
function linkList:clean()
    self.first_ = nil
    self.last_ = nil
    self.size_ = 0
end

-- 获取首节点
function linkList:front()
    return self.first_
end

-- 获取末节点
function linkList:last()
    return self.last_
end

-- 删除第一个节点
function linkList:pop()
    local node = self.first_
    self:remove(self.first_)
    return node
end

-- 排序
function linkList:sort()
    local nextNode = self.first_
    linkList.clean(self)
    while nextNode do
        local node = nextNode
        nextNode = nextNode.next
        node.pre = nil
        node.next = nil
        linkList.insert(self, node)
    end
end

-- 获取某个位置的节点
function linkList:getNode( pos )
    if pos and pos <= self:size() then
        local i = 1
        local node = self:front()
        while node do
            if pos == i then
                return node
            end
            i = i + 1
            node = node.next
        end
    end
end

-- 获取节点的位置
function linkList:getPos(node)
    if node and not self:empty() then
        local curNode = self:front()
        local i = 1
        while curNode do
            if node == curNode then
                return i
            end
            i = i + 1
            curNode = curNode.next
        end
    end
end

-- 删除某个位置的节点
function linkList:removePos( pos )
    local node = self:getNode(pos)
    if node then
        self:remove(node)
    end
    return node
end

-- 判断list是否为空
function linkList:empty()
    if not self.first_ and self.size_ <=0 then
        return true
    end

    return false
end

-- 获取list的size
function linkList:size()
    return self.size_
end

function linkList:dump(_title)
    print("============" .. (_title or "linklist") .. "===========")
    local function dumpNode(node, title)
        if not node then
            print("node is nil")
        elseif node[self.datakey].dump then
            node[self.datakey]:dump(title)
        else
            title = title and title .. ":" or ""
            print(title, node)
            print("\n")
        end
    end

    if not self.first_ then
        print("list is empty!\n\n\n")
        return
    end

    dumpNode(self.first_, "first node")

    local node = self.first_
    local i = 2
    while node and node.next do
        node = node.next
        dumpNode(node, "the " .. i .. " node!")
        i = i + 1
    end

    print("\n\n\n")
end

-- 插入
function linkList:push(node)
    if node.pre or node.next then
        serviceFunctions.exception("linklist:insert: invalid node!")
        return
    end

    -- 判断队列是否为空
	if self:empty() then
		-- 如果为空，插入到list中，self.first_
		self.first_ = node
		self.last_ = node
		self.size_ = 1
    else
		insertNodeNext(self, node, self.last_)
		self.size_ = self.size_ + 1
    end
end

return linkList