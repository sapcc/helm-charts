#!/usr/bin/env bash

set -o pipefail

{{- include "tempest-base.function_start_tempest_tests" . }}

PROTECT="${PROTECT:-^neutron-tempest|locust}"
PROTECTED_IDS_FILE="${PROTECTED_IDS_FILE:-}"

TARGET_PROJECT_ID=""

declare -A PROTECTED_IDS=()
declare -A TOTAL=()

function load_protected_ids() {
    [[ -n "$PROTECTED_IDS_FILE" ]] || return 0
    if [[ ! -r "$PROTECTED_IDS_FILE" ]]; then
        echo "FATAL: PROTECTED_IDS_FILE=$PROTECTED_IDS_FILE is not readable, aborting" >&2
        return 1
    fi
    local line
    while read -r line || [[ -n "$line" ]]; do
        line="${line%%#*}"
        line="${line//[[:space:]]/}"
        [[ -n "$line" ]] && PROTECTED_IDS["$line"]=1
    done < "$PROTECTED_IDS_FILE"
    echo "Loaded ${#PROTECTED_IDS[@]} protected ids from $PROTECTED_IDS_FILE"
    return 0
}

function is_protected() {
    local rid="$1" rname="$2"
    if [[ -n "${PROTECTED_IDS[$rid]:-}" ]]; then
        echo "      KEEP [baseline] ${rname:-<unnamed>} ($rid)"
        return 0
    fi
    if [[ -n "$rname" ]] && [[ "$rname" =~ $PROTECT ]]; then
        echo "      KEEP [name] $rname ($rid)"
        return 0
    fi
    return 1
}

function assert_owned() {
    local rtype="$1" rid="$2" pid
    pid=$(openstack $rtype show "$rid" -f value -c project_id 2>/dev/null)
    [[ -n "$pid" && "$pid" == "$TARGET_PROJECT_ID" ]]
}

function list_scoped() {
    local name_col="$1" extra_col="$2"; shift 2
    local out

    out=$("$@" --project "$TARGET_PROJECT_ID" -f json 2>/dev/null)
    [[ -n "$out" ]] || out=$("$@" -f json 2>/dev/null)
    [[ -n "$out" ]] || return 0

    printf '%s' "$out" | python3 -c "
import sys, json
pid, name_col, extra_col = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    rows = json.load(sys.stdin)
except Exception:
    sys.exit(0)
if not isinstance(rows, list):
    sys.exit(0)
if rows and 'Project' not in rows[0]:
    sys.stderr.write('      WARN: no Project column in response, skipping\n')
    sys.exit(1)
for r in rows:
    if r.get('Project') != pid:
        continue
    extra = (r.get(extra_col) or '') if extra_col else ''
    print('%s\x1f%s\x1f%s' % (r.get('ID') or '', r.get(name_col) or '', extra))
" "$TARGET_PROJECT_ID" "$name_col" "$extra_col"
}

function list_ids_names() {
    local out
    out=$("$@" --project "$TARGET_PROJECT_ID" -f json 2>/dev/null)
    [[ -n "$out" ]] || out=$("$@" -f json 2>/dev/null)
    [[ -n "$out" ]] || return 0

    printf '%s' "$out" | python3 -c "
import sys, json
try:
    rows = json.load(sys.stdin)
except Exception:
    sys.exit(0)
if not isinstance(rows, list):
    sys.exit(0)
for r in rows:
    print('%s\x1f%s' % (r.get('ID') or '', r.get('Name') or ''))
"
}

function port_info() {
    openstack port show "$1" -f json 2>/dev/null | python3 -c "
import sys, json, ast
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
td = d.get('trunk_details')
tid = ''
if isinstance(td, dict):
    tid = td.get('trunk_id') or ''
elif isinstance(td, str) and td not in ('', 'None'):
    try:
        tid = (ast.literal_eval(td) or {}).get('trunk_id') or ''
    except Exception:
        tid = ''
dev = d.get('device_id') or ''
if dev == 'None':
    dev = ''
print('%s\x1f%s\x1f%s\x1f%s' % (
    d.get('project_id') or d.get('tenant_id') or '',
    d.get('device_owner') or '',
    dev,
    tid))
"
}

function remove_port() {
    local port="$1" pid owner dev

    IFS=$'\037' read -r pid owner dev _ < <(port_info "$port")

    case "$owner" in
        network:dhcp*)
            return 0 ;;
        network:floatingip|network:router_gateway|network:floatingip_agent_gateway|network:router_centralized_snat)
            return 0 ;;
    esac

    if [[ "$pid" != "$TARGET_PROJECT_ID" ]]; then
        echo "      SKIP port $port: owned by ${pid:-<unknown>}, not $OS_PROJECT_NAME"
        return 0
    fi

    case "$owner" in
        network:router_interface|network:router_interface_distributed|network:ha_router_replicated_interface)
            if [[ -n "$dev" ]] && openstack router show "$dev" -f value -c id >/dev/null 2>&1; then
                echo "      detach $port from router $dev"
                openstack router remove port "$dev" "$port" \
                    || echo "      WARN: could not detach port $port"
            else
                # router gone, port survived; clearing device_owner may be
                # denied without admin, delete is attempted either way
                echo "      orphaned router interface $port"
                openstack port set "$port" --device-owner "" 2>/dev/null \
                    || echo "      WARN: could not clear device_owner on $port (needs admin)"
                openstack port delete "$port" || echo "      WARN: could not delete port $port"
            fi
            ;;
        *)
            openstack port set "$port" --disable --no-fixed-ip 2>/dev/null || true
            openstack port delete "$port" || echo "      WARN: could not delete port $port"
            ;;
    esac
}

function cleanup_fips() {
    local fip_id fip_desc fip_addr n=0

    while IFS=$'\037' read -r fip_id fip_desc fip_addr; do
        [[ -n "$fip_id" ]] || continue
        is_protected "$fip_id" "$fip_desc" && continue

        echo "    FIP ${fip_addr:-?} ($fip_id)"
        openstack floating ip delete "$fip_id" || echo "      WARN: could not delete $fip_id"
        n=$((n + 1))
    done < <(list_scoped Description "Floating IP Address" openstack floating ip list --long)

    TOTAL[fips]=$(( ${TOTAL[fips]:-0} + n ))
    echo "  floating ips: $n"
}

function cleanup_routers() {
    local router_id router_name port_id n=0
    local -a port_ids=()

    while IFS=$'\037' read -r router_id router_name _; do
        [[ -n "$router_id" ]] || continue
        is_protected "$router_id" "$router_name" && continue

        echo "    Router '${router_name:-<unnamed>}' ($router_id)"

        openstack router unset --external-gateway "$router_id" \
            || echo "      WARN: could not unset external gateway"

        port_ids=()
        mapfile -t port_ids < <(openstack port list --router "$router_id" -f value -c ID)
        for port_id in "${port_ids[@]}"; do
            [[ -n "$port_id" ]] || continue
            openstack router remove port "$router_id" "$port_id" 2>/dev/null || true
        done

        openstack router delete "$router_id" || echo "      WARN: could not delete router $router_id"
        n=$((n + 1))
    done < <(list_scoped Name "" openstack router list)

    TOTAL[routers]=$(( ${TOTAL[routers]:-0} + n ))
    echo "  routers: $n"
}

function cleanup_networks() {
    local net_id net_name port_id subnet_id pid trunk_id n=0

    while IFS=$'\037' read -r net_id net_name _; do
        [[ -n "$net_id" ]] || continue
        is_protected "$net_id" "$net_name" && continue
        echo "    Network '${net_name:-<unnamed>}' ($net_id)"
        while read -r port_id; do
            [[ -n "$port_id" ]] || continue
            IFS=$'\037' read -r pid _ _ trunk_id < <(port_info "$port_id")
            [[ "$pid" == "$TARGET_PROJECT_ID" ]] || continue
            [[ -n "$trunk_id" ]] || continue
            echo "      trunk $trunk_id (parent port $port_id)"
            openstack network trunk delete "$trunk_id" || true
        done < <(openstack port list --network "$net_id" -f value -c ID)

        while read -r port_id; do
            [[ -n "$port_id" ]] || continue
            remove_port "$port_id"
        done < <(openstack port list --network "$net_id" -f value -c ID)

        while read -r subnet_id; do
            [[ -n "$subnet_id" ]] || continue
            if ! assert_owned subnet "$subnet_id"; then
                echo "      SKIP subnet $subnet_id: not owned by $OS_PROJECT_NAME"
                continue
            fi
            openstack subnet delete "$subnet_id" \
                || echo "      WARN: could not delete subnet $subnet_id"
        done < <(openstack subnet list --network "$net_id" -f value -c ID)

        openstack network delete "$net_id" || echo "      WARN: could not delete network $net_id"
        n=$((n + 1))
    done < <(list_scoped Name "" openstack network list --long)

    TOTAL[networks]=$(( ${TOTAL[networks]:-0} + n ))
    echo "  networks: $n"
}

function cleanup_orphan_ports() {
    local port_id port_name pid owner n=0

    while IFS=$'\037' read -r port_id port_name; do
        [[ -n "$port_id" ]] || continue

        IFS=$'\037' read -r pid owner _ _ < <(port_info "$port_id")
        [[ "$pid" == "$TARGET_PROJECT_ID" ]] || continue
        [[ -z "$owner" ]] || continue

        is_protected "$port_id" "$port_name" && continue

        echo "    Orphan port '${port_name:-<unnamed>}' ($port_id)"
        remove_port "$port_id"
        n=$((n + 1))
    done < <(list_ids_names openstack port list)

    TOTAL[orphan_ports]=$(( ${TOTAL[orphan_ports]:-0} + n ))
    echo "  orphan ports: $n"
}

function cleanup_security_groups() {
    local sg_id sg_name n=0

    while IFS=$'\037' read -r sg_id sg_name _; do
        [[ -n "$sg_id" ]] || continue
        [[ "$sg_name" == "default" ]] && continue
        is_protected "$sg_id" "$sg_name" && continue

        echo "    SG '${sg_name:-<unnamed>}' ($sg_id)"
        openstack security group delete "$sg_id" || echo "      WARN: could not delete SG $sg_id"
        n=$((n + 1))
    done < <(list_scoped Name "" openstack security group list)

    TOTAL[security_groups]=$(( ${TOTAL[security_groups]:-0} + n ))
    echo "  security groups: $n"
}

function cleanup_misc() {
    local res id name n

    for res in "address group" "subnet pool" "address scope"; do
        n=0
        while IFS=$'\037' read -r id name; do
            [[ -n "$id" ]] || continue
            assert_owned "$res" "$id" || continue
            is_protected "$id" "$name" && continue

            echo "    $res '${name:-<unnamed>}' ($id)"
            openstack $res delete "$id" || echo "      WARN: could not delete $res $id"
            n=$((n + 1))
        done < <(list_ids_names openstack $res list)
        [[ "$n" -gt 0 ]] && echo "  $res: $n"
    done
    return 0
}

function cleanup_project_neutron() {
    TARGET_PROJECT_ID=$(openstack token issue -f value -c project_id 2>/dev/null)
    if [[ -z "$TARGET_PROJECT_ID" ]]; then
        echo "FATAL: authentication failed for $OS_USERNAME in $OS_PROJECT_NAME, skipping" >&2
        return 0
    fi

    echo ""
    echo "=== $OS_PROJECT_NAME ($TARGET_PROJECT_ID) as $OS_USERNAME ==="

    cleanup_fips
    cleanup_routers
    cleanup_networks
    cleanup_orphan_ports
    cleanup_security_groups
    cleanup_misc
}

function cleanup_tempest_leftovers() {
    echo "Starting Neutron-only cleanup"

    load_protected_ids || return 1

    local i k

    for i in $(seq 1 10); do
        export OS_USERNAME="neutron-tempestuser$i"
        export OS_PROJECT_NAME="neutron-tempest$i"
        export OS_TENANT_NAME="neutron-tempest$i"
        cleanup_project_neutron
    done

    for i in $(seq 1 4); do
        export OS_USERNAME="neutron-tempestadmin$i"
        export OS_PROJECT_NAME="neutron-tempest-admin$i"
        export OS_TENANT_NAME="neutron-tempest-admin$i"
        cleanup_project_neutron
    done

    echo ""
    echo "=== TOTAL DELETED ==="
    for k in fips routers networks orphan_ports security_groups; do
        echo "  $k: ${TOTAL[$k]:-0}"
    done
}

{{- include "tempest-base.function_main" . }}

main
