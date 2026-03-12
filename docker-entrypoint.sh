#!/bin/bash
set -e

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
echo "Java Version:"
java -version 2>&1 | head -1
echo ""
echo "Maven Version:"
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
echo "Working Directory: $(pwd)"
echo "========================================="
echo ""

# Execute the provided command
exec "$@"
