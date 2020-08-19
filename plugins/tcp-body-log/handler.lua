local tcp_body_log_serializer = require "kong.plugins.tcp-body-log.serializer"
local BasePlugin = require "kong.plugins.base_plugin"
local log = require "kong.plugins.tcp-body-log.log"
local kong = kong
local ngx = ngx
local cjson = require "cjson"

local TCPBodyLogHandler = BasePlugin:extend()

function TCPBodyLogHandler:new()
    TCPBodyLogHandler.super.new(self, "tcp-body-log")
end

function TCPBodyLogHandler:access(conf)
    TCPBodyLogHandler.super.access(self)
    kong.ctx.tcp_body_log = { request_body = "", response_body = "" }

    if (conf.log_request_body) then
        local body, err = kong.request.get_raw_body()

        if err then
            kong.log.err(err)
        else
            kong.ctx.tcp_body_log.request_body = body
        end
    end
end

function TCPBodyLogHandler:body_filter(conf)

    TCPBodyLogHandler.super.body_filter(self)

    if (conf.log_response_body) then
        -- kong.ctx.tcp_body_log is nil, if route not found
        if (kong.ctx.tcp_body_log == nil) then
            kong.ctx.tcp_body_log = { request_body = "", response_body = "" }
        end

        local chunk = ngx.arg[1]
        kong.ctx.tcp_body_log.response_body = kong.ctx.tcp_body_log.response_body .. (chunk or "")
    end

end

function TCPBodyLogHandler:log(conf)
    TCPBodyLogHandler.super.log(self)

    if (ngx.var.request_time * 1000 > conf.duration) then

        -- Call serializer
        local message = tcp_body_log_serializer.serialize(ngx, kong)

        -- Call execute method of 'log' initialized earlier
        log.execute(conf, message)
    end
end

TCPBodyLogHandler.PRIORITY = 1

return TCPBodyLogHandler