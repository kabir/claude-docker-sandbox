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

# Check if we're in copy mode by looking for .claude-copy-info files
if find /workspace -maxdepth 2 -name ".claude-copy-info" -type f 2>/dev/null | grep -q .; then
    echo "⚠️  COPY MODE ACTIVE - You are working on a COPY"
    echo "   Original files will NOT be modified"
    echo "   View info: cat .claude-copy-info (in any copied directory)"
    echo ""
fi

# Execute the provided command
exec "$@"
