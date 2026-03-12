#!/bin/bash
set -e

# Claude Podman Runner - Flexible directory mounting
# Usage: ./claude-pod.sh [--mount /path/to/dir:/workspace/name] [command] [args]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="claude-sandbox:latest"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}ℹ${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }

# Load .env if exists
if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a
    source "$SCRIPT_DIR/.env"
    set +a
fi

# Parse mount arguments
MOUNT_ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        --mount|-m)
            MOUNT_ARGS+=("-v" "$2")
            shift 2
            ;;
        --help|-h)
            cat << 'EOF'
Claude Podman Runner

Usage: ./claude-pod.sh [options] [command]

Options:
    --mount, -m <host:container>    Mount a directory
                                    Example: -m ~/myproject:/workspace/myproject

    --help, -h                      Show this help

Commands:
    build                           Build the image
    shell                           Start interactive shell
    run <cmd>                       Run a command
    claude <task> [mode]           Run Claude autonomously

    If no command is given, starts interactive shell

Mounting Examples:
    # Mount one directory
    ./claude-pod.sh -m ~/myproject:/workspace/myproject shell

    # Mount multiple directories
    ./claude-pod.sh \
        -m ~/project1:/workspace/p1 \
        -m ~/project2:/workspace/p2 \
        shell

    # Run Claude with mounted project
    ./claude-pod.sh -m ~/myproject:/workspace/myproject \
        claude "add tests" plan

Permission Modes for claude command:
    plan                (default) Show plan, ask for approval
    auto                Auto-approve safe operations
    dontAsk             Fewer prompts
    bypassPermissions   No prompts (dangerous!)

Examples:
    # Build the image
    ./claude-pod.sh build

    # Interactive shell with no mounts (just config)
    ./claude-pod.sh shell

    # Mount a project and explore
    ./claude-pod.sh -m ~/thinbg/my-cool-project:/workspace/cool shell

    # Run Claude on a specific project
    ./claude-pod.sh -m ~/tmp/a2a-java-copy:/workspace/work \
        claude "refactor error handling" plan

    # Mount multiple projects
    ./claude-pod.sh \
        -m ~/project-a:/workspace/a \
        -m ~/project-b:/workspace/b \
        run "ls -la /workspace"

EOF
            exit 0
            ;;
        *)
            break
            ;;
    esac
done

# Base podman run command with common settings
podman_run() {
    local interactive="$1"
    shift

    podman run $interactive --rm \
        --name "claude-sandbox-$$" \
        -v "$HOME/.claude:/home/claude/.claude" \
        -v "$HOME/.config/gcloud:/home/claude/.config/gcloud:ro" \
        "${MOUNT_ARGS[@]}" \
        -e CLAUDE_CODE_USE_VERTEX="${CLAUDE_CODE_USE_VERTEX:-1}" \
        -e ANTHROPIC_VERTEX_PROJECT_ID="${ANTHROPIC_VERTEX_PROJECT_ID}" \
        -e ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY}" \
        -e GIT_AUTHOR_NAME="${GIT_AUTHOR_NAME:-Claude Sandbox}" \
        -e GIT_AUTHOR_EMAIL="${GIT_AUTHOR_EMAIL:-sandbox@claude.local}" \
        -e GIT_COMMITTER_NAME="${GIT_COMMITTER_NAME:-Claude Sandbox}" \
        -e GIT_COMMITTER_EMAIL="${GIT_COMMITTER_EMAIL:-sandbox@claude.local}" \
        -w /workspace \
        "$IMAGE_NAME" \
        "$@"
}

# Build the image
build() {
    print_info "Building Claude sandbox image..."
    cd "$SCRIPT_DIR"
    podman build -t "$IMAGE_NAME" .
    print_success "Image built successfully"
}

# Start interactive shell
shell() {
    print_info "Starting interactive shell..."
    podman_run "-it" /bin/bash
}

# Run a command
run_cmd() {
    local cmd="$1"
    print_info "Running: $cmd"
    podman_run "-it" bash -c "source ~/.sdkman/bin/sdkman-init.sh && $cmd"
}

# Run Claude
run_claude() {
    local task="$1"
    local mode="${2:-plan}"

    print_warning "Running Claude with --permission-mode=$mode"
    print_info "Task: $task"

    podman_run "-it" bash -c "source ~/.sdkman/bin/sdkman-init.sh && cd /workspace && claude --permission-mode=$mode '$task'"
}

# Cleanup
cleanup() {
    print_info "Cleaning up..."
    podman container prune -f
    print_success "Cleanup complete"
}

# Main command handling
case "${1:-shell}" in
    build)
        build
        ;;
    shell)
        shell
        ;;
    run)
        shift
        if [ -z "$1" ]; then
            print_error "Command required for 'run'"
            exit 1
        fi
        run_cmd "$*"
        ;;
    claude)
        shift
        if [ -z "$1" ]; then
            print_error "Task required for 'claude'"
            exit 1
        fi
        task="$1"
        mode="${2:-plan}"
        run_claude "$task" "$mode"
        ;;
    cleanup)
        cleanup
        ;;
    *)
        print_error "Unknown command: $1"
        print_info "Run './claude-pod.sh --help' for usage"
        exit 1
        ;;
esac
