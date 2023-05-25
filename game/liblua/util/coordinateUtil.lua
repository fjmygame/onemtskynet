-- --------------------------------
-- Filename: coordinateUtil.lua
-- Project: util
-- Date: 2020-02-13, 4:54:45 pm
-- Author: lxy
-- --------------------------------
--[[
    坐标相关的
]]
local coordinateUtil = BuildUtil("coordinateUtil")

--判断一条线是否经过一个区域
--@p1 线的一个端点结构{x=1,y=1}
--@p2 线的另一个端点结构{x=1,y=1}
--@rang 矩形区域结构{startX=1,startY=1,endX=1,endY=1}
function coordinateUtil.lineIntersectRang(p1, p2, rang)
    if coordinateUtil.getHitPoint(p1, p2, {x = rang.startX, y = rang.startY}, {x = rang.endX, y = rang.startY}) then
        return true
    elseif coordinateUtil.getHitPoint(p1, p2, {x = rang.endX, y = rang.startY}, {x = rang.endX, y = rang.endY}) then
        return true
    elseif coordinateUtil.getHitPoint(p1, p2, {x = rang.startX, y = rang.endY}, {x = rang.endX, y = rang.endY}) then
        return true
    elseif coordinateUtil.getHitPoint(p1, p2, {x = rang.startX, y = rang.startY}, {x = rang.startX, y = rang.endY}) then
        return true
    else
        --skynet.error(string.safeFormat("coordinateUtil.lineIntersectRang false,x=%d,y=%d,x1=%d,y1=%d,startX=%d,startY=%d,endX=%d,endY=%d", p1.x, p1.y, p2.x, p2.y, rang.startX, rang.startY, rang.endX, rang.endY))
        return false
    end
end

--计算p1,p2组成的线段和p3,p4组成的线段的交点
function coordinateUtil.getHitPoint(p1, p2, p3, p4)
    --根据数学,求出直接的表达示:y=kx+b
    local p = nil
    --是否平行
    local isParallel = false

    --两条线均不与Y轴平行
    if p1.x ~= p2.x and p3.x ~= p4.x then
        local k1 = (p1.y - p2.y) / (p1.x - p2.x)
        local b1 = p1.y - k1 * p1.x

        local k2 = (p3.y - p4.y) / (p3.x - p4.x)
        local b2 = p3.y - k2 * p3.x

        --两条线平行
        if k1 == k2 then
            isParallel = true
            return nil, isParallel
        end

        p = {}
        p.x = -(b1 - b2) / (k1 - k2)
        p.y = (k1 * b2 - k2 * b1) / (k1 - k2)
    else
        local k
        local b
        --经过p1,p2的直线与y轴平行,
        if (p1.x == p2.x and p3.x ~= p4.x) then
            k = (p3.y - p4.y) / (p3.x - p4.x)
            b = p3.y - k * p3.x

            p = {}
            p.x = p1.x
            p.y = k * p.x + b
        elseif (p1.x ~= p2.x) then
            k = (p1.y - p2.y) / (p1.x - p2.x)
            b = p1.y - k * p1.x

            p = {}
            p.x = p3.x
            p.y = k * p.x + b
        end
    end

    --如果两条线段没有相交,延长线相交则返回nil
    if p then
        p.x = tonumber(tostring(p.x))
        p.y = tonumber(tostring(p.y))
        if
            (p.x < math.min(p1.x, p2.x) or p.x > math.max(p1.x, p2.x) or p.x < math.min(p3.x, p4.x) or
                p.x > math.max(p3.x, p4.x) or
                p.y < math.min(p1.y, p2.y) or
                p.y > math.max(p1.y, p2.y) or
                p.y < math.min(p3.y, p4.y) or
                p.y > math.max(p3.y, p4.y))
         then
            return nil, isParallel
        end
    end

    return p, isParallel
end

-- 计算两点之间的距离
function coordinateUtil.lineSpace(x1, y1, x2, y2)
    local lineLength = math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2))
    return lineLength
end

--点到线段距离
function coordinateUtil.pointToLine(x1, y1, x2, y2, x0, y0)
    local space
    local a, b, c
    a = coordinateUtil.lineSpace(x1, y1, x2, y2) -- 线段的长度
    b = coordinateUtil.lineSpace(x1, y1, x0, y0) -- (x1,y1)到点的距离
    c = coordinateUtil.lineSpace(x2, y2, x0, y0) -- (x2,y2)到点的距离
    if (c <= 0.000001 or b <= 0.000001) then
        space = 0
        return space
    end
    if (a <= 0.000001) then
        space = b
        return space
    end
    if (c * c >= a * a + b * b) then
        space = b
        return space
    end
    if (b * b >= a * a + c * c) then
        space = c
        return space
    end
    local p = (a + b + c) / 2 -- 半周长
    local s = math.sqrt(p * (p - a) * (p - b) * (p - c)) -- 海伦公式求面积
    space = 2 * s / a -- 返回点到线的距离（利用三角形面积公式求高）
    return space
end

--计算地图两点间距离
function coordinateUtil.getMapDistance(x1, y1, x2, y2)
    return math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2)) * 100
end

--计算地图两点间距离
function coordinateUtil.getTwoPointDistance(x1, y1, x2, y2)
    return math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2))
end

--两点是否相等
function coordinateUtil.isPointSame(p1, p2)
    return p1.x == p2.x and p1.y == p2.y
end

-- 模糊对比
-- 返回：true, 优先级 或 false
-- 完全匹配(1) > 其他匹配(2)
function coordinateUtil.vagueCompare(comStr, origStr)
    if "string" == type(comStr) and "string" == type(origStr) then
        -- 判断是否完全一样
        if comStr == origStr then
            return true, 1
        end

        -- 都转化为小写
        origStr = string.lower(origStr)
        comStr = string.lower(comStr)

        -- 匹配
        local ret = string.match(origStr, "^(" .. comStr .. ")")
        if ret then
            return true, 2
        end
    end

    return false
end

function coordinateUtil.pIsSegmentIntersect(pt1, pt2, pt3, pt4)
    local s, t = 0, 0
    local ret
    ret, s, t = coordinateUtil.pIsLineIntersect(pt1, pt2, pt3, pt4, s, t)

    if ret and s >= 0.0 and s <= 1.0 and t >= 0.0 and t <= 1.0 then
        return true
    end
    --skynet.error(3,s, t)
    return false
end

function coordinateUtil.pIsLineIntersect(A, B, C, D, s, t)
    if ((A.x == B.x) and (A.y == B.y)) or ((C.x == D.x) and (C.y == D.y)) then
        --skynet.error(1,s, t)
        return false, s, t
    end

    local BAx = B.x - A.x
    local BAy = B.y - A.y
    local DCx = D.x - C.x
    local DCy = D.y - C.y
    local ACx = A.x - C.x
    local ACy = A.y - C.y

    local denom = DCy * BAx - DCx * BAy
    s = DCx * ACy - DCy * ACx
    t = BAx * ACy - BAy * ACx

    if (denom == 0) then
        if (s == 0 or t == 0) then
            return true, s, t
        end
        --skynet.error(2,s, t)
        return false, s, t
    end

    s = s / denom
    t = t / denom

    return true, math.abs(s), math.abs(t)
end

--判断线段是否和矩形的四条边相交
function coordinateUtil.pLineIntersectRect(p1, p2, rang)
    if coordinateUtil.pIsSegmentIntersect(p1, p2, {x = rang.startX, y = rang.startY}, {x = rang.endX, y = rang.startY}) then
        return true
    elseif coordinateUtil.pIsSegmentIntersect(p1, p2, {x = rang.endX, y = rang.startY}, {x = rang.endX, y = rang.endY}) then
        return true
    elseif coordinateUtil.pIsSegmentIntersect(p1, p2, {x = rang.endX, y = rang.endY}, {x = rang.startX, y = rang.endY}) then
        return true
    elseif
        coordinateUtil.pIsSegmentIntersect(p1, p2, {x = rang.startX, y = rang.endY}, {x = rang.startX, y = rang.startY})
     then
        return true
    else
        --skynet.error(string.safeFormat("coordinateUtil.lineIntersectRang false,x=%d,y=%d,x1=%d,y1=%d,startX=%d,startY=%d,endX=%d,endY=%d", p1.x, p1.y, p2.x, p2.y, rang.startX, rang.startY, rang.endX, rang.endY))
        return false
    end
end

--获取最后指定位数的数字
--@orgValue 原始值
--@digitNum 取最后多少位
function coordinateUtil.getLastDigit(orgValue, digitNum)
    if not digitNum or type(digitNum) ~= "number" then
        return orgValue
    end
    local ratio = 10 ^ digitNum
    local result = orgValue - math.floor(orgValue / ratio) * ratio
    return result
end

function coordinateUtil.getMapKey(x, y)
    return math.floor(x * 10000 + y)
end

function coordinateUtil.isInRang(x, y, rang)
    --skynet.error("function coordinateUtil.isInRang", x, y, rang)
    if x >= rang.startX and x <= rang.endX and y >= rang.startY and y <= rang.endY then
        return true
    else
        return false
    end
end

function coordinateUtil.isInRangs(x, y, rangs, startXKey, startYKey, endXKey, endYKey)
    for _, rang in pairs(rangs) do
        if
            x >= rang[startXKey or "startX"] and x <= rang[endXKey or "endX"] and y >= rang[startYKey or "startY"] and
                y <= rang[endYKey or "endY"]
         then
            return true
        end
    end
    return false
end

--是否在黑土地
function coordinateUtil.isInRangBySquare(x, y, size, rang)
    for itX = x, x + size - 1 do
        for itY = y, y + size - 1 do
            if coordinateUtil.isInRang(itX, itY, rang) then
                return true
            end
        end
    end
    return false
end
return coordinateUtil
