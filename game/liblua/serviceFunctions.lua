--[[
    serviceFunction
    服务端用的公用函数
--]]
local skynet = require("skynet")

-- local gcStep = 1
local serviceFunctions = {}

-- 打印异常
function serviceFunctions.exception(errorMessage)
    log.Error("sys", "exception:", tostring(errorMessage), debug.traceback())
end

-- xpcall
function serviceFunctions.xpcall(f, ...)
    return xpcall(f, serviceFunctions.exception, ...)
end

function serviceFunctions.xpcall_ret(f, ...)
    return procss_xpcall_ret(xpcall(f, serviceFunctions.exception, ...))
end

function serviceFunctions.fork(f, ...)
    skynet.fork(xpcall, f, serviceFunctions.exception, ...)
end

-- 发送httppost
function serviceFunctions.httpPost(host, data, url, contentType)
    --skynet.error("serviceFunctions.httpPost(host, url, data)", host, url, data)
    local httpc = require "http.httpc"
    url = url or "/"
    local recvheader = {}
    local header = {
        ["content-type"] = contentType or "application/x-www-form-urlencoded"
    }
    local status, body = httpc.request("POST", host, url, recvheader, header, data)
    --log.Dump("old",status, "http status=", 10)
    --log.Dump("old",body, "http body=", 10)
    local isSuccess = (tostring(status) == "200")
    return isSuccess, body
end

function serviceFunctions.convertStringToArray(input)
    if "string" ~= type(input) and string.len(input) > 0 then
        return {input}
    end

    local array = {}
    local len = string.len(input)
    local pos = 1
    local arr = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
    while 0 < pos and pos <= len do
        local tmp = string.byte(input, pos)
        local i = #arr
        while arr[i] do
            if tmp >= arr[i] then
                local c = string.sub(input, pos, pos + i - 1)
                table.insert(array, c)
                pos = pos + i
                break
            end
            i = i - 1
        end
    end

    return array
end

--内存回收
function serviceFunctions.memoryRecovery()
    log.Dump("sys", collectgarbage("count"), "collectgarbage start", 10)
    --skynet.send(skynet.self(),"debug","GC")
    collectgarbage("collect")
    log.Dump("sys", collectgarbage("count"), "collectgarbage end", 10)
end

--内存回收步长自增
function serviceFunctions.gcStep()
    -- log.Debug("old", "gcStep step", gcStep)
    -- log.Dump("old",collectgarbage("count"), "gcStep start", 10)
    -- collectgarbage("step")
    -- -- log.Dump("old",collectgarbage("count"), "gcStep end", 10)
    -- gcStep = gcStep +1
end

-- 字符串入库处理
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
--转移
function serviceFunctions.escape(_str)
    return strgsub(_str, '[\0\b\n\r\t\26\\\'"]', escape_map)
end

-- 是否是Emoji表情字符
-- 参考链接 https://apps.timwhitlock.info/emoji/tables/unicode
function serviceFunctions.isEmojiSymbol(str)
    if #str == 4 then
        local char1 = string.byte(str, 1)
        local char2 = string.byte(str, 2)
        local char3 = string.byte(str, 3)
        local char4 = string.byte(str, 4)
        -- 1. Emoticons ( 1F601 - 1F64F )
        if char1 == 0xF0 and char2 == 0x9F then
            if char3 >= 0x98 and char3 <= 0x99 then
                -- char4 ~
                return true
            end
        end

        -- 3. Transport and map symbols ( 1F680 - 1F6C0 )
        if char1 == 0xF0 and char2 == 0x9F and char3 == 0x9A then
            if char4 >= 0x80 and char4 <= 0xBE then
                return true
            end
        end

        if char1 == 0xF0 and char2 == 0x9F and char3 == 0x9B and char4 == 0x80 then
            return true
        end

        -- 4. Enclosed characters ( 24C2 - 1F251 )
        if char1 == 0xF0 and char2 == 0x9F and char3 == 0x85 then
            if char3 >= 0x85 and char3 <= 0x89 then
                -- char4 ~
                return true
            end
        end

        -- 5. Uncategorized
        if char1 == 0xF0 and char2 == 0x9F then
            if char3 >= 0x80 and char3 <= 0x98 then
                -- char4 无限制 （暂时）
                return true
            end
        end

        if char2 == 0xE2 and char3 == 0x83 and char4 == 0xA3 then
            if char1 >= 0x23 and char1 <= 0x39 then
                return true
            end
        end

        -- 6b. Additional transport and map symbols ( 1F681 - 1F6C5 )
        if char1 == 0xF0 and char2 == 0x9F then
            if char3 >= 0x8C and char3 <= 0x95 then
                -- char4
                return true
            end
        end
    end

    if #str == 3 then
        local char1 = string.byte(str, 1)
        local char2 = string.byte(str, 2)
        local char3 = string.byte(str, 3)
        -- 2. Dingbats ( 2702 - 27B0 )
        if char1 == 0xE2 then
            if char2 >= 0x9C and char2 <= 0x9E then
                -- char3 ~
                return true
            end
        end

        -- 3. Transport and map symbols ( 1F680 - 1F6C0 )
        if char1 == 0xE2 and char2 == 0x93 and char3 == 0x82 then
            return true
        end

        -- 5. Uncategorized
        if char1 == 0xE2 then
            if char2 >= 0x80 and char2 <= 0xAD then
                -- char3 无限制（暂时）
                return true
            end
        end
    end

    if #str == 2 then
        local char1 = string.byte(str, 1)
        local char2 = string.byte(str, 2)
        if char1 == 0xc2 and (char2 == 0xA9 or char2 == 0xAE) then
            return true
        end
    end

    if #str == 6 then
        local char1 = string.byte(str, 1)
        local char2 = string.byte(str, 2)
        local char3 = string.byte(str, 3)
        -- 4. Enclosed characters ( 24C2 - 1F251 )  ---- \xE2\x93\x82 --6个字节
        if char1 == 0xF0 and char2 == 0x9F and char3 == 0x87 then
            --6个字节 -- char4 ~ char5 ~ char6 ~
            return true
        end
    end

    return false
end

--非法字符
function serviceFunctions.hasIllegalityWords(words)
    local wordArray = serviceFunctions.convertStringToArray(words)
    if not wordArray then
        return false
    end
    -- local specialChat ={
    --     ["َ"] = true,
    --     ["ً"] = true,
    --     ["ُ"] = true,
    --     ["ٌ"] = true,
    --     ["ِ"] = true,
    --     ["ٍ"] = true,
    --     ["ْ"] = true,
    --     ["ّ"] = true,
    -- }

    -- if string.match(words, "[\"':;/%?><,{}|\\%+=%)%(%*&^$#@!`~%%%-%[%]]") then
    --     return true
    -- end
    local specialChat = {
        ["\0"] = true,
        ["\b"] = true,
        ["\n"] = true,
        ["\r"] = true,
        ["\t"] = true,
        ["\26"] = true,
        ["\\"] = true,
        ["'"] = true,
        ['"'] = true,
        ["("] = true,
        [")"] = true,
        ["（"] = true,
        ["）"] = true,
        ["<"] = true,
        [">"] = true
    }
    for i, v in ipairs(wordArray) do
        if specialChat[v] then
            return true
        end
    end
    -- emoji判断
    for i, v in ipairs(wordArray) do
        if serviceFunctions.isEmojiSymbol(wordArray[i]) then
            return true
        end
    end
    return false
end

-- emoji
function serviceFunctions.hasEmoji(words)
    local wordArray = serviceFunctions.convertStringToArray(words)
    for i, v in ipairs(wordArray) do
        --emoji 表情
        local c = wordArray[i]
        if serviceFunctions.isEmojiSymbol(c) then
            --  Log.i("shieldedWordsltCtrl:hasEmoji error,has emoji")
            return true
        end
    end
    return false
end

-- 四维属性叠加
function serviceFunctions.addAttrs4d(attrs, attrsAdd)
    if attrsAdd then
        for k, v in pairs(attrsAdd) do
            if attrs[k] then
                attrs[k] = attrs[k] + v
            else
                attrs[k] = v
            end
        end
    end
end

-- 四维属性减法
function serviceFunctions.subAttrs4d(attrs, attrsSub)
    if attrsSub then
        for k, v in pairs(attrsSub) do
            attrs[k] = attrs[k] - v
        end
    end
end

-- 获取四维属性总值
function serviceFunctions.getAttrs4dTotal(attrs)
    local total = 0
    for _, v in ipairs(attrs) do
        total = total + v
    end
    return total
end

-- 获取两组属性的差量
function serviceFunctions.getAttrsAddOf(attrs1, attrs2)
    if attrs2 then
        local attrsAdd = {}
        for k, v in pairs(attrs2) do
            attrsAdd[k] = attrs1[k] - v
        end
        return attrsAdd
    end
    return attrs1
end

-- 四维属性加成 (boost:加成千分比)
function serviceFunctions.attrs4dBoost(attrs, boost)
    local retAttrs = {}
    for k, v in pairs(attrs) do
        retAttrs[k] = math.floor(v * (1 + boost / 1000))
    end
    return retAttrs
end

-- 抛出使用道具事件
function serviceFunctions.publishUseItemEvent(uid, id, count)
    local serviceNotify = require("serviceNotify")
    local eventName = gEventName.event_use_item .. "_" .. id
    local event = {
        uid = uid,
        data = {
            id = id,
            num = count
        }
    }
    serviceNotify.publish(uid, eventName, event)
end

--[[
    抛出属性减少事件
    目前只有士兵事件需要curVal
]]
function serviceFunctions.publishDelAttrEvent(uid, id, count, curVal, aid)
    local serviceNotify = require("serviceNotify")
    local gameLib = require("gameLib")
    serviceNotify.publish(
        uid,
        gameLib.getAttrDelName(id),
        {
            uid = uid,
            aid = aid,
            data = {rankKey = tostring(uid), score = count, curVal = curVal, info = {uid = uid}}
        }
    )
end

--[[
    抛出属性减少事件
    目前只有士兵事件需要curVal
]]
function serviceFunctions.publishDelAttrEvents(uid, uses, aid)
    if not uses then
        return
    end
    for _, v in ipairs(uses) do
        serviceFunctions.publishDelAttrEvent(uid, v.id, v.count, v.curVal, aid)
    end
end

return serviceFunctions
