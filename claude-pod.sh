#!/bin/bash
set -e

# Claude Podman Runner - Flexible directory mounting with copy support
# Usage: ./claude-pod.sh [-m ~/path] [-c] [command]
# Examples:
#   ./claude-pod.sh                    # Start shell
#   ./claude-pod.sh here               # Mount current dir
#   ./claude-pod.sh -m ~/project       # Mount specific dir
#   ./claude-pod.sh -c -m ~/project    # Work on copy

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="claude-sandbox:latest"
USE_COLOR=true

# Colors (will be disabled if --no-color is passed)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Disable colors function
disable_colors() {
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    NC=''
    USE_COLOR=false
}

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

# First pass: Check for --copy flag anywhere in arguments
# This ensures COPY_MODE is set before processing mounts
for arg in "$@"; do
    if [[ "$arg" == "--copy" ]] || [[ "$arg" == "-c" ]]; then
        COPY_MODE=true
        break
    fi
done

while [[ $# -gt 0 ]]; do
    case $1 in
        --profile|-p)
            load_profile "$2"
            shift 2
            ;;
        --no-color|--no-colour)
            disable_colors
            shift
            ;;
        --mount|-m)
            MOUNT_SPEC="$2"

            # Smart path handling: if no colon, auto-derive container path
            if [[ "$MOUNT_SPEC" != *":"* ]]; then
                # Expand ~ to home directory first
                SRC_PATH="${MOUNT_SPEC/#\~/$HOME}"
                # Auto-derive container path from basename
                BASENAME=$(basename "$SRC_PATH")
                CONTAINER_PATH="/workspace/$BASENAME"
                print_info "Auto-mapping: $MOUNT_SPEC → $CONTAINER_PATH"
            else
                # Explicit mapping provided
                SRC_PATH="${MOUNT_SPEC%%:*}"
                CONTAINER_PATH="${MOUNT_SPEC#*:}"
                # Expand ~ to home directory
                SRC_PATH="${SRC_PATH/#\~/$HOME}"
            fi

            if [ "$COPY_MODE" = true ]; then
                # Create copy in ~/.cache/claude-copies/
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
                MOUNT_ARGS+=("-v" "$SRC_PATH:$CONTAINER_PATH")
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
    -m <path>                       Mount a directory (auto-maps to /workspace/basename)
                                    Example: -m ~/myproject → /workspace/myproject
                                    Or explicit: -m ~/myproject:/workspace/proj

    -c, --copy                      Work on copies instead of originals (safe mode)
                                    Creates timestamped copies in ~/.cache/claude-copies/

    -p, --profile <name>            Load a saved mount profile

    --no-color                      Disable colored output (for CI/CD)

    -h, --help                      Show this help

Commands:
    build                           Build the container image
    shell                           Interactive shell (default if no command given)
    here                            Mount current directory and start shell
    run <cmd>                       Run a command in container
    claude <task> [mode]            Run Claude autonomously

    list-copies, ls-copies          List all copies
    clean-copies [--force] --all    Remove all copies (prompts unless --force)
    clean-copies [--force] --old    Remove old copies (prompts unless --force)
    cleanup                         Remove stopped containers

    save-profile <name>             Save current mounts as a profile
    list-profiles, ls-profiles      List all saved profiles
    delete-profile <name>           Delete a saved profile

Quick Start Examples:
    # Start shell with no mounts
    ./claude-pod.sh

    # Mount current directory
    ./claude-pod.sh here

    # Mount a specific project (auto-maps to /workspace/myproject)
    ./claude-pod.sh -m ~/myproject

    # Work on a copy (safe mode)
    ./claude-pod.sh -c -m ~/myproject

    # Multiple directories
    ./claude-pod.sh -m ~/project-a -m ~/project-b

Mounting Examples:
    # Simple auto-mapping
    -m ~/myproject              → /workspace/myproject
    -m ~/code/testing           → /workspace/testing

    # Explicit mapping (if you need custom paths)
    -m ~/myproject:/workspace/proj

    # Work on multiple copies simultaneously
    Terminal 1: ./claude-pod.sh -c -m ~/proj claude "try approach A"
    Terminal 2: ./claude-pod.sh -c -m ~/proj claude "try approach B"
    Terminal 3: ./claude-pod.sh -c -m ~/proj claude "try approach C"

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

Workflow Examples:
    # Build the image (one-time)
    ./claude-pod.sh build

    # Quick shell
    ./claude-pod.sh

    # Work on current directory
    cd ~/myproject
    ./claude-pod.sh here

    # Work on a copy (safest!)
    ./claude-pod.sh -c -m ~/myproject claude "refactor everything" auto

    # Compare three approaches simultaneously
    ./claude-pod.sh -c -m ~/proj claude "use strategy A" auto &
    ./claude-pod.sh -c -m ~/proj claude "use strategy B" auto &
    ./claude-pod.sh -c -m ~/proj claude "use strategy C" auto &
    wait

    # Manage copies
    ./claude-pod.sh list-copies                    # List all copies
    ./claude-pod.sh clean-copies --old 7           # Clean old (prompts)
    ./claude-pod.sh clean-copies --force --all     # Clean all (no prompt)

Profile Examples:
    # Save a profile
    ./claude-pod.sh -m ~/sdk -m ~/app save-profile my-workspace

    # Use a profile
    ./claude-pod.sh --profile my-workspace

    # List profiles
    ./claude-pod.sh list-profiles

    # Delete a profile
    ./claude-pod.sh delete-profile my-workspace

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
        print_warning "Running in COPY mode - working on copies"
        if [ ${#COPY_PATHS[@]} -gt 0 ]; then
            for entry in "${COPY_PATHS[@]}"; do
                COPY="${entry%%|*}"
                ORIG="${entry#*|}"
                print_copy "Copy location: $COPY"
                print_info "Original: $ORIG"
            done
        fi
    fi
    print_info "Starting interactive shell..."
    podman_run "-it" /bin/bash
}

# Run a command
run_cmd() {
    local cmd="$1"
    if [ "$COPY_MODE" = true ]; then
        print_warning "Running in COPY mode - working on copies"
        if [ ${#COPY_PATHS[@]} -gt 0 ]; then
            for entry in "${COPY_PATHS[@]}"; do
                COPY="${entry%%|*}"
                print_copy "Copy: $COPY"
            done
        fi
    fi
    print_info "Running: $cmd"
    podman_run "-it" bash -c "source ~/.sdkman/bin/sdkman-init.sh && $cmd"
}

# Run Claude
run_claude() {
    local task="$1"
    local mode="${2:-plan}"

    if [ "$COPY_MODE" = true ]; then
        print_warning "Running in COPY mode - working on copies"
        if [ ${#COPY_PATHS[@]} -gt 0 ]; then
            for entry in "${COPY_PATHS[@]}"; do
                COPY="${entry%%|*}"
                ORIG="${entry#*|}"
                print_copy "Copy: $COPY"
                print_info "Original: $ORIG"
            done
        fi
        print_warning "Original files will NOT be modified"
    fi

    print_warning "Running Claude with --permission-mode=$mode"
    print_info "Task: $task"

    podman_run "-it" bash -c "source ~/.sdkman/bin/sdkman-init.sh && cd /workspace && claude --permission-mode=$mode '$task'"
}

# Cleanup containers
cleanup_containers() {
    print_info "Cleaning up stopped containers..."
    podman container prune -f
    print_success "Cleanup complete"
}

# List all copies
list_copies() {
    COPY_DIR="$HOME/.cache/claude-copies"
    if [ ! -d "$COPY_DIR" ] || [ -z "$(ls -A "$COPY_DIR" 2>/dev/null)" ]; then
        print_info "No copies found in $COPY_DIR"
        return
    fi

    print_info "Copies in $COPY_DIR:"
    echo ""
    for copy in "$COPY_DIR"/copy-*; do
        if [ -d "$copy" ]; then
            SIZE=$(du -sh "$copy" | cut -f1)
            TIMESTAMP=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$copy" 2>/dev/null || stat -c "%y" "$copy" 2>/dev/null | cut -d'.' -f1)
            printf "  📋 %-50s %8s  %s\n" "$(basename "$copy")" "$SIZE" "$TIMESTAMP"
        fi
    done
    echo ""
    print_info "Total: $(ls -1d "$COPY_DIR"/copy-* 2>/dev/null | wc -l | tr -d ' ') copies"
}

# Clean old copies
clean_copies() {
    COPY_DIR="$HOME/.cache/claude-copies"

    if [ ! -d "$COPY_DIR" ]; then
        print_info "No copies directory found"
        return
    fi

    local COPIES=$(ls -1d "$COPY_DIR"/copy-* 2>/dev/null | wc -l | tr -d ' ')
    if [ "$COPIES" -eq 0 ]; then
        print_info "No copies to clean"
        return
    fi

    local FORCE=false
    local MODE=""
    local DAYS=7

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force|-f)
                FORCE=true
                shift
                ;;
            --all|-a)
                MODE="all"
                shift
                ;;
            --old)
                MODE="old"
                DAYS="${2:-7}"
                shift
                if [[ "$1" =~ ^[0-9]+$ ]]; then
                    shift
                fi
                ;;
            *)
                shift
                ;;
        esac
    done

    if [ "$MODE" = "all" ]; then
        if [ "$FORCE" = false ]; then
            print_warning "About to remove all $COPIES copies:"
            echo ""
            for copy in "$COPY_DIR"/copy-*; do
                if [ -d "$copy" ]; then
                    SIZE=$(du -sh "$copy" | cut -f1)
                    printf "  📋 %-50s %8s\n" "$(basename "$copy")" "$SIZE"
                fi
            done
            echo ""
            read -p "Are you sure? (yes/no): " confirm
            if [ "$confirm" != "yes" ]; then
                print_info "Cancelled"
                return
            fi
        fi
        print_warning "Removing all $COPIES copies..."
        rm -rf "$COPY_DIR"/copy-*
        print_success "All copies removed"
    elif [ "$MODE" = "old" ]; then
        # Find old copies
        OLD_COPIES=$(find "$COPY_DIR" -maxdepth 1 -name "copy-*" -type d -mtime +$DAYS 2>/dev/null)
        if [ -z "$OLD_COPIES" ]; then
            print_info "No copies older than $DAYS days found"
            return
        fi

        OLD_COUNT=$(echo "$OLD_COPIES" | wc -l | tr -d ' ')

        if [ "$FORCE" = false ]; then
            print_warning "About to remove $OLD_COUNT copies older than $DAYS days:"
            echo ""
            echo "$OLD_COPIES" | while read copy; do
                if [ -d "$copy" ]; then
                    SIZE=$(du -sh "$copy" | cut -f1)
                    AGE=$(stat -f "%Sm" -t "%Y-%m-%d" "$copy" 2>/dev/null || stat -c "%y" "$copy" 2>/dev/null | cut -d' ' -f1)
                    printf "  📋 %-50s %8s  %s\n" "$(basename "$copy")" "$SIZE" "$AGE"
                fi
            done
            echo ""
            read -p "Are you sure? (yes/no): " confirm
            if [ "$confirm" != "yes" ]; then
                print_info "Cancelled"
                return
            fi
        fi
        print_info "Removing copies older than $DAYS days..."
        find "$COPY_DIR" -maxdepth 1 -name "copy-*" -type d -mtime +$DAYS -exec rm -rf {} \;
        print_success "Old copies removed"
    else
        print_error "Usage: clean-copies [--force] --all | --old [days]"
        echo "  --all, -a           Remove all copies"
        echo "  --old [days]        Remove copies older than N days (default: 7)"
        echo "  --force, -f         Skip confirmation prompt"
    fi
}

# Mount current directory
here_cmd() {
    local CWD=$(pwd)
    local BASENAME=$(basename "$CWD")

    # Check if we're in a meaningful directory (not home or root)
    if [ "$CWD" = "$HOME" ] || [ "$CWD" = "/" ]; then
        print_error "Cannot mount home or root directory"
        print_info "Navigate to a project directory first"
        exit 1
    fi

    print_info "Mounting current directory: $CWD"
    MOUNT_ARGS+=("-v" "$CWD:/workspace/$BASENAME")

    # Start shell
    shell
}

# Save mount profile
save_profile() {
    local PROFILE_NAME="$1"
    local PROFILE_DIR="$HOME/.claude/profiles"

    if [ -z "$PROFILE_NAME" ]; then
        print_error "Profile name required"
        print_info "Usage: ./claude-pod.sh save-profile <name>"
        return 1
    fi

    if [ ${#MOUNT_ARGS[@]} -eq 0 ]; then
        print_error "No mounts to save"
        print_info "Use -m flags before save-profile"
        return 1
    fi

    mkdir -p "$PROFILE_DIR"
    local PROFILE_FILE="$PROFILE_DIR/$PROFILE_NAME.profile"

    # Save mounts to profile file
    > "$PROFILE_FILE"  # Clear file
    for arg in "${MOUNT_ARGS[@]}"; do
        if [ "$arg" != "-v" ]; then
            echo "$arg" >> "$PROFILE_FILE"
        fi
    done

    print_success "Profile '$PROFILE_NAME' saved with ${#MOUNT_ARGS[@]} mounts"
    print_info "Saved to: $PROFILE_FILE"
}

# Load mount profile
load_profile() {
    local PROFILE_NAME="$1"
    local PROFILE_DIR="$HOME/.claude/profiles"
    local PROFILE_FILE="$PROFILE_DIR/$PROFILE_NAME.profile"

    if [ -z "$PROFILE_NAME" ]; then
        print_error "Profile name required"
        print_info "Usage: ./claude-pod.sh --profile <name> [command]"
        return 1
    fi

    if [ ! -f "$PROFILE_FILE" ]; then
        print_error "Profile '$PROFILE_NAME' not found"
        print_info "Available profiles:"
        list_profiles
        return 1
    fi

    # Load mounts from profile
    print_info "Loading profile '$PROFILE_NAME'..."
    while IFS= read -r mount; do
        MOUNT_ARGS+=("-v" "$mount")
        print_info "  Mount: $mount"
    done < "$PROFILE_FILE"

    print_success "Profile loaded with ${#MOUNT_ARGS[@]} mounts"
}

# List mount profiles
list_profiles() {
    local PROFILE_DIR="$HOME/.claude/profiles"

    if [ ! -d "$PROFILE_DIR" ] || [ -z "$(ls -A "$PROFILE_DIR" 2>/dev/null)" ]; then
        print_info "No profiles found"
        print_info "Create one with: ./claude-pod.sh -m ~/path save-profile <name>"
        return
    fi

    print_info "Saved profiles in $PROFILE_DIR:"
    echo ""
    for profile in "$PROFILE_DIR"/*.profile; do
        if [ -f "$profile" ]; then
            local NAME=$(basename "$profile" .profile)
            local MOUNTS=$(wc -l < "$profile" | tr -d ' ')
            printf "  📁 %-30s (%s mounts)\n" "$NAME" "$MOUNTS"

            # Show mounts
            while IFS= read -r mount; do
                printf "     → %s\n" "$mount"
            done < "$profile"
            echo ""
        fi
    done
}

# Delete mount profile
delete_profile() {
    local PROFILE_NAME="$1"
    local PROFILE_DIR="$HOME/.claude/profiles"
    local PROFILE_FILE="$PROFILE_DIR/$PROFILE_NAME.profile"

    if [ -z "$PROFILE_NAME" ]; then
        print_error "Profile name required"
        print_info "Usage: ./claude-pod.sh delete-profile <name>"
        return 1
    fi

    if [ ! -f "$PROFILE_FILE" ]; then
        print_error "Profile '$PROFILE_NAME' not found"
        return 1
    fi

    # Show what will be deleted
    print_warning "About to delete profile '$PROFILE_NAME':"
    cat "$PROFILE_FILE" | sed 's/^/  → /'
    echo ""
    read -p "Are you sure? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        print_info "Cancelled"
        return
    fi

    rm "$PROFILE_FILE"
    print_success "Profile '$PROFILE_NAME' deleted"
}

# Main command handling
case "${1:-shell}" in
    build)
        build
        ;;
    shell)
        shell
        ;;
    here)
        here_cmd
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
    list-copies|ls-copies)
        list_copies
        ;;
    clean-copies)
        shift
        clean_copies "$@"
        ;;
    save-profile)
        shift
        save_profile "$1"
        ;;
    list-profiles|ls-profiles)
        list_profiles
        ;;
    delete-profile|rm-profile)
        shift
        delete_profile "$1"
        ;;
    *)
        print_error "Unknown command: $1"
        print_info "Run './claude-pod.sh --help' for usage"
        exit 1
        ;;
esac
