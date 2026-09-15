local _M = {}

local token_lookup = require "token_lookup"
local get_token = token_lookup.get_token
local lookup = token_lookup.lookup
local host_from_entry = token_lookup.host_from_entry
local url_base = "/cell1/shellinabox/" -- TODO: Get the "shellinabox" from the proxy dynamically somehow

-- The server may respond with a redirect, and we
-- transform that redirect to one relative on "our"
-- host with the token still in the path and whatever
-- prefix we use on the ingress
-- Unfortunately, we also need to parse query parameters,
-- as that is how the vnc host is passed on to the javascript
-- vnc client running in the browser
function _M.handle_redirect()
    local location = ngx.header.Location
    if not location then return end

    local token = get_token()
    if not token then return end
    local token_base = url_base .. token

    local self_host = ngx.var.host
    local scheme, host, path, query = location:match("([^:]+)://([^/]+)([^?]+)(?%g+)")
    local new_q = {}
    -- query starts with '?', which we remove with sub(2), then we iterate over
    -- all query paramters, which are split by &
    for key, value in query:sub(2):gmatch("([^=&]+)=([^&]*)") do
        -- ip would point to the BMC, now it points to this server
        if key == "ip" then value = self_host
        -- This is a bit hacky: the client concatenates <ip>:<kvmport> to open
        -- a websocket connection to. Since we need the token to know which host
        -- to proxy to, we add it to the "port", so it becomes
        -- wss://<self_host>:443/<token>
        elseif key == "kvmport" then value = "443" .. token_base
        -- The next one replaces the actual name from the baremetal host
        -- with the instance uuid. We probably do not want to expose the baremetal hostname
        elseif key == "title" then value = ngx.ctx.entry.instance_uuid or "KVM"
        end
        table.insert(new_q, key .. "=" .. value)
    end
    local new_query = table.concat(new_q, "&")

    local new_location = token_base .. path .. "?" .. new_query
    ngx.header.Location = new_location
end

-- This gets called with the token in the path, which we need to strip
-- from the request path, and the rest goes straight on to the actual host
function _M.process()
    local entry = lookup()
    if not entry then return end
    local host = host_from_entry(entry)
    local request_uri = ngx.var.request_uri
    local sub_uri = request_uri:sub(38)  -- 38 = uuid(36) + 2 * '/'
    return host .. sub_uri
end

-- Gets called with just a token. That is the standard way of doing things in nova,
-- but we need the token in every request just for this proxy, so encode it in the url
-- After the token comes the path on the host in the field `internal_access_path`
function _M.root()
    local token = get_token()
    local entry = lookup()
    if entry then
        return ngx.redirect(url_base .. token .. entry.internal_access_path)
    else
        return ngx.exit(ngx.HTTP_UNAUTHORIZED)
    end
end

return _M
