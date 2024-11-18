local _M = {}

local token_lookup = require "token_lookup"

-- This gets called with the token as query string when requesting the
-- WebSocket from VMware
function _M.process()
	-- we don't need memcache for MKS, because we're only getting a single
	-- request
    local use_memcache = false
    local entry = token_lookup.lookup(use_memcache)
    if not entry then return end
    local host = token_lookup.host_from_entry(entry)
    local uri = entry.internal_access_path
    return host .. uri
end

return _M
