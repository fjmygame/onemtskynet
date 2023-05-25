-- --------------------------------------
-- Create Date:2023-03-21 10:00:58
-- Author  : sgys
-- Version : 1.0
-- Filename: fsmStateMachine.lua
-- Introduce  : 类介绍
-- --------------------------------------
---@class fsmStateMachine
local fsmStateMachine = class("fsmStateMachine")

function fsmStateMachine:ctor(config)
    if config then
        self.state = config.state
        self.event = {}
        for k, v in pairs(self.state) do
            self.event[k] = {}
        end
        self.curState = config.curState

        if config.transition then
            for _, v in pairs(config.transition) do
                self:addTransition(v[1], v[2], v[3])
            end
        end
    else
        self.state = {}
        self.event = {}
        self.curState = nil
    end
end

function fsmStateMachine:addTransition(before, input, after)
    if self.event[before] then
        if self.event[before][input] then
            assert("event already be added")
        else
            self.event[before][input] = after
        end
    end
end

function fsmStateMachine:stateTransition(input, ...)
    assert(self.curState)

    local out = self.event[self.curState][input]
    if out then
        log.Info("sys", string.safeFormat("%s reponse to input:%s, %d-->%d", self.id, input, self.curState, out))
        -- respont to this event
        self.state[self.curState]:exit(...)
        self.curState = out
        self.state[self.curState]:enter(...)
    else
        -- no related event
        log.Info("sys", string.safeFormat("%s no reponse to input:%s, %d-->?", self.id, input, self.curState))
    end
end

function fsmStateMachine:handleMsg(name, ...)
    assert(self.curState)
    local state = self.state[self.curState]

    local function ret(...)
        if not ... then
            log.Info("sys", string.safeFormat("queue:%s state:%d no handler to msg:%s", self.id, self.curState, name))
        end
        return ...
    end

    return ret(state:handleMsg(name, ...))
end
return fsmStateMachine
