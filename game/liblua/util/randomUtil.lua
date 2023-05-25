-- randomUtil.lua
--[[
	随机工具
]]
---@class randomUtil
local randomUtil = BuildUtil("randomUtil")

local randomSeed
-- 设置随机种子
function randomUtil.setRandomSeed(num)
    randomSeed = num or tostring(timeUtil.systemTime()):reverse():sub(1, 6)
    math.randomseed(randomSeed)
end

-- 生成一个随机种子
function randomUtil.genSeed()
    local seed = tostring(timeUtil.systemTime()):reverse():sub(1, 6)
    return seed
end

function randomUtil.random(min, max)
    if not randomSeed then
        randomUtil.setRandomSeed()
    end
    return math.random(min, max)
end
local random = randomUtil.random

--随机一个范围(min, max)内的数字，和给定的数字(num)比较，如果小于等于为true,大于为false
--min,max默认为（1, 1000）
function randomUtil.isRandomSuccess(num, min, max)
    if not min then
        min = 1
    end
    if not max then
        max = 1000
    end
    return random(min, max) <= num
end

-- 洗牌
function randomUtil.shuffle(tbl)
    local size = #tbl
    for i = size, 1, -1 do
        local rand = random(1, size)
        tbl[i], tbl[rand] = tbl[rand], tbl[i]
    end
    return tbl
end

--随机一个概率范围内的索引
--@rates {100, 200, 700}
function randomUtil.getRandomIndex(rates)
    --计算概率总和
    local totalRate = 0
    for _, rate in ipairs(rates) do
        totalRate = totalRate + rate
    end
    if totalRate > 0 then
        local randNum = random(1, totalRate)
        local index = 1
        local curTotalRate = 0
        for _, rate in ipairs(rates) do
            curTotalRate = curTotalRate + rate
            if randNum <= curTotalRate then
                return index
            end
            index = index + 1
        end
    end
end
local getRandomIndex = randomUtil.getRandomIndex

--随机一个概率范围内的索引
--@rates {100, 200, 700} totalRate:rates总和不要每次求和
function randomUtil.randomIndex(rates, totalRate)
    --计算概率总和
    if totalRate > 0 then
        local randNum = random(1, totalRate)
        local index = 1
        local curTotalRate = 0
        for _, rate in pairs(rates) do
            curTotalRate = curTotalRate + rate
            if randNum <= curTotalRate then
                return index
            end
            index = index + 1
        end
    end
end

--------------------------------------------------------------
-- 随机库

--[[
itemList = { -- 随机列表
	[1] = {
		["id"] = xx,	-- ID
		["count"] = xx,	-- 数量(缺省值)
		["rate"] = xxx, -- 概率
	},...
}
num 随机次数(缺省值 默认一次)
unrepeat 多次随机不重复获得
]]
function randomUtil.multiRandom(itemList, num, unrepeat)
    num = num or 1

    local rates = {}
    for _, item in ipairs(itemList) do
        table.insert(rates, item.rate)
    end

    local ret = {}
    for i = 1, num do
        local index = getRandomIndex(rates)
        local item = itemList[index]
        if item then
            table.insert(ret, {id = item.id, count = item.count})
            if unrepeat then
                rates[index] = 0
            end
        end
    end
    return ret
end

--[[
    逻辑同randomUtil.multiRandom
    新增抛弃id为0的奖励
]]
function randomUtil.multiRandomDropZero(itemList, num, unrepeat)
    local ret = {}

    if not itemList or #itemList <= 0 then
        return ret
    end

    num = num or 1

    local rates = {}
    for _, item in ipairs(itemList) do
        table.insert(rates, item.rate)
    end

    for i = 1, num do
        local index = getRandomIndex(rates)
        local item = itemList[index]
        if item and item.id > 0 and item.count > 0 then
            table.insert(ret, {id = item.id, count = item.count})
            if unrepeat then
                rates[index] = 0
            end
        end
    end
    return ret
end

--[[
-- 一组随机，每个随机独立
itemList = { -- 随机列表
    [1] = {
        ["id"] = xx,    -- ID
        ["count"] = xx, -- 数量(缺省值)
        ["rate"] = xxx, -- 概率[千分比 500=50%]
    },...
}
num 随机几次
]]
function randomUtil.aloneRandom(itemList, num)
    num = num or 1
    local ret = {}
    local temp = {}
    for i = 1, num do
        for _, v in ipairs(itemList) do
            local rand = random(1, 1000)
            if v.rate >= rand then
                if not temp[v.id] then
                    temp[v.id] = v.count
                else
                    temp[v.id] = temp[v.id] + v.count
                end
            end
        end
    end

    -- 组成起来
    for k, v in pairs(temp) do
        table.insert(ret, {id = k, count = v})
    end
    return ret
end

--- itemList中随机取num个元素
-- 不重复随机[如果随机数>库存，则返回全部]
function randomUtil.unrepeat(dest, num)
    num = num or 1
    local rates = {}
    for _, v in ipairs(dest) do
        table.insert(rates, 1)
    end

    if num >= #dest then -- 超过最大值了，不用随机
        return dest
    end

    local ret = {}
    for i = 1, num do
        local index = getRandomIndex(rates)
        local item = dest[index]
        if item then
            table.insert(ret, item)
            rates[index] = 0
        end
    end
    return ret
end

--按概率不重复取n个元素
function randomUtil.unrepeatWithRate(dest, num)
    num = num or 1
    local rates = {}
    for i, v in ipairs(dest) do
        rates[i] = v.rate
    end

    if num >= #dest then -- 超过最大值了，不用随机
        return dest
    end

    local ret = {}
    for i = 1, num do
        local index = getRandomIndex(rates)
        local item = dest[index]
        if item then
            table.insert(ret, item)
            rates[index] = 0
        end
    end
    return ret
end

function randomUtil.sortFunc(l, r)
    return l.rate > r.rate
end

--[[
-- 计算权重
itemList = { -- 随机列表
    [1] = {
        ["xxxx"] = xx, -- 数量(缺省值)
        ["rate"] = xxx, -- 权重[有权重就可以用]
    },...
}
一定要有rate字段
返回: newItems, totalRate: 计算好权重的数组,权重总和
]]
function randomUtil.calcRate(itemList)
    local newItems = {}
    local totalRate = 0
    for _, v in ipairs(itemList) do
        local temp = table.copy(v)
        temp.rate = v.rate + totalRate -- make list in order
        table.binaryInsert(newItems, temp, randomUtil.sortFunc)
        totalRate = totalRate + v.rate
    end

    return {
        itemList = newItems,
        totalRate = totalRate
    }
end

--[[
-- 随机物品列表，列表返回前做整理合并，itemList必须符合规则
data.itemList  -- 已经算好权重
data.totalRate -- 权重总和
itemList = { -- 随机列表
    [1] = {
        ["id"] = xx,    -- ID
        ["count"] = xx, -- 数量(缺省值)
        ["rate"] = xxx, -- 权重[有权重就可以用]
    },...
}
num 随机几次
]]
function randomUtil.randomItems(data, num)
    if not data or not data.itemList or not data.totalRate then
        log.Warn("sys", "randomUtil.randomItems", dumpTable(data), debug.traceback())
        return false
    end
    local dataItemSize = #data.itemList
    if dataItemSize <= 0 or data.totalRate <= 0 then
        return false
    end

    if not num then
        num = 1
    end

    local temp = {}
    local numMap = {} -- 详细的随机结果
    for i = 1, num do
        local index
        if dataItemSize == 1 then
            index = 1
        else
            local rand = random(1, data.totalRate)
            index = table.binaryFind(data.itemList, {rate = rand}, randomUtil.sortFunc)
        end

        local item = data.itemList[index]
        if item.id > 0 then
            if not temp[item.id] then
                temp[item.id] = item.count
            else
                temp[item.id] = temp[item.id] + item.count
            end
        end
        numMap[index] = numMap[index] and numMap[index] + 1 or 1
    end

    local ret = {}
    -- 组成起来
    for k, v in pairs(temp) do
        table.insert(ret, {id = k, count = v})
    end

    local details = {}
    for index, randnum in pairs(numMap) do
        local item = data.itemList[index]
        table.insert(details, {id = item.id, count = item.count, randnum = randnum})
    end

    if #ret <= 0 then
        log.ErrorStack("sys", "randomItems temp", dumpLuaTable(temp))
    end

    return true, ret, details
end

--[[
-- 普通随机不对内容处理
data.itemList  -- 已经算好权重
data.totalRate -- 权重总和
itemList = { -- 随机列表
    [1] = {
        ["xxxx"] = xx,
        ["rate"] = xxx, -- 权重[有权重就可以用]
    },...
}
num 随机几次
]]
function randomUtil.normalRandom(data, num)
    if not data or not data.itemList or not data.totalRate then
        return false
    end

    if not num then
        num = 1
    end

    local ret = {}
    for i = 1, num do
        local rand = random(1, data.totalRate)
        local index = table.binaryFind(data.itemList, {rate = rand}, randomUtil.sortFunc)
        local item = data.itemList[index]
        table.insert(ret, table.copy(item))
    end
    return true, ret
end

function randomUtil.randomOne(data)
    if data.totalRate > 0 then
        local rand = random(1, data.totalRate)
        local index = table.binaryFind(data.itemList, {rate = rand}, randomUtil.sortFunc)
        local item = data.itemList[index]
        return table.copy(item), index
    end
end

-- 去重随机[需要一个唯一的key(比如id)来区分是否是相同]
--[[
itemList = { -- 随机列表
    [1] = {
        ["xxxx"] = xx, -- 数量(缺省值)
        ["rate"] = xxx, -- 权重[有权重就可以用]
    },...
}
一定要有rate字段
]]
function randomUtil.distinctRandom(itemList, uniquekey, num)
    if not itemList or not next(itemList) then
        return false
    end
    if not uniquekey then
        log.ErrorStack("sys", "randomUtil.distinctRandom uniquekey is nil.")
        return false
    end
    -- 验证下key是否存在
    if not itemList[1][uniquekey] then
        log.ErrorStack(
            "sys",
            "randomUtil.distinctRandom uniquekey is err.",
            uniquekey,
            dumpTable(itemList, "itemList", 10)
        )
        return false
    end
    -- 防止篡改外部数据，这里copy下数据
    local itemListCopy = table.copy(itemList)
    if not num then
        num = 1
    end
    local ret = {}
    for i = 1, num do
        if not next(itemListCopy) then
            log.ErrorStack("sys", "randomUtil.distinctRandom num is too large.", i, num, #itemList)
            break
        end
        local data = randomUtil.calcRate(itemListCopy)
        local rand = random(1, data.totalRate)
        local index = table.binaryFind(data.itemList, {rate = rand}, randomUtil.sortFunc)
        local item = data.itemList[index]
        table.insert(ret, item)
        -- 随到过的删除掉
        local id = item[uniquekey]
        for j = #itemListCopy, 1, -1 do
            if itemListCopy[j][uniquekey] == id then
                table.remove(itemListCopy, j)
                break
            end
        end
    end
    return true, ret
end

---- 放入一整张配置，取出其中一条
function randomUtil.randomOneData(cfg)
    local totalRate = 0
    local randomList = {}
    for index, v in pairs(cfg) do
        totalRate = totalRate + v.rate
        randomList[#randomList + 1] = {index = index, rate = totalRate}
    end

    local num = random(1, totalRate)
    for _, v in ipairs(randomList) do
        if num <= v.rate then
            local index = v.index
            return cfg[index], index
        end
    end
end

--- 随机出物品，可能会为空，也就是说没有得到奖励，如果权重有另外传的话，默认权重是总和
---itemList 必须是{{"id":xxx,"count":xxx, "rate":xxxx}, ...}格式
function randomUtil.randomReward(itemList, weight)
    local total_weight = 0
    local rewardList = {}
    for _, v in pairs(itemList) do
        local reward = v
        total_weight = total_weight + v.rate
        reward.rate = total_weight
        rewardList[#rewardList + 1] = reward
    end
    if weight and weight > total_weight then
        total_weight = weight
    end
    local get_reward = {}
    ---- 进行计算概率
    local random_num = randomUtil.random(1, total_weight)
    for k, v in pairs(rewardList) do
        if random_num <= v.rate then
            get_reward = {id = v.id, count = v.count}
            break
        end
    end
    --没有获得奖励
    if not next(get_reward) then
        return false
    end
    return true, get_reward
end

--- 该接口不要求itemlist物品下标一定按照顺序，返回最终获得得奖励和下标
--[[
    要求必须是以下格式
    itemList = { -- 随机列表
	[1] = {
		["id"] = xx,	-- ID
		["count"] = xx,	-- 数量(缺省值)
		["rate"] = xxx, -- 概率
	}，.....
]]
function randomUtil.randomUnorderReward(itemList)
    if not itemList then
        return
    end
    local totalRate = 0
    local newRewardList = {}
    for k, v in pairs(itemList) do
        totalRate = totalRate + v.rate
        newRewardList[#newRewardList + 1] = {
            id = v.id,
            count = v.count,
            rate = totalRate,
            index = k
        }
    end
    local rate = randomUtil.random(1, totalRate)
    for k, v in pairs(newRewardList) do
        if rate <= v.rate then
            return {id = v.id, count = v.count}, v.index
        end
    end
end

-- 随机一个静默期的时间戳【从凌晨2点到4点随机一个时间】
function randomUtil.randomSilentTime()
    return randomUtil.random(7200, 14400)
end

-- 随机性别
function randomUtil.randomGender()
    if randomUtil.isRandomSuccess(500) then
        return gGender.Man
    end
    return gGender.Woman
end

return randomUtil
