-- --------------------------------------
-- Create Date:2021-05-31 15:44:48
-- Author  : sgys
-- Version : 1.0
-- Filename: constellationUtil.lua
-- Introduce  : 星座相关
-- --------
-- Last Modified: Thu Mar 16 2023
-- Modified By: Happy Su
-- --------------------------------------

--[[

--------- (1)20 ---------- (2)19 --------- (3)21 --------- (4)20 --------- (5)21 --------- (6)22 -------- (7)23 ---------- (8)23 --------- (9)23 -------- (10)24 --------- (11)23 -------- (12)22 ----------

--12.摩羯座-- | ---1.水瓶座--- | ---2.双鱼座--- | ---3.白羊座--- | ---4.金牛座--- | ---5.双子座--- | ---6.巨蟹座--- | ---7.狮子座--- | ---8.处女座--- | ---9.天秤座--- | ---10.天蝎座--- | ---11.射手座--- | ---12.摩羯座---

------- 本系统统一使用每月21号作为星座划分界限，如下
---------- (1)21 --------- (2)21 --------- (3)21 --------- (4)21 --------- (5)21 --------- (6)21 -------- (7)21 ---------- (8)21--------- (9)21 -------- (10)21 --------- (11)21 -------- (12)21 ----------

--12.摩羯座-- | ---1.水瓶座--- | ---2.双鱼座--- | ---3.白羊座--- | ---4.金牛座--- | ---5.双子座--- | ---6.巨蟹座--- | ---7.狮子座--- | ---8.处女座--- | ---9.天秤座--- | ---10.天蝎座--- | ---11.射手座--- | ---12.摩羯座---


]]
local staticSettingltInst = require("staticSettingltInst")
---@class constellationUtil
local _M = BuildUtil("constellationUtil")

-- 获取指定时间对应的星座id
function _M.getConstellationId(time)
    time = time or timeUtil.systemTime()
    local day = tonumber(os.date("%d", time))
    local month = tonumber(os.date("%m", time))
    local range = staticSettingltInst:getInt(gGlobalKey.Constellation)
    local val = day < range and month - 1 or month
    if val == 0 then
        val = 12
    end
    return val
end

return _M
