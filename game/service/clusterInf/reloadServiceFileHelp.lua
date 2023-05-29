-- --------------------------------------
-- Create Date:2021-03-29 14:16:43
-- Author  : Happy Su
-- Version : 1.0
-- Filename: reloadServiceFileHelp.lua
-- Introduce  : 服务文件重载
-- --------------------------------------
local skynet = require "skynet"
local clusterExt = require "clusterExt"
local svrAddressMgr = require "svrAddressMgr"
---@class reloadServiceFileHelp
local _M = class("reloadServiceFileHelp")

function _M.adjust_address(address)
    if address:sub(1, 1) ~= ":" then
        address = address | (skynet.harbor(skynet.self()) << 24)
    end
    return address
end

function _M.call_inject(address, filename)
    local f = io.open(filename, "rb")
    if not f then
        return false, "Can't open " .. filename
    end
    local src = f:read "*a"
    f:close()
    return clusterExt.call(address, "debug", "RUN", src, filename)
end

-- 找到匹配的服务地址列表
function _M.callAllServiceAddrMap()
    local addressMap = {}
    local retList = clusterExt.call(".launcher", "lua", "LIST")
    -- log.Dump("sys", retList, "injectScript.launcher.serviceList")
    for strAddress, strSvrName in pairs(retList) do
        local address = string.safeFormat("%d", "0x" .. string.sub(strAddress, 2))
        addressMap[strSvrName] = _M.adjust_address(address)
    end
    log.Dump("sys", addressMap, "injectScript.callAllServiceAddrMap")
    return addressMap
end

function _M.callServiceMapAddrList(serviceNameMap)
    local arrAddress = {}
    local retList = clusterExt.call(".launcher", "lua", "LIST")
    -- log.Dump("sys", retList, "callServiceMapAddrList.serviceList")
    for strAddress, strSvrName in pairs(retList) do
        local address = string.safeFormat("%d", "0x" .. string.sub(strAddress, 2))
        local arrName = string.split(strSvrName, " ")
        local svrName = arrName[2]
        local curNodeId = tonumber(arrName[3])
        if serviceNameMap[svrName] then
            log.Info(
                "gm",
                "callServiceMapAddrList injectScript curNodeId, svrName, address",
                curNodeId,
                svrName,
                strAddress
            )
            -- table.insert(arrAddress, address)
            arrAddress[#arrAddress + 1] = _M.adjust_address(address)
        end
    end
    return arrAddress
end

-- 找到匹配的服务地址列表
function _M.callServiceAddrList(serviceName)
    local arrAddress = {}
    local retList = clusterExt.call(".launcher", "lua", "LIST")
    -- log.Dump("sys", retList, "callServiceAddrList.serviceList")
    for strAddress, strSvrName in pairs(retList) do
        local address = string.safeFormat("%d", "0x" .. string.sub(strAddress, 2))
        local arrName = string.split(strSvrName, " ")
        local svrName = arrName[2]
        local curNodeId = tonumber(arrName[3])
        -- log.Info("gm", "injectScript svrName, serviceName 111", svrName, serviceName)
        if svrName == serviceName then
            log.Info(
                "gm",
                string.safeFormat(
                    "callServiceAddrList curNodeId:%s, svrName:%s, address:%s",
                    curNodeId,
                    svrName,
                    strAddress
                )
            )
            -- table.insert(arrAddress, address)
            arrAddress[#arrAddress + 1] = _M.adjust_address(address)
        end
    end
    return arrAddress
end

function _M.inject_agentlt(serviceName, fileFullPath)
    -- 如果是agent的话，需要记录下，让agent重新加载它
    local playerAgentPoolSvrAdd = svrAddressMgr.getSvr(svrAddressMgr.playerAgentPoolSvr, dbconf.curnodeid)
    local bok, err = clusterExt.call(playerAgentPoolSvrAdd, "lua", "hotFixAgent", fileFullPath)

    local injectRet = {
        [fileFullPath] = {
            bok = bok,
            err = err
        }
    }

    return true, "injectScript success", injectRet
end

function _M.inject_common(serviceName, fileFullPath)
    local arrAddress = _M.callServiceAddrList(serviceName)
    local injectRet = {}
    local bSuccessRet = true
    if #arrAddress <= 0 then
        return false, "injectScript can not found service", injectRet
    else
        for _, address in pairs(arrAddress) do
            log.Info("gm", "injectScript address:", address, fileFullPath)
            local bok, err = _M.call_inject(address, fileFullPath)
            if not bok then
                bSuccessRet = false
                local addrStr = string.safeFormat("[:%08x]", address)
                injectRet[addrStr] = {
                    bok = bok,
                    err = err
                }
            elseif err then
                local addrStr = string.safeFormat("[:%08x]", address)
                injectRet[addrStr] = {
                    bok = bok,
                    err = err
                }
            end
            log.Info("gm", "injectScript ret:", bok, err)
        end
    end

    return bSuccessRet, "injectScript complete", injectRet
end

function _M.getInjectFunc(serviceName)
    -- 现在只有agentlt特殊，如果后期特殊的多了，改为map映射
    if serviceName == "agentlt" then
        return _M.inject_agentlt
    else
        return _M.inject_common
    end
end

return _M
