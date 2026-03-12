#!/bin/bash
set -e

# Claude Podman Runner - Flexible directory mounting with copy support
# Usage: ./claude-pod.sh [--mount /path/to/dir:/workspace/name] [--copy] [command] [args]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="claude-sandbox:latest"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_info() { echo -e "${BLUE}ℹ${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_copy() { echo -e "${CYAN}📋${NC} $1"; }

# Load .env if exists
if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a
    source "$SCRIPT_DIR/.env"
    set +a
fi

# Parse arguments
MOUNT_ARGS=()
COPY_MODE=false
COPY_PATHS=()
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

while [[ $# -gt 0 ]]; do
    case $1 in
        --mount|-m)
            if [ "$COPY_MODE" = true ]; then
                # In copy mode, extract source and create copy
                MOUNT_SPEC="$2"
                SRC_PATH="${MOUNT_SPEC%%:*}"
                CONTAINER_PATH="${MOUNT_SPEC#*:}"

                # Expand ~ to home directory
                SRC_PATH="${SRC_PATH/#\~/$HOME}"

                # Create copy in ~/.cache/claude-copies/ (works with Podman on macOS)
                COPY_DIR="$HOME/.cache/claude-copies"
                mkdir -p "$COPY_DIR"

                BASENAME=$(basename "$SRC_PATH")
                COPY_PATH="${COPY_DIR}/copy-${BASENAME}-${TIMESTAMP}"

                print_copy "Creating copy: $SRC_PATH → $COPY_PATH"
                cp -r "$SRC_PATH" "$COPY_PATH"

                # Track for cleanup message later
                COPY_PATHS+=("$COPY_PATH|$SRC_PATH")

                # Mount the copy instead
                MOUNT_ARGS+=("-v" "$COPY_PATH:$CONTAINER_PATH")
            else
                # Normal mode, mount original
                MOUNT_SPEC="$2"
                # Expand ~ to home directory
                MOUNT_SPEC="${MOUNT_SPEC/#\~/$HOME}"
                MOUNT_ARGS+=("-v" "$MOUNT_SPEC")
            fi
            shift 2
            ;;
        --copy|-c)
            COPY_MODE=true
            shift
            ;;
        --help|-h)
            cat << 'EOF'
Claude Podman Runner

Usage: ./claude-pod.sh [options] [command]

Options:
    --mount, -m <host:container>    Mount a directory
                                    Example: -m ~/myproject:/workspace/myproject

    --copy, -c                      Work on copies in ~/.cache/claude-copies/ instead of originals
                                    Creates timestamped copies for safe experimentation

    --help, -h                      Show this help

Commands:
    build                           Build the image
    shell                           Start interactive shell
    run <cmd>                       Run a command
    claude <task> [mode]           Run Claude autonomously

    If no command is given, starts interactive shell

Mounting Examples:
    # Mount original directory (changes affect original)
    ./claude-pod.sh -m ~/myproject:/workspace/myproject shell

    # Work on a copy (safe experimentation)
    ./claude-pod.sh --copy -m ~/myproject:/workspace/myproject shell

    # Work on multiple copies simultaneously
    Terminal 1: ./claude-pod.sh -c -m ~/proj:/workspace/p claude "try approach A"
    Terminal 2: ./claude-pod.sh -c -m ~/proj:/workspace/p claude "try approach B"
    Terminal 3: ./claude-pod.sh -c -m ~/proj:/workspace/p claude "try approach C"

    # Mount multiple directories (mix copy and original)
    ./claude-pod.sh --copy \
        -m ~/project-a:/workspace/a \
        -m ~/project-b:/workspace/b \
        shell

Permission Modes for claude command:
    plan                (default) Show plan, ask for approval
    auto                Auto-approve safe operations
    dontAsk             Fewer prompts
    bypassPermissions   No prompts (dangerous!)

Copy Mode Benefits:
    ✓ Safe experimentation without affecting originals
    ✓ Work on multiple variants simultaneously
    ✓ Easy to compare different approaches
    ✓ Discard bad ideas, keep good ones

Examples:
    # Build the image
    ./claude-pod.sh build

    # Interactive shell with no mounts
    ./claude-pod.sh shell

    # Mount original
    ./claude-pod.sh -m ~/myproject:/workspace/proj shell

    # Work on a copy (safest!)
    ./claude-pod.sh --copy -m ~/myproject:/workspace/proj \
        claude "refactor everything" auto

    # Compare three approaches simultaneously
    ./claude-pod.sh -c -m ~/proj:/workspace/p claude "use strategy A" auto &
    ./claude-pod.sh -c -m ~/proj:/workspace/p claude "use strategy B" auto &
    ./claude-pod.sh -c -m ~/proj:/workspace/p claude "use strategy C" auto &
    wait
    # Then review all three copies in /tmp

After Copy Mode:
    # Copies are in ~/.cache/claude-copies/
    ls -la ~/.cache/claude-copies/

    # Review changes
    diff -r ~/original ~/.cache/claude-copies/copy-original-20260312_143000

    # Copy back if you like it
    rsync -av ~/.cache/claude-copies/copy-original-20260312_143000/ ~/original/

    # Or delete
    rm -rf ~/.cache/claude-copies/copy-original-20260312_143000

    # Clean all copies
    rm -rf ~/.cache/claude-copies/

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

# Show copy locations after command completes
show_copy_summary() {
    if [ ${#COPY_PATHS[@]} -gt 0 ]; then
        echo ""
        print_success "Copy mode completed!"
        echo ""
        for entry in "${COPY_PATHS[@]}"; do
            COPY="${entry%%|*}"
            ORIG="${entry#*|}"
            print_copy "Copy: $COPY"
            print_info "Original: $ORIG"
            echo ""
            echo "  Review changes:"
            echo "    diff -r \"$ORIG\" \"$COPY\""
            echo ""
            echo "  Copy back if you like the changes:"
            echo "    rsync -av \"$COPY/\" \"$ORIG/\""
            echo ""
            echo "  Or delete the copy:"
            echo "    rm -rf \"$COPY\""
            echo ""
        done
    fi
}

# Cleanup function
cleanup() {
    show_copy_summary
}

# Register cleanup
trap cleanup EXIT

# Build the image
build() {
    print_info "Building Claude sandbox image..."
    cd "$SCRIPT_DIR"
    podman build -t "$IMAGE_NAME" .
    print_success "Image built successfully"
}

# Start interactive shell
shell() {
    if [ "$COPY_MODE" = true ]; then
        print_warning "Running in COPY mode - working on copies in /tmp"
    fi
    print_info "Starting interactive shell..."
    podman_run "-it" /bin/bash
}

# Run a command
run_cmd() {
    local cmd="$1"
    if [ "$COPY_MODE" = true ]; then
        print_warning "Running in COPY mode - working on copies in /tmp"
    fi
    print_info "Running: $cmd"
    podman_run "-it" bash -c "source ~/.sdkman/bin/sdkman-init.sh && $cmd"
}

# Run Claude
run_claude() {
    local task="$1"
    local mode="${2:-plan}"

    if [ "$COPY_MODE" = true ]; then
        print_warning "Running in COPY mode - working on copies in /tmp"
        print_warning "Original files will NOT be modified"
    fi

    print_warning "Running Claude with --permission-mode=$mode"
    print_info "Task: $task"

    podman_run "-it" bash -c "source ~/.sdkman/bin/sdkman-init.sh && cd /workspace && claude --permission-mode=$mode '$task'"
}

# Cleanup containers
cleanup_containers() {
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
        cleanup_containers
        ;;
    *)
        print_error "Unknown command: $1"
        print_info "Run './claude-pod.sh --help' for usage"
        exit 1
        ;;
esac
