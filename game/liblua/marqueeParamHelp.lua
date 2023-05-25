-- --------------------------------------
-- Create Date:2021-11-13 11:00:42
-- Author  : sgys
-- Version : 1.0
-- Filename: marqueeParamHelp.lua
-- Introduce  : 类介绍
-- --------------------------------------

---@class marqueeParamHelp
local _M = BuildOther("marqueeParamHelp")

-- 参数定义
local ParamDef = {
    i18n = "i18n",
    string = "string", -- 纯字符串
    npc = "npc", --npc：英雄／妃子【名称】
    item = "item", -- 道具【名】
    title = "title", -- 称号@性别 packTitleGender(title, gender)
    num = "num", -- 数量【需要缩写】
    percent = "percent", -- 百分比
    time = "time", -- 时间【单位s】
    property = "property", -- 四维属性【名】
    server = "server", -- 区服
    allianceAbbr = "allianceAbbr", -- 联盟简称
    pokerType = "pokerType", -- 扑克牌型
    pid = "pid", -- 活动pid用于跑马灯积分单位
    uid = "uid"
}

_M.ParamDef = ParamDef

-- 组装title@gender
function _M.packTitleGender(title, gender, lordlv)
    return string.safeFormat("%s@%s@%s", tostring(title), tostring(gender or 1), tostring(lordlv or 0))
end

-- 构造
function _M.build(...)
    local parList = {}
    local params = {...}
    local index = 0
    for i = 1, #params, 2 do
        local paramType, paramValue = params[i], params[i + 1]
        index = index + 1
        local key = string.safeFormat("%s_%s", ParamDef[paramType], index)
        parList[key] = paramValue or ""
    end
    return parList
end

function _M.buildByList(paramsList)
    local parList = {}
    local index = 0
    for i = 1, #paramsList, 2 do
        local paramType, paramValue = paramsList[i], paramsList[i + 1]
        index = index + 1
        local key = string.safeFormat("%s_%s", ParamDef[paramType], index)
        parList[key] = paramValue or ""
    end
    return parList
end

return _M
