local cjson_decode = require("cjson").decode

local pcall = pcall

local _M = {}

local function get_mapped_error(message)
    --[[
    This function handles mapping between Kong error messages and custom error
    messages/structures.
    --]]
    local error_msg_mappings = {}

    error_msg_mappings["API rate limit exceeded"] = '{"meta": {"code": 9990,"message": "访问过于频繁", "hint": "API rate limit exceeded"}}'

    error_msg_mappings["name resolution failed"] = '{"meta": {"code": 9991,"message": "服务器升级中，请耐心等待", "hint": "name resolution failed"}}'

    error_msg_mappings["no Route matched with those values"] = '{"meta": {"code": 9992, "message": "路由错误", "hint": "no Route matched with those values"}}'

    error_msg_mappings["Unauthorized"] = '{"meta": {"code": 9993, "message": "未授权", "hint": "Unauthorized"}}'

    error_msg_mappings["Invalid authentication credentials"] = '{"meta": {"code": 9994, "message": "授权无效", "hint": "Invalid authentication credentials"}}'

    error_msg_mappings["Your IP address is not allowed"] = '{"meta": {"code": 9995, "message": "您的IP不允许访问", "hint": "Your IP address is not allowed"}}'

    error_msg_mappings["You cannot consume this service"] = '{"meta": {"code": 9996, "message": "授权无效", "hint": "You cannot consume this service"}}'

    error_msg_mappings["An unexpected error occurred"] = '{"meta": {"code": 9998, "message": "未知错误", "hint": "An unexpected error occurred"}}'

    if error_msg_mappings[message] ~= nil then
        return error_msg_mappings[message]
    else
        return string.format('{"meta": {"code": 9999, "message": "网关错误", "hint": "%s"}}', message)
    end
end

local function read_json_body(body)
    if body then
        local status, res = pcall(cjson_decode, body)
        if status then
            return res
        end
    end
end

function _M.transform_error(body)
    --[[
    Module function which reads JSON response and transforms
    Kong errors to custom errors.
    --]]
    local json_body = read_json_body(body)

    if (json_body ~= nil and json_body['message'] ~= nil) then
        local mapped_error = get_mapped_error(json_body['message'])
        return mapped_error
    else
        return nil
    end
end

return _M
