{{ define "utils.snippets.set_openstack_request_id" }}
set_by_lua_block $global_request_id {
    local global_request_id = ngx.req.get_headers()["X-OpenStack-Request-ID"]

    if not global_request_id then
        -- req_id is a uuid without hyphens, but openstack needs a certain format
        local req_id = ngx.var.req_id
        global_request_id = "req-" .. req_id:sub(1,8) .. "-" .. req_id:sub(9,12) .. "-" .. req_id:sub(13,16) .. "-" .. req_id:sub(17,20) .. "-" .. req_id:sub(21,-1)
        global_request_id = global_request_id:lower()
        ngx.req.set_header("X-OpenStack-Request-ID", global_request_id)
    end

    return global_request_id
}
{{- end }}
