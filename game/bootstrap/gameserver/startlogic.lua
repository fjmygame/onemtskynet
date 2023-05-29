local skynet = require("skynet")

local function gameserver_startlogic()

    local nodeIdParser = require "game.liblua.util.nodeIdParser"
    nodeIdParser.runTest()

end

return gameserver_startlogic
