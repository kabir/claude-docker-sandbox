#!/bin/bash
# Merge sandbox-config.json and sandbox-config.local.json
# Local config overrides/extends shared config

BASE_CONFIG="sandbox-config.json"
LOCAL_CONFIG="sandbox-config.local.json"
OUTPUT="/tmp/sandbox-config-merged.json"

if [ ! -f "$BASE_CONFIG" ]; then
    echo "Error: $BASE_CONFIG not found" >&2
    exit 1
fi

# If no local config, just use base
if [ ! -f "$LOCAL_CONFIG" ]; then
    cp "$BASE_CONFIG" "$OUTPUT"
    exit 0
fi

# Merge configs using jq
# Arrays are concatenated, objects are merged (local overrides)
jq -s '
  .[0] as $base |
  .[1] as $local |
  {
    project_name: ($local.project_name // $base.project_name),
    instructions: ($base.instructions + ($local.instructions // [])),
    environment_notes: ($base.environment_notes + ($local.environment_notes // [])),
    recommended_workflow: ($base.recommended_workflow + ($local.recommended_workflow // []))
  } +
  # Include any extra fields from local config
  ($local | with_entries(select(.key | in({"project_name":1,"instructions":1,"environment_notes":1,"recommended_workflow":1}) | not)))
' "$BASE_CONFIG" "$LOCAL_CONFIG" > "$OUTPUT"

echo "✓ Merged $BASE_CONFIG + $LOCAL_CONFIG → $OUTPUT" >&2
