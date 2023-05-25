-- --------------------------------------
-- Create Date:2020-07-24 17:35:17
-- Author  : Happy Su
-- Version : 1.0
-- Filename: elasticSearchUserLib.lua
-- Introduce  : 类介绍
-- --------
-- Last Modified: Thu Mar 16 2023
-- Modified By: Happy Su
-- --------------------------------------
local elasticSearchLib = require("es.elasticSearchLib")

local elasticSearchUserLib = BuildOther("elasticSearchUserLib")
local pre = "user"

function elasticSearchUserLib.set(key, data)
	return elasticSearchLib.set(pre, key, data)
end

-- 局部更新
function elasticSearchUserLib.update(key, data)
	return elasticSearchLib.update(pre, key, data)
end

function elasticSearchUserLib.get(key)
	return elasticSearchLib.get(pre, key)
end

function elasticSearchUserLib.del(key)
	return elasticSearchLib.del(pre, key)
end

-- 通过字符串全文匹配
function elasticSearchUserLib.queryString(str)
	return elasticSearchLib.queryString(pre, str)
end

-- 键值模糊匹配
-- key需要加上.keyword  例如: query("nick", "XX")->query("nick.keyword", "XX")
function elasticSearchUserLib.query(key, value)
	return elasticSearchLib.query(pre, key, value)
end

--[[
condtions = {
	{
		key = key,			-- 字段名
		value = xx,			-- 值
		wildcard = true, 	-- 是否通配符匹配
	},
}
]]
-- key需要加上.keyword  例如: "nick", "XX"->"nick.keyword", "XX"
function elasticSearchUserLib.multiQuery(queryfmt)
	return elasticSearchLib.multiQuery(pre, queryfmt)
end

-- 翻页
function elasticSearchUserLib.scroll(scroll_id)
	return elasticSearchLib.scroll(scroll_id)
end

return elasticSearchUserLib
