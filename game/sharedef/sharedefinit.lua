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

local function load_file(filename)
    sharetable.loadfile(string.safeFormat("%s%s", cur_path, filename))
end

local function query_file(filename)
    return sharetable.query(string.safeFormat("%s%s", cur_path, filename))
end

local function query_files(filenameList)
    return sharetable.queryall(filenameList)
end

function _M.load()
    load_file("errDef.lua")
end

function _M.query()
    ---@type gErrDef
    local filenameList = {
        "errDef.lua"
    }
    local all = query_files(filenameList)
    -- todo lhs
    -- gErrDef = all[]
    ---@type logDef
    -- gLogDef = query_file("logDef.lua")
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
