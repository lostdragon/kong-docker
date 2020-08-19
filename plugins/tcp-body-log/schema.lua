return {
    fields = {
        host = { required = true, type = "string" },
        port = { required = true, type = "number" },
        timeout = { default = 10000, type = "number" },
        keepalive = { default = 30, type = "number" },
        duration = { default = 1000, type = "number" },
        log_request_body = { type = "boolean", default = false },
        log_response_body = { type = "boolean", default = false }
    }
}