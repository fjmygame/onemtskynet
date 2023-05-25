-- --------------------------------------
-- Create Date:2019-08-30 22:18:26
-- Author  : Happy Su
-- Version : 1.0
-- Filename: connlt.lua
-- Introduce  : 负责一个用户UDP数据包处理，以及用户基础信息
-- --------------------------------------
local skynet = require "skynet"
local KCP = require "lkcp"
local netlog = require "netlog"
local socketdriver = require "socketdriver"
local _M = class("Connlt")

function _M:ctor(conv, flowid, conkey, from, fromstr, udp)
    self._conv = conv
    self._flowid = flowid
    self._conkey = conkey
    self._from = from
    self._fromstr = fromstr
    self._udp = udp

    local _kcp =
        KCP.lkcp_create(
        conv,
        function(_data)
            netlog.udp_log(string.safeFormat("fromstr:%s conn:%s send msg mmmmm", self._fromstr, conv))
            socketdriver.udp_send(self._udp, self._from, _data)
        end
    )
    _kcp:lkcp_nodelay(1, 10, 2, 1)
    _kcp:lkcp_wndsize(128, 128)

    self._kcp = _kcp
    self.heartbeat = skynet.now()
    self.recvTag = false
end

function _M:getFlowID()
    return self._flowid
end

-- 判断流水id是否太旧
function _M:isOldFlowID(flowid)
    return self._flowid >= flowid
end

function _M:getFrom()
    return self._from
end

function _M:checkFrom(from)
    return self._from == from
end

function _M:getFromStr()
    return self._fromstr
end

function _M:resetFrom(from, fromstr, flowid)
    self._flowid = flowid
    self._from = from
    self._fromstr = fromstr
end

function _M:getConKey()
    return self._conkey
end

function _M:checkConKey(conKey)
    if not conKey then
        return false
    end

    return self._conkey == conKey
end

function _M:setExpireTime(time)
    self.expireTime = time
end

function _M:isExpire()
    return self.expireTime > skynet.now()
end

function _M:update(clock)
    self._kcp:lkcp_update(clock)
    return self.heartbeat
end

function _M:input(data)
    self.recvTag = true
    self._kcp:lkcp_input(data)
    self.heartbeat = skynet.now()
    netlog.udp_log("connlt input time:", self.heartbeat)
end

function _M:send(data)
    return self._kcp:lkcp_send(data)
end

function _M:recv()
    local len, buffer = self._kcp:lkcp_recv()

    if (len > 0) then
        local packlen = string.unpack(">I2", buffer)
        local relbuffer = string.sub(buffer, 3)
        if packlen ~= string.len(relbuffer) then
            netlog.LOG_ERROR("err buffer packlen:%s relbuffer:%s", packlen, string.len(relbuffer))
            return
        end
        netlog.udp_log(string.safeFormat("_conv:%s recv msg len:%s packlen:%s", self._conv, len, packlen))
        return relbuffer
    end
end

-- 是否接收过消息的标记
function _M:getRecvTag()
    return self.recvTag
end

return _M
