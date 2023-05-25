--------------------------------------------------------------------------------
-- 文件: serviceUtil.lua
-- 作者: zkb
-- 时间: 2021-02-04 20:36:23
-- 描述: 世界工具
--------------------------------------------------------------------------------
local mfloor = math.floor
local _M = BuildUtil("serviceUtil")

function _M.copyId2Str(copyId)
    local copyIndex = copyId % 100
    local temp = mfloor(copyId / 100)
    local mapIndex = temp % 1000
    local sectionId = mfloor(temp / 1000)
    return sectionId, mapIndex, copyIndex
end

return _M
