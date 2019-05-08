---
--- Created by lhertz.
--- DateTime: 2019-04-18 11:49
---

local cjson = require "cjson"
local ngx = ngx
local ngx_req_get_headers = ngx.req.get_headers
local ngx_req_get_method = ngx.req.get_method
local ngx_req_raw_header = ngx.req.raw_header
local ngx_req_set_header = ngx.req.set_header
local ngx_encode_base64 = ngx.encode_base64
local ngx_log = ngx.log
local ngx_ERR = ngx.ERR
local ngx_now = ngx.now

local DEFAULT_METHOD = "GNodeMethod"
local DEFAULT_URL = "GNodeURL"

local HTTP_HEADER_KEY = "X-Botsonar-Information"

local _M = {
    _VERSION = "0.01"
}

local function get_client_ip(headers)

    if headers['x-real-ip'] then
        return headers['x-real-ip']
    end

    if headers['x-forwarded-for'] and headers['x-forwarded-for'] ~= '' then
        local lastcomma = string.find(headers['x-forwarded-for'], ',', 1)
        if lastcomma then
            return string.sub(headers['x-forwarded-for'], 0, lastcomma - 1)
        else
            return headers['x-forwarded-for']
        end
    end

    return ngx.var.remote_addr
end

local function collectInfo()
    local headers = ngx_req_get_headers()
    local info = {
        type = 0,
        web = {
            rawHeaders = ngx_req_raw_header(true),
            requestMethod = ngx_req_get_method() or DEFAULT_METHOD,
            requestURL = ngx.var.request_uri or DEFAULT_URL,
            requestTime = ngx_now(),
            clientAddress = get_client_ip(headers)
        }
    }
    local tmp = cjson.encode(info)
    local result = ngx_encode_base64(tmp)
    ngx_req_set_header(HTTP_HEADER_KEY, result)
end

function _M.run()
    local ok, err = pcall(collectInfo)
    if not ok then
        ngx_log(ngx_ERR, "GNode Plugin collect web information failed! Error: ", err)
    end
    return
end

return _M