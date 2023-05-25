--------------------------------------------------------------------------------
-- 文件: stringEx.lua
-- 作者: zkb
-- 时间: 2020-02-25 14:24:42
-- 描述: string扩展
--------------------------------------------------------------------------------

string._htmlspecialchars_set = {}
string._htmlspecialchars_set["&"] = "&amp;"
string._htmlspecialchars_set['"'] = "&quot;"
string._htmlspecialchars_set["'"] = "&#039;"
string._htmlspecialchars_set["<"] = "&lt;"
string._htmlspecialchars_set[">"] = "&gt;"

-- start --

--------------------------------
-- 将特殊字符转为 HTML 转义符
-- @function [parent=#string] htmlspecialchars
-- @param string input 输入字符串
-- @return string#string  转换结果

--[[--

将特殊字符转为 HTML 转义符

~~~ lua

log.Debug("old",string.htmlspecialchars("<ABC>"))
-- 输出 &lt;ABC&gt;

~~~

]]
-- end --

function string.htmlspecialchars(input)
    for k, v in pairs(string._htmlspecialchars_set) do
        input = string.gsub(input, k, v)
    end
    return input
end

-- start --

--------------------------------
-- 将 HTML 转义符还原为特殊字符，功能与 string.htmlspecialchars() 正好相反
-- @function [parent=#string] restorehtmlspecialchars
-- @param string input 输入字符串
-- @return string#string  转换结果

--[[--

将 HTML 转义符还原为特殊字符，功能与 string.htmlspecialchars() 正好相反

~~~ lua

log.Debug("old",string.restorehtmlspecialchars("&lt;ABC&gt;"))
-- 输出 <ABC>

~~~

]]
-- end --

function string.restorehtmlspecialchars(input)
    for k, v in pairs(string._htmlspecialchars_set) do
        input = string.gsub(input, v, k)
    end
    return input
end

-- start --

--------------------------------
-- 将字符串中的 \n 换行符转换为 HTML 标记
-- @function [parent=#string] nl2br
-- @param string input 输入字符串
-- @return string#string  转换结果

--[[--

将字符串中的 \n 换行符转换为 HTML 标记

~~~ lua

log.Debug("old",string.nl2br("Hello\nWorld"))
-- 输出
-- Hello<br />World

~~~

]]
-- end --

function string.nl2br(input)
    return string.gsub(input, "\n", "<br />")
end

-- start --

--------------------------------
-- 将字符串中的特殊字符和 \n 换行符转换为 HTML 转移符和标记
-- @function [parent=#string] text2html
-- @param string input 输入字符串
-- @return string#string  转换结果

--[[--

将字符串中的特殊字符和 \n 换行符转换为 HTML 转移符和标记

~~~ lua

log.Debug("old",string.text2html("<Hello>\nWorld"))
-- 输出
-- &lt;Hello&gt;<br />World

~~~

]]
-- end --

function string.text2html(input)
    input = string.gsub(input, "\t", "    ")
    input = string.htmlspecialchars(input)
    input = string.gsub(input, " ", "&nbsp;")
    input = string.nl2br(input)
    return input
end

-- start --

--------------------------------
-- 用指定字符或字符串分割输入字符串，返回包含分割结果的数组
-- @function [parent=#string] split
-- @param string input 输入字符串
-- @param string delimiter 分割标记字符或字符串
-- @return array#array  包含分割结果的数组

--[[--

用指定字符或字符串分割输入字符串，返回包含分割结果的数组

~~~ lua

local input = "Hello,World"
local res = string.split(input, ",")
-- res = {"Hello", "World"}

local input = "Hello-+-World-+-Quick"
local res = string.split(input, "-+-")
-- res = {"Hello", "World", "Quick"}

~~~

]]
-- end --

function string.split(szFullString, szSeparator)
    szFullString = tostring(szFullString)
    szSeparator = tostring(szSeparator)
    if (szSeparator == "") then
        return false
    end
    local nFindStartIndex = 1
    local nSplitIndex = 1
    local nSplitArray = {}
    while true do
        local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex, true)
        if not nFindLastIndex then
            nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))
            break
        end
        nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)
        nFindStartIndex = nFindLastIndex + string.len(szSeparator)
        nSplitIndex = nSplitIndex + 1
    end
    return nSplitArray
end

-- 字符串分割，并去掉每段的前后空格
function string.splitTrim(szFullString, szSeparator)
    local nSplitArray = {}
    if type(szFullString) == "string" then
        local nFindStartIndex = 1
        local nSplitIndex = 1
        while true do
            local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)
            if not nFindLastIndex then
                nSplitArray[nSplitIndex] =
                    string.trim(string.sub(szFullString, nFindStartIndex, string.len(szFullString)))
                break
            end
            nSplitArray[nSplitIndex] = string.trim(string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1))
            nFindStartIndex = nFindLastIndex + string.len(szSeparator)
            nSplitIndex = nSplitIndex + 1
        end
    end
    return nSplitArray
end

--[[分割字符串[平台信息相关]
]]
function string.splitPlateformInfo(plateform)
    local arr = string.split(plateform, " ")
    return table.unpack(arr)
end

-- start --

--------------------------------
-- 去除输入字符串头部的空白字符，返回结果
-- @function [parent=#string] ltrim
-- @param string input 输入字符串
-- @return string#string  结果
-- @see string.rtrim, string.trim

--[[--

去除输入字符串头部的空白字符，返回结果

~~~ lua

local input = "  ABC"
log.Debug("old",string.ltrim(input))
-- 输出 ABC，输入字符串前面的两个空格被去掉了

~~~

空白字符包括：

-   空格
-   制表符 \t
-   换行符 \n
-   回到行首符 \r

]]
-- end --

function string.ltrim(input)
    return string.gsub(input, "^[ \t\n\r]+", "")
end

-- start --

--------------------------------
-- 去除输入字符串尾部的空白字符，返回结果
-- @function [parent=#string] rtrim
-- @param string input 输入字符串
-- @return string#string  结果
-- @see string.ltrim, string.trim

--[[--

去除输入字符串尾部的空白字符，返回结果

~~~ lua

local input = "ABC  "
log.Debug("old",string.rtrim(input))
-- 输出 ABC，输入字符串最后的两个空格被去掉了

~~~

]]
-- end --

function string.rtrim(input)
    return string.gsub(input, "[ \t\n\r]+$", "")
end

-- start --

--------------------------------
-- 去掉字符串首尾的空白字符，返回结果
-- @function [parent=#string] trim
-- @param string input 输入字符串
-- @return string#string  结果
-- @see string.ltrim, string.rtrim

--[[--

去掉字符串首尾的空白字符，返回结果

]]
-- end --

function string.trim(input)
    return string.match(input, "%s*(.-)%s*$")
end

-- start --

--------------------------------
-- 将字符串的第一个字符转为大写，返回结果
-- @function [parent=#string] ucfirst
-- @param string input 输入字符串
-- @return string#string  结果

--[[--

将字符串的第一个字符转为大写，返回结果

~~~ lua

local input = "hello"
log.Debug("old",string.ucfirst(input))
-- 输出 Hello

~~~

]]
-- end --

function string.ucfirst(input)
    return string.upper(string.sub(input, 1, 1)) .. string.sub(input, 2)
end

local function urlencodechar(char)
    return "%" .. string.format("%02X", string.byte(char))
end

-- start --

--------------------------------
-- 将字符串转换为符合 URL 传递要求的格式，并返回转换结果
-- @function [parent=#string] urlencode
-- @param string input 输入字符串
-- @return string#string  转换后的结果
-- @see string.urldecode

--[[--

将字符串转换为符合 URL 传递要求的格式，并返回转换结果

~~~ lua

local input = "hello world"
log.Debug("old",string.urlencode(input))
-- 输出
-- hello%20world

~~~

]]
-- end --

function string.urlencode(input)
    -- convert line endings
    input = string.gsub(tostring(input), "\n", "\r\n")
    -- escape all characters but alphanumeric, '.' and '-'
    input = string.gsub(input, "([^%w%.%- ])", urlencodechar)
    -- convert spaces to "+" symbols
    return string.gsub(input, " ", "+")
end

-- start --

--------------------------------
-- 将 URL 中的特殊字符还原，并返回结果
-- @function [parent=#string] urldecode
-- @param string input 输入字符串
-- @return string#string  转换后的结果
-- @see string.urlencode

--[[--

将 URL 中的特殊字符还原，并返回结果

~~~ lua

local input = "hello%20world"
log.Debug("old",string.urldecode(input))
-- 输出
-- hello world

~~~

]]
-- end --

function string.urldecode(input)
    input = string.gsub(input, "+", " ")
    input =
        string.gsub(
        input,
        "%%(%x%x)",
        function(h)
            return string.char(checknumber(h, 16))
        end
    )
    input = string.gsub(input, "\r\n", "\n")
    return input
end

-- start --

--------------------------------
--将格式字符串转化为lua table,如："1,2,3,4"=>{1,2,3,4}
function string.format2Table(str)
    local ret = {}
    for w in string.gmatch(str, "%w+") do
        table.insert(ret, w)
    end
    return ret
end

-- 匹配阿拉伯字符数字英文字母
function string.matchArabCharNum(str)
    local regx = "^[\216\128-\216\191a-z\217\128-\217\191A-Z\218\128-\218\1910-9\219\128-\219\191]+$"
    local ret = string.match(str, regx)
    if ret then
        return true, ret
    else
        return false
    end
end

-- 只匹配中文和字母
function string.matchCharNumber(str)
    local regx = "^[A-Za-z0-9]+$"
    local ret = string.match(str, regx)
    if ret then
        return true, ret
    else
        return false
    end
end

-- 字符串按ascii码求和
function string.byteSum(str)
    local len = string.len(str)
    local sbyte = string.byte
    local sum = 0
    for i = 1, len do
        sum = sum + sbyte(str, i)
    end
    return sum
end

-- 是否中文
function string.isChineseContent(str)
    if type(str) ~= "string" then --
        return true
    end
    -- 【】「」、|；：‘’”“，《。》？
    local allowSymbolCfg = {
        [12304] = true,
        [12305] = true,
        [12300] = true,
        [12301] = true,
        [12289] = true,
        [65307] = true,
        [65306] = true,
        [8216] = true,
        [8217] = true,
        [8220] = true,
        [8221] = true,
        [65292] = true,
        [12298] = true,
        [12290] = true,
        [12299] = true,
        [65311] = true
    }
    local function allowSymbol(char)
        local code = utf8.codepoint(char) or 0
        return allowSymbolCfg[code]
    end

    local function isChinese(char)
        if "string" ~= type(char) or "" == char then
            return
        end

        if #char == 3 then
            local curByte1 = string.byte(char, 1)
            local curByte2 = string.byte(char, 3)
            if curByte1 > 127 and curByte2 > 127 then
                return true
            end
        end

        return false
    end

    str = string.gsub(str, "%s+", "")

    local array = serviceFunctions.convertStringToArray(str)
    for i = 1, #array do
        local char = array[i]
        if (not allowSymbol(char)) and isChinese(char) then
            return true
        end
    end

    return false
end

--将id范围的格式字符串转化为int数组,如："1-3,5"=>{1,2,3,5}
function string.idRangeStr2IntArray(str)
    local ids = {}
    local array = string.split(str, ",")
    for _, v in ipairs(array) do
        local arr2 = string.split(v, "-")
        if #arr2 == 1 then
            table.insert(ids, tonumber(arr2[1]))
        elseif #arr2 == 2 then
            local from = tonumber(arr2[1])
            local to = tonumber(arr2[2])
            print("from to", arr2[1], arr2[2])
            for i = from, to do
                table.insert(ids, i)
            end
        end
    end
    return ids
end

function string.prefixCheck(str, prefix)
    if type(str) ~= "string" then
        return false
    end
    local arr = string.split(str, ".")
    return #arr > 0 and arr[1] == prefix
end

function string.safeFormat(fmt, ...)
    local bok, err = xpcall(string.format, debug.traceback, fmt, ...)
    if not bok then
        log.Error("sys", "string.safeFormat error", err, fmt, ...)
        return ""
    end

    return err
end

-- 把空格替换为不间断空格 \u0020 --> \u00A0
function string.changeBlank(str)
    return string.gsub(str, utf8.char(32), utf8.char(160))
end

-- 空格反转
function string.reverseBlank(str)
    return string.gsub(str, utf8.char(160), utf8.char(32))
end

-- 处理名字(玩家、联盟、子嗣等)
function string.fixName(str)
    if not str then
        return
    end
    -- 去掉左右空格
    str = string.trim(str)
    -- 普通空格改为连续空格
    return string.changeBlank(str)
end

---@param codePoint integer codePoint 字符编码
function string.isEmoji(codePoint)
    -- utf32的判断
    if codePoint >= 0xE000 and codePoint <= 0xF8FF then
        -- if (codePoint >= 0x1F200 and codePoint <= 0x1FFFF) or (codePoint >= 0x2500 and codePoint <= 0x2FFF) then
        return true
    else
        return false
    end
end

function string.startWith(str, start)
    return string.sub(str, 1, #start) == start
end

function string.concat(sep, args)
    assert(type(args) == "table", "string.concat args must be table")
    sep = sep or "_"
    local ret = ""
    for i = 1, #args do
        if i > 1 then
            ret = ret .. sep
        end
        ret = ret .. args[i]
    end
    return ret
end
