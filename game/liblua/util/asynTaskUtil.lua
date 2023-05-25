-- --------------------------------------
-- Create Date:2022-11-23 09:40:32
-- Author  : tangheng
-- Version : 1.0
-- Filename: asynTaskUtil.lua
-- Introduce  : 类介绍
-- --------------------------------------
local skynet = require("skynet")
---@class asynTaskUtil
local _M = BuildUtil("asynTaskUtil")

--taskMap并行任务列表,任务名和对应的函数
--[[
返回值:
    bSuc: 只有xpcall全部成功才为true
    doResultMap:每个task的第一个返回值，任务名为key
    doFail: xpcall返回失败的任务名列表
]]
---@param taskMap table<string, function>
function _M.doAsynTasks(taskMap)
    local doFail = {}
    local doResultMap = {}
    local taskNum = 0
    local doNum = 0
    local bSuc = true
    local co = coroutine.running()
    for taskName, func in pairs(taskMap) do
        taskNum = taskNum + 1
        skynet.fork(
            function()
                local ok, result = xpcall(func, debug.traceback)
                if not ok then
                    doFail[#doFail + 1] = taskName
                    log.ErrorStack("sys", "asynTaskUtil.doAsynTasks err", taskName, result)
                    bSuc = false
                else
                    if result then
                        doResultMap[taskName] = result
                    end
                end

                doNum = doNum + 1
                if doNum == taskNum then
                    skynet.wakeup(co)
                end
            end
        )
    end

    if taskNum > 0 then
        skynet.wait(co)
    end

    if next(doFail) then
        log.ErrorStack("sys", "asynTaskUtil.doAsynTasks doFail taskName", dumpTable(doFail))
    end

    return bSuc, doResultMap, doFail
end

return _M
