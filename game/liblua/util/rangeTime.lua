-- --------------------------------------
-- Create Date:2023-04-18 15:47:24
-- Author  : sgys
-- Version : 1.0
-- Filename: rangeTime.lua
-- Introduce  : 范围时间
-- --------------------------------------

local rangeTime = BuildUtil("rangeTime")

-- 检查格式是否ok
function rangeTime.fmtOK(time)
	if not time or not time.beginTime or not time.endTime then
		return false
	end
	return true
end

-- 将来时/时间还没到
function rangeTime.future(time)
	local curTime = timeUtil.systemTime()
	return time.beginTime > curTime
end

-- 进行时/在时间范围
function rangeTime.doing(time)
	local curTime = timeUtil.systemTime()
	return curTime >= time.beginTime and curTime <= time.endTime
end

-- 过去时/已过期
function rangeTime.done(time)
	local curTime = timeUtil.systemTime()
	return curTime > time.endTime
end

return rangeTime
