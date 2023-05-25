--------------------------------------------------------------------------------
-- 文件: tableEx.lua
-- 作者: zkb
-- 时间: 2020-02-25 14:20:27
-- 描述: table拓展
--------------------------------------------------------------------------------
--[[
    将一个数组分割成按比例分割成另一个数组
    比如：
   t = { key1, value1, key2, value2 ... }

    keys = { "id", "count" }

    那么
    ret = { { id = key1, count = value1 }, { id = key2, count = value2 } }
--]]
local next = next

function table.format(t, keys)
    local ret = {}
    local n = keys and #keys or 0
    if n <= 0 then
        keys = {"id", "count"} -- 添加默认值
        n = 2
    end
    if not t then
        log.ErrorStack("sys", "table.format error" .. dumpTable(keys))
    end
    local totalNum = #t
    assert(totalNum % n == 0, "配置表和分割数不对应:" .. dumpTable(keys) .. "-" .. table.concat(t, ","))
    for i = 1, #t, n do
        local d = {}
        for j, key in ipairs(keys) do
            d[key] = t[i + j - 1]
        end

        ret[#ret + 1] = d
    end
    return ret
end

-- start --

--------------------------------
-- 计算表格包含的字段数量
-- @function [parent=#table] nums
-- @param table t 要检查的表格
-- @return integer#integer

--[[--
计算表格包含的字段数量
Lua table 的 "#" 操作只对依次排序的数值下标数组有效，table.nums() 则计算 table 中所有不为 nil 的值的个数。
]]
-- end --

function table.nums(t)
    local count = 0
    for k, v in pairs(t) do
        count = count + 1
    end
    return count
end

-- start --

--------------------------------
-- 返回指定表格中的所有键
-- @function [parent=#table] keys
-- @param table hashtable 要检查的表格
-- @return table#table

--[[--

返回指定表格中的所有键

~~~ lua

local hashtable = {a = 1, b = 2, c = 3}
local keys = table.keys(hashtable)
-- keys = {"a", "b", "c"}

~~~

]]
-- end --

function table.keys(hashtable)
    local keys = {}
    for k, v in pairs(hashtable) do
        keys[#keys + 1] = k
    end
    return keys
end

-- start --

--------------------------------
-- 返回指定表格中的所有值
-- @function [parent=#table] values
-- @param table hashtable 要检查的表格
-- @return table#table

--[[--

返回指定表格中的所有值

~~~ lua

local hashtable = {a = 1, b = 2, c = 3}
local values = table.values(hashtable)
-- values = {1, 2, 3}

~~~

]]
-- end --

function table.values(hashtable)
    local values = {}
    for k, v in pairs(hashtable) do
        values[#values + 1] = v
    end
    return values
end

-- start --

--------------------------------
-- 将来源表格中所有键及其值复制到目标表格对象中，如果存在同名键，则覆盖其值
-- @function [parent=#table] merge
-- @param table dest 目标表格
-- @param table src 来源表格

--[[--

将来源表格中所有键及其值复制到目标表格对象中，如果存在同名键，则覆盖其值

~~~ lua

local dest = {a = 1, b = 2}
local src  = {c = 3, d = 4}
table.merge(dest, src)
-- dest = {a = 1, b = 2, c = 3, d = 4}

~~~

]]
-- end --

function table.merge(dest, src)
    if not src then
        return
    end
    for k, v in pairs(src) do
        dest[k] = v
    end
end

--深度合并
function table.deepMerge(dest, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if not dest[k] then
                dest[k] = {}
            else
                assert(type(dest[k]) == "table", "deepMerge type not same")
            end

            table.deepMerge(dest[k], v)
        else
            dest[k] = v
        end
    end
end

-- 拷贝
function table.copy(src)
    if (type(src) ~= "table") then
        return nil
    end
    local ret = {}
    for i, v in pairs(src) do
        local t = type(v)
        if (t == "table") then
            ret[i] = table.copy(v)
        elseif (t == "thread") then
            ret[i] = v
        elseif (t == "userdata") then
            ret[i] = v
        else
            ret[i] = v
        end
    end
    return ret
end

function table.copyByObj(src, obj)
    local ret = {}
    for k, v in pairs(obj) do
        local t = src[k]
        if t then
            ret[k] = table.copy(t) or t
        end
    end
    return ret
end

-- start --

--------------------------------
-- 往数组中插入一个唯一值，如果重复了return false
-- @function [parent=#table] insertOnly
-- @param table array 要插入的数组表格
-- @param table element 要插入的值
-- @return true/false

--[[--

返回true / false

~~~ lua

local array = {1, 2, 3}
local ok = table.insertOnly(array, 1)
-- ok = false

~~~

]]
-- end --

function table.insertOnly(array, element)
    for _, v in ipairs(array) do
        if v == element then
            return false
        end
    end
    table.insert(array, element)
    return true
end

-- start --

--------------------------------
-- 在目标表格的指定位置插入来源表格，如果没有指定位置则连接两个表格
-- @function [parent=#table] insertto
-- @param table dest 目标表格
-- @param table src 来源表格
-- @param integer begin 插入位置,默认最后

--[[--

在目标表格的指定位置插入来源表格，如果没有指定位置则连接两个表格

~~~ lua

local dest = {1, 2, 3}
local src  = {4, 5, 6}
table.insertto(dest, src)
-- dest = {1, 2, 3, 4, 5, 6}

dest = {1, 2, 3}
table.insertto(dest, src, 5)
-- dest = {1, 2, 3, nil, 4, 5, 6}

~~~

]]
-- end --

function table.insertto(dest, src, begin)
    -- begin = checkint(begin)
    if "number" ~= type(begin) then
        begin = #dest + 1
    elseif begin <= 0 then
        begin = #dest + 1
    end

    local len = #src
    for i = 0, len - 1 do
        dest[i + begin] = src[i + 1]
    end
end

-- 升序
function table.ascFunc(l, r)
    return l < r
end

-- 降序
function table.descFunc(l, r)
    return l > r
end

--- 采用二分查找插入 测试代码 table_test.lua-->TestSortInsert
-- @number t: 源表，必须要有序，不然插入有问题
-- @number v: 插入的对象
-- @number f: 排序sort方法
-- @return pos,newTb 插入位置,新表
-- @usage table.binaryInsert(t, v, sort)
function table.binaryInsert(t, v, f)
    local len = #t -- length
    local left = 1
    local right = len
    while (left <= right) do
        local mid = left + math.floor((right - left) / 2)
        if f(t[mid], v) then
            left = mid + 1
        elseif f(v, t[mid]) then
            right = mid - 1
        else
            return mid, table.insert(t, mid, v)
        end
    end
    return left, table.insert(t, left, v)
end

--- 采用二分查找删除 测试代码 table_test.lua
-- @number t: 源表，必须要有序，不然删除有问题
-- @number v: 删除的对象
-- @number f: 排序sort方法
-- @return pos,newTb 删除位子,新表
-- @usage table.binaryRemove(t, v, sort)
function table.binaryRemove(t, v, f)
    local len = #t -- length
    local left = 1
    local right = len
    while (left <= right) do
        local mid = left + math.floor((right - left) / 2)
        if f(t[mid], v) then
            left = mid + 1
        elseif f(v, t[mid]) then
            right = mid - 1
        else
            return mid, table.remove(t, mid)
        end
    end
    return left, nil -- table.remove(t, left)
end

-- 采用二分查询
-- @number t: 源表，必须要有序
-- @number v: 比较的对象
-- @number f: 排序sort方法
-- @return find, v该位置的值
-- 返回第一个满足条件的值，即如果大到小，返回第一个大的数，反之第一个小的数
-- @usage local find, val = table.binaryFind(t, v, sort)
function table.binaryFind(t, v, f)
    local len = #t -- length
    local left = 1
    local right = len
    local find = 1
    while (left <= right) do
        local mid = left + math.floor((right - left) / 2)
        if f(t[mid], v) then
            left = mid + 1
            find = mid
        elseif f(v, t[mid]) then
            right = mid - 1
        else
            find = mid
            return find, t[find]
        end
    end
    return find, t[find]
end

--- 有序table pop出第一个元素
-- @number number desc
-- @return return desc
-- @usage usage desc
function table.pop(t)
    if not t or not next(t) then
        return nil
    end
    local ret = t[1]
    table.remove(t, 1)
    return ret
end

-- 数组append另外一个数组
function table.append(dest, src)
    dest = dest or {}
    for _, v in ipairs(src) do
        table.insert(dest, v)
    end
    return dest
end

-- start --

--------------------------------
-- 从表格中查找指定值，返回其索引，如果没找到返回 false
-- @function [parent=#table] indexof
-- @param table array 表格
-- @param mixed value 要查找的值
-- @param integer begin 起始索引值
-- @return integer#integer

--[[--

从表格中查找指定值，返回其索引，如果没找到返回 false

~~~ lua

local array = {"a", "b", "c"}
log.Debug("old",table.indexof(array, "b")) -- 输出 2

~~~

]]
-- end --

function table.indexof(array, value, begin)
    for i = begin or 1, #array do
        if array[i] == value then
            return i
        end
    end
    return false
end

-- start --

--------------------------------
-- 从表格中查找指定值，返回其 key，如果没找到返回 nil
-- @function [parent=#table] keyof
-- @param table hashtable 表格
-- @param mixed value 要查找的值
-- @return string#string  该值对应的 key

--[[--

从表格中查找指定值，返回其 key，如果没找到返回 nil

~~~ lua

local hashtable = {name = "dualface", comp = "chukong"}
log.Debug("old",table.keyof(hashtable, "chukong")) -- 输出 comp

~~~

]]
-- end --

function table.keyof(hashtable, value)
    for k, v in pairs(hashtable) do
        if v == value then
            return k
        end
    end
    return nil
end

-- start --

--------------------------------
-- 从表格中删除指定值，返回删除的值的个数
-- @function [parent=#table] removebyvalue
-- @param table array 表格
-- @param mixed value 要删除的值
-- @param boolean removeall 是否删除所有相同的值
-- @return integer#integer

--[[--

从表格中删除指定值，返回删除的值的个数

~~~ lua

local array = {"a", "b", "c", "c"}
log.Debug("old",table.removebyvalue(array, "c", true)) -- 输出 2

~~~

]]
-- end --

function table.removebyvalue(array, value, removeall)
    local c = 0
    for i = #array, 1, -1 do
        if array[i] == value then
            c = c + 1
            table.remove(array, i)
            if not removeall then
                break
            end
        end
    end
    return c
end

-- start --

--------------------------------
-- 对表格中每一个值执行一次指定的函数，并用函数返回值更新表格内容
-- @function [parent=#table] map
-- @param table t 表格
-- @param function fn 函数

--[[--

对表格中每一个值执行一次指定的函数，并用函数返回值更新表格内容

~~~ lua

local t = {name = "dualface", comp = "chukong"}
table.map(t, function(v, k)
    -- 在每一个值前后添加括号
    return "[" .. v .. "]"
end)

-- 输出修改后的表格内容
for k, v in pairs(t) do
    log.Debug("old",k, v)
end

-- 输出
-- name [dualface]
-- comp [chukong]

~~~

fn 参数指定的函数具有两个参数，并且返回一个值。原型如下：

~~~ lua

function map_function(value, key)
    return value
end

~~~

]]
-- end --

function table.map(t, fn)
    for k, v in pairs(t) do
        t[k] = fn(v, k)
    end
end

-- start --

--------------------------------
-- 对表格中每一个值执行一次指定的函数，但不改变表格内容
-- @function [parent=#table] walk
-- @param table t 表格
-- @param function fn 函数

--[[--

对表格中每一个值执行一次指定的函数，但不改变表格内容

~~~ lua

local t = {name = "dualface", comp = "chukong"}
table.walk(t, function(v, k)
    -- 输出每一个值
    log.Debug("old",v)
end)

~~~

fn 参数指定的函数具有两个参数，没有返回值。原型如下：

~~~ lua

function map_function(value, key)

end

~~~

]]
-- end --

function table.walk(t, fn)
    for k, v in pairs(t) do
        fn(v, k)
    end
end

-- start --

--------------------------------
-- 对表格中每一个值执行一次指定的函数，如果该函数返回 false，则对应的值会从表格中删除
-- @function [parent=#table] filter
-- @param table t 表格
-- @param function fn 函数

--[[--

对表格中每一个值执行一次指定的函数，如果该函数返回 false，则对应的值会从表格中删除

~~~ lua

local t = {name = "dualface", comp = "chukong"}
table.filter(t, function(v, k)
    return v ~= "dualface" -- 当值等于 dualface 时过滤掉该值
end)

-- 输出修改后的表格内容
for k, v in pairs(t) do
    log.Debug("old",k, v)
end

-- 输出
-- comp chukong

~~~

fn 参数指定的函数具有两个参数，并且返回一个 boolean 值。原型如下：

~~~ lua

function map_function(value, key)
    return true or false
end

~~~

]]
-- end --

function table.filter(t, fn)
    for k, v in pairs(t) do
        if not fn(v, k) then
            t[k] = nil
        end
    end
end

-- start --

--------------------------------
-- 遍历表格，确保其中的值唯一
-- @function [parent=#table] unique
-- @param table t 表格
-- @param boolean bArray t是否是数组,是数组,t中重复的项被移除后,后续的项会前移
-- @return table#table  包含所有唯一值的新表格

--[[--

遍历表格，确保其中的值唯一

~~~ lua

local t = {"a", "a", "b", "c"} -- 重复的 a 会被过滤掉
local n = table.unique(t)

for k, v in pairs(n) do
    log.Debug("old",v)
end

-- 输出
-- a
-- b
-- c

~~~

]]
-- end --

function table.unique(t, bArray)
    local check = {}
    local n = {}
    local idx = 1
    for k, v in pairs(t) do
        if not check[v] then
            if bArray then
                n[idx] = v
                idx = idx + 1
            else
                n[k] = v
            end
            check[v] = true
        end
    end
    return n
end

--[[
    将一个数组分割成按比例分割成map
    比如: array = { key1, value1, key2, value2 ... }
    那么: ret = { [key1] = value1, [key2] = value2 }
    transfer: 转化函数，可以不用
--]]
function table.arrayToMap(array, transfer)
    local ret = {}
    local num = #array
    assert(num % 2 == 0, "配置表和分割数不对应")
    for i = 1, num, 2 do
        local key = array[i]
        if "function" == type(transfer) then
            key = transfer(key)
        end
        local value = array[i + 1]
        ret[key] = value
    end
    return ret
end

-- 如果key tonumber不为int则不可用
-- map类型转换成list{key,num,key,num}类型数据
-- 如果key是字符串转int
function table.mapToArray(map)
    if not map then
        return {}
    end
    local array = {}
    for k, v in pairs(map) do
        array[#array + 1] = tonumber(k)
        array[#array + 1] = v
    end
    return array
end

-- 数组转set ["a","b","c"]->{[1"a"]=1, ["b"]=2, ["c"]=3}
function table.arrayToSet(array)
    local set = {}
    for i, v in ipairs(array) do
        set[v] = i
    end
    return set
end

--验证某个值是否在该数组中
function table.in_array(value, arr)
    if type(arr) ~= "table" or type(value) == "table" or #arr == 0 then
        return false
    end
    for _, v in ipairs(arr) do
        if value == v then
            return true
        end
    end
    return false
end

-- 和map里面的值比较看是否有存在
function table.in_map_val(value, arr)
    if type(arr) ~= "table" or table.nums(arr) == 0 then
        return false
    end
    for _, v in pairs(arr) do
        if value == v then
            return true
        end
    end
    return false
end

-- 返回经过排序的jsonstr
function table.sort_json(t)
    local depth = 1
    local keys = {}
    for k, _ in pairs(t) do
        keys[#keys + 1] = k
    end
    table.sort(keys)

    local subDepth = 0 --嵌套table层
    local str_arr = {}
    for _, k in ipairs(keys) do
        if #str_arr == 0 then
            str_arr[#str_arr + 1] = "{"
        else
            str_arr[#str_arr + 1] = ","
        end
        local v = t[k]
        str_arr[#str_arr + 1] = '"'
        str_arr[#str_arr + 1] = k
        str_arr[#str_arr + 1] = '":'
        if type(v) == "number" then
            str_arr[#str_arr + 1] = v
        elseif type(v) == "table" then
            local tmpdepth
            str_arr[#str_arr + 1], tmpdepth = table.sort_json(v)
            if tmpdepth > subDepth then
                subDepth = tmpdepth
            end
        elseif type(v) == "string" then
            str_arr[#str_arr + 1] = '"'
            str_arr[#str_arr + 1] = v
            str_arr[#str_arr + 1] = '"'
        else
            assert(false, "The table is Err!")
        end
    end
    depth = depth + subDepth
    assert(depth <= 3, string.format("The table format is Err!"))
    if #str_arr > 0 then
        str_arr[#str_arr + 1] = "}"
        return table.concat(str_arr), depth
    end
    return "{}", depth
end

--------------------------------------------------------------------------------
-- list

--- table.sum list里面的值相加
-- @number list 数组
-- @return total 总和
-- @usage table.sum({100,900}) => 1000
function table.sum(list)
    if #list == 0 then
        return 0
    end
    local sum = 0
    for _, v in ipairs(list) do
        sum = sum + v
    end
    return sum
end

--- table.min 无序list取最小值O(1)
-- @number list 数组
-- @return min 最小值
-- @usage table.min({9,5,10})
function table.min(list)
    local _, min = next(list)
    local minfunc = math.min
    for _, v in ipairs(list) do
        min = minfunc(min, v)
    end
    return min
end

-- 字符串数组转number数组
function table.arrayTonum(strArray)
    local ret = {}
    for _, v in ipairs(strArray) do
        ret[#ret + 1] = tonumber(v)
    end
    return ret
end

-- list end
--------------------------------------------------------------------------------

-- map结构中的值转数组返回
function table.mapValue2Array(map)
    if not map then
        return nil
    end
    local array = {}
    for _, v in pairs(map) do
        array[#array + 1] = v
    end
    return array
end

-- map结构中的键转数字数组返回
function table.mapKey2NumberArray(map)
    if not map then
        return nil
    end
    local array = {}
    for k, _ in pairs(map) do
        array[#array + 1] = tonumber(k)
    end
    return array
end

-- map结构中的键转数字数组并且排除指定key返回
function table.mapKey2NumberExcludeArray(map, key)
    if not map then
        return nil
    end
    local array = {}
    for k, _ in pairs(map) do
        if k ~= key then
            array[#array + 1] = tonumber(k)
        end
    end
    return array
end

---- map转成 id,count的List
function table.mapToReward(map)
    if not map or not next(map) then
        return {}
    end
    local list = {}
    for k, v in pairs(map) do
        list[#list + 1] = {
            id = k,
            count = v
        }
    end
    return list
end

function table.mapToRewardRemoveEmpty(map)
    if not map or not next(map) then
        return {}
    end
    local list = {}
    for k, v in pairs(map) do
        if v > 0 then
            list[#list + 1] = {
                id = k,
                count = v
            }
        end
    end
    return list
end

---- 合并一个数组里的数据到另外一个数据里
--- 一定要有值用，不然就坑了
function table.mergeList(list, toList)
    if not list or not toList or type(list) ~= "table" or type(toList) ~= "table" then
        return
    end
    for _, v in pairs(list) do
        toList[#toList + 1] = v
    end
    return toList
end

function table.mergeArray(array, toArray)
    if not array or not toArray or type(array) ~= "table" or type(toArray) ~= "table" then
        return
    end
    for _, v in ipairs(array) do
        table.insert(toArray, v)
    end
end

----- 从list中通过指定地址段获取需要的那个list
function table.getListByIndex(list, head, tail)
    if not list or head < tail then
        return
    end
    local array = {}
    for i = head, tail do
        array[#array + 1] = list[i]
    end
    return array
end

function table.replacedTable(replacedTable)
    local ret = {}

    local _isSwitched
    local function _next(table, index)
        if _isSwitched then
            local k, v = next(replacedTable, index)
            if rawget(table, k) then -- 原生表有了，跳过
                return _next(table, k)
            else
                return k, v
            end
        else
            local k, v = next(table, index)
            if k ~= nil then
                return k, v
            else
                _isSwitched = true
                return _next(table)
            end
        end
    end

    return setmetatable(
        ret,
        {
            __index = replacedTable,
            __pairs = function()
                _isSwitched = false
                return _next, ret, nil
            end
        }
    )
end

--- 向数组里面每个值都加上同一个数字成为新的一个数组
function table.addNumToList(list, num)
    if not list or type(list) ~= "table" or type(num) ~= "number" then
        return
    end
    local retList = {}
    for k, v in ipairs(list) do
        retList[k] = v + num
    end

    return retList
end

function table.array2map(list)
    local map = {}
    for _, v in ipairs(list) do
        map[v] = true
    end
    return map
end

--- 返回两个Table的交集
function table.getIntersection(tab1, tab2)
    local intersection = {}
    local map2 = table.array2map(tab2)
    for _, v in pairs(tab1) do
        if map2[v] then
            intersection[#intersection + 1] = v
        end
    end
    return intersection
end

--- 返回两个Table的交集
function table.isIntersection(tab1, tab2)
    local map2 = table.array2map(tab2)
    for _, v in pairs(tab1) do
        if map2[v] then
            return true
        end
    end
    return false
end

--- 选择排序 从小到大
function table.selectionSort(arr)
    local index = 0
    local minIndex
    local temp
    for i = 1, #arr - 1 do
        minIndex = i
        for j = i + 1, #arr do
            -- 寻找最小的数
            if arr[j] < arr[minIndex] then
                --  将最小数的索引保存
                minIndex = j
            end
            index = index + 1
        end
        temp = arr[i]
        arr[i] = arr[minIndex]
        arr[minIndex] = temp
    end
    return arr
end

--- 从大到小
function table.selectionReverseSort(arr)
    local index = 0
    local maxIndex
    local temp
    for i = 1, #arr - 1 do
        maxIndex = i
        for j = i + 1, #arr do
            -- 寻找最大的数
            if arr[j] > arr[maxIndex] then
                --  将最小数的索引保存
                maxIndex = j
            end
            index = index + 1
        end
        temp = arr[i]
        arr[i] = arr[maxIndex]
        arr[maxIndex] = temp
    end
    return arr
end

--- 插入排序 从小到大
function table.insertSort(t)
    local preIndex, current
    local index = 0
    for i = 2, #t do
        preIndex = i - 1
        current = t[i]
        while preIndex >= 1 and t[preIndex] > current do
            t[preIndex + 1] = t[preIndex]
            preIndex = preIndex - 1
            index = index + 1
        end
        t[preIndex + 1] = current
    end
    return t
end

--希尔排序
function table.shellSort(t)
    local gap = math.floor(#t / 2)
    local index = 0
    while gap > 0 do
        for i = gap + 1, #t do
            local j = i
            while j > gap and t[j] < t[j - gap] do
                local temp = t[j]
                t[j] = t[j - gap]
                t[j - gap] = temp
                j = j - gap
            end
            index = index + 1
        end
        gap = math.floor(gap / 2)
    end
    return t
end

----冒泡排序
function table.bubbleSort(t)
    local index = 0
    for i = 1, #t - 1 do
        for j = 1, #t - i do
            if t[j] > t[j + 1] then
                t[j], t[j + 1] = t[j + 1], t[j]
                index = index + 1
            end
        end
    end
    return t
end

---table里面含有的某个值全部删除，并返回删除后的新table
function table.delVal(tb, val)
    local new_tb = {}
    for _, v in pairs(tb) do
        if v ~= val then
            new_tb[#new_tb + 1] = v
        end
    end
    return new_tb
end

-- 将数组里的数字全部相加，必须是list并且是数字
function table.sum(tb)
    local sum = 0
    for _, v in ipairs(tb) do
        sum = sum + v
    end
    return sum
end

--- 转化成记录下标得一个新得list
---- 这个是针对{index = true, index2 = true} => {index, index2} 类型
function table.mapTranList(map)
    local list = {}
    for k, v in pairs(map) do
        if v and v == true then
            list[#list + 1] = k
        end
    end
    return list
end

-- 乱序 只支持array
function table.shuffle(t)
    local randomUtil = require("randomUtil")
    -- 乱序
    for index = #t, 1, -1 do
        local change_index = math.floor(randomUtil.random(1, index))
        t[index], t[change_index] = t[change_index], t[index]
    end
end

---- 排序，这里就是一个是需要排序的list，一个是传入的值，根据某个属性情况来排序
--- sort_name 排序的属性名字，可以是"id", "time"各种
--- 这个接口的调用一般是在某个map进行遍历的时候
--- sortList外部调用的时候传进来的需要排序的list，实际返回的值也是sortList不断变化的
---这个为倒序 从大到小的排
function table.sortReverseTable(v, sortList, sort_name)
    local length = #sortList
    ---空表那就直接存
    if length == 0 then
        sortList[#sortList + 1] = v
        return sortList
    end
    -- 这里需要一个空表存放
    for i = 1, length do
        if sortList[i][sort_name] < v[sort_name] then
            table.insert(sortList, i, v)
            return sortList
        end
    end
    --会到这里说明都小于里面的值，那就直接在后面加上去就好了
    sortList[#sortList + 1] = v
    log.Dump("table", sortList, "sortReverseTable sortList")
    return sortList
end

---- 这个接口是用来将数据往数组最前面加的
---- 就用这个 往前插入接口
function table.insertFront(insertData, sortList)
    if #sortList == 0 then
        sortList[#sortList + 1] = insertData
        return sortList
    end
    table.insert(sortList, 1, insertData)
    log.Dump("table", sortList, "insertFront sortList")
    return sortList
end

----从数组里将传入的值删除掉
function table.delValueInList(value, list)
    for i = #list, 1, -1 do
        if list[i] == value then
            table.remove(list, i)
        end
    end
    return list
end

function table.arrayAdd(a, b)
    local c = {}
    local length = math.max(#a, #b)
    for i = 1, length do
        c[i] = (a[i] or 0) + (b[i] or 0)
    end

    return c
end

-- 初始化设定长度的数组
function table.newFillList(length, d)
    if length <= 0 then
        return {}
    end
    local t = {}
    for i = 1, length do
        t[i] = d and table.copy(d) or 0
    end
    return t
end

-- 将数组初始化成map 分割长度2
function table.formatMap(t)
    local ret = {}
    local n = 2
    local totalNum = #t
    assert(totalNum % n == 0, "配置表和分割数不对应")
    -- 默认配置中key不会重复
    for i = 1, totalNum, n do
        local key = t[i]
        local value = t[i + 1]
        ret[key] = value
    end
    return ret
end

-- 过滤数组内重复数据
function table.arrayDeduplication(t)
    local m = {}
    local ret = {}
    for _, v in ipairs(t) do
        if not m[v] then
            table.insert(ret, v)
            m[v] = true
        end
    end
    return ret
end

-- 非重复元素数组
function table.isDeduplicationArray(t, size)
    local r = table.arrayDeduplication(t)
    -- #r ~= #t 重复， #r ~= size 不足
    if #r ~= #t or (size and #r ~= size) then
        return false
    end
    return true
end

function table.equalTable(t1, t2)
    if not t1 or not t2 or type(t1) ~= "table" or type(t2) ~= "table" then
        return false
    end
    if t1 == t2 then
        return true
    end
    for key1, value1 in pairs(t1) do
        local value2 = t2[key1]
        if value2 == nil then
            return false
        end
        if type(value1) == "table" then
            if not table.equalTable(value1, value2) then
                return false
            end
        else
            if value1 ~= value2 then
                return false
            end
        end
    end
    for key2, value2 in pairs(t2) do
        if t1[key2] == nil then
            return false
        end
    end
    return true
end
