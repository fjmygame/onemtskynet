-- --------------------------------------
-- Create Date:2021-04-28 09:11:27
-- Author  : Happy Su
-- Version : 1.0
-- Filename: debugcmd.lua
-- Introduce  : 每个服务的debug扩展
-- --------
-- Last Modified: Thu Mar 16 2023
-- Modified By: Happy Su
-- --------------------------------------
local skynet = require("skynet")
local debug = require("skynet.debug")

local reg_debugcmd = debug.reg_debugcmd

reg_debugcmd(
    "hotfix",
    function(fileList)
        local files = string.splitTrim(fileList, ",")
        log.Info("hotfix", "debugcmd hotfix servicename:", SERVICE_NAME, dumpTable(files, "files:", 10))
        local successfiles = {}
        local faildfiles = {}
        if files then
            -- 需要保证有序
            for index = 1, #files do
                local fileName = files[index]
                if package.loaded[fileName] then
                    package.loaded[fileName] = nil
                    require(fileName)
                    successfiles[#successfiles + 1] = fileName
                else
                    faildfiles[#faildfiles + 1] = fileName
                end
            end
        end
        local successFileStr, faildfilesStr
        if #successfiles > 0 then
            successFileStr = table.concat(successfiles, ",")
            log.Warn(
                "hotfix",
                string.format(
                    "hotfix file success serviceName:%s addr:%#x fileName:%s",
                    SERVICE_NAME,
                    skynet.self(),
                    successFileStr
                )
            )
        end
        if #faildfiles > 0 then
            faildfilesStr = table.concat(faildfiles, ",")
            log.Warn(
                "hotfix",
                string.format(
                    "hotfix file faild serviceName:%s addr:%#x fileName:%s",
                    SERVICE_NAME,
                    skynet.self(),
                    faildfilesStr
                )
            )
        end
        skynet.retpack(successFileStr, faildfilesStr)
    end
)

-- 检查是否需要热更
reg_debugcmd(
    "checkNeedHotfix",
    function(files)
        log.Info("hotfix", "debugcmd checkNeedHotfix servicename:", SERVICE_NAME, dumpTable(files, "files:", 10))
        local successfiles = {}
        local faildfiles = {}
        if files then
            -- 需要保证有序
            for index = 1, #files do
                local fileName = files[index]
                if package.loaded[fileName] then
                    successfiles[#successfiles + 1] = fileName
                else
                    faildfiles[#faildfiles + 1] = fileName
                end
            end
        end
        local successFileStr, faildfilesStr
        if #successfiles > 0 then
            successFileStr = table.concat(successfiles, ",")
            log.Warn(
                "hotfix",
                string.format(
                    "checkNeedHotfix success serviceName:%s addr:%#x fileName:%s",
                    SERVICE_NAME,
                    skynet.self(),
                    successFileStr
                )
            )
        end
        if #faildfiles > 0 then
            faildfilesStr = table.concat(faildfiles, ",")
            log.Warn(
                "hotfix",
                string.format(
                    "checkNeedHotfix faild serviceName:%s addr:%#x fileName:%s",
                    SERVICE_NAME,
                    skynet.self(),
                    faildfilesStr
                )
            )
        end
        skynet.retpack(faildfilesStr)
    end
)

-- 根据文件列表热更
reg_debugcmd(
    "hotfixByFileList",
    function(files)
        log.Info("hotfix", "debugcmd hotfixByFileList servicename:", SERVICE_NAME, dumpTable(files, "files:", 10))
        local successfiles = {}
        local faildfiles = {}
        if files then
            -- 需要保证有序
            for index = 1, #files do
                local fileName = files[index]
                if package.loaded[fileName] then
                    package.loaded[fileName] = nil
                    require(fileName)
                    successfiles[#successfiles + 1] = fileName
                else
                    faildfiles[#faildfiles + 1] = fileName
                end
            end
        end
        local successFileStr, faildfilesStr
        if #successfiles > 0 then
            successFileStr = table.concat(successfiles, ",")
            log.Warn(
                "hotfix",
                string.format(
                    "hotfixByFileList success serviceName:%s addr:%#x fileName:%s",
                    SERVICE_NAME,
                    skynet.self(),
                    successFileStr
                )
            )
        end
        if #faildfiles > 0 then
            faildfilesStr = table.concat(faildfiles, ",")
            log.Warn(
                "hotfix",
                string.format(
                    "hotfixByFileList faild serviceName:%s addr:%#x fileName:%s",
                    SERVICE_NAME,
                    skynet.self(),
                    faildfilesStr
                )
            )
        end
        skynet.retpack(faildfilesStr)
    end
)

reg_debugcmd(
    "openModuleLog",
    function(logModuleNames)
        for _, name in pairs(logModuleNames) do
            if not log.openModule[name] then
                log.openModule[name] = true
            end
        end
        skynet.retpack(true)
    end
)

reg_debugcmd(
    "closeModuleLog",
    function(logModuleNames)
        for _, name in pairs(logModuleNames) do
            if log.openModule[name] then
                log.openModule[name] = false
            end
        end
        skynet.retpack(true)
    end
)

reg_debugcmd(
    "openAllModuleLog",
    function()
        for name, _ in pairs(log.openModule) do
            log.openModule[name] = true
        end
        skynet.retpack(true)
    end
)

reg_debugcmd(
    "closeAllModuleLog",
    function()
        for name, _ in pairs(log.openModule) do
            log.openModule[name] = false
        end
        skynet.retpack(true)
    end
)
