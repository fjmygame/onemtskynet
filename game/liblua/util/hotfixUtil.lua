-- @Author: sgys
-- @Date:   2020-09-10 20:28:53
-- @Last Modified by:   sgys
-- @Last Modified time: 2020-09-10 20:36:15

local skynet = require("skynet")
local svrAddressMgr = require("svrAddressMgr")
local hotfixUtil = BuildUtil("hotfixUtil")
---@type configNameTrans
local configNameTrans = require("configNameTrans")

function hotfixUtil.printFixRet(...)
    log.Info("hotfix", "fixPlayerAgent nodeid[", dbconf.curnodeid, "] ret=", ...)
end

-- 加载配置表
function hotfixUtil.loadfile(cfgname)
    cfgname = configNameTrans:getNameByZone(cfgname, dbconf.zone)
    local name = "game/localtb/" .. cfgname .. ".lua"
    local file = io.open(name, "rb")
    if not file then
        hotfixUtil.printFixRet("config error: Can't open " .. name)
        return
    end
    local source = file:read "*a"
    file:close()

    local f, err = load(source, nil, "t")
    if not f then
        hotfixUtil.printFixRet("config error: load file[" .. name .. "] error \n " .. err)
    end
    return f()
end

-- 热更agent
function hotfixUtil.fixAgent(scriptName)
    -- 各个服务器开始进行热更
    log.Info("hotfix", "fix 1 fixPlayerAgent begin nodeid", dbconf.curnodeid)

    log.Info("hotfix", "********************")
    local playerAgentPoolSvrAdd = svrAddressMgr.getSvr(svrAddressMgr.playerAgentPoolSvr, dbconf.curnodeid)
    log.Info("hotfix", "********************1", playerAgentPoolSvrAdd)
    local fileFullPath = "game/hotfix/" .. scriptName .. ".lua"
    hotfixUtil.printFixRet(skynet.call(playerAgentPoolSvrAdd, "lua", "hotFixAgent", fileFullPath))
end

return hotfixUtil
