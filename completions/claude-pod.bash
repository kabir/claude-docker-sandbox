#!/usr/bin/env bash
# Bash completion for claude-pod.sh
# Installation: Source this file or copy to /etc/bash_completion.d/

_claude_pod_completion() {
    local cur prev opts commands
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # Available commands
    commands="build shell here run claude list-copies ls-copies clean-copies cleanup save-profile list-profiles ls-profiles delete-profile rm-profile"

    # Options
    opts="-m --mount -c --copy -p --profile --no-color --no-colour -h --help"

    # Flags for clean-copies
    clean_flags="--force -f --all -a --old"

    # Claude permission modes
    claude_modes="plan auto dontAsk bypassPermissions"

    # Get available profiles
    _get_profiles() {
        local profile_dir="$HOME/.claude/profiles"
        if [[ -d "$profile_dir" ]]; then
            ls -1 "$profile_dir"/*.profile 2>/dev/null | xargs -n1 basename | sed 's/\.profile$//'
        fi
    }

    # Completion logic
    case "${prev}" in
        -m|--mount)
            # Complete with directories
            COMPREPLY=( $(compgen -d -- "${cur}") )
            return 0
            ;;
        -p|--profile)
            # Complete with profile names
            COMPREPLY=( $(compgen -W "$(_get_profiles)" -- "${cur}") )
            return 0
            ;;
        save-profile|delete-profile|rm-profile)
            # Complete with profile names for delete, just text for save
            if [[ "${prev}" == "save-profile" ]]; then
                return 0
            else
                COMPREPLY=( $(compgen -W "$(_get_profiles)" -- "${cur}") )
                return 0
            fi
            ;;
        claude)
            # Complete with permission modes
            COMPREPLY=( $(compgen -W "${claude_modes}" -- "${cur}") )
            return 0
            ;;
        clean-copies)
            # Complete with clean-copies flags
            COMPREPLY=( $(compgen -W "${clean_flags}" -- "${cur}") )
            return 0
            ;;
        --old)
            # Suggest common day values
            COMPREPLY=( $(compgen -W "7 14 30" -- "${cur}") )
            return 0
            ;;
    esac

    # Complete commands or options
    if [[ ${cur} == -* ]]; then
        COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
    elif [[ ${COMP_CWORD} -eq 1 ]]; then
        COMPREPLY=( $(compgen -W "${commands}" -- "${cur}") )
    fi

    return 0
}

# Register the completion function
complete -F _claude_pod_completion claude-pod.sh
complete -F _claude_pod_completion ./claude-pod.sh
