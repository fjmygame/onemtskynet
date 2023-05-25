-- --------------------------------------
-- Create Date:2020-07-27 17:26:15
-- Author  : Happy Su
-- Version : 1.0
-- Filename: elasticSearchAllianceLib.lua
-- Introduce  : 类介绍
-- --------
-- Last Modified: Thu Mar 16 2023
-- Modified By: Happy Su
-- --------------------------------------

local elasticSearchLib = require("es.elasticSearchLib")

local elasticSearchAllianceLib = BuildOther("elasticSearchAllianceLib")
local pre = "alliance"

function elasticSearchAllianceLib.set(key, data)
	return elasticSearchLib.set(pre, key, data)
end

-- 局部更新
function elasticSearchAllianceLib.update(key, data)
	return elasticSearchLib.update(pre, key, data)
end

function elasticSearchAllianceLib.get(key)
	return elasticSearchLib.get(pre, key)
end

function elasticSearchAllianceLib.del(key)
	return elasticSearchLib.del(pre, key)
end

-- 通过字符串全文匹配
function elasticSearchAllianceLib.queryString(str)
	return elasticSearchLib.queryString(pre, str)
end

-- 键值模糊匹配
-- key需要加上.keyword  例如: query("nick", "XX")->query("nick.keyword", "XX")
function elasticSearchAllianceLib.query(key, value)
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
function elasticSearchAllianceLib.multiQuery(queryfmt)
	return elasticSearchLib.multiQuery(pre, queryfmt)
end

-- 翻页
function elasticSearchAllianceLib.scroll(scroll_id)
	return elasticSearchLib.scroll(scroll_id)
end

return elasticSearchAllianceLib
