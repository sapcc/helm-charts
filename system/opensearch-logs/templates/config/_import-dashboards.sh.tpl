#!/bin/sh
set -e

# OpenSearch 3.5.0+ uses /api/ instead of /_plugins/_dashboards/api/
export DASHBOARDS_URL="https://logs.{{ .Values.global.region }}.{{ .Values.global.tld }}"
API_BASE="/api"  # Updated for 3.5.0+

echo "===================================="
echo "OpenSearch Dashboards Import Tool"
echo "Target: $DASHBOARDS_URL"
echo "API Base: $API_BASE (OpenSearch 3.5.0+)"
echo "===================================="

# Wait for OpenSearch Dashboards to be ready
echo "Waiting for OpenSearch Dashboards..."
RETRY=0
MAX_RETRIES=60

until curl -s -o /dev/null -w "%{http_code}" "$DASHBOARDS_URL/api/status" | grep -q 200; do
  RETRY=$((RETRY+1))
  if [ $RETRY -ge $MAX_RETRIES ]; then
    echo "ERROR: OpenSearch Dashboards did not become ready in time"
    exit 1
  fi
  echo "Waiting... (attempt $RETRY/$MAX_RETRIES)"
  sleep 5
done

echo "✓ OpenSearch Dashboards is ready!"
echo ""

# Validate dashboard files before import
echo "Validating dashboard files..."
echo "===================================="

VALIDATION_FAILED=0

for dashboard in dashboards/*.ndjson; do
  if [ ! -f "$dashboard" ]; then
    echo "No dashboard files found in /dashboards/"
    continue
  fi

  DASHBOARD_NAME=$(basename "$dashboard")
  echo "Validating: $DASHBOARD_NAME"

  # Check if file is empty
  if [ ! -s "$dashboard" ]; then
    echo "  ✗ ERROR: File is empty"
    VALIDATION_FAILED=$((VALIDATION_FAILED+1))
    continue
  fi

  # Validate NDJSON format - each line must be valid JSON
  LINE_NUM=0
  VALID_OBJECTS=0
  while IFS= read -r line || [ -n "$line" ]; do
    LINE_NUM=$((LINE_NUM+1))

    # Skip empty lines
    if [ -z "$line" ]; then
      continue
    fi

    # Try to parse as JSON using jq
    if echo "$line" | jq empty >/dev/null 2>&1; then
      VALID_OBJECTS=$((VALID_OBJECTS+1))
    else
      echo "  ✗ ERROR: Invalid JSON at line $LINE_NUM"
      echo "  Preview: $(echo "$line" | cut -c1-80)..."
      VALIDATION_FAILED=$((VALIDATION_FAILED+1))
      break
    fi
  done < "$dashboard"

  if [ $VALIDATION_FAILED -eq 0 ]; then
    echo "  ✓ Valid NDJSON with $VALID_OBJECTS objects"
  fi
done

echo ""
if [ $VALIDATION_FAILED -gt 0 ]; then
  echo "ERROR: Dashboard validation failed for $VALIDATION_FAILED file(s)"
  echo "Please fix the dashboard files before importing"
  exit 1
fi

echo "✓ All dashboard files are valid!"
echo ""
if [ $VALIDATION_FAILED -gt 0 ]; then
  echo "ERROR: Dashboard validation failed for $VALIDATION_FAILED file(s)"
  echo "Please fix the dashboard files before importing"
  exit 1
fi

echo "✓ All dashboard files are valid!"
echo ""

# Check OpenSearch version
echo "Checking OpenSearch Dashboards version..."
VERSION_INFO=$(curl -s "$DASHBOARDS_URL/api/status" -u ${OPENSEARCH_USERNAME}:${OPENSEARCH_PASSWORD} | grep -o '"version":"[^"]*"' || echo "unknown")
echo "Version info: $VERSION_INFO"
echo ""

# Import dashboards
echo "Importing dashboards from /dashboards/"
echo "===================================="

SUCCESS=0
FAILED=0

for dashboard in dashboards/*.ndjson; do
  if [ ! -f "$dashboard" ]; then
    echo "No dashboard files found in /dashboards/"
    continue
  fi
  
  DASHBOARD_NAME=$(basename "$dashboard")
  echo ""
  echo "Processing: $DASHBOARD_NAME"
  echo "------------------------------------"
  
  # Import with overwrite (OpenSearch 3.5.0+ endpoint)
  RESPONSE=$(curl -w "\n%{http_code}" -X POST \
    "$DASHBOARDS_URL${API_BASE}/saved_objects/_import?overwrite=true" \
    -H "osd-xsrf: true" \
    -H "securitytenant: global" \
    -u ${OPENSEARCH_USERNAME}:${OPENSEARCH_PASSWORD} \
    --form file=@"$dashboard" 2>&1)
  
  HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
  BODY=$(echo "$RESPONSE" | sed '$d')
  
  if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ Successfully imported $DASHBOARD_NAME"
    
    # Parse response for details
    SUCCESS_COUNT=$(echo "$BODY" | grep -o '"successCount":[0-9]*' | grep -o '[0-9]*' || echo "0")
    ERROR_COUNT=$(echo "$BODY" | grep -o '"errors":\[[^]]*\]' | wc -l || echo "0")
    
    echo "  Objects imported: $SUCCESS_COUNT"
    if [ "$ERROR_COUNT" -gt 0 ]; then
      echo "  Warnings: $ERROR_COUNT"
      echo "  Response: $BODY"
    fi
    SUCCESS=$((SUCCESS+1))
  else
    echo "✗ Failed to import $DASHBOARD_NAME"
    echo "  HTTP Code: $HTTP_CODE"
    echo "  Response: $BODY"
    FAILED=$((FAILED+1))
    
    # Provide helpful error messages
    if echo "$BODY" | grep -q "no handler found"; then
      echo "  ERROR: API endpoint not found. Check OpenSearch Dashboards version."
      echo "  This script is for OpenSearch 3.5.0+. For older versions, use:"
      echo "  /_plugins/_dashboards/api/saved_objects/_import"
    elif echo "$BODY" | grep -q "security_exception"; then
      echo "  ERROR: Authentication/authorization failed."
      echo "  Check credentials and user permissions."
    elif echo "$BODY" | grep -q "Unauthorized"; then
      echo "  ERROR: Invalid credentials."
    fi
  fi
done

echo ""
echo "===================================="
echo "Import Summary:"
echo "  Success: $SUCCESS"
echo "  Failed:  $FAILED"
echo "===================================="

if [ $FAILED -gt 0 ]; then
  echo ""
  echo "ERROR: Some dashboards failed to import"
  exit 1
fi

echo ""
echo "✓ All dashboards imported successfully!"
