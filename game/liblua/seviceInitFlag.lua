--------------------------------------------------------------------------------
-- 文件: seviceInitFlag.lua
-- 作者: zkb
-- 时间: 2021-02-01 17:50:35
-- 描述: 服务用的initFlag
--------------------------------------------------------------------------------
local _M = BuildOther("seviceInitFlag")

local mapFlag = CreateBlankTable(_M, "mapFlag")

function _M.initFlag(uid)
    mapFlag[uid] = true
end

function _M.cleanFlag(uid)
    mapFlag[uid] = nil
end

function _M.isInit(uid)
    return mapFlag[uid]
end

return _M
