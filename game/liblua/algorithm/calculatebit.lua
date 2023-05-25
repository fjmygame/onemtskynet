-- --------------------------------------
-- Create Date:2021-07-13 17:01:33
-- Author  : lxy
-- Version : 1.0
-- Filename: calculatebit.lua
-- Introduce  : 类介绍
-- --------
-- Last Modified: 2021-07-14 09:32:21
-- Modified By: lxy
-- --------------------------------------

local _M = class("calculatebit")

local _perLen
local _mask = 0
function _M:init(perLen)
    _perLen = perLen
    for i = 1, perLen do
        _mask = _mask + 1 << i
    end
end

function _M:getBit(data, bit_index)
    local moveLen = _perLen * (bit_index - 1)
    local value = data >> moveLen & _mask
    return value
end

function _M:setBit(data, value, bit_index)
    local moveLen = _perLen * (bit_index - 1)
    data = data & (0xffffff ~ (_mask << moveLen)) | (value << moveLen)
    return data
end

return _M
