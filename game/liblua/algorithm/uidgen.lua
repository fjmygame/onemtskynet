--------------------------------------------------------------------------------
-- 文件: uidgen.lua
-- 作者: zkb
-- 时间: 2020-04-17 09:22:13
-- 描述: uid混淆
--------------------------------------------------------------------------------
local uidgen = {}

-- 进制字母
local codekey = {
    [0] = "0",
    "D",
    "X",
    "2",
    "I",
    "1",
    "N",
    "Q",
    "L",
    "Y",
    "J",
    "5",
    "R",
    "U",
    "T",
    "P",
    "A",
    "3",
    "V",
    "K",
    "9",
    "F",
    "7",
    "H",
    "4",
    "G",
    "W",
    "B",
    "M"
}

local generateCodeLen1 = 9
local generateCodeLen2 = 11
local move_uid_limit = 1000000 * 100000
local _index = 0
local function generateIndex()
    _index = _index + 1
    return _index
end
local codekey_value = {
    ["0"] = 0,
    ["D"] = generateIndex(),
    ["X"] = generateIndex(),
    ["2"] = generateIndex(),
    ["I"] = generateIndex(),
    ["1"] = generateIndex(),
    ["N"] = generateIndex(),
    ["Q"] = generateIndex(),
    ["L"] = generateIndex(),
    ["Y"] = generateIndex(),
    ["J"] = generateIndex(),
    ["5"] = generateIndex(),
    ["R"] = generateIndex(),
    ["U"] = generateIndex(),
    ["T"] = generateIndex(),
    ["P"] = generateIndex(),
    ["A"] = generateIndex(),
    ["3"] = generateIndex(),
    ["V"] = generateIndex(),
    ["K"] = generateIndex(),
    ["9"] = generateIndex(),
    ["F"] = generateIndex(),
    ["7"] = generateIndex(),
    ["H"] = generateIndex(),
    ["4"] = generateIndex(),
    ["G"] = generateIndex(),
    ["W"] = generateIndex(),
    ["B"] = generateIndex(),
    ["M"] = generateIndex()
}
-- 编码不足时的随机替代字母，无含义
local fillingkey = {
    "E",
    "S",
    "6",
    "C",
    "8"
}
local fillNum = #fillingkey -- 填充的个数

function uidgen.checkPid(pid)
    if not pid or (string.len(pid) ~= generateCodeLen1 and string.len(pid) ~= generateCodeLen2) then
        return false
    end
    return true
end

function uidgen.encode(uid)
    local id = uid
    if not uid or "number" ~= type(uid) then
        return
    end

    local baseNum = #codekey
    local codeStr = ""
    while id > 0 do
        local curValue = id % baseNum
        id = (id - curValue) / baseNum
        codeStr = codekey[curValue] .. codeStr
    end

    local curLen = #codeStr
    assert(curLen <= generateCodeLen1, "err uid:" .. uid .. " err code:" .. codeStr)
    local destNum = generateCodeLen1
    -- 迁服的uid，pid为11位
    if uid > move_uid_limit then
        destNum = generateCodeLen2
    end
    while #codeStr < destNum do
        local index = (uid % #codeStr) % fillNum + 1
        codeStr = fillingkey[index] .. codeStr
    end

    return codeStr
end

function uidgen.decode(codeStr)
    local uid = 0
    codeStr = string.upper(codeStr)
    local codeLen = #codeStr
    local baseNum = #codekey
    for index = 0, codeLen - 1 do
        local codeIndex = codeLen - index
        local code = string.sub(codeStr, codeIndex, codeIndex)
        local value = codekey_value[code]
        if value then
            uid = baseNum ^ index * value + uid
        end
    end
    return math.floor(uid)
end

return uidgen
