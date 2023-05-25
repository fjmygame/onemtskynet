-- --------------------------------------
-- Create Date:2020-05-11 09:15:19
-- Author  : Happy Su
-- Version : 1.0
-- Filename: netlog.lua
-- Introduce  : 类介绍
-- --------
-- Last Modified: Thu Mar 16 2023
-- Modified By: Happy Su
-- --------------------------------------
local skynet = require "skynet"
local _M = {}

function _M.udp_log(...)
    skynet.error("udp_log:", os.date("%Y-%m-%d %H:%M:%S"), ...)
end

function _M.LOG_ERROR(...)
    log.Warn("udp", ...)
end

function _M.LOG_WARNING(...)
    log.Warn("udp", ...)
end

return _M
