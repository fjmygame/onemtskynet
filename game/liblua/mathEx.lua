-- --------------------------------------
-- Create Date:2023-04-18 15:29:17
-- Author  : sgys
-- Version : 1.0
-- Filename: mathEx.lua
-- Introduce  : math扩展
-- --------------------------------------

--[[
    四舍五入
    @param num 整数
    @param pos 保留小数位
--]]
function math.rounding(num, pos)
    if "number" ~= type(num) or "number" ~= type(pos) then
        return num
    end

    pos = pos or 0
    if pos < 0 then
        return num
    end

    local n = 10 ^ (-pos) / 2
    if num < 0 then
        n = -n
    end

    num = num + n
    if pos == 0 then
        num = math.floor(num)
    else
        num = tonumber(string.format("%." .. pos .. "f", num))
    end
    return num
end

-- 是否是小数
function math.isDecimal(num)
    if string.match(num, "%d+%.%d+") then
        return true
    end

    return false
end

-- 精度计算
function math.rightNum(num)
    if num > 0 then
        return num + 0.000001
    elseif num < 0 then
        return num - 0.000001
    end
    return num
end

-- 整个数组都取整
function math.floorArray(arr)
    for i = 1, #arr do
        arr[i] = math.gfloor(arr[i])
    end
    return arr
end

-- 游戏内向下取整
function math.gfloor(value)
    if not value or ("number" ~= type(value)) then
        return 0
    end
    return math.floor(value + 0.0000001)
end

-- 游戏内向上取整
function math.gceil(value)
    if not value or ("number" ~= type(value)) then
        return 0
    end

    return math.ceil(value - 0.0000001)
end

--- 保留小数后num位   num>0

function math.decimal(val, num)
    if not val or ("number" ~= type(val)) then
        log.Warn("sys", "math.decimal val err")
        return
    end
    if num <= 0 then
        return
    end
    ---精确到2位，需要先算到第三位
    local accNum = num + 1
    local accVal = val * 10 ^ accNum
    --- 四舍五入完再继续除以10的num次方，就是真正要的值了
    local ret_val = math.floor(accVal / 10) / 10 ^ num
    return ret_val
end
