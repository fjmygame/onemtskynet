-- --------------------------------------
-- Create Date:2021-04-18 13:42:31
-- Author  : Happy Su
-- Version : 1.0
-- Filename: instanceclass.lua
-- Introduce  : 单例类
-- --------------------------------------
instanceClass = function(classname, super)
    local _M = class(classname, super)

    local func = rawget(_M, "instance")
    if nil == func then
        if _M.instance then
            assert(false, string.safeFormat("super:%s has instance function", super.__cname))
        end
        _M.instance = function()
            if nil == _M.__instance then
                _M.__instance = _M.new()
            end
            return _M.__instance
        end
    end

    return _M
end
