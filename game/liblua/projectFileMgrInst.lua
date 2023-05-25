-- --------------------------------------
-- Create Date:2023-03-18 11:29:37
-- Author  : Happy Su
-- Version : 1.0
-- Filename: projectFileMgrInst.lua
-- Introduce  : 代码工程文件管理类
-- --------------------------------------
---@type fileUtil
local fileUtil = require("fileUtil")
---@class projectFileMgrInst
local _M = instanceClass("projectFileMgrInst")

local function getFileServiceCfg()
    return fileUtil.loadfile("game/conf/file_service_cfg")
end

local function getLuaFilePathCfg()
    return fileUtil.loadfile("game/conf/lua_path_cfg")
end

local function trimFileName(fileName)
    local fileArr = string.split(fileName, ".")
    return fileArr[#fileArr]
end

local function getFilePath(filePathCfg, fileName)
    local fealFileName = trimFileName(fileName)
    local path = filePathCfg[fealFileName]
    if path then
        return path
    else
        return fileName
    end
end

-- 根据服务分类文件列表
---@param fileList table lua文件列表
---@return table @<serviceName, fileList>
function _M:fileClassifyService(fileList)
    if not fileList or #fileList <= 0 then
        return {}
    end

    -- lua文件路径配置
    local filePathCfg = getLuaFilePathCfg()

    local fileServiceCfg = getFileServiceCfg()
    local servcieFileTable = {}
    -- 数组pairs时便是有序的，这样搜集之后，单服务内，文件顺序也是和fileList中相同
    for _, fileName in pairs(fileList) do
        local serviceList = fileServiceCfg[fileName]
        if serviceList then
            for _, serviceName in pairs(serviceList) do
                local fileArr = CreateBlankTable(servcieFileTable, serviceName)
                fileArr[#fileArr + 1] = getFilePath(filePathCfg, fileName)
            end
        else
            log.Error("sys", "can not found file service fileName:", fileName)
        end
    end

    return servcieFileTable
end

-- 根据hotfixList转成服务对应文件列表
function _M:changeHotfixListToServiceFileTable(hotfixList)
    if not hotfixList or #hotfixList <= 0 then
        return {}
    end

    -- lua文件路径配置
    local filePathCfg = getLuaFilePathCfg()

    local servcieFileTable = {}
    for _, hotfixInfo in pairs(hotfixList) do
        local serviceName = hotfixInfo.serviceName
        local fileList = string.splitTrim(hotfixInfo.fileList, ",")
        if fileList and #fileList > 0 then
            local filePathList = {}
            for _, fileName in pairs(fileList) do
                filePathList[#filePathList + 1] = getFilePath(filePathCfg, fileName)
            end
            servcieFileTable[serviceName] = filePathList
        end
    end

    return servcieFileTable
end

return _M.instance()
