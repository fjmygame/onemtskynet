--------------------------------------
-- Author: szk
-- Date: 2019-01-23 14:40:22
-- Des: elasticSearchLib es搜索库
--------------------------------------
local httpc = require "http.httpc"
local json = require("json")
local es_host = esConf and esConf.host
local es_url = esConf and esConf.url

local function initConf()
	local confAPI = require "confAPI"
	local esConf = confAPI.getESConf()
	es_host = esConf.host
	es_url = esConf.url
end

local function getHost()
	if not es_host then
		initConf()
	end

	return es_host
end

local function getUrl()
	if not es_url then
		initConf()
	end
	return es_url
end

local elasticSearchLib = BuildOther("elasticSearchLib")
local default_size = 20

local function xpcall_http(msgType, ...)
	if dbconf.DEBUG and dbconf.bDisableEs then
		return
	end
	local bok, status, body = xpcall(httpc.request, debug.traceback, msgType, ...)
	if not bok then
		log.Error("elastic", "httpc.request err:", tostring(status))
		return bok
	end
	status = tostring(status)
	local isSuccess = (status == "200" or status == "201")
	if not isSuccess then
		log.Dump("elastic", {msgType, status, body}, "elasticSearchLib.result")
	end
	return isSuccess, body
end

local function httpPost(url, content)
	-- if not esConf then return false end
	local header = {
		["content-type"] = "application/json"
	}
	return xpcall_http("POST", getHost(), url, {}, header, content)
end

local function httpGet(url)
	-- if not esConf then return false end
	return xpcall_http("GET", getHost(), url, {}, nil)
end

local function httpDel(url)
	-- if not esConf then return false end
	return xpcall_http("DELETE", getHost(), url)
end

local function getSourceData(result)
	local data = result._source
	data.id = result._id
	return data
end

function elasticSearchLib.set(pre, key, data)
	if dbconf.DEBUG and dbconf.bDisableEs then
		return
	end

	local url = string.safeFormat("%s_%s/log/%s", getUrl(), pre, key)
	local ok, body = httpPost(url, json.encode(data))
	log.Debug("elastic", "elasticSearchLib.set.ok", ok, key)
	log.Dump("elastic", body, "elasticSearchLib.set.body")
	return ok
end

-- 局部更新
function elasticSearchLib.update(pre, key, data)
	if dbconf.DEBUG and dbconf.bDisableEs then
		return
	end
	local url = string.safeFormat("%s_%s/log/%s/_update", getUrl(), pre, key)
	local content = {
		doc = data
	}
	local ok, body = httpPost(url, json.encode(content))
	log.Debug("elastic", "elasticSearchLib.update.ok", ok, key)
	log.Dump("elastic", body, "elasticSearchLib.update.body")
	return ok
end

function elasticSearchLib.get(pre, key)
	local url = string.safeFormat("%s_%s/log/%s", getUrl(), pre, key)
	local ok, body = httpGet(url)
	if ok then
		local data = json.decode(body)
		if data.found then
			return getSourceData(data)
		end
	end
end

function elasticSearchLib.del(pre, key)
	local url = string.safeFormat("%s_%s/log/%s", getUrl(), pre, key)
	local ok, _ = httpDel(url)
	return ok
end

-- 通过字符串全文匹配
function elasticSearchLib.queryString(pre, str)
	local url = string.safeFormat("%s_%s/log/_search?q=*%s*", getUrl(), pre, str)
	local ok, body = httpGet(url)
	local ret = {}
	if ok then
		local data = json.decode(body)
		for i, v in ipairs(data.hits.hits) do
			table.insert(ret, getSourceData(v))
		end
	end
	return ret
end

-- 键值模糊匹配
-- key需要加上.keyword  例如: query("nick", "XX")->query("nick.keyword", "XX")
function elasticSearchLib.query(pre, key, value)
	local content = {
		query = {
			wildcard = {
				[key] = string.safeFormat("*%s*", value)
			}
		},
		size = default_size
	}
	local url = string.safeFormat("%s_%s/log/_search?scroll=10m", getUrl(), pre)
	local ok, body = httpPost(url, json.encode(content))
	local ret, scroll_id, total = {}, nil, 0
	if ok then
		local data = json.decode(body)
		for i, v in ipairs(data.hits.hits) do
			table.insert(ret, getSourceData(v))
		end

		total = data.hits.total
		if type(total) == "table" then
			total = total.value
		end
		if total > table.nums(ret) then
			scroll_id = data._scroll_id
		end
	end
	return ret, scroll_id, total
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
function elasticSearchLib.multiQuery(pre, queryfmt)
	local content = {
		query = queryfmt,
		size = default_size
	}
	local url = string.safeFormat("%s_%s/log/_search?scroll=10m", getUrl(), pre)
	local ok, body = httpPost(url, json.encode(content))
	local ret, scroll_id, total = {}, nil, 0
	if ok then
		local data = json.decode(body)
		for i, v in ipairs(data.hits.hits) do
			table.insert(ret, getSourceData(v))
		end

		total = data.hits.total
		if type(total) == "table" then
			total = total.value
		end
		if total > table.nums(ret) then
			scroll_id = data._scroll_id
		end
	end
	return ret, scroll_id, total
end

-- 翻页
function elasticSearchLib.scroll(scroll_id)
	local url = string.safeFormat("_search/scroll?scroll=1m&scroll_id=%s", scroll_id)
	local ok, body = httpGet(url)
	local ret = {}
	if ok then
		local data = json.decode(body)
		for i, v in ipairs(data.hits.hits) do
			table.insert(ret, getSourceData(v))
		end
	end
	return ret
end

return elasticSearchLib
