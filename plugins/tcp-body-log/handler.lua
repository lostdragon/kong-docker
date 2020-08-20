local tcp_body_log_serializer = require "kong.plugins.tcp-body-log.serializer"
local BasePlugin = require "kong.plugins.base_plugin"
local log = require "kong.plugins.tcp-body-log.log"

local kong = kong
local ngx = ngx
local string_find = string.find

local TCPBodyLogHandler = BasePlugin:extend()

function TCPBodyLogHandler:new()
    TCPBodyLogHandler.super.new(self, "tcp-body-log")
end

function TCPBodyLogHandler:access(conf)
    TCPBodyLogHandler.super.access(self)
    kong.ctx.plugin.request_body = ""
    kong.ctx.plugin.response_body = ""
    -- check config
    if (conf.log_request_body) then
        -- check request method
        local method = kong.request.get_method():upper()
        if (method == "POST" or method == "PUT" or method == "DELETE") then
            -- check request content_type
            local content_type = kong.request.get_header('content-type')
            if content_type then
                content_type = content_type:lower()
                -- only get json\form\xml body
                if (string_find(content_type, "application/json", nil, true)
                        or string_find(content_type, "application/x-www-form-urlencoded", nil, true)
                        or string_find(content_type, "text/xml", nil, true)
                ) then
                    local body, err = kong.request.get_raw_body()
                    if err then
                        kong.log.err(err)
                    else
                        kong.ctx.plugin.request_body = body
                    end
                end
            end
        end
    end
end

function TCPBodyLogHandler:body_filter(conf)

    TCPBodyLogHandler.super.body_filter(self)

    if (conf.log_response_body) then
        -- kong.ctx.plugin is nil, if route not found
        if (kong.ctx.plugin.request_body == nil) then
            kong.ctx.plugin.request_body = ""
        end

        if (kong.ctx.plugin.response_body == nil) then
            kong.ctx.plugin.response_body = ""
        end

        local chunk = ngx.arg[1]
        kong.ctx.plugin.response_body = kong.ctx.plugin.response_body .. (chunk or "")
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