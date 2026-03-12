#!/bin/bash
# Install shell completion for claude-pod.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_TYPE="${1:-auto}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }

# Detect shell if auto
if [[ "$SHELL_TYPE" == "auto" ]]; then
    if [[ -n "$ZSH_VERSION" ]] || [[ "$SHELL" == *"zsh"* ]]; then
        SHELL_TYPE="zsh"
    elif [[ -n "$BASH_VERSION" ]] || [[ "$SHELL" == *"bash"* ]]; then
        SHELL_TYPE="bash"
    else
        print_warning "Could not detect shell type"
        echo "Please specify: ./install-completion.sh [zsh|bash]"
        exit 1
    fi
fi

echo "════════════════════════════════════════════"
echo "  Installing Shell Completion for claude-pod"
echo "════════════════════════════════════════════"
echo ""

case "$SHELL_TYPE" in
    zsh)
        print_info "Installing Zsh completion..."

        # Create completion directory if it doesn't exist
        COMP_DIR="$HOME/.zsh/completions"
        mkdir -p "$COMP_DIR"

        # Copy completion file
        cp "$SCRIPT_DIR/completions/claude-pod.zsh" "$COMP_DIR/_claude-pod.sh"
        print_success "Copied completion file to $COMP_DIR/_claude-pod.sh"

        # Add to .zshrc if not already present
        ZSHRC="$HOME/.zshrc"
        if ! grep -q "fpath=.*\.zsh/completions" "$ZSHRC" 2>/dev/null; then
            echo "" >> "$ZSHRC"
            echo "# claude-pod.sh completion" >> "$ZSHRC"
            echo 'fpath=(~/.zsh/completions $fpath)' >> "$ZSHRC"
            echo 'autoload -Uz compinit && compinit' >> "$ZSHRC"
            print_success "Added completion setup to $ZSHRC"
        else
            print_info "Completion path already in $ZSHRC"
        fi

        echo ""
        print_success "Zsh completion installed!"
        print_info "Reload your shell or run: source ~/.zshrc"
        ;;

    bash)
        print_info "Installing Bash completion..."

        # Determine bash completion directory
        if [[ -d "/usr/local/etc/bash_completion.d" ]]; then
            COMP_DIR="/usr/local/etc/bash_completion.d"
            sudo cp "$SCRIPT_DIR/completions/claude-pod.bash" "$COMP_DIR/claude-pod"
            print_success "Copied completion file to $COMP_DIR/claude-pod (requires sudo)"
        else
            # Use user directory
            COMP_DIR="$HOME/.bash_completion.d"
            mkdir -p "$COMP_DIR"
            cp "$SCRIPT_DIR/completions/claude-pod.bash" "$COMP_DIR/claude-pod"
            print_success "Copied completion file to $COMP_DIR/claude-pod"

            # Add sourcing to .bashrc if not present
            BASHRC="$HOME/.bashrc"
            if ! grep -q "\.bash_completion\.d" "$BASHRC" 2>/dev/null; then
                echo "" >> "$BASHRC"
                echo "# claude-pod.sh completion" >> "$BASHRC"
                echo 'for f in ~/.bash_completion.d/*; do source "$f"; done' >> "$BASHRC"
                print_success "Added completion setup to $BASHRC"
            fi
        fi

        echo ""
        print_success "Bash completion installed!"
        print_info "Reload your shell or run: source ~/.bashrc"
        ;;

    *)
        print_warning "Unknown shell type: $SHELL_TYPE"
        echo "Supported: zsh, bash"
        exit 1
        ;;
esac

echo ""
echo "════════════════════════════════════════════"
echo "  Test it out!"
echo "════════════════════════════════════════════"
echo ""
echo "Try typing:"
echo "  ./claude-pod.sh <TAB>"
echo "  ./claude-pod.sh --prof<TAB>"
echo "  ./claude-pod.sh clean-copies --<TAB>"
echo ""
