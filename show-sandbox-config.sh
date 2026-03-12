#!/bin/bash
# Helper script to display sandbox configuration
# This gets copied into the container at /usr/local/bin/sandbox-info

CONFIG_FILE="$HOME/.sandbox-config.json"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "No sandbox configuration found."
    exit 0
fi

echo "========================================="
echo "Sandbox Configuration"
echo "========================================="
echo ""

if command -v jq &> /dev/null; then
    echo "📋 Instructions:"
    jq -r '.instructions[]' "$CONFIG_FILE" | sed 's/^/  • /'
    echo ""

    echo "🚫 Test Exclusions:"
    jq -r '.test_exclusions | to_entries[] | "  \(.key): \(.value)"' "$CONFIG_FILE"
    echo ""

    echo "📝 Environment Notes:"
    jq -r '.environment_notes[]' "$CONFIG_FILE" | sed 's/^/  • /'
    echo ""

    echo "💡 Recommended Workflow:"
    jq -r '.recommended_workflow[]' "$CONFIG_FILE" | sed 's/^/  • /'
else
    cat "$CONFIG_FILE"
fi

echo ""
echo "========================================="
