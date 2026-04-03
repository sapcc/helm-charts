#!/bin/sh
set -e

export OS_AUTH_URL={{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}/v3
export OS_USERNAME={{ .Release.Name }}{{ .Values.global.user_suffix }}
export OS_PROJECT_NAME=service
export OS_PROJECT_DOMAIN_ID=default
export OS_USER_DOMAIN_ID=default

ARCHERCTL="${ARCHERCTL:-archerctl}"

# Resolve hostname to IP address if needed
resolve_ip() {
    host="$1"
    # Check if already an IP address
    if echo "$host" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'; then
        echo "$host"
        return
    fi
    # Use nslookup
    resolved=$(nslookup "$host" 2>/dev/null | awk '/^Address: / { print $2 }' | head -1)
    if [ -n "$resolved" ]; then
        echo "$resolved"
        return
    fi
    echo "ERROR: Could not resolve hostname '$host'" >&2
    return 1
}

manage_service() {
    name="$1"
    az="$2"
    ip_or_host="$3"
    require_approval="$4"
    visibility="$5"
    proxy_protocol="$6"
    protocol="$7"
    shift 7
    # Remaining args are ports - store as space-separated string
    ports="$*"

    echo "=== Managing service: $name ==="

    # Resolve hostname to IP if needed
    ip=$(resolve_ip "$ip_or_host")
    if [ -z "$ip" ]; then
        echo "Error: Failed to resolve IP for '$ip_or_host', skipping service '$name'"
        return
    fi

    # Check if service exists by name
    SERVICE_LIST=$(${ARCHERCTL} service list -f value -c id -c name -c ip_addresses -c ports -c require_approval -c visibility -c proxy_protocol -c protocol -c provider 2>/dev/null || true)
    EXISTING=$(echo "$SERVICE_LIST" | awk -v name="$name" '$2 == name { print }')

    if [ -n "$EXISTING" ]; then
        EXISTING_ID=$(echo "$EXISTING" | awk '{print $1}')
        # Strip brackets and CIDR notation: [10.114.1.246/32] -> 10.114.1.246
        EXISTING_IP=$(echo "$EXISTING" | awk '{print $3}' | tr -d '[]' | sed 's|/.*||')
        # Strip brackets: [80] -> 80
        EXISTING_PORTS=$(echo "$EXISTING" | awk '{print $4}' | tr -d '[]')
        EXISTING_APPROVAL=$(echo "$EXISTING" | awk '{print $5}')
        EXISTING_VISIBILITY=$(echo "$EXISTING" | awk '{print $6}')
        EXISTING_PROXY_PROTOCOL=$(echo "$EXISTING" | awk '{print $7}')
        EXISTING_PROTOCOL=$(echo "$EXISTING" | awk '{print $8}')
        EXISTING_PROVIDER=$(echo "$EXISTING" | awk '{print $9}')

        if [ "$EXISTING_PROVIDER" != "cp" ]; then
            echo "Error: Service '$name' exists but is provided by '$EXISTING_PROVIDER', expected 'cp'. Skipping."
            return
        fi

        echo "Service '$name' exists with ID: $EXISTING_ID"

        # Build update command only with changed fields
        CMD=""
        CHANGES=""

        if [ "$EXISTING_IP" != "$ip" ]; then
            CMD="$CMD --ip-address=$ip"
            CHANGES="${CHANGES}ip_address($EXISTING_IP -> $ip) "
        fi

        # Compare ports (sort and deduplicate for comparison)
        DESIRED_PORTS=$(echo "$ports" | tr ' ' '\n' | sort -n | uniq | tr '\n' ',' | sed 's/,$//')
        CURRENT_PORTS=$(echo "$EXISTING_PORTS" | tr ',' '\n' | sort -n | tr '\n' ',' | sed 's/,$//')
        if [ "$CURRENT_PORTS" != "$DESIRED_PORTS" ]; then
            for port in $(echo "$ports" | tr ' ' '\n' | sort -n | uniq); do
                CMD="$CMD --port=$port"
            done
            CHANGES="${CHANGES}ports($CURRENT_PORTS -> $DESIRED_PORTS) "
        fi

        if [ "$EXISTING_APPROVAL" != "$require_approval" ]; then
            if [ "$require_approval" = "true" ]; then
                CMD="$CMD --require-approval"
            fi
            CHANGES="${CHANGES}require_approval($EXISTING_APPROVAL -> $require_approval) "
        fi

        if [ "$EXISTING_VISIBILITY" != "$visibility" ]; then
            CMD="$CMD --visibility=$visibility"
            CHANGES="${CHANGES}visibility($EXISTING_VISIBILITY -> $visibility) "
        fi

        if [ "$EXISTING_PROXY_PROTOCOL" != "$proxy_protocol" ]; then
            if [ "$proxy_protocol" = "true" ]; then
                CMD="$CMD --proxy-protocol"
            fi
            CHANGES="${CHANGES}proxy_protocol($EXISTING_PROXY_PROTOCOL -> $proxy_protocol) "
        fi

        if [ "$EXISTING_PROTOCOL" != "$protocol" ]; then
            CMD="$CMD --protocol=$protocol"
            CHANGES="${CHANGES}protocol($EXISTING_PROTOCOL -> $protocol) "
        fi

        if [ -n "$CMD" ]; then
            echo "Updating: $CHANGES"
            echo "Running: $ARCHERCTL service set $CMD $EXISTING_ID"
            $ARCHERCTL service set $CMD "$EXISTING_ID"
            echo "Service updated"
        else
            echo "No changes detected"
        fi
    else
        echo "Service '$name' does not exist, creating..."

        CMD="$ARCHERCTL service create --provider=cp --name=$name"
        CMD="$CMD --availability-zone=$az --ip-address=$ip --visibility=$visibility"
        CMD="$CMD --protocol=$protocol"
        for port in $(echo "$ports" | tr ' ' '\n' | sort -n | uniq); do
            CMD="$CMD --port=$port"
        done
        [ "$require_approval" = "true" ] && CMD="$CMD --require-approval"
        [ "$proxy_protocol" = "true" ] && CMD="$CMD --proxy-protocol"

        echo "Running: $CMD"
        eval "$CMD"
        echo "Service created"
    fi
    echo ""
}

{{- range $name, $config := .Values.agents.ni }}
{{- if $config.create_service }}
manage_service \
    "{{ $name }}" \
    "{{ required (printf "availability_zone is required for service %s" $name) $config.availability_zone }}" \
    "{{ $config.service_upstream_host }}" \
    "{{ $config.service_require_approval | default false }}" \
    "{{ if $config.service_public }}public{{ else }}private{{ end }}" \
    "{{ $config.service_proxy_protocol | default false }}" \
    "{{ $config.service_protocol | default "TCP" }}"{{- if $config.service_ports }}{{- range $config.service_ports }} \
    "{{ . }}"{{- end }}{{- else if $config.service_port }} \
    "{{ $config.service_port }}"{{- end }}

{{- end }}
{{- end }}

echo "=== All services processed ==="

{{- if and $.Values.global.linkerd_enabled $.Values.global.linkerd_requested }}
# Shutdown Linkerd sidecar
wget -O- --post-data hello=shutdown http://0.0.0.0:4191/shutdown || true
{{- end }}
