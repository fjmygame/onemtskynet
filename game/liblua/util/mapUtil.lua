-- --------------------------------------
-- Create Date:2023-04-18 15:45:39
-- Author  : sgys
-- Version : 1.0
-- Filename: mapUtil.lua
-- Introduce  : 类介绍
-- --------------------------------------

---@class mapUtil
local _M = BuildUtil("mapUtil")

--------------------------------------------------------------------------------
-- 内存用map,存储用array [arrayToMap,setId]组合使用
--- arrayToMap 数组转map
-- @table map
-- @table array
-- @usage arrayToMap(map, src)
function _M.arrayToMap(map, array)
    if not array then
        return map
    end

    for _, id in ipairs(array) do
        map[id] = true
    end
    return map
end

function _M.setId(map, array, id)
    if map[id] then
        return false
    end
    map[id] = true
    table.insert(array, id)
end

return _M
