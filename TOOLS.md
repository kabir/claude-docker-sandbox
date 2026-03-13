# Tools and Features Reference

## Complete Tool List

### Programming Languages & Runtimes

| Tool | Version | Management | Notes |
|------|---------|------------|-------|
| **Java** | 17.0.13 (default) | SDKMan | LTS, default for most projects |
| **Java** | 21.0.5 | SDKMan | LTS, latest stable |
| **Java** | 25.0.1 | SDKMan | LTS, newest |
| **Maven** | 3.9.9 | SDKMan | Build automation |
| **Python** | 3.12.3 | System | Default Python |
| **Node.js** | 20.20.1 | System | For Claude Code CLI |

**Switching Java versions:**
```bash
# Inside container
sdk use java 21.0.5-tem
sdk use java 25.0.1-tem
sdk default java 17.0.13-tem

# List all installed
sdk list java
```

### Development Tools

| Tool | Purpose |
|------|---------|
| **gh** | GitHub CLI - create PRs, manage issues |
| **git** | Version control |
| **backlog** | Task management CLI (Backlog.md) |
| **grpcurl** | gRPC API testing (like curl for gRPC) |
| **curl** | HTTP client |
| **wget** | Download files |
| **ripgrep (rg)** | Fast code search, better than grep |
| **fd** | Fast find replacement |
| **bat** | Cat with syntax highlighting |
| **protobuf** | Protocol buffer compiler |
| **jq** | JSON processor |
| **tree** | Directory tree visualization |

**Using Backlog.md:**
```bash
# Initialize backlog in your project
backlog init

# Create a task
backlog create feature "Add authentication"

# List tasks
backlog list

# More info: https://backlog.md
```

### Python Tools

| Tool | Purpose |
|------|---------|
| **ruff** | Fast Python linter/formatter |
| **mypy** | Static type checker |
| **pytest** | Testing framework |
| **pytest-asyncio** | Async testing support |
| **pre-commit** | Git hook manager |
| **uv** | Fast Python package manager |

### Build Tools

| Tool | Purpose |
|------|---------|
| **gcc/g++** | C/C++ compiler |
| **make** | Build automation |
| **maven** | Java build tool |

### Editors

| Tool | Notes |
|------|-------|
| **vim** | Terminal editor |
| **nano** | Simple editor |

## MCP Servers (Serena, Sequential, etc.)

**IMPORTANT:** MCP servers run on your **HOST machine**, not in the container!

- ✅ Your `~/.claude` config is mounted → Container sees your MCP configs
- ✅ MCP servers run as processes on your Mac
- ✅ Claude Code CLI inside container connects to them
- ❌ You don't install MCPs in the container

**How it works:**
1. MCPs run on macOS host (via Claude Code)
2. Container mounts `~/.claude` (read your configs)
3. Claude CLI in container connects to host MCPs
4. Everything just works!

## Network Access

✅ **Container has full network access** by default!

- Can clone/push/pull git repos
- Can install packages (npm, pip, apt)
- Can access APIs
- Can use `gh` for GitHub operations

**Test it:**
```bash
./claude-pod.sh run "curl -s https://api.github.com/zen"
```

## Authentication & Credentials

### Claude Code

Your `~/.claude` directory is automatically mounted:
- ✅ Vertex AI authentication
- ✅ API keys
- ✅ Settings
- ✅ Conversation history
- ✅ MCP configurations

### GitHub (gh)

First time inside container:
```bash
# Inside container
gh auth login
# Follow prompts
```

Or mount your host credentials:
```bash
./claude-pod.sh \
    -m ~/.config/gh:/home/claude/.config/gh:ro \
    shell
```

### Git/SSH

Mount your SSH keys for git operations:
```bash
./claude-pod.sh \
    -m ~/.ssh:/home/claude/.ssh:ro \
    -m ~/myproject:/workspace/proj \
    shell

# Inside:
git push  # Uses your SSH keys
```

### Google Cloud (gcloud)

Already mounted read-only:
- `~/.config/gcloud` → `/home/claude/.config/gcloud:ro`

## Path Information

### User Paths

- `/home/claude` - Claude user home
- `/home/claude/.local/bin` - Python user binaries
- `/home/claude/.sdkman` - SDKMan installation
- `/home/claude/.claude` - Your Claude config (mounted)

### Working Directory

- `/workspace` - Default working directory
- Your projects mount here (e.g., `/workspace/myproject`)

## Copy Mode Details

### Where Copies Are Stored

`~/.cache/claude-copies/copy-{project}-{timestamp}/`

Example:
```
~/.cache/claude-copies/
├── copy-myproject-20260312_150001/
├── copy-myproject-20260312_150245/
└── copy-another-20260312_151030/
```

### Copy Management

**Built-in Commands** (Recommended):
```bash
./claude-pod.sh list-copies                              # List with sizes/timestamps
./claude-pod.sh clean-copies --old 7                     # Clean older than 7 days (prompts)
./claude-pod.sh clean-copies copy-project-20260312_150001     # Remove specific copy (prompts)
./claude-pod.sh clean-copies --all                       # Remove all (prompts)
./claude-pod.sh clean-copies --force --all               # Force removal without prompts
```

**Manual Commands** (if needed):
```bash
ls -la ~/.cache/claude-copies/                           # List copies
du -sh ~/.cache/claude-copies/*                          # Check sizes
find ~/.cache/claude-copies -mtime +7 -exec rm -rf {} \; # Clean old copies
rm -rf ~/.cache/claude-copies/*                          # Clean all copies
```

### When Copies Are Created

- ✅ When you use `--copy` flag
- ✅ One copy per mount point
- ✅ Timestamped for uniqueness
- ❌ Original files never modified

## Resource Usage

### Image Size

- **Base image**: ~800MB (Ubuntu 24.04)
- **With all tools**: ~2.5GB
- **Cached layers**: Reused on rebuild

### Disk Space for Copies

Copies are full duplicates:
- Project size × number of copies
- Example: 500MB project × 3 copies = 1.5GB

Clean regularly!

### Container Lifecycle

- **Ephemeral**: Container deleted after exit (`--rm` flag)
- **Mounts persist**: Changes to mounted dirs saved
- **Copies persist**: In `~/.cache/claude-copies/` until deleted

## Customization

### Add a Tool

Edit `Containerfile`:
```dockerfile
# Install your tool
USER root
RUN apt-get update && apt-get install -y your-tool \
    && rm -rf /var/lib/apt/lists/*
```

Then rebuild:
```bash
./claude-pod.sh build
```

### Change Default Java

Edit `Containerfile`:
```dockerfile
&& sdk default java 21.0.5-tem \  # Change this line
```

### Add Python Packages

Edit `Containerfile`:
```dockerfile
USER claude
RUN pip3 install --user --break-system-packages \
    your-package \
    another-package
```

## Quick Reference

### Frequently Used Commands

**From Host (Outside Container)**:
```bash
# Build/rebuild image
./claude-pod.sh build

# Shell with no mounts
./claude-pod.sh shell

# Mount and explore
./claude-pod.sh -m ~/proj:/workspace/p shell

# Work on a copy
./claude-pod.sh --copy -m ~/proj:/workspace/p shell

# Run Claude on copy
./claude-pod.sh -c -m ~/proj:/workspace/p claude "refactor" plan

# List and manage copies
./claude-pod.sh list-copies
./claude-pod.sh clean-copies --old 7

# Check Java versions
./claude-pod.sh run "sdk list java"

# GitHub operations
./claude-pod.sh run "gh pr list"

# Search code with ripgrep
./claude-pod.sh -m ~/proj:/workspace/p run "rg 'TODO' /workspace/p"
```

**Inside Container**:
```bash
# View sandbox configuration and constraints
sandbox-info

# Switch Java version
sdk use java 21.0.5-tem
java -version

# List installed Java versions
sdk list java
```

### Environment Variables Available

Inside container:
- `$SDKMAN_DIR` - SDKMan installation
- `$JAVA_HOME` - Current Java installation
- `$MAVEN_HOME` - Maven installation
- `$PATH` - Includes all tools
- Your `.env` vars (ANTHROPIC_*, GIT_*)

## Troubleshooting Common Issues

### Tool Not Found

```bash
# Check if installed
./claude-pod.sh run "which tool-name"

# If missing, add to Containerfile and rebuild
```

### Java Version Wrong

```bash
# Check current
./claude-pod.sh run "java -version"

# Switch (temporary)
./claude-pod.sh shell
> sdk use java 17.0.13-tem

# Change default (rebuild needed)
# Edit Containerfile: sdk default java 17.0.13-tem
```

### Python Package Missing

```bash
# Install temporarily
./claude-pod.sh shell
> pip install --user --break-system-packages package-name

# Make permanent: add to Containerfile
```

### Network Issues

```bash
# Test network
./claude-pod.sh run "curl -v https://google.com"

# Check DNS
./claude-pod.sh run "cat /etc/resolv.conf"
```

### MCP Not Working

MCPs run on host, not container. Check:
1. MCP server running on macOS?
2. `~/.claude` mounted? (automatic)
3. Claude Code CLI can connect?

```bash
./claude-pod.sh run "ls -la ~/.claude"
```

## Performance Tips

1. **Use --copy for experiments** - Don't pollute git history
2. **Clean copies regularly** - They use disk space
3. **Parallel experiments** - Run multiple copies simultaneously
4. **Layer caching** - Rebuild is fast if Containerfile hasn't changed
5. **Mount only what you need** - Faster startup
