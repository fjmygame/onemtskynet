-- --------------------------------------
-- Create Date:2022-07-07 15:03:43
-- Author  : sgys
-- Version : 1.0
-- Filename: nameUtil.lua
-- Introduce  : 名字验证
-- --------------------------------------

---@type shieldwordsUtil
local shieldwordsUtil = require("shieldwordsUtil")
---@class nameUtil
local _M = BuildUtil("nameUtil")

function _M.check(name, minLen, maxLen)
    local old_name = name
    -- 先反转空格
    name = string.reverseBlank(name)
    -- 去掉左右空格
    name = string.trim(name)
    local curlen = utf8.len(name)
    if not curlen then
        log.Error("sys", "name check err:", old_name, name, utf8.len(old_name), curlen)
        return gErrDef.Err_NICKNAME_SENSITIVE_CHARACTER
    end

    if curlen > maxLen or curlen < minLen then
        return gErrDef.Err_NAME_LEN_ERR
    end
    -- -- 不能包含中文
    -- if string.isChineseContent(name) then
    --     return gErrDef.Err_NICKNAME_CONTAIN_CHINESE
    -- end
    --检测是否包含敏感字符
    if shieldwordsUtil:checkName(name) then
        return gErrDef.Err_NICKNAME_SENSITIVE_CHARACTER
    end
    --昵称不包含emoji和非法字符
    if serviceFunctions.hasIllegalityWords(name) then
        return gErrDef.Err_NICKNAME_IIIEGAL_CHARACTER
    end
    name = string.changeBlank(name)
    return gErrDef.Err_None, name
end

return _M
