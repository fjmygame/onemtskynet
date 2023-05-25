-- --------------------------------------
-- Create Date:2019-09-04 10:53:16
-- Author  : Happy Su
-- Version : 1.0
-- Filename: conncommon.lua
-- Introduce  : 类介绍
-- --------------------------------------
local conncommon = {}

conncommon.cmd_size = 12

-- UDP协议cmd
conncommon.eConnCmd = {
    eConnect_req = 1,       -- 发起连接
    eConnect_ret = 2,       -- 连接返回
    eDisconnect = 3,    -- 断开
    eData = 4,        -- 消息包
    eReconnect_req = 5, -- 重连请求
    eReconnect_ret = 6, -- 重连返回
}

conncommon.eDisconnectType = {
    normal = 0, -- 默认值
    timeout = 1, -- 超时
    unfoundcon = 2, -- 连接找不到
    fromchange = 3, -- ip/port不匹配
    linkmax = 4, -- 连接数达到上限
    errkey = 5, -- 错误的秘钥
}

return conncommon