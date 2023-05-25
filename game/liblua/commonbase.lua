-- --------------------------------------
-- Create Date:2021-04-17 10:18:18
-- Author  : Happy Su
-- Version : 1.0
-- Filename: commonbase.lua
-- Introduce  : 各类接口存储
-- --------------------------------------
local utilMap = {}
local apiMap = {}
local otherMap = {}

local commonbase = {
    utilMap = utilMap,
    apiMap = apiMap,
    otherMap = otherMap
}

function getCommonBase()
    return commonbase
end

--[[
    默认创建一个空table，如果有传默认对象，则使用默认对象
]]
function CreateBlankTable(self, tableName, defaultData)
    local retTable = self[tableName]
    if not retTable then
        if defaultData then
            retTable = defaultData
        else
            retTable = {}
        end
        self[tableName] = retTable
    end
    return retTable
end

-- 初始化Value
function InitalValue(self, valueName, value)
    if nil == self[valueName] then
        self[valueName] = value
    end
end

--[[
    accountUtil
    aidUtil
    coordinateUtil
    csUtil
    dailyUtil
    effectUtil
    hotfixUtil
    chatUtil
]]
function BuildUtil(utilName)
    if utilMap[utilName] then
        return utilMap[utilName]
    end

    local util = {}
    utilMap[utilName] = util
    return util
end

--[[
    activityAPI
    statsAPI
    rankAPI
    princessAPI
    newMailAPI
    friendAPI
    lordAttrAPI
    lordAPI
    batchDataAPI
    heroAPI
    allianceAPI
    redAPI
    feastAPI
    loginAPI
    clusterInfAPI
    crossActRankAPI
    accountAPI
    chatAPI
    chatRoomAPI
    conquestAPI
]]
function BuildAPI(apiName)
    if apiMap[apiName] then
        return apiMap[apiName]
    end

    local api = {}
    apiMap[apiName] = api
    return api
end

--[[
    newPlayerStrategy
    chatChannelCheckConf
    chatlogPrivateDB
    chatlogPrivateLib
    elasticSearchAllianceLib
    elasticSearchLib
    elasticSearchUserLib
    gmSystem
    crossNotify
    notify
    serviceNotify
]]
function BuildOther(otherName)
    if otherMap[otherName] then
        return otherMap[otherName]
    end

    local other = {}
    otherMap[otherName] = other
    return other
end

-- 构建一个基于baseData，可被extraData覆盖的数据table
function CreateDataExtraTable(baseData, extraData)
    local retTable =
        setmetatable(
        {
            __baseData = baseData,
            __extraData = extraData
        },
        {
            __index = function(t, key)
                if t.__extraData[key] then
                    return t.__extraData[key]
                end

                return t.__baseData[key]
            end
        }
    )

    return retTable
end

function handlerName(obj, funcName)
    assert("function" == type(obj[funcName]), "handler error: the func is not a function!")
    return function(...)
        return obj[funcName](obj, ...)
    end
end

function handlerPureFun(className, funcName)
    assert("function" == type(className[funcName]), "handler error: the func is not a function!")
    return function(...)
        return className[funcName](...)
    end
end

function retpackHandlerName(obj, funcName)
    assert("function" == type(obj[funcName]), "handler error: the method is not a function!")
    return function(...)
        require("skynet").retpack(obj[funcName](obj, ...))
    end
end

-- 布尔值转为运营日志所需的值
function bool2logType(b)
    local boolEnum = {
        yes = 1,
        no = 2
    }
    return b and boolEnum.yes or boolEnum.no
end

-- 布尔值转开关
function bool2onoff(b)
    local boolEnum = {
        on = 1,
        off = 0
    }
    return b and boolEnum.on or boolEnum.off
end

-- 打包一个包含错误码的table
function packErrorRet(err, info, ...)
    log.Warn("base", info, err, ...)
    return {err = err}
end

-- 往data对象中添加错误码
function packErrorDataRet(err, data, info, ...)
    log.Warn("base", info, err, ...)
    if not data then
        data = {err = err}
    else
        data.err = err
    end
    return data
end

-- data中添加 gErrDef.Err_None
function packOkRet(data)
    if not data then
        data = {err = gErrDef.Err_None}
    else
        data.err = gErrDef.Err_None
    end
    return data
end
