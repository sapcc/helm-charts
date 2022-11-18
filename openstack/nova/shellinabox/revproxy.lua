local _M = {} -- That will be the module we return in the end

local config = require "config" -- Hold the config rendered by the helm-chart

local cjson = require "cjson"
local resty_sha256 = require "resty.sha256"
local str = require "resty.string"
local memcached = require "resty.memcached"
local mysql = require "resty.mysql"

local guid_pattern = "%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x"
local url_base = "/shellinabox/" -- TODO: Get the "shellinabox" from the proxy dynamically somehow

-- Little wrapper function, which avoids a
-- potentially expensive function call "f"
-- by caching the result in the ngx.ctx, which
-- is preserved over all phases of a request
local function store_in_ctx(key, f)
    local function caching_function(...)
        local value = ngx.ctx[key]
        if value ~= nil then return value end
        value = f(...)
        if value ~= nil then ngx.ctx[key] = value end
        return value
    end

    return caching_function
end

local function sha256_hex(token)
    local sha256 = resty_sha256:new()
    sha256:update(token)
    local final  = sha256:final()
    if final then return str.to_hex(final) end
end

-- Converts the entry to the upstream with an optional port
local function host_from_entry(entry)
    if entry.port and entry.port ~= 443 then
        return "https://" .. entry.host .. ":" .. entry.port
    else
        return "https://" .. entry.host
    end
end

-- set_keepalive puts a socket back in a pool,
-- that may fail so we log it as a warning
-- That is needed for memcached as well as mysql
local function logged_keepalive(sock)
    local ok, err = sock:set_keepalive(10000, 50)
    if not ok then ngx.log(ngx.WARN, "failed to set keepalive: ", err) end
end

-- Extracts the token from either the query parameter
-- the url, or from the referrer
-- Caches the value, as it won't change over the request
-- and apparently ngx.var lookups are not the cheapest
local get_token = store_in_ctx("token", function()
    local var_token = ngx.var.token
    if var_token then return var_token end

    local args, err = ngx.req.get_uri_args()
    if err == "truncated" then
        ngx.say([[{"error": "Too many query parameters (>100)"}]])
        return ngx.exit(ngx.HTTP_BAD_REQUEST)
    end

    if args.token then return args.token end

    local http_referer = ngx.var.http_referer
    if http_referer then
        local match = http_referer:match("token=" .. guid_pattern)
        if match then return match:sub(7) end
    end

    ngx.say([[{"error": "No token"}]])
    return ngx.exit(ngx.HTTP_BAD_REQUEST)
end)

-- Sends a query to a single database defined by connect_params
local function connect_and_query(query, connect_params)
    local db, err = mysql:new()
    if not db then return { nil, "failed to instantiate mysql: " .. err } end

    db:set_timeout(1000) -- 1 sec

    local ok, err, errcode, sqlstate = db:connect(connect_params)
    if not ok then return { nil, "failed to connect: " .. err .. ": " .. errcode .. " " .. sqlstate } end

    local res, err, errcode, sqlstate = db:query(query)
    if not res then return { nil, "bad result: " .. err .. ": " .. errcode .. ": " .. sqlstate .. "." } end

    logged_keepalive(db)
    local entry = res[1]
    if entry and entry.host and entry.internal_access_path then
        return { entry, nil }
    end

    return { nil, nil }
end

-- Query all configured databases for a valid token_hash
-- Expiry is checked server side by the query
-- The results are still checked in order for simplicity sake
-- It could be a bit faster but more complicated to check first the fastest
-- result, and cancel all other threads
local function lookup_db(token_hash)
    local query = "SELECT host, port, internal_access_path, expires, instance_uuid" ..
        " FROM console_auth_tokens" ..
        " WHERE token_hash=" .. ngx.quote_sql_str(token_hash) ..
        " AND expires > UNIX_TIMESTAMP()"

    local dbs = config.dbs
    local dbs_len = #dbs
    local threads = {}
    -- Fire of the queries
    for i = 1, dbs_len do
        threads[i] = ngx.thread.spawn(connect_and_query, query, dbs[i])
    end

    local errors = {}
    -- Collect them in-order
    for i = 1, dbs_len do
        local ok, res = ngx.thread.wait(threads[i])
        if not ok then
            table.insert(errors, "Could not query thread due to " .. res)
        elseif res then
            -- We return the first result, as we do not expect
            -- there to be more. The other threads are still
            -- waited on by the whole http-request. Canceling things
            -- here might make things faster, but makes things more complex
            if res[1] then return res[1] end
            if res[2] then table.insert(errors, err) end
        end
    end

    -- We may be without result due to an error (or more)
    if #errors > 0 then return nil, "Lookup failed due to: " .. table.concat(errors, "\n")  end
    ngx.log(ngx.INFO, "No results for hash " .. token_hash)
end


-- Lookup the token_hash in memcached, and failing that
-- query the databases, and store the result (if there is one)
local function lookup_memc(token_hash)
    local memc, err = memcached:new()
    if not memc then return nil, "failed to instantiate memc: " .. err end
    memc:set_timeout(1000) -- 1 sec

    local ok, err = memc:connect(config.memcached[1], config.memcached[2])
    if not ok then return nil, "failed to connect: " .. err end

    local res, flags, err = memc:get(token_hash)
    if err then ngx.log(ngx.WARN, "failed to get token from memcached due to: ", err) end
    if res then
        logged_keepalive(memc)
        return cjson.decode(res)
    end

    res = lookup_db(token_hash)
    -- We store the token in memcached with a relative short TTL,
    -- as we expect a bunch of request to come together.
    -- First all the resources (html/js/css) and finally the websocket
    -- We could calculate the TTL from the expiry to cache
    -- the value more accurately in case the user opens the console
    -- again after some time, but that comes at some complexity,
    -- and this solution strives to be simple (for now)
    if res then memc:set(token_hash, cjson.encode(res), 10) end
    logged_keepalive(memc)
    return res
end

-- Toplevel lookup, get the token hash it, and send it through
-- the lookup hierarchy. Store/cache the result in ngx.ctx
local lookup = store_in_ctx("entry", function()
    local token = get_token()
    local token_hash = sha256_hex(token)
    if not token_hash then
        ngx.log(ngx.ERR, "Could not hash token")
        return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    local entry, err = lookup_memc(token_hash)

    if err then
        ngx.log(ngx.ERR, "could not retrieve user: ", err)
        return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end
    return entry
end)


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
