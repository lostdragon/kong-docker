local cjson = require "cjson"
local BasePlugin = require "kong.plugins.base_plugin"
local _M = {}

local ngx_timer_at = ngx.timer.at

local TcpLogHandler = BasePlugin:extend()

TcpLogHandler.PRIORITY = 2

local function log(premature, conf, message)
    if premature then
        return
    end

    local ok, err
    local host = conf.host
    local port = conf.port
    local timeout = conf.timeout
    local keepalive = conf.keepalive

    local sock = ngx.socket.tcp()
    sock:settimeout(timeout)

    ok, err = sock:connect(host, port)
    if not ok then
        kong.long.err("[tcp-body-log] failed to connect to " .. host .. ":" .. tostring(port) .. ": ", err)
        return
    end
    -- ngx.log(ngx.ERR, "[tcp-body-log] send message " .. cjson.encode(message), err)
    ok, err = sock:send(cjson.encode(message) .. "\r\n")
    if not ok then
        kong.long.err("[tcp-body-log] failed to send data to " .. host .. ":" .. tostring(port) .. ": ", err)
    end

    ok, err = sock:setkeepalive(keepalive)
    if not ok then
        kong.long.err("[tcp-body-log] failed to keepalive to " .. host .. ":" .. tostring(port) .. ": ", err)
        return
    end
end

function _M.execute(conf, message)
    local ok, err = ngx_timer_at(0, log, conf, message)
    if not ok then
        kong.long.err("[tcp-body-log] failed to create timer: ", err)
    end
end

return _M