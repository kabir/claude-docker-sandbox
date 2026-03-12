#compdef claude-pod.sh

# Zsh completion for claude-pod.sh
# Installation: Source this file or copy to your zsh completions directory

_claude-pod() {
    local -a commands options flags

    commands=(
        'build:Build the container image'
        'shell:Interactive shell (default)'
        'here:Mount current directory and start shell'
        'run:Run a command in container'
        'claude:Run Claude autonomously'
        'list-copies:List all copies'
        'ls-copies:List all copies (alias)'
        'clean-copies:Remove copies'
        'cleanup:Remove stopped containers'
        'save-profile:Save current mounts as a profile'
        'list-profiles:List all saved profiles'
        'ls-profiles:List all saved profiles (alias)'
        'delete-profile:Delete a saved profile'
        'rm-profile:Delete a saved profile (alias)'
    )

    options=(
        '-m[Mount a directory (auto-maps to /workspace/basename)]:path:_files -/'
        '--mount[Mount a directory]:path:_files -/'
        '-c[Work on copies instead of originals]'
        '--copy[Work on copies instead of originals]'
        '-p[Load a saved mount profile]:profile:_claude_pod_profiles'
        '--profile[Load a saved mount profile]:profile:_claude_pod_profiles'
        '--no-color[Disable colored output]'
        '--no-colour[Disable colored output]'
        '-h[Show help]'
        '--help[Show help]'
    )

    flags=(
        '--force:Skip confirmation prompts'
        '-f:Skip confirmation prompts'
        '--all:Remove all copies'
        '-a:Remove all copies'
        '--old:Remove old copies'
    )

    _arguments -C \
        '1: :->command' \
        '*:: :->args' \
        $options

    case $state in
        command)
            _describe 'command' commands
            ;;
        args)
            case $words[1] in
                clean-copies)
                    _arguments \
                        '(-f --force)'{-f,--force}'[Skip confirmation]' \
                        '(-a --all)'{-a,--all}'[Remove all copies]' \
                        '--old[Remove old copies]:days:(7 14 30)'
                    ;;
                save-profile)
                    _message 'profile name'
                    ;;
                delete-profile|rm-profile)
                    _arguments '1:profile:_claude_pod_profiles'
                    ;;
                --profile|-p)
                    _arguments '1:profile:_claude_pod_profiles'
                    ;;
                run)
                    _message 'command to run'
                    ;;
                claude)
                    _arguments \
                        '1:task:_message "task description"' \
                        '2:mode:(plan auto dontAsk bypassPermissions)'
                    ;;
            esac
            ;;
    esac
}

# Helper function to list available profiles
_claude_pod_profiles() {
    local profile_dir="$HOME/.claude/profiles"
    local -a profiles

    if [[ -d "$profile_dir" ]]; then
        profiles=(${(f)"$(ls -1 "$profile_dir"/*.profile 2>/dev/null | xargs -n1 basename | sed 's/\.profile$//')"})
        _describe 'profile' profiles
    fi
}

_claude-pod "$@"
