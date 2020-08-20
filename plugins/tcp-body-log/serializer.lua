local _M = {}

function _M.serialize(ngx, kong)
    local authenticated_entity
    if ngx.ctx.authenticated_credential ~= nil then
        authenticated_entity = {
            id = ngx.ctx.authenticated_credential.id,
            consumer_id = ngx.ctx.authenticated_credential.consumer_id
        }
    end

    local request_uri = ngx.var.request_uri or ""

    local request_body
    local response_body
    if kong.ctx.plugin then
        request_body = kong.ctx.plugin.request_body
        response_body = kong.ctx.plugin.response_body
    end

    return {
        request = {
            uri = request_uri,
            url = ngx.var.scheme .. "://" .. ngx.var.host .. ":" .. ngx.var.server_port .. request_uri,
            querystring = ngx.req.get_uri_args(), -- parameters, as a table
            method = ngx.req.get_method(), -- http method
            headers = ngx.req.get_headers(),
            size = ngx.var.request_length,
            body = request_body
        },
        response = {
            status = ngx.status,
            headers = ngx.resp.get_headers(),
            size = ngx.var.bytes_sent,
            body = response_body
        },
        latencies = {
            kong = (ngx.ctx.KONG_ACCESS_TIME or 0) +
                    (ngx.ctx.KONG_RECEIVE_TIME or 0),
            proxy = ngx.ctx.KONG_WAITING_TIME or -1,
            request = ngx.var.request_time * 1000
        },
        tries = (ngx.ctx.balancer_data or {}).tries,
        authenticated_entity = authenticated_entity,
        upstream_uri = ngx.var.upstream_uri,
        client_ip = ngx.var.remote_addr,
        started_at = ngx.req.start_time() * 1000,
        node_id = kong.node.get_id()
    }
end

return _M 