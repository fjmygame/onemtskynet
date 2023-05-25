-- --------------------------------------
-- Create Date:2022-06-08 19:09:05
-- Author  : Happy Su
-- Version : 1.0
-- Filename: serverUtil.lua
-- Introduce  : 服务器管理
-- --------------------------------------
local accountUtil = require("accountUtil")
---@class serverUtil
local serverUtil = BuildUtil("serverUtil")

-- 分区索引
local area_server_num = 50
-- 获取服务器的区域id 0开始
function serverUtil.getAreaIndex(litkid, level)
    local kidIndex = accountUtil.getKidIndex(litkid)

    -- 计算区域用
    local area = math.floor((kidIndex - 1) / area_server_num)

    -- 自动开启运营活动服务器分组由配置修改为：
    -- 进度=1-4，50服一个分组；进度>=5,100服一个分组；进度>=8，200服一个分组
    if not level or level >= 8 then
        area = area - area % 4
    elseif level >= 5 then
        area = area - area % 2
    end

    return area
end

return serverUtil
