-- --------------------------------------
-- Create Date : 2023-05-27 03:12:28
-- Author      : LHS
-- Version     : 1.0
-- Filename    : confAPI.lua
-- Introduce   : 服务器配置相关接口获取
-- --------------------------------------
---@class confAPI
local confAPI = BuildAPI("confAPI")
local sharedataLib = require "game.liblua.sd.sharedataLib"

--------------------------------配置key START------------------------------
local SHAREDATA_KEY_CFG = {

}
--------------------------------配置key END------------------------------

local sharedataRef = CreateBlankTable(confAPI, "sharedataRef")

local function getConf(key, nodeId)
    local ret = sharedataRef[key]
    if not ret then
        ret = sharedataLib.query(key)
        sharedataRef[key] = ret
    end

    if nodeId then
        for _, v in pairs(ret) do
            if tonumber(nodeId) == v.nodeId then
                return v
            end
        end
    else
        return ret
    end
end

function confAPI.initAll()
    for _, value in pairs(SHAREDATA_KEY_CFG) do
        getConf(value)
    end
end

return confAPI
