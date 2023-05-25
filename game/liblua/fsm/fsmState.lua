-- --------------------------------------
-- Create Date:2023-03-21 10:01:12
-- Author  : sgys
-- Version : 1.0
-- Filename: fsmState.lua
-- Introduce  : 类介绍
-- --------------------------------------
---@class fsmState
local fsmState = class("fsmState")

function fsmState:ctor(config)
    if config then
        if type(config.enter) == "function" then
            self.enter = config.enter
        end
        if type(config.exit) == "function" then
            self.exit = config.exit
        end

        self.msg = config.msg
    end
end

function fsmState:enter()
end

function fsmState:exit()
end

function fsmState:handleMsg(name, ...)
    if not self.msg or not self.msg[name] then
        return false
    end

    local function xpcall_ret(ok, ...)
        if not ok then
            return false
        else
            return ... or true
        end
    end

    return xpcall_ret(xpcall(self.msg[name], serviceFunctions.exception, ...))
end

return fsmState
