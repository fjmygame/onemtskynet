-- --------------------------------------
-- Create Date:2023-03-16 11:28:40
-- Author  : Happy Su
-- Version : 1.0
-- Filename: sharedefinit.lua
-- Introduce  : 类介绍
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
