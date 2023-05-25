-- --------------------------------------
-- Create Date:2023-01-07 14:46:21
-- Author  : tangheng
-- Version : 1.0
-- Filename: recordListMgr.lua
-- Introduce  : 类介绍
-- --------------------------------------
local json = require("json")
local skynetQueue = require "skynet.queue"
---@class recordListMgr
local _M = class("recordListMgr")

function _M:insertRecord(rid, uid, data)
    assert(false)
end

function _M:deleteRecord(rid)
    assert(false)
end

function _M:deleteMultiRecord(rids)
    assert(false)
end

function _M:queryRecords(uid)
    assert(false)
end

function _M:deleteAll()
    assert(false)
end

function _M:loadAll()
    assert(false)
end
---------------------------------------

function _M:ctor(limit, autoId)
    self.limit = limit
    self.autoId = autoId
    self.uidMap = {}

    self.lock_tb = {}
    self.lock_counter = {}
end

function _M:genId()
    self.autoId = self.autoId + 1
    return self.autoId
end

function _M:addRecord(uid, data)
    if self._relaseTag then
        return
    end

    local rid = self:genId()
    data.rid = rid
    local uData = self.uidMap[uid]
    if uData then
        local limit = self.limit
        local map = uData.map
        local list = uData.list
        list[#list + 1] = rid
        map[rid] = data
        if #list > limit then
            local removeId = list[1]
            table.remove(list, 1)
            self:deleteRecord(removeId)
            map[removeId] = nil
        end
    end

    self:insertRecord(rid, uid, data)
end

function _M:preLoadAll()
    if self._relaseTag then
        return
    end
    local uidMap = {}
    -- actid, groupid, id, uid, data
    local records = self:loadAll()
    for _, v in ipairs(records) do
        local uid = v.uid
        local rid = v.id
        local uData = uidMap[uid]
        if not uData then
            uData = self:_getDefultPlayer()
            uidMap[uid] = uData
        end
        local map = uData.map
        local list = uData.list
        list[#list + 1] = rid
        map[rid] = json.decode(v.data)
    end
    self.uidMap = uidMap
end

function _M:preLoadRecords(uid)
    if self._relaseTag then
        return
    end

    local uData = self.uidMap[uid]
    if uData then
        return
    end

    self:lock(uid, _M._loadRecords, self, uid)
end

function _M:_getDefultPlayer()
    return {
        map = {},
        list = {}
    }
end

function _M:_loadRecords(uid)
    if self._relaseTag then
        return self:_getDefultPlayer()
    end

    local uData = self.uidMap[uid]
    if uData then
        return uData
    end

    local dbDatas = self:queryRecords(uid)
    if not dbDatas then
        return self:_getDefultPlayer()
    end

    if self._relaseTag then
        return self:_getDefultPlayer()
    end
    local data = self:buildData(dbDatas)
    self.uidMap[uid] = data
    return data
end

function _M:buildData(dbDatas)
    local data = self:_getDefultPlayer()
    local map = data.map
    local list = data.list
    local limit = self.limit

    local rmIds = {}
    for _, dbData in ipairs(dbDatas) do
        local rid = dbData.id
        list[#list + 1] = rid
        map[rid] = json.decode(dbData.data)
        if #list > limit then
            local removeId = list[1]
            table.remove(list, 1)
            map[removeId] = nil
            rmIds[#rmIds + 1] = removeId
        end
    end
    if next(rmIds) then
        self:deleteMultiRecord(rmIds)
    end

    return {
        map = map,
        list = list
    }
end

function _M:_genRecordList(data, startId)
    local list = data.list

    if not startId then
        startId = list[#list]
    end

    local startIndex
    for index = #list, 1, -1 do
        if list[index] == startId then
            startIndex = index
        end
    end

    local map = data.map
    local ret = {}
    if startIndex then
        local endIndex = math.max(startIndex - 20, 1)
        for index = startIndex, endIndex, -1 do
            local rid = list[index]
            if rid then
                local record = map[rid]
                if record then
                    ret[#ret + 1] = record
                end
            end
        end
    end

    return ret, #list
end

function _M:getRecords(uid, startId)
    if self._relaseTag then
        return {}
    end

    local uidMap = self.uidMap
    local data = uidMap[uid]
    if data then
        return self:_genRecordList(data, startId)
    end

    data = self:lock(uid, _M._loadRecords, self, uid)
    return self:_genRecordList(data, startId)
end

function _M:releaseRecords(uid)
    self.uidMap[uid] = nil
end

function _M:clean()
    self._relaseTag = true
    self:deleteAll()
    self.uidMap = nil
end

------------------------------------------------------------------------
-- 锁
function _M:lock(key, func, ...)
    local tb = self.lock_tb
    local counter = self.lock_counter
    if not tb[key] then
        tb[key] = skynetQueue()
        counter[key] = 1
    else
        counter[key] = counter[key] + 1
    end
    local cs = tb[key]
    return self:procssLockRet(key, xpcall(cs, debug.traceback, func, ...))
end

-- 处理cs调用返回
function _M:procssLockRet(key, bok, err, ...)
    self:unlock(key)
    if bok then
        return err, ...
    else
        log.Error("sys", "csUtil.procssLockRet", err, key)
    end
end

-- 删除cs
function _M:unlock(key)
    local counter = self.lock_counter
    counter[key] = counter[key] - 1
    if counter[key] <= 0 then
        self.lock_tb[key] = nil
    end
end

return _M
