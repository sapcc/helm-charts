local _M = {} -- That will be the module we return in the end

local config = require "config" -- Hold the config rendered by the helm-chart

local resty_sha256 = require "resty.sha256"
local str = require "resty.string"
local memcached = require "resty.memcached"
local mysql = require "resty.mysql"

local guid_pattern = "%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x"

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
_M.get_token = store_in_ctx("token", function()
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
	-- FIXME This would not be necessary if we'd provide the right URL already and thus would run a shellinabox for each cell with its own config
	-- TODO Do we need those threads to not block other, parallel requests from continuing?
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
_M.lookup = store_in_ctx("entry", function(use_memc)
    local token = _M.get_token()
    local token_hash = sha256_hex(token)
    if not token_hash then
        ngx.log(ngx.ERR, "Could not hash token")
        return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    if not use_memc then
        return lookup_db(token_hash)
    end

    local entry, err = lookup_memc(token_hash)

    if err then
        ngx.log(ngx.ERR, "could not retrieve user: ", err)
        return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    return entry
end)

-- Converts the entry to the upstream with an optional port
function _M.host_from_entry(entry)
    if entry.port and entry.port ~= 443 then
        return "https://" .. entry.host .. ":" .. entry.port
    else
        return "https://" .. entry.host
    end
end

return _M
