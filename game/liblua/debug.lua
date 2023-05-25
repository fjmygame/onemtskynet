--[[

Copyright (c) 2011-2014 chukong-inc.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be required in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

]]
--[[--


]]
function DEPRECATED(newfunction, oldname, newname)
    return function(...)
        PRINT_DEPRECATED(string.format("%s() is deprecated, please use %s()", oldname, newname))
        return newfunction(...)
    end
end

--[[--


]]
function PRINT_DEPRECATED(msg)
    if not DISABLE_DEPRECATED_WARNING then
        printf("[DEPRECATED] %s", msg)
    end
end

--[[--

打印调试信息

### 用法示例

~~~ lua

printLog("WARN", "Network connection lost at %d", os.time())

~~~

@param string tag 调试信息的 tag
@param string fmt 调试信息格式
@param [mixed ...] 更多参数

]]
function printLog(tag, fmt, ...)
    local t = {
        "[",
        string.upper(tostring(tag)),
        "] ",
        string.format(tostring(fmt), ...)
    }
    print(table.concat(t))
end

--[[--

输出 tag 为 ERR 的调试信息

@param string fmt 调试信息格式
@param [mixed ...] 更多参数

]]
function printError(fmt, ...)
    printLog("ERR", fmt, ...)
    print(debug.traceback("", 2))
end

--[[--

输出 tag 为 INFO 的调试信息

@param string fmt 调试信息格式
@param [mixed ...] 更多参数

]]
function printInfo(fmt, ...)
    printLog("INFO", fmt, ...)
end

-- 获取dump字符串
function dumpLuaTable(desValue, oDesciption, nesting)
    if type(nesting) ~= "number" then
        nesting = 3
    end

    local lookupTable = {}
    local result = {}

    local function _v(v)
        if type(v) == "string" then
            v = '"' .. v .. '"'
        end
        return tostring(v)
    end

    --    local traceback = string.split(debug.traceback("", 2), "\n")
    --    log.Debug("old","dump from: " .. string.trim(traceback[3]))

    local function _dump(value, desciption, indent, nest, keylen)
        desciption = desciption or "<var>"
        local spc = ""
        if type(keylen) == "number" then
            spc = string.rep(" ", keylen - string.len(_v(desciption)))
        end
        if type(value) ~= "table" then
            result[#result + 1] = string.format("%s%s%s = %s", indent, _v(desciption), spc, _v(value))
        elseif lookupTable[value] then
            result[#result + 1] = string.format("%s%s%s = *REF*", indent, desciption, spc)
        else
            lookupTable[value] = true
            if not next(value) then
                result[#result + 1] = string.format("%s%s = {}", indent, _v(desciption))
            else
                if nest > nesting then
                    result[#result + 1] = string.format("%s%s = *MAX NESTING*", indent, desciption)
                else
                    result[#result + 1] = string.format("%s%s = {", indent, _v(desciption))
                    local indent2 = indent .. "    "
                    local keys = {}
                    local keylen2 = 0
                    local values = {}
                    for k, v in pairs(value) do
                        keys[#keys + 1] = k
                        local vk = _v(k)
                        local vkl = string.len(vk)
                        if vkl > keylen2 then
                            keylen2 = vkl
                        end
                        values[k] = v
                    end
                    table.sort(
                        keys,
                        function(a, b)
                            if type(a) == "number" and type(b) == "number" then
                                return a < b
                            else
                                return tostring(a) < tostring(b)
                            end
                        end
                    )
                    for i, k in ipairs(keys) do
                        _dump(values[k], k, indent2, nest + 1, keylen2)
                    end
                    result[#result + 1] = string.format("%s}", indent)
                end
            end
        end
    end
    _dump(desValue, oDesciption, "- ", 1)

    local output = ""
    for i, line in ipairs(result) do
        output = output .. line .. "\n"
    end

    return output
end

local escape_map = {
    ["\0"] = "\\0",
    ["\b"] = "\\b",
    ["\n"] = "\\n",
    ["\r"] = "\\r",
    ["\t"] = "\\t",
    ["\26"] = "\\Z",
    ["\\"] = "\\\\",
    ["'"] = "\\'",
    ['"'] = '\\"'
}
local strgsub = string.gsub
local strformat = string.format
local function quote_sql_str(str)
    return strformat("'%s'", strgsub(str, '[\0\b\n\r\t\26\\\'"]', escape_map))
end

-- 获取dump字符串
function transformTableToJsonString(desValue, oDesciption, nesting)
    if type(nesting) ~= "number" then
        nesting = 3
    end

    local lookupTable = {}
    local result = {}

    local function _key(k)
        if type(k) == "string" then
            k = '"' .. k .. '"'
        elseif type(k) == "number" then
            k = '"(n)' .. tostring(k) .. '"'
        end
        return tostring(k)
    end

    local function _v(v)
        if type(v) == "string" then
            v = '"' .. quote_sql_str(v) .. '"'
        end
        return tostring(v)
    end

    --    local traceback = string.split(debug.traceback("", 2), "\n")
    --    log.Debug("old","dump from: " .. string.trim(traceback[3]))

    local function _dump(value, desciption, nest, tail)
        desciption = desciption or "var"
        tail = tail or ""
        if type(value) ~= "table" then
            result[#result + 1] = string.format("%s:%s%s", _key(desciption), _v(value), tail)
        elseif lookupTable[value] then
            result[#result + 1] = string.format("%s:*REF*%s", _key(desciption), tail)
        else
            lookupTable[value] = true
            if nest > nesting then
                result[#result + 1] = string.format('%s:"*MAX NESTING*"%s', _key(desciption), tail)
            else
                if nest == 1 then
                    result[#result + 1] = string.format("<%s> => {", desciption)
                else
                    result[#result + 1] = string.format("%s:{", _key(desciption))
                end
                local keys = {}
                local values = {}
                for k, v in pairs(value) do
                    keys[#keys + 1] = k
                    values[k] = v
                end
                table.sort(
                    keys,
                    function(a, b)
                        if type(a) == "number" and type(b) == "number" then
                            return a < b
                        else
                            return tostring(a) < tostring(b)
                        end
                    end
                )
                local keylen = #keys
                for i, k in ipairs(keys) do
                    if i == keylen then
                        _dump(values[k], k, nest + 1)
                    else
                        _dump(values[k], k, nest + 1, ",")
                    end
                end
                result[#result + 1] = string.format("}%s", tail)
            end
        end
    end
    _dump(desValue, oDesciption, 1)

    local output = table.concat(result, "")

    return output
end

--[[--

输出值的内容

### 用法示例

~~~ lua

local t = {comp = "chukong", engine = "quick"}

dump(t)

~~~

@param mixed value 要输出的值

@param [string desciption] 输出内容前的文字描述

@parma [integer nesting] 输出时的嵌套层级，默认为 3

]]
-- function dump(value, desciption, nesting)
--     printError("please use log.Dump!!!!")
-- end

dumpTable = transformTableToJsonString
