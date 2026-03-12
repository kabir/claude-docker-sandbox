# Shell Completion Scripts

Tab completion for `claude-pod.sh` - makes the CLI much more user-friendly!

## Installation

From the project root:

```bash
./install-completion.sh
```

The installer will:
1. Auto-detect your shell (Zsh or Bash)
2. Copy the appropriate completion script
3. Update your shell configuration
4. Tell you how to reload your shell

## Manual Installation

### Zsh (macOS default)

```bash
# Create completion directory
mkdir -p ~/.zsh/completions

# Copy completion file
cp completions/claude-pod.zsh ~/.zsh/completions/_claude-pod.sh

# Add to .zshrc
echo 'fpath=(~/.zsh/completions $fpath)' >> ~/.zshrc
echo 'autoload -Uz compinit && compinit' >> ~/.zshrc

# Reload shell
source ~/.zshrc
```

### Bash

```bash
# System-wide (requires sudo)
sudo cp completions/claude-pod.bash /usr/local/etc/bash_completion.d/claude-pod

# Or user-level
mkdir -p ~/.bash_completion.d
cp completions/claude-pod.bash ~/.bash_completion.d/claude-pod

# Add to .bashrc
echo 'for f in ~/.bash_completion.d/*; do source "$f"; done' >> ~/.bashrc

# Reload shell
source ~/.bashrc
```

## What Gets Completed

### Commands
- `build`, `shell`, `here`, `run`, `claude`
- `list-copies`, `clean-copies`, `cleanup`
- `save-profile`, `list-profiles`, `delete-profile`

### Options
- `-m`, `--mount` (with directory completion)
- `-c`, `--copy`
- `-p`, `--profile` (with profile name completion)
- `--no-color`
- `-h`, `--help`

### Dynamic Completions
- **Profiles**: Completes with your saved profile names
- **Claude modes**: `plan`, `auto`, `dontAsk`, `bypassPermissions`
- **Clean flags**: `--all`, `--old`, `--force`
- **Directories**: Standard path completion for `-m`

## Examples

```bash
# Tab completion shows all commands
./claude-pod.sh <TAB>

# Completes to --profile
./claude-pod.sh --prof<TAB>

# Shows your saved profiles
./claude-pod.sh --profile <TAB>

# Shows: --all  --old  --force
./claude-pod.sh clean-copies --<TAB>

# Directory completion
./claude-pod.sh -m ~/pro<TAB>
```

## Files

- **claude-pod.zsh** - Zsh completion script (advanced, feature-rich)
- **claude-pod.bash** - Bash completion script (compatible, robust)
- **README.md** - This file

## Uninstallation

### Zsh
```bash
rm ~/.zsh/completions/_claude-pod.sh
# Remove the fpath and compinit lines from ~/.zshrc
```

### Bash
```bash
rm ~/.bash_completion.d/claude-pod
# Or: sudo rm /usr/local/etc/bash_completion.d/claude-pod
# Remove the sourcing lines from ~/.bashrc
```

## Troubleshooting

**Completion not working after installation?**
1. Make sure you reloaded your shell: `source ~/.zshrc` or `source ~/.bashrc`
2. For Zsh, check: `echo $fpath` includes `~/.zsh/completions`
3. For Bash, check: `type _claude_pod_completion` shows a function

**Profile completion not working?**
- Make sure you have profiles saved in `~/.claude/profiles/`
- Create one with: `./claude-pod.sh -m ~/path save-profile test`

**Colors in completion?**
- Zsh shows descriptions with colors by default
- Bash shows simpler completions (no descriptions)

## Development

To modify completions:
1. Edit `claude-pod.zsh` or `claude-pod.bash`
2. Reload: `source ~/.zshrc` or `source ~/.bashrc`
3. Test: `./claude-pod.sh <TAB>`

For Zsh, you can debug with:
```bash
# Show what completion would generate
_complete_debug ./claude-pod.sh <TAB>
```
