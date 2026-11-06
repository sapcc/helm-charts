#!/bin/bash
# no set -e: a transient error must not kill the long-running rotation loop
set -uo pipefail

max=$((MAX_SIZE_MB * 1024 * 1024))
f="$SLOW_LOG_DIR/$POD_NAME-slow.log"

while true; do
	sleep "$INTERVAL_SECONDS"
	[ -f "$f" ] || continue
	[ "$(stat -c %s "$f")" -gt "$max" ] || continue
	if [ "$KEEP_PREVIOUS" = true ]; then
		cp -f "$f" "$f.1"
	fi
	: > "$f"
done
