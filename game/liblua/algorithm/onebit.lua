-- @Author: sgys
-- @Date:   2020-08-04 22:14:56
-- @Last Modified by:   sgys
-- @Last Modified time: 2020-08-04 22:17:03
-- @Desc:   32位整数位运算

---@class onebit
local onebit = {}

function onebit.setOn(val, index)
    return val | (1 << index)
end

function onebit.setOff(val, index)
    return val & (0xffffff ~(1<<index))
end

function onebit.isOn(val, index)
    return val & (1 << index) > 0
end


return onebit