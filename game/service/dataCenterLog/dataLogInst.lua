-- --------------------------------------
-- Create Date:2022-08-05 11:16:19
-- Author  : tangheng
-- Version : 1.0
-- Filename: dataLogInst:lua
-- Introduce  : 类介绍
-- --------------------------------------
local skynet = require "skynet"
local json = require("json")
---@class dataLogInst
local _M = instanceClass("dataLogInst")

local math_floor = math.floor

function _M:ctor()
    self.file_map = {}
    self.module_map = {}
    self.dirMap = {}
end

local function createDir(dirName)
    local bok = os.execute("mkdir -p " .. dirName)
    if not bok then
        bok = os.execute("mkdir -p " .. dirName)
        if not bok then
            log.ddNotify(string.safeFormat("create dir:%s failed", dirName))
        end
    end
end

function _M:getAiid(time)
    if self._lastTime ~= time then
        self._lastTime = time
        self._index = 1
    else
        self._index = (self._index or 0) + 1
    end
    return self._index
end

function _M:getDirName(synType)
    local dirMap = self.dirMap
    if dirMap[synType] then
        return dirMap[synType]
    end

    local dirName
    dirName = skynet.getenv "logdatapath" or "/data/kow_data_log"

    dirName = dirName .. "/" .. synType .. "/node_" .. gNodeId .. "/"

    dirMap[synType] = dirName

    createDir(dirName)

    return dirName
end

function _M:check_close_oldfile(modulename, new_file)
    local module_map = self.module_map
    local old_file = module_map[modulename]
    if old_file then
        old_file:close()
    end
    module_map[modulename] = new_file
end

local synTypeCfg = {
    create_role = true,
    create_recharge = true,
    create_account = true,
    online_line = true,
    online = true,
    real_online = true,
    recharge = true,
    server_error = true,
    server_start = true,

}

-- 文件同步方式
function _M:getSynType(ptype)
    if ptype and synTypeCfg[ptype] then
        return "sync_log"
    end

    return "async_log"
end

function _M:getUniqueId(pre, curTime, data)
    return pre .. "_" .. gZone .. "_" .. gNodeId .. "_" .. curTime .. "_" .. data.aiid
end

function _M:queryFile(synType, fileName)
    local file_map = self.file_map
    local file = file_map[fileName]
    if not file then
        file = io.open(fileName, "a+")
        file_map[fileName] = file
        self:check_close_oldfile(synType, file)
    end
    if not file then
        return nil, "can not query file:" .. fileName
    end

    return file
end

local timeFormatCfg = {
    data = "!%Y-%m-%d-%H",
    error = "!%Y-%m-%d"
}

function _M:getTimeFormat(preName)
    return timeFormatCfg[preName] or "!%Y-%m-%d"
end

function _M:writeFile(preName, data)
    local synType = self:getSynType(data.ptype)
    local curTime = math_floor(skynet.time())
    data.aiid = self:getAiid(curTime)
    data.uniqueid = self:getUniqueId(preName, curTime, data)
    local timeFormat = self:getTimeFormat(preName)
    local timestr = ""
    if timestr then
        timestr = os.date(timeFormat, os.time())
    end
    local dirName = self:getDirName(synType)
    local fileName = string.safeFormat("%s%s%s.log", dirName, preName, timestr)
    local file = self:queryFile(synType, fileName)
    if not file then
        -- 文件创建失败，怀疑是文件夹不存在，尝试直接创建一下文件夹
        createDir(dirName)
        file = self:queryFile(synType, fileName)
    end
    if not file then
        return false, "file not exist:" .. fileName
    end

    local str_data = json.encode(data)
    if nil == str_data then
        return false, "json.encode fail" .. dumpTable(data, "data", 10)
    end
    file:write(str_data)
    file:write("\n")
    file:flush()
    return true
end

function _M:close()
    for _, file in pairs(self.file_map) do
        file:close()
    end
    self.file_map = {}
    self.module_map = {}
end

return _M.instance()
