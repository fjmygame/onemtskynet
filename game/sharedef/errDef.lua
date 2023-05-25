--[[
网络消息处理错误类型定义
]]
---@class gErrDef
local gErrDef = {
    ----- 通用错误码
    None = 0,
    Err_None = 0, -- 没有错误
    Err_SERVICE_EXCEPTION = 1, -- 服务器异常
    Err_RESOUCH_NOT_REACH = 2, --资源不足
    Err_GOLD_NOT_REACH = 3, --金币不足
    Err_BUY_GOOD_FAILED = 4, --购买物品失败
    Err_CMD_NOT_FOUND = 5, -- 指令未找到
    Err_CLIENT_EXCEPTION = 6, -- 客户端异常
    Err_ILLEGAL_PARAMS = 7, -- 非法的参数
    Err_NOT_IN_THIS_KINGDOM = 8, -- 玩家不在这个王国
    Err_LOCAL_CONFIG_ERROR = 9, -- 配置错误
    Err_LORD_ATTR_NOT_REACH = 10, --领主属性值不足
    Err_REWARD_GOT = 11, -- 奖励已领取
    Err_LORD_ATTR_FULL = 12, -- 属性值已满
    Err_PARAMETER_ERROR = 13, -- 参数错误
    Err_SERVICE_BUSY = 14, -- 服务器繁忙
    Err_NODEID_NOT_EXIST = 15, --节点不存在
    Err_SILVER_NOT_REACH = 16, --银币不足
    Err_PID_ONLY_CHAR_NUM = 17, -- pid只能是字母+数字
    Err_NO_CHANGE = 18, -- 未修改
    Err_NOT_FOUND_USER = 19, -- 未找到玩家
    Err_NOT_BUY_GOODS = 20, --该道具不可购买
    Err_BUY_COUNT_PASS_LIMIT = 21, ---购买数量超过上限
    Err_Reward_Caculate = 22, -- 奖励结算中
    Err_NOT_DEBUG_STATE = 23, -- 不是DEBUG状态
    Err_CONDITION = 24, -- 条件不满足
    Err_NOT_SAME_SERVER = 25, -- 不同服的玩家不可查询
    Err_ITEM_USE_TYPE_ERR = 26, --道具使用类型不对
    Err_ALLIANCE_NOT_EXIST = 27, --联盟不存在
    Err_FUNCTION_NOT_OPEN = 28, --功能未开放
    Err_SERVER_MAINTAIN = 29, -- 服务器维护中
    Err_LORD_INFO_SERVER_MAINTAIN = 30, -- 查询领主信息，服务器维护中
    Err_Proto_Version_NotMatch = 31, -- 协议版本不匹配
    Err_Activation_Code_Channel_Err = 32, -- 激活码渠道参数错误
    Err_PLAYER_PID_ERR = 33, -- PID非法
    Err_PLAYER_GDPR = 34, -- 玩家被gdpr了
    Err_DIAMOND_NOT_REACH = 35, -- 钻石不足
    Err_WebActivity_Mail_Repeat = 36, -- web活动邮件重复了
    Err_Act_No_Certificate = 37, -- 活动没有资格
    Err_Act_Sub_State_Wait = 38, -- 活动子状态为等待中
    Err_Cheat_fail = 39, -- 作弊失败
    Err_Act_Sub_State_No_Playing = 40 -- 活动子状态不在玩法期
}

return gErrDef
