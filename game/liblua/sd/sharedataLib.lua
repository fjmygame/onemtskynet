local sharedata = require "sharedata"

local queryCount = 0

local queryRecord = {}

---@class sharedataLib
local sharedataLib = {}

--增加引用计数
function sharedataLib.query(name)
	if not queryRecord[name] then
		queryCount = queryCount + 1
	end
	queryRecord[name] = (queryRecord[name] or 0) + 1
	return sharedata.query(name)
end

--获取查询数量
function sharedataLib.getQueryCount()
	return queryCount, queryRecord
end

function sharedataLib.new(name, v)
	sharedata.new(name, v)
end

function sharedataLib.update(name, v)
	sharedata.update(name, v)
end

function sharedataLib.delete(name)
	sharedata.delete(name)
end

return sharedataLib
