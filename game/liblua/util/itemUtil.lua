-- --------------------------------------
-- Create Date:2021-04-28 16:46:04
-- Author  : sgys
-- Version : 1.0
-- Filename: itemUtil.lua
-- Introduce  : 物品相关 物品: {id=1001, count=999} 游戏内统一格式
-- --------
-- Last Modified: Mon Dec 19 2022
-- Modified By: tangheng
-- --------------------------------------
---@class itemUtil
local itemUtil = BuildUtil("itemUtil")

--- 合并两个物品表
-- @src 被合并的表
-- @dst 合并后的表
-- @return
-- @usage 合并物品表
function itemUtil.merge(src, dst)
    if "table" ~= type(src) or "table" ~= type(dst) then
        return false
    end

    for _, vSrc in ipairs(src) do
        local isExist = false
        for _, vDst in ipairs(dst) do
            if (vDst.id == vSrc.id and vDst.extraId == vSrc.extraId) then
                vDst.count = vDst.count + vSrc.count
                isExist = true
                break
            end
        end

        if isExist == false and vSrc.count > 0 then
            table.insert(dst, {id = vSrc.id, count = vSrc.count, extraId = vSrc.extraId})
        end
    end
    return true
end

-- 合并相同id
function itemUtil.mergeSameId(src)
    local dst = {}
    itemUtil.merge(src, dst)
    return dst
end

-- 物品组增加一个
function itemUtil.push(src, id, count, extraId)
    if "table" ~= type(src) or not id or not count then
        return false
    end
    for _, item in ipairs(src) do
        if item.id == id and item.extraId == extraId then
            item.count = item.count + count
            return true
        end
    end
    -- 没有相同id，追加一个
    table.insert(src, {id = id, count = count, extraId = extraId})
    return true
end

-- 物品统一乘一个数
function itemUtil.mutl(src, num)
    for _, v in ipairs(src) do
        v.count = v.count * num
    end
end

-- 物品gfloor[如果由客户端发来的物品需要调用这个]
function itemUtil.gfloor(src)
    for _, v in ipairs(src) do
        v.count = math.gfloor(v.count)
    end
end

-- 移除指定id的物品
function itemUtil.remove(src, id)
    if "table" ~= type(src) or not id then
        return false
    end
    local index
    for i, item in ipairs(src) do
        if item.id == id then
            index = i
            break
        end
    end
    if index then
        table.remove(src, index)
    end
end

-- 两个物品集比较，一样返回true，不一样返回false
function itemUtil.compare(src, dst, key, value)
    key = key or "id"
    value = value or "count"
    local srcmap = {}
    for _, item in ipairs(src) do
        srcmap[item[key]] = item[value]
    end
    for _, item in ipairs(dst) do
        if item[value] ~= srcmap[item[key]] then
            return false
        end
        -- 比较过的移除掉
        srcmap[item[key]] = nil
    end
    -- 全比较过了，src如果还有东西也是不一致的
    if next(srcmap) then
        return false
    end
    return true
end

------------------------ 物品map整合 ------------------------
-- 下面几个接口一起用
function itemUtil.mapPush(result, id, count, extraId)
    if not extraId then
        result[id] = (result[id] or 0) + count
    else
        if not result[id] then
            result[id] = {}
            result[id][extraId] = count
        else
            local info = result[id]
            info[extraId] = (info[extraId] or 0) + count
        end
    end
end

function itemUtil.mapPushItem(result, items)
    for _, v in ipairs(items) do
        itemUtil.mapPush(result, v.id, v.count, v.extraId)
    end
end

-- 最终转为items格式 [0不显示]
function itemUtil.mapResult(result)
    if not result or not next(result) then
        return {}
    end

    local ret = {}
    for id, v in pairs(result) do
        if type(v) == "table" then
            for extraId, count in pairs(v) do
                if count ~= 0 then
                    ret[#ret + 1] = {id = id, count = count, extraId = extraId}
                end
            end
        else
            if v ~= 0 then
                ret[#ret + 1] = {id = id, count = v}
            end
        end
    end
    return ret
end

-- 道具数据转成字符串为key的map格式
function itemUtil.toStrKeyMap(items)
    if not items or not next(items) then
        return {}
    end
    local ret = {}
    for _, v in ipairs(items) do
        local id, count = v.id, v.count
        local idstr = tostring(id)
        if not ret[idstr] then
            ret[idstr] = count
        else
            ret[idstr] = ret[idstr] + count
        end
    end
    return ret
end

------------------------ 物品map整合end ------------------------

return itemUtil
