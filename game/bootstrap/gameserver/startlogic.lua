local skynet = require("skynet")

local function gameserver_startlogic(serverType)
    log.Error("sys", serverType .. " start begin")

    log.DebugFormat("sys", "hello lhs %s", 1024)
    log.InfoFormat("sys", "hello lhs %s", 1024)
    log.WarnFormat("sys", "hello lhs %s", 1024)
    log.ErrorFormat("sys", "hello lhs %s", 1024)

    log.Error("sys", "-----set level 1")
    log.SetLevel(1)
    log.DebugFormat("sys", "hello lhs %s", 1024)
    log.InfoFormat("sys", "hello lhs %s", 1024)
    log.WarnFormat("sys", "hello lhs %s", 1024)
    log.ErrorFormat("sys", "hello lhs %s", 1024)

    log.Error("sys", "-----set level 2")
    log.SetLevel(2)
    log.DebugFormat("sys", "hello lhs %s", 1024)
    log.InfoFormat("sys", "hello lhs %s", 1024)
    log.WarnFormat("sys", "hello lhs %s", 1024)
    log.ErrorFormat("sys", "hello lhs %s", 1024)

    log.Error("sys", "-----set level 3")
    log.SetLevel(3)
    log.DebugFormat("sys", "hello lhs %s", 1024)
    log.InfoFormat("sys", "hello lhs %s", 1024)
    log.WarnFormat("sys", "hello lhs %s", 1024)
    log.ErrorFormat("sys", "hello lhs %s", 1024)

    local t = {name = "lhs", value = 1024}
    log.SetLevel(0)
    log.Dump("sys", t)

    log.Error("sys", serverType .. " start end")
end

return gameserver_startlogic
