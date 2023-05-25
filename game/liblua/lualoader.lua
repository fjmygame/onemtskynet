-- --------------------------------------
-- Create Date:2023-03-22 15:16:19
-- Author  : Happy Su
-- Version : 1.0
-- Filename: lualoader.lua
-- Introduce  : 类介绍
-- --------------------------------------
local args = {}
for word in string.gmatch(..., "%S+") do
    table.insert(args, word)
end

SERVICE_NAME = args[1]

local main, pattern
local err = {}

if string.find(SERVICE_NAME, "Service") then
    local pat = "game/service/" .. string.sub(SERVICE_NAME, 1, -8) .. "/?.lua"
    local filename = string.gsub(pat, "?", SERVICE_NAME)
    local f, msg = loadfile(filename)
    if f then
        pattern = pat
        main = f
    end
end

if not main then
    for pat in string.gmatch(LUA_SERVICE, "([^;]+);*") do
        local filename = string.gsub(pat, "?", SERVICE_NAME)
        local f, msg = loadfile(filename)
        if not f then
            table.insert(err, msg)
        else
            pattern = pat
            main = f
            break
        end
    end
end

if not main then
    error(table.concat(err, "\n"))
end

LUA_SERVICE = nil
package.path, LUA_PATH = LUA_PATH
package.cpath, LUA_CPATH = LUA_CPATH

local service_path = string.match(pattern, "(.*/)[^/?]+$")

if service_path then
    service_path = string.gsub(service_path, "?", args[1])
    package.path = service_path .. "?.lua;" .. package.path
    SERVICE_PATH = service_path
else
    local p = string.match(pattern, "(.*/).+$")
    SERVICE_PATH = p
end

if LUA_PRELOAD then
    local f = assert(loadfile(LUA_PRELOAD))
    f(table.unpack(args))
    LUA_PRELOAD = nil
end

main(select(2, table.unpack(args)))
