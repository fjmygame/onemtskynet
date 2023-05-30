-- --------------------------------------
-- Create Date : 2023-05-24 05:42:22
-- Author      : LHS
-- Version     : 1.0
-- Filename    : sharedefinit.lua
-- Introduce   : <<description>>
-- --------------------------------------
local sharetable = require "skynet.sharetable"

local _M = {}

local cur_path = "./game/sharedef/"
local shareDefFileNameList = {
    cur_path .. "errDef.lua",
    cur_path .. "eventNameDef.lua",
    cur_path .. "logDef.lua"
}

function _M.load()
    for _, filename in ipairs(shareDefFileNameList) do
        sharetable.loadfile(filename)
    end
end

function _M.query()
    local queryResult = sharetable.queryall(shareDefFileNameList)
    ---@type gErrDef
    gErrDef = queryResult[cur_path .. "errDef.lua"]
    ---@type logDef
    gLogDef = queryResult[cur_path .. "logDef.lua"]
    ---@type eventNameDef
    gEventName = queryResult[cur_path .. "eventNameDef.lua"]
end

setmetatable(
    _M,
    {
        __call = function(_, ...)
            return _M.query()
        end
    }
)

return _M
