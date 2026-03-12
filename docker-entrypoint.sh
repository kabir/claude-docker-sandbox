#!/bin/bash
set -e

# Add Python user packages to PATH
export PATH="$HOME/.local/bin:$PATH"

# Source SDKMan to make Java and Maven available
if [ -f "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
    source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

# Source cargo environment for uv
if [ -f "$HOME/.cargo/env" ]; then
    source "$HOME/.cargo/env"
fi

# Display environment info
echo "========================================="
echo "Claude Code Sandbox Environment"
echo "========================================="

# Show sandbox configuration if it exists
if [ -f "$HOME/.sandbox-config.json" ]; then
    echo ""
    echo "📋 Sandbox Instructions:"
    if command -v jq &> /dev/null; then
        jq -r '.instructions[]' "$HOME/.sandbox-config.json" | sed 's/^/  ℹ️  /'
    else
        grep -o '"instructions":\s*\[.*\]' "$HOME/.sandbox-config.json" | sed 's/^/  /'
    fi
    echo ""
    echo "  💡 View full config: cat ~/.sandbox-config.json"
fi
echo "Java (default):"
java -version 2>&1 | head -1
echo "  All installed: $(sdk list java 2>/dev/null | grep installed | awk '{print $NF}' | tr '\n' ' ')"
echo ""
echo "Maven:"
mvn -version | head -1
echo ""
echo "Python Version:"
python --version
echo ""
echo "Node Version:"
node --version
echo ""
echo "Claude Code Version:"
claude --version
echo ""
echo "Modern CLI Tools:"
which rg fd bat gh grpcurl 2>&1 | sed 's/^/  /'
echo ""
echo "Python Tools:"
which pytest ruff mypy 2>&1 | sed 's/^/  /'
echo ""
echo "Working Directory: $(pwd)"
echo "========================================="
echo ""

# Check if we're in copy mode by examining mount paths
# Copy mode creates directories under ~/.cache/claude-copies/
if mount | grep -q '/workspace.*claude-copies'; then
    echo "⚠️  COPY MODE ACTIVE - You are working on a COPY"
    echo "   Original files will NOT be modified"
    echo "   Copy location visible in host shell output"
    echo ""
fi

# Execute the provided command
exec "$@"
