-- --------------------------------------
-- Create Date:2023-03-28 12:09:18
-- Author  : Happy Su
-- Version : 1.0
-- Filename: json.lua
-- Introduce  : 类介绍
-- --------------------------------------
local cjson = require("cjson")
---@class json
local json = BuildOther("json")

function json.encode(var)
	local status, result = pcall(cjson.encode, var)
	if status then
		return result
	else
		log.ErrorStack("sys", "json.encode error", result)
	end
end

function json.decode(text)
	local status, result = pcall(cjson.decode, text)
	if status then
		return result
	else
		log.ErrorStack("sys", "json.encode error", result)
	end
end

return json
