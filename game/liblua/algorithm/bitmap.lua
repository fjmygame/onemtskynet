---@class bitmap
local bitmap = {}
local length = 31 --每个整数存32位

-- data: {value1,value2,...,valueN}
function bitmap.setBitPos(data, bitPos)
    local nPos = math.ceil(bitPos / length)
    if nPos <= 0 then
        return false
    end

    --实际使用，理论上不会太长，往前填充0
    for i = 1, nPos do
        if not data[i] then
            data[i] = 0
        end
    end

    local left = (bitPos - 1) % length
    data[nPos] = data[nPos] | (1 << left)
    return true
end

function bitmap.clearBitPos(data, bitPos)
    local nPos = math.ceil(bitPos / length)
    if nPos <= 0 then
        return false
    end

    if not data[nPos] then
        return true
    end

    local left = (bitPos - 1) % length
    data[nPos] = data[nPos] & ~(1 << left)
    return true
end

function bitmap.isSetBitPos(data, bitPos)
    local nPos = math.ceil(bitPos / length)
    if nPos <= 0 then
        return false
    end

    if not data[nPos] then
        return false
    end

    local left = (bitPos - 1) % length
    return data[nPos] & (1 << left) ~= 0
end

-- 返回最后一个为1的位
function bitmap.maxBitPos(data)
    local nLastPos = #data
    local nMaxPos = 0
    for nPos = nLastPos, 1, -1 do
        if data[nPos] ~= 0 then
            nMaxPos = nPos
            break
        end
    end

    if nMaxPos <= 0 then
        return 0
    end

    local value = data[nMaxPos]
    local left = 1
    for i = length, 1, -1 do
        if value & (1 << (i - 1)) ~= 0 then
            left = i
            break
        end
    end

    return length * (nMaxPos - 1) + left
end
--

--测试
--[[
local bitPos = 33
local bitPos2 = 64
local data = {}
print("setbit")
bitmap.setBitPos(data,bitPos)
bitmap.setBitPos(data,bitPos2)
for k,v in pairs(data) do
    print("k:"..k.."   v:"..v)
end

print("maxbitpos:"..bitmap.maxBitPos(data))

print("issetbit")
print(bitPos..":"..tostring(bitmap.isSetBitPos(data,bitPos)))
print(bitPos2..":"..tostring(bitmap.isSetBitPos(data,bitPos2)))

print("clearbit")
bitmap.clearBitPos(data,bitPos)
for k,v in pairs(data) do
    print("k:"..k.."   v:"..v)
end

print("if pos<=0")
print(bitmap.setBitPos(data,0))
print(bitmap.isSetBitPos(data,0))
print(bitmap.clearBitPos(data,0))
]] return bitmap
