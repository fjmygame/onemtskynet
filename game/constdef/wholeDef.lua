--[[
    全局枚举定义，数量比较小的
--]]
-- 游戏名
gGameName = "KOW"

-- 大区类型定义
gZoneType = {
    None = 0,
    America = 1, -- 美洲
    Europe = 2, -- 欧洲
    SouthEastAsia = 3, -- 东南亚
    EastAsiz = 4 -- 东亚
}

-- 角色状态
gPlayerStatus = {
    normal = 0, -- 正常
    seal = 1, -- 封号
    gdpr = 2, -- GDPR 玩家
    active = 666, -- 活跃(这个状态在数据库存的是0，只有在kingdomweb接口才会动态返回)
    gmSealDetailBase = 1000 -- 1000+  带后台详细封号类型的封号
}

-- 星期
gWeekDay = {
    MONDAY = 1,
    TUESDA = 2,
    WEDNESDAY = 3,
    THURSDAY = 4,
    FRIDAY = 5,
    SATURDAY = 6,
    SUNDAY = 7
}

-- 子嗣性别
gGender = {
    Man = 1, --男
    Woman = 2 --女
}

-- 周期类型定义
gPeriodType = {
    None = 0,
    Daily = 1, -- 每天
    Weekly = 2, -- 每周
    Monthly = 3, -- 每月
    FullReset = 4, -- 限购次数满了重置
    DailyFullReset = 5 -- 每日或购买完毕后无限重置（满足任一规则都进行重置）
}
