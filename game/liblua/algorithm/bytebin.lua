-- --------------------------------------
-- Create Date:2021-07-08 17:33:34
-- Author  : lxy
-- Version : 1.0
-- Filename: bytebin.lua
-- Introduce  : 类介绍
-- --------
-- Last Modified: 2021-07-14 09:33:02
-- Modified By: lxy
-- --------------------------------------
--- 多进制调用接口

local bytebin = {}

--- 转2进制
--- length为长度，就是保留多少位，注意，如果保留得长度小于传进来得值转换后得长度
----- 默认就是正规得二进制数据8位
function bytebin.to2bin(value, length)
    if length <= 0 or not length then
        length = 7
    end
    local t = {}
    for i = length, 0, -1 do
        t[#t + 1] = math.floor(value / 2 ^ i)
        value = value % 2 ^ i
    end
    return table.concat(t)
end

return bytebin
