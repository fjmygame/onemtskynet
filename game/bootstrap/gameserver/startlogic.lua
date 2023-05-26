local skynet = require("skynet")

local function gameserver_startlogic(serverType)
    log.Debug("sys", serverType .. " start begin")

    skynet.error("hello world")
    local t = {name = "lhs", value = 1024}
    log.Dump("sys", t, "lhs", 10)

    log.Debug("sys", serverType .. " start end")
end

return gameserver_startlogic
