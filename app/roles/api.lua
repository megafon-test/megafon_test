local vshard = require('vshard')
local errors = require('errors')

local err_vshard_router = errors.new_class("Vshard routing error")
local err_httpd = errors.new_class("httpd error")

--- получение информации по звонку по call_id
local function http_find_call_by_call_id(req)
    local call_id = tonumber(req:stash('call_id'))

    local bucket_id = vshard.router.bucket_id(call_id)

    local call, error = err_vshard_router:pcall(
        vshard.router.call,
        bucket_id,
        'read',
        'find_call_by_id',
        {call_id}
    )

    if error then
        local resp = req:render({json = {
            info = "Internal error",
            error = error
        }})
        resp.status = 500
        return resp
    end

    if call == nil then
        local resp = req:render({json = { info = "Call not found" }})
        resp.status = 404
        return resp
    end

    local resp = req:render({json = call})
    resp.status = 200
    return resp
end


local function init(opts)
    rawset(_G, 'vshard', vshard)

    if opts.is_master then
        box.schema.user.grant('guest',
            'read,write,execute',
            'universe',
            nil, { if_not_exists = true }
        )
    end

    local httpd = cartridge.service_get('httpd')

    if not httpd then
        return nil, err_httpd:new("not found")
    end

    --- функция-обработчик
    httpd:route(
        { path = '/storage/call/:call_is', method = 'GET', public = true },
        http_find_call_by_call_id
    )

    return true
end

return {
    role_name = 'api',
    init = init,
    dependencies = {'cartridge.roles.vshard-router'},
}
