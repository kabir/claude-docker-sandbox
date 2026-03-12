# Claude Code Podman Sandbox - Project Context

This document provides context for Claude Code when working on this project.

## Project Overview

**What**: A production-ready Podman/Docker sandbox for running Claude Code in an isolated Linux environment
**Why**: Reproducible development environment with specific tool versions (Java 17/21/25, Python 3.12, Node.js 20)
**For**: Development work requiring Linux, specific tools, or safe experimentation with copy mode

## Key Design Principles

1. **User-Friendly First**: Simple syntax, smart defaults, minimal typing
2. **Safety by Default**: Copy mode for experiments, confirmation prompts for destructive operations
3. **Flexibility**: Mount any directory, work on originals or copies, save configurations as profiles
4. **Professional Quality**: Tab completion, proper error handling, comprehensive documentation

## Architecture

### Core Components

**Container Image** (`Containerfile`):
- Base: Ubuntu 24.04
- Languages: Java (17/21/25 via SDKMan), Python 3.12.3, Node.js 20.20.1
- Tools: Maven, git, gh, ripgrep, fd, bat, grpcurl, protobuf, pytest, ruff, mypy
- User: `claude` (non-root)
- Working directory: `/workspace`

**Runner Script** (`claude-pod.sh`):
- Main interface for all operations
- ~550 lines of Bash
- Features: smart mounting, copy mode, profiles, shell completion integration
- Follows strict safety practices: absolute paths, confirmation prompts, no auto-commit

**Shell Completion** (`completions/`):
- Full tab completion for Zsh and Bash
- Dynamic completion for profiles, commands, options
- Professional UX enhancement

### File Structure

```
claude-docker-sandbox/
├── Containerfile                      # Image definition (OCI standard, not Dockerfile)
├── docker-entrypoint.sh               # Container startup script (sources SDKMan, sets PATH)
├── claude-pod.sh                      # Main CLI interface (all commands route through here)
├── install-completion.sh              # Shell completion installer
├── completions/                       # Tab completion scripts
│   ├── claude-pod.zsh                 # Zsh completion
│   ├── claude-pod.bash                # Bash completion
│   └── README.md                      # Completion docs
├── sandbox-config.json                # Base sandbox configuration (committed)
├── sandbox-config.local.json.example  # Local config template
├── merge-sandbox-config.sh            # Config merging script (build time)
├── show-sandbox-config.sh             # Display config (sandbox-info command)
├── README.md                          # User documentation
├── TOOLS.md                           # Complete tool reference
├── INSTALL.md                         # Advanced setup guide
├── GITHUB.md                          # Safe publishing guide
├── .env                               # User configuration (gitignored)
├── .env.example                       # Configuration template
├── .gitignore                         # Protects secrets
└── sandbox-config.local.json          # Personal config overrides (gitignored)
```

## Key Features Implemented

### Smart Mount Syntax (Auto-Mapping)
```bash
# Old way: ./claude-pod.sh -m ~/myproject:/workspace/myproject shell
# New way: ./claude-pod.sh -m ~/myproject
# Result: Auto-maps to /workspace/myproject (uses basename)
```

**Implementation**: In `claude-pod.sh`, mount parsing checks for `:` delimiter. If absent, uses `basename` to derive container path.

### User Namespace Mapping (Write Permissions)
**Problem Solved**: Mounted directories were read-only due to UID/GID mismatches between Mac and container.

**Solution**: Runtime user namespace mapping via `--userns=keep-id:uid=X,gid=Y`
- Build time: Creates generic `claude` user (UID/GID 1000 by default)
- Runtime: Script detects your Mac UID/GID (`id -u`, `id -g`) and maps container user to match
- Result: Seamless read/write access to mounted directories
- Portable: Same image works for any user without rebuilds

**Implementation**: `claude-pod.sh` passes detected UID/GID to Podman's `--userns` flag. Files remain owned by you on Mac, accessible as you in container.

### Copy Mode (Safe Experimentation)
```bash
./claude-pod.sh -c -m ~/project
# Creates timestamped copy in ~/.cache/claude-copies/copy-project-YYYYMMDD_HHMMSS
# Original never touched
```

**Implementation**: When `-c` flag is set, creates copy before mounting. Tracks copies for cleanup. Shows exact copy location at start and completion.

**Key Detail**: Copy mode detection uses mount path analysis (checks for `claude-copies` in path) rather than marker files, keeping copied directories clean. No `.claude-copy-info` files are created.

### Enhanced Copy Management
```bash
./claude-pod.sh list-copies                                # Show all copies with sizes
./claude-pod.sh clean-copies --old 7                   # Remove copies older than 7 days
./claude-pod.sh clean-copies copy-project-20260312_150001   # Remove specific copy by name
./claude-pod.sh clean-copies --force --all             # Remove all without prompts
```

**Implementation**: Shell completion dynamically suggests available copy names. Accepts both `copy-project-timestamp` and `project-timestamp` formats. Confirmation prompts show size and path unless `--force` used.

### Sandbox Configuration System
**Purpose**: Inform Claude about sandbox constraints and capabilities on container startup.

**Components**:
1. **`sandbox-config.json`** (committed, shared with team)
   - Generic sandbox limitations (no Docker/Testcontainers)
   - Available tools and versions (Java 17/21/25, Maven, Python, etc.)
   - Universal constraints applying to all projects

2. **`sandbox-config.local.json`** (gitignored, personal)
   - Personal cross-project workflow preferences
   - Your coding standards and reminders
   - Machine-specific environment notes

3. **`merge-sandbox-config.sh`** - Merges base + local at build time
   - Arrays concatenated (both sets of instructions)
   - Objects merged (local overrides base)
   - Extra fields from local preserved

4. **`show-sandbox-config.sh`** - Display merged config (`sandbox-info` command)
   - Pretty formatted output with jq
   - Fallback to raw JSON if jq unavailable

**Philosophy**:
- Base config = generic sandbox constraints (committed to repo)
- Local config = personal cross-project preferences (gitignored)
- Project config = project-specific instructions (in each project's CLAUDE.md)
- Three-layer approach: sandbox → personal → project

**How Claude Sees It**:
- Container startup shows key instructions from merged config
- `sandbox-info` command displays full config anytime
- Claude understands Docker unavailable, which tests to skip, available tools

**Implementation**:
- `Containerfile`: Copies configs, runs merge, installs to `~/.sandbox-config.json`
- `docker-entrypoint.sh`: Displays key instructions on startup
- `claude-pod.sh`: Creates temporary empty local config if needed for build

### Profile Management
```bash
./claude-pod.sh -m ~/sdk -m ~/app save-profile workspace
./claude-pod.sh --profile workspace  # Loads both mounts
```

**Implementation**: Profiles stored in `~/.claude/profiles/<name>.profile` as simple text files (one mount per line). Shell completion dynamically lists available profiles.

### Commands Reference

| Command | Purpose | Example |
|---------|---------|---------|
| `build` | Build container image | `./claude-pod.sh build` |
| `shell` | Interactive shell (default) | `./claude-pod.sh` or `./claude-pod.sh shell` |
| `here` | Mount current dir | `./claude-pod.sh here` |
| `run` | Execute command | `./claude-pod.sh run "java -version"` |
| `claude` | Run Claude autonomously | `./claude-pod.sh -m ~/proj claude "add tests" plan` |
| `list-copies` | Show all copies | `./claude-pod.sh list-copies` |
| `clean-copies` | Remove copies | `./claude-pod.sh clean-copies --old 7` or by name |
| `save-profile` | Save mount config | `./claude-pod.sh -m ~/a -m ~/b save-profile dev` |
| `list-profiles` | Show profiles | `./claude-pod.sh list-profiles` |
| `delete-profile` | Remove profile | `./claude-pod.sh delete-profile dev` |
| `cleanup` | Remove containers | `./claude-pod.sh cleanup` |

**Inside Container**:
| Command | Purpose | Example |
|---------|---------|---------|
| `sandbox-info` | Show sandbox config | Pretty display of merged configuration |
| `sdk use java X` | Switch Java version | `sdk use java 21.0.5-tem` |

## Development Guidelines

### When Modifying the Script

1. **Safety First**: Never compromise on safety (absolute paths, confirmation prompts)
2. **Test Thoroughly**: Test with real directories, edge cases (home dir, root, spaces in names)
3. **Update Help**: If adding commands/options, update `--help` text and README.md
4. **Follow Patterns**: Use existing print_* functions, maintain color scheme
5. **Error Handling**: Always check for edge cases, provide helpful error messages

### When Modifying the Container

1. **Rebuild Required**: Any Containerfile changes require `./claude-pod.sh build`
2. **Test Versions**: Verify Java switching works: `sdk use java 21.0.5-tem`
3. **PATH Important**: Ensure Python tools in PATH via docker-entrypoint.sh
4. **Layer Caching**: Order matters - frequently changing stuff at the end
5. **Size Matters**: Use `--no-cache-dir` for pip, `rm -rf /var/lib/apt/lists/*` for apt

### When Adding Features

1. **User-Friendly**: Is it simple to use? Can it be simplified further?
2. **Document**: README.md, help text, and this CLAUDE.md
3. **Shell Completion**: Update completion scripts if adding commands/options
4. **Backward Compatible**: Don't break existing usage patterns
5. **Test All Shells**: Verify bash and zsh compatibility

## Common Tasks

### Adding a New Tool to Container

```bash
# Edit Containerfile
USER root
RUN apt-get update && apt-get install -y new-tool \
    && rm -rf /var/lib/apt/lists/*
USER claude

# Rebuild
./claude-pod.sh build

# Verify
./claude-pod.sh run "which new-tool"
```

### Adding a New Command

```bash
# 1. Add function in claude-pod.sh
new_command() {
    print_info "Doing something..."
    # implementation
}

# 2. Add to case statement
case "${1:-shell}" in
    new-cmd)
        new_command
        ;;

# 3. Update help text
# 4. Update README.md
# 5. Update shell completion scripts
```

### Debugging the Script

```bash
# Add -x for debugging
bash -x ./claude-pod.sh [command]

# Check what mount args are being passed
echo "${MOUNT_ARGS[@]}"

# Verify copy creation
ls -la ~/.cache/claude-copies/
```

## Testing Checklist

Before committing changes:

- [ ] `./claude-pod.sh build` succeeds
- [ ] `./claude-pod.sh` starts shell
- [ ] `./claude-pod.sh here` works from a project directory
- [ ] `./claude-pod.sh -m ~/path` auto-maps correctly
- [ ] `./claude-pod.sh -c -m ~/path` creates copy
- [ ] `./claude-pod.sh list-copies` shows copies
- [ ] `./claude-pod.sh clean-copies --all` prompts before deletion
- [ ] `./claude-pod.sh clean-copies copy-name` removes specific copy
- [ ] `sandbox-info` command works inside container
- [ ] `./claude-pod.sh --help` displays correctly
- [ ] Tab completion works (test with a fresh shell)
- [ ] Profile save/load/list/delete all work
- [ ] All examples in README.md work as shown

## Important Notes

### Security & Safety

1. **Never Auto-Commit**: The script uses `--rm` flag - containers are ephemeral
2. **Absolute Paths**: All paths are expanded (`${path/#\~/$HOME}`)
3. **Copy Safety**: Copy mode ensures originals never modified
4. **Confirmation Prompts**: Destructive operations ask before proceeding (use `--force` to skip)
5. **No Default Mounts**: Clean workspace by default, user explicitly chooses what to expose

### Container Lifecycle

- **Ephemeral**: Containers deleted after exit (`--rm` flag)
- **Mounts Persist**: Changes to mounted dirs saved to host
- **Copies Persist**: Copies remain in `~/.cache/claude-copies/` until manually cleaned

### Network Access

- **Required**: Claude needs network for API connectivity
- **Security**: Comes from container isolation + selective mounting, not network restrictions
- **Full Access**: Can clone repos, install packages, access APIs

### MCP Servers

- **Run on Host**: Serena, Sequential, Context7, etc. run on macOS host
- **Container Connects**: Via mounted `~/.claude` config
- **No Installation Needed**: In container - they're on the host

## Git Workflow

```bash
# Always check status first
git status && git branch

# Feature branch for all work
git checkout -b feature/description

# Commit with descriptive messages
git add file1 file2
git commit -m "feat: Add feature X

Detailed explanation of what and why."

# Push to remote
git push origin feature/description
```

## Troubleshooting

### Container won't start
- Check `podman machine status` - ensure Podman VM is running
- Try `./claude-pod.sh build` to rebuild image
- Check `.env` file for valid configuration

### Completion not working
- Run `./install-completion.sh` again
- Verify `source ~/.zshrc` or `source ~/.bashrc`
- Check `echo $fpath` includes `~/.zsh/completions`

### Mount not showing up
- Check path exists: `ls -la ~/path/to/mount`
- Try absolute path: `./claude-pod.sh -m /full/path/to/dir`
- Verify Podman machine can access path

### Java version not switching
- Run `sdk list java` to see installed versions
- Ensure using correct identifier: `21.0.5-tem` not `21`
- Check JAVA_HOME: `echo $JAVA_HOME`

## Quick Reference

**Most Common Usage**:
```bash
./claude-pod.sh                              # Just start a shell
./claude-pod.sh here                         # Mount current directory
./claude-pod.sh -m ~/project                 # Mount specific project
./claude-pod.sh -c -m ~/project              # Safe copy mode
./claude-pod.sh --profile workspace          # Use saved profile
```

**Building**:
```bash
./claude-pod.sh build                        # Build/rebuild image
```

**Copy Management**:
```bash
./claude-pod.sh list-copies                                # See all copies
./claude-pod.sh clean-copies --old 7                     # Clean old copies (prompts)
./claude-pod.sh clean-copies copy-project-20260312_150001     # Remove specific copy
./claude-pod.sh clean-copies --force --all               # Clean all (no prompt)
```

**Running Commands**:
```bash
./claude-pod.sh run "mvn clean test"         # Run Maven tests
./claude-pod.sh run "sdk use java 21.0.5-tem && java -version"  # Switch Java
```

## Project Goals

1. ✅ **Reproducible**: Same environment on any machine
2. ✅ **Safe**: Copy mode prevents accidents
3. ✅ **User-Friendly**: Simple syntax, tab completion
4. ✅ **Professional**: Proper error handling, documentation
5. ✅ **Flexible**: Mount anything, save configs, work how you want

## Version History

- **v2.2** (Current - March 12, 2026): Sandbox configuration system, user namespace mapping for write permissions
- **v2.1** (March 12, 2026): Enhanced copy management with name-based cleanup, removed .claude-copy-info files
- **v2.0** (March 2026): User-friendly improvements, profiles, shell completion
- **v1.0**: Initial release with copy mode and flexible mounting
- **v0.1**: Basic Podman sandbox

## Future Considerations

Potential enhancements (not committed to, just ideas):

- Status command showing running containers, copies, disk usage
- Git-aware mounting (auto-detect repo root)
- Config file support (~/.claude-pod.yaml)
- Copy comparison tool
- Sync command for merging copy changes

## Contact & Support

- Project issues: GitHub issues (if/when published)
- Claude Code docs: https://code.claude.com/docs
- Podman docs: https://podman.io/docs

---

**Last Updated**: March 12, 2026
**Maintainer**: Kabir Khan
**License**: (To be determined)
