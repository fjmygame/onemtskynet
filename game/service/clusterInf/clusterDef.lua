-- --------------------------------------
-- Create Date:2020-12-07 19:22:49
-- Author  : Happy Su
-- Version : 1.0
-- Filename: clusterDef.lua
-- Introduce  : 类介绍
-- --------
-- Last Modified: 2021-05-20 10:12:29
-- Modified By: sgys
-- --------------------------------------

---@class clusterDef
local clusterDef = {
    cluster_register_seconds = 5, -- 节点注册时间
    cluster_expire_seconds = 15, -- 节点过期时间
    close_step = {
        step_pre = 1, -- 关服步骤一（登录服关闭登录、游戏服踢人）
        step_close = 2 -- 二 （关闭节点）
    }
}

return clusterDef
