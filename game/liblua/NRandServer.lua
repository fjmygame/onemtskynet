-- --------------------------------------
-- Create Date:2022-08-05 15:11:18
-- Author  : Happy Su
-- Version : 1.0
-- Filename: NRandServer.lua
-- Introduce  : 伪随机库使用
-- --------------------------------------

local mathS = require "mathS"
local NRand = class("NRandServer")

function NRand:ctor()
    self.seed = 65536
    self.times = 0
end

function NRand:SetSeed(seed)
    self.seed = seed
end

function NRand:Random(max)
    local seed, val = mathS.nRandom(self.seed, max)
    self.seed = seed
    self.times = self.times + 1
    return val
end

return NRand
