-- --------------------------------------
-- Create Date:2019-09-04 10:26:06
-- Author  : Happy Su
-- Version : 1.0
-- Filename: connectionmgr.lua
-- Introduce  : udp连接管理类
-- --------------------------------------

local skynet = require "skynet"
local conncommon = require "conncommon"
local Connlt = require "connlt"
local socketdriver = require "socketdriver"
local KCP = require "lkcp"
local netlog = require "netlog"
local _M = class("ConnectionMgr")

local cmd_eConn_ret_str = string.pack(">I2", conncommon.eConnCmd.eConnect_ret)
local cmd_eConn_dis_str = string.pack(">I2", conncommon.eConnCmd.eDisconnect)

local kcp_connection_timeout_time = 10 * 100 -- 10s
local kcp_connection_wait_sec = 5 * 100 -- 5s

local eDisconnectType = conncommon.eDisconnectType

local MIN_CONV = 1000
local MAX_CONV = 0xfffffff

local _maxclient  -- max client
local _client_number = 0
local _cur_conv = MIN_CONV

local function UDPAddressToKey(from)
    local addr, port = socketdriver.udp_address(from)
    return addr .. ":" .. port
end

function _M:ctor()
    self._connMap = {} -- [conv] = conn
    self._fromConvMap = {} -- [form] = conv
    self._releaseMap = {} -- [conv] = conn 等待删除的连接
end

-- ------------------------ private ------------------------

-- 生成一个conv
function _M:get_new_conv()
    _cur_conv = _cur_conv + 1
    if _cur_conv >= MAX_CONV then
        _cur_conv = MIN_CONV + 1
    end
    return _cur_conv | (math.random(15) << 28)
end

-- 获取连接
function _M:_get_conn(conv)
    return self._connMap[conv]
end

-- 增加连接
function _M:_add_new_conn(conv, flowid, from, fromstr)
    local conkey = math.random(1000000)
    self._connMap[conv] = Connlt.new(conv, flowid, conkey, from, fromstr, self._udp)
    self._fromConvMap[fromstr] = conv
    netlog.udp_log(string.safeFormat("new conn fromstr:%s conv:%s conkey:%s", fromstr, conv, conkey))
    return conkey
end

-- 修改连接
function _M:_change_conn(conn, flowid, conv, oldFromStr, from, fromstr)
    conn:resetFrom(from, fromstr, flowid)

    self._fromConvMap[oldFromStr] = nil
    self._fromConvMap[fromstr] = conv

    netlog.udp_log(
        string.safeFormat("process _change_conn conv:%s oldFromStr:%s fromstr:%s", conv, oldFromStr, fromstr)
    )
end

-- 移除连接
function _M:_remove_conn(fromstr, bNow)
    local conv = self._fromConvMap[fromstr]
    if conv then
        self._fromConvMap[fromstr] = nil
        local conn = self._connMap[conv]
        self._connMap[conv] = nil
        if not bNow and conn then
            conn:setExpireTime(skynet.now() + kcp_connection_wait_sec)
            self._releaseMap[conv] = conn
        end
        _client_number = _client_number - 1
    end
end

-- 处理新连接
function _M:_handle_connect_packet(conv, flowid, conkey, from)
    netlog.udp_log("_handle_connect_packet, conv:", conv, flowid, conkey, from)
    local data =
        cmd_eConn_ret_str .. string.pack(">I2", flowid) .. string.pack(">I4", conv) .. string.pack(">I4", conkey)
    socketdriver.udp_send(self._udp, from, string.pack(">s2", data))
end

-- 处理重连回包
function _M:_handle_reconnect_packet(conv, flowid, conkey, from)
    local data =
        cmd_eConn_ret_str .. string.pack(">I2", flowid) .. string.pack(">I4", conv) .. string.pack(">I4", conkey)
    socketdriver.udp_send(self._udp, from, string.pack(">s2", data))
end

-- 处理连接断开
function _M:_handle_disconnect_packet(from, flowid, distype, conv)
    distype = distype or 0
    conv = conv or 0
    local data =
        cmd_eConn_dis_str .. string.pack(">I2", flowid) .. string.pack(">I4", conv) .. string.pack(">I4", distype)
    socketdriver.udp_send(self._udp, from, string.pack(">s2", data))
end

-- ------------------------ public ------------------------
function _M:open(address, port, maxclient)
    self._udp = socketdriver.udp(address, port)
    _maxclient = maxclient or 1024
    skynet.error(string.safeFormat("UDP Listen on %s:%d maxclient:%s", address, port, maxclient))
    return self._udp
end

function _M:close()
    assert(self._udp)
    socketdriver.close(self._udp)
    self._udp = nil
end

local function new_conn(self, from, data, index)
    -- 流水id，如果当前连接的流水id更大，则忽略小id的请求
    local flowid
    flowid, index = string.unpack(">I2", data, index)

    --[[
        进来可能性
        1.新连接第一次请求(建立新连接，回秘钥)
        2.新连接没收到之前的回包，再次请求(是否直接用之前的连接，还是重新建立呢？)
        3.还有可能是网络原因，收到了之前的建立连接请求，这时候如果断开，那可能就把正常连接给踢了
    ]]
    -- TODOS：是否要判断 from 的存在性，然后判断状态？
    -- TODOS: 这里可能更需要直接踢掉老连接，新连接顺利继续下去（因为老连接可能废弃了，这样会导致新连接一直无法建立）
    local fromstr = UDPAddressToKey(from)
    local old_conv = self._fromConvMap[fromstr]
    if old_conv then
        local oldConn = self:_get_conn(old_conv)
        -- TODOS:网络上的延迟包，直接忽略了，也可能是客户端杀端之后重新请求了
        if oldConn:isOldFlowID(flowid) then
            return
        end

        if oldConn:getRecvTag() then
            netlog.LOG_WARNING("new_conn warn getRecvTag true when new_conn from:", fromstr)
        end

        --[[
            这种情况只能是客户端没收到握手回包，重新握手请求
            重回握手包
        ]]
        self:_handle_connect_packet(old_conv, flowid, oldConn:getConKey(), from)
        return
    end

    -- 连接数满了，就不增加了
    if _client_number > _maxclient then
        -- 发送消息给客户端，连接断开
        self:_handle_disconnect_packet(from, flowid, eDisconnectType.linkmax)
        return
    end

    local conv = self:get_new_conv()
    local conKey = self:_add_new_conn(conv, flowid, from, fromstr)

    _client_number = _client_number + 1

    -- 发握手包
    self:_handle_connect_packet(conv, flowid, conKey, from)
    -- 通知新连接建立
    self._connect_func(conv, UDPAddressToKey(from))
end

local function reconn(self, from, data, index)
    local conv, flowid, conKey
    flowid, index = string.unpack(">I2", data, index)
    conv, index = string.unpack(">I4", data, index)
    conKey, index = string.unpack(">I4", data, index)
    local conn = self:_get_conn(conv)
    if not conn then
        netlog.udp_log("process reconn tag 1")
        -- 发送消息给客户端，连接断开
        self:_handle_disconnect_packet(from, flowid, eDisconnectType.unfoundcon, conv)
        return
    end

    -- 网络上的延迟包，直接忽略了
    if conn:isOldFlowID(flowid) then
        -- TODOS:是否需要回包？
        return
    end

    if not conn:checkConKey(conKey) then
        netlog.udp_log("process reconn tag 2")
        -- 发送消息给客户端，连接断开
        self:_handle_disconnect_packet(from, flowid, eDisconnectType.errkey, conv)
        return
    end

    -- 检查ip/port是否改变，没变不处理
    if conn:checkFrom(from) then
        netlog.udp_log("process reconn tag 3")
        return
    end

    local oldFromStr = conn:getFromStr()
    local fromstr = UDPAddressToKey(from)
    self:_change_conn(conn, flowid, conv, oldFromStr, from, fromstr)

    -- 发握手包
    self:_handle_reconnect_packet(conv, flowid, conKey, from)
    -- 通知重连
    -- self._connect_func(conv, UDPAddressToKey(from))
end

local function data_conn(self, from, data)
    netlog.udp_log("data_conn 11111")
    if string.len(data) < 24 then
        return
    end

    local conv = KCP.lkcp_getconv(data)
    netlog.udp_log(string.safeFormat("data_conn conv:%s datalen:%s", conv, string.len(data)))
    local conn = self:_get_conn(conv)
    if not conn then
        netlog.udp_log("data_conn 22222")
        -- 发送消息给客户端，连接断开
        -- TODOS:这里没有flowid，如果这个网络包只网络中滞留了，很危险~
        self:_handle_disconnect_packet(from, 0, eDisconnectType.unfoundcon, conv)
        return
    end

    -- 校验四元组
    if not conn:checkFrom(from) then
        -- 发送消息给客户端，连接断开
        self:_handle_disconnect_packet(from, conn:getFlowID(), eDisconnectType.fromchange, conv)
        return
    end

    -- 输入数据
    conn:input(data)

    -- 考虑到可能输出多包
    while true do
        local buff = conn:recv()
        if buff then
            self._data_func(conv, buff)
        else
            break
        end
    end
end

local cmd_cfg = {
    [conncommon.eConnCmd.eConnect_req] = new_conn,
    [conncommon.eConnCmd.eData] = data_conn,
    [conncommon.eConnCmd.eReconnect_req] = reconn
}
-- 接收消息
function _M:handle_udp_receive_from(from, data)
    local len = string.len(data)
    if len >= 24 then
        data_conn(self, from, data)
    else
        local packagesize, index = string.unpack(">I2", data)
        if packagesize + 2 ~= len then
            netlog.LOG_WARNING(
                "unknow conn data from:%s packagesize:%s totalsize:%s",
                UDPAddressToKey(from),
                packagesize,
                len
            )
            return
        end
        local cmd
        cmd, index = string.unpack(">I2", data, index)
        local cmdfuc = cmd_cfg[cmd]
        if cmdfuc then
            cmdfuc(self, from, data, index)
        else
            -- 未知cmd
            netlog.LOG_WARNING("unknow conn cmd:%s from:%s", cmd, UDPAddressToKey(from))
        end
    end
end

-- 断开连接
function _M:disconnectclient(conv, fromstr)
    self:_remove_conn(fromstr)
    -- 通知断开回调(去掉阻塞了)
    self._disconnect_func(conv)
end

-- 释放连接
function _M:releaseclient(conv, distype)
    local conn = self:_get_conn(conv)
    if not conn then
        return
    end

    -- 移除连接
    local from = conn:getFrom()
    local fromstr = conn:getFromStr()
    -- 发连接断开包
    self:_handle_disconnect_packet(from, conn:getFlowID(), distype)
    -- 断开连接
    self:disconnectclient(conv, fromstr)
end

-- 设置事件回调函数（三个函数都不能阻塞！！！）
function _M:set_callback(connect_func, disconnect_func, data_func)
    assert(connect_func)
    assert(disconnect_func)
    assert(data_func)
    self._connect_func = connect_func
    self._disconnect_func = disconnect_func
    self._data_func = data_func
end

function _M:run(frame)
    local expireConnList = {}
    local curTime = skynet.now() * 10
    local expire_militime = skynet.now() - kcp_connection_timeout_time
    for conv, conn in pairs(self._connMap) do
        local heartbeat = conn:update(curTime)
        if heartbeat < expire_militime then
            netlog.udp_log(
                "run check expire conv:",
                conv,
                "heartbeat:",
                heartbeat,
                "expire_militime:",
                expire_militime,
                "curTime:",
                skynet.now()
            )
            expireConnList[#expireConnList + 1] = {conv, conn:getFromStr()}
        end
    end

    for _, tinfo in ipairs(expireConnList) do
        self:disconnectclient(tinfo[1], tinfo[2])
    end

    -- 防止立即释放对象，导致对方收不到最后一个包，所以做一个延时
    local tempList = {}
    local _releaseMap = self._releaseMap
    for conv, conn in pairs(_releaseMap) do
        conn:update(curTime)
        if conn:isExpire() then
            tempList[#tempList + 1] = conv
        end
    end

    for index = 1, #tempList do
        _releaseMap[tempList[index]] = nil
    end
end

function _M:send_msg(conv, data)
    local conn = self:_get_conn(conv)
    if not conn then
        -- 连接已经不存在
        netlog.LOG_WARNING("can not found conv:%s", conv)
        return false
    end

    -- 发送数据
    local ret_send = conn:send(data)
    if nil == ret_send or ret_send == -2 then
        local fromstr = conn:getFromStr()
        self:disconnectclient(conv, fromstr)
    end
    return true
end

return _M
