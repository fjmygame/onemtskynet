-- --------------------------------------
-- Create Date:2021-08-30 10:35:01
-- Author  : sgys
-- Version : 1.0
-- Filename: shieldwordsUtil.lua
-- Introduce  : 敏感词处理
-- --------------------------------------

local sharetable = require "skynet.sharetable"
---@class shieldwordsUtil
local _M = BuildUtil("shieldwordsUtil")

function _M:init()
    local conf = sharetable.query("LOCAL_SHIELD_WORDS_CONF")
    self.shieldedWordsSplit_list = conf.shieldedWordsSplit_list
    self.shieldedNameSplit_list = conf.shieldedNameSplit_list
    self.fuzzys = sharetable.query("LOCAL_FUZZY_SHIELD_WORDS_CONF")
end

-- 获取默认语言
function _M:getDefaultLanguage()
    return gTranslateLanguage.en
end

function _M:convertStringToArray(str)
    if "string" ~= type(str) and string.len(str) > 0 then
        return {str}
    end
    local array = {}
    local len = string.len(str)
    local pos = 1
    local arr = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
    while 0 < pos and pos <= len do
        if #array >= 21 then
            table.insert(array, string.sub(str, pos, len))
            break
        end
        local tmp = string.byte(str, pos)
        local i = #arr
        while arr[i] do
            if tmp >= arr[i] then
                local c = string.sub(str, pos, pos + i - 1)
                table.insert(array, c)
                pos = pos + i
                break
            end
            i = i - 1
        end
    end
    return array
end

-- 是否是英文字母
function _M:isEnAlphabet(str)
    if "string" ~= type(str) or "" == str then
        return
    end
    if string.match(str, "%a") then
        return true
    end
    return false
end

function _M:isChatLegality(c)
    return (" " ~= c)
end

function _M:findShieldWord(wordArray, shieldConfig, beginIter, endIter, shieldedWordList)
    local tempConfig = shieldConfig

    local shieldedWord
    local subString
    local subModule

    local tempShieldedWord = ""
    local iter = beginIter
    local beginPos
    local retIter
    local firstIllegalPos

    while tempConfig and iter <= endIter do
        local word = wordArray[iter]
        tempConfig = tempConfig[string.lower(word)]
        if tempConfig then
            if not self:isChatLegality(word) and not firstIllegalPos then
                firstIllegalPos = iter
                retIter = firstIllegalPos
            end

            if not beginPos then
                beginPos = iter
            end
            tempShieldedWord = tempShieldedWord .. word
            if tempConfig["end"] then
                local nextWord = wordArray[iter + 1]
                if not nextWord then
                    shieldedWord = tempShieldedWord
                    -- log.Debug("old","发现屏蔽字$:", shieldedWord, beginPos, iter)
                    retIter = iter
                    if 1 == math.abs(retIter - beginPos) + 1 then
                        subString = "*"
                    else
                        subString = "**"
                    end
                    subModule = 1
                    table.insert(shieldedWordList, {shieldedWord, subModule, subString})

                    return retIter
                elseif not self:isChatLegality(nextWord) then
                    shieldedWord = tempShieldedWord
                    -- log.Debug("old","发现屏蔽字^:", shieldedWord, beginPos, iter)
                    if 1 == math.abs(iter - beginPos) + 1 then
                        subString = "*"
                    else
                        subString = "**"
                    end
                    subModule = 2
                    retIter = iter
                end
            end

            iter = iter + 1
        else
            -- log.Debug("old","结束了！ word, pos = ", word, iter)
            if shieldedWord then
                -- log.Debug("old","有找到屏蔽词 shieldedWord, retIter = ", shieldedWord, retIter)
                table.insert(shieldedWordList, {shieldedWord, subModule, subString})
                return retIter
            else
                -- log.Debug("old","未有找到屏蔽词")
                if firstIllegalPos then
                    -- log.Debug("old","有找到第一个非法字符 firstIllegalPos ", firstIllegalPos)
                    return firstIllegalPos
                else
                    retIter = iter
                    if word and not self:isChatLegality(word) then
                        -- log.Debug("old","结束word 是非法的，返回当前位置")
                        return retIter
                    end

                    -- log.Debug("old","结束word 不是非法的继续走")
                    local nextWord = wordArray[retIter + 1]
                    while nextWord and self:isChatLegality(nextWord) do
                        retIter = retIter + 1
                        nextWord = wordArray[retIter + 1]
                    end
                    return retIter
                end
            end
        end
    end

    if firstIllegalPos then
        -- log.Debug("old","有找到第一个非法字符 firstIllegalPos ", firstIllegalPos)
        return firstIllegalPos
    end

    return endIter
end

-- 语言库屏蔽验证
function _M:languagesShieldCheck(splitList, words)
    local wordArray = self:convertStringToArray(words)
    local function _check(shieldedSplit)
        local n = #wordArray
        local iter = 1
        while iter <= n do
            local pos = iter
            local shieldedWordList = {}
            local nextIter = self:findShieldWord(wordArray, shieldedSplit, pos, n, shieldedWordList)
            if next(shieldedWordList) then
                return true
            end
            iter = nextIter + 1
        end
        return false
    end
    -- 全部语言都要验证
    for _, _shieldedSplit in pairs(splitList) do
        local ok = _check(_shieldedSplit)
        if ok then
            return true
        end
    end
    return false
end

-- 是否有屏蔽名字
function _M:isShieldName(words)
    if "string" ~= type(words) or "" == string.trim(words) then
        return false
    end
    return self:languagesShieldCheck(self.shieldedNameSplit_list, words)
end

-- 是否有屏蔽字
function _M:hasShieldedWord(words)
    if "string" ~= type(words) or "" == words then
        return false
    end
    return self:languagesShieldCheck(self.shieldedWordsSplit_list, words)
end

-- 脏话？
function _M:hasFuzzyWord(name)
    local _check = function(words)
        if not words then
            return false
        end
        for _, word in ipairs(words) do
            if string.find(name, word) then
                return true
            end
        end
        return false
    end
    for _, _words in pairs(self.fuzzys) do
        local ok = _check(_words)
        if ok then
            return true
        end
    end
    return false
end

-- 名字是否敏感
function _M:checkName(name)
    return self:isShieldName(name) or self:hasShieldedWord(name) or self:hasFuzzyWord(name)
end

--------------------- 给客户端用 ---------------
function _M:replaceShieldWord(shieldedWordList, words)
    if "table" == type(shieldedWordList) and next(shieldedWordList) then
        local lastShieldWordInfo = shieldedWordList[#shieldedWordList]
        local shieldedWord = lastShieldWordInfo[1]
        shieldedWord = string.gsub(shieldedWord, "[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
        local subString = lastShieldWordInfo[3]
        if lastShieldWordInfo[2] == 1 then
            words = string.gsub(words, "(" .. shieldedWord .. ")$", subString)
        else
            words = string.gsub(words, shieldedWord .. "(%s+)", subString .. "%1", 1)
        end
    end
    return words
end

-- 用*替换屏蔽字
function _M:replaceShieldedWords(words, language)
    if "string" ~= type(words) or "" == string.trim(words) then
        return words
    end

    local wordArray = serviceFunctions.convertStringToArray(words)
    local n = #wordArray

    local _replace = function(shieldedSplit)
        local iter = 1
        while iter <= n do
            local pos = iter
            local shieldedWordList = {}
            local nextIter = self:findShieldWord(wordArray, shieldedSplit, pos, n, shieldedWordList)
            words = self:replaceShieldWord(shieldedWordList, words)
            iter = nextIter + 1
        end
    end
    local splitList = self.shieldedWordsSplit_list
    for _, _shieldedSplit in pairs(splitList) do
        _replace(_shieldedSplit)
    end
    return words
end

return _M
