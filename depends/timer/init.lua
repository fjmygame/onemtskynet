-- local core = require "timer.c"

-- local uuid = 0
-- local MAX_INT = 4294967295
-- local timer_cb = {}
-- local on_cb

-- local function add_on_cb(handle, cb)
--     if not on_cb then
--         on_cb = {}
--     end
--     on_cb[handle] = cb
-- end

-- local p = core()
-- p:set_on_timer_cb(
--     function(handle)
--         local cb = timer_cb[handle]
--         if cb then
--             timer_cb[handle] = nil
--             add_on_cb(handle, cb)
--         end
--     end
-- )

-- local M = {}

-- local function genHandle()
--     if uuid < MAX_INT then
--         uuid = uuid + 1
--     else
--         uuid = 1
--     end
--     return uuid
-- end

-- function M.init()
--     local skynet = require "skynet"
--     print("INIT", p:time(), skynet.now())
-- end

-- function M.time()
--     return p:time()
-- end

-- function M.add(ti, cb)
--     if not cb then
--         return
--     end
    
--     ti = math.ceil(ti)
--     local handle = genHandle()
--     if ti < 1 then
--         add_on_cb(handle, cb)
--         return handle
--     else
--         p:add(handle, ti * 100)
--         timer_cb[handle] = cb
--         return handle
--     end
-- end

-- function M.remove(handle)
--     timer_cb[handle] = nil
-- end

-- function M.reset(handle, ti)
--     local cb = timer_cb[handle]
--     if cb then
--         timer_cb[handle] = nil
--         return M.add(ti, cb)
--     end
--     return handle
-- end

-- function M.update(diff)
--     -- print("TIMER DIFF", diff)
--     p:update(diff)
    
--     if on_cb then
--         for handle,cb in pairs(on_cb) do
--             pcall(cb, handle, diff,  p:time())
--         end
--         on_cb = nil
--     end
-- end

local M = require "timerMgr"
local skynet = require "skynet"

M.update = M.run
function M.add(ti, cb)
    return M.createTimer(ti, function () skynet.fork(cb) end)
end

M.remove = M.cancelTimer

return M