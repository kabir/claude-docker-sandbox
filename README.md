# Claude Code Podman Sandbox

A flexible, reproducible development environment for running Claude Code in an isolated Linux container.

## Why Use This vs Native `/sandbox`?

### Native `/sandbox` (Built into Claude Code)
- ✅ Instant startup, no setup
- ✅ Perfect for quick experiments
- ❌ macOS only (your host OS)
- ❌ Uses whatever tools you have installed
- ❌ Files deleted after session

**Use when:** Quick throwaway experiments, testing macOS-specific code

### This Podman Sandbox
- ✅ True Linux environment (Ubuntu 24.04)
- ✅ Reproducible across machines
- ✅ Specific tool versions (Java 21, Python 3.12, etc.)
- ✅ Mount any directory on-demand
- ✅ Shareable with team
- ❌ Requires initial build (~5 min)
- ❌ ~2.5GB disk space

**Use when:** Need Linux, specific tools, reproducible environments, or team collaboration

**Recommendation:** Use both! Native `/sandbox` for quick tasks, this for serious development.

## Features

- **Isolated Linux Environment**: Ubuntu 24.04 container
- **Multi-Language Support**: Java 21 (SDKMan), Python 3.12, Node.js 20
- **Pre-configured Tools**: Maven, git, protobuf, pytest, ruff, mypy
- **Flexible Mounting**: Mount any directory on-demand
- **Your Configuration**: Automatically mounts `~/.claude` (auth, settings, history)
- **No Default Mounts**: Clean workspace, you choose what to mount

## Quick Start

### 1. Build the Image (One-Time)

```bash
cd ~/sourcecontrol/AI/claude-docker-sandbox  # or wherever you put it
./claude-pod.sh build
```

This takes ~5 minutes the first time.

### 2. Configure Authentication

```bash
cp .env.example .env
nano .env  # Add your ANTHROPIC_VERTEX_PROJECT_ID
```

Your `~/.claude` config is automatically mounted, so existing auth works.

### 3. Start Using It

```bash
# Interactive shell with no projects mounted
./claude-pod.sh shell

# Mount a project
./claude-pod.sh -m ~/myproject:/workspace/proj shell

# Run Claude on a project
./claude-pod.sh -m ~/myproject:/workspace/proj claude "add tests" plan
```

## Usage

### Basic Commands

```bash
# Build the image
./claude-pod.sh build

# Interactive shell (empty workspace)
./claude-pod.sh shell

# Run a command
./claude-pod.sh run "java -version"

# Help
./claude-pod.sh --help
```

### Mounting Directories

Mount any directory into the container workspace:

```bash
# Mount one directory
./claude-pod.sh -m ~/myproject:/workspace/myproject shell

# Mount multiple directories
./claude-pod.sh \
    -m ~/project-a:/workspace/a \
    -m ~/project-b:/workspace/b \
    shell

# Inside container, they appear at:
/workspace/myproject/
/workspace/a/
/workspace/b/
```

### Copy Mode - Safe Experimentation

The `--copy` flag creates copies in `~/.cache/claude-copies/` instead of modifying originals:

```bash
# Work on a copy (safest!)
./claude-pod.sh --copy -m ~/myproject:/workspace/proj shell

# Run Claude on a copy
./claude-pod.sh --copy -m ~/myproject:/workspace/proj \
    claude "refactor everything" auto

# Run multiple experiments in parallel
./claude-pod.sh -c -m ~/proj:/workspace/p claude "try approach A" auto &
./claude-pod.sh -c -m ~/proj:/workspace/p claude "try approach B" auto &
./claude-pod.sh -c -m ~/proj:/workspace/p claude "try approach C" auto &
wait

# After completion, you get:
# ✓ Copy mode completed!
# 📋 Copy: ~/.cache/claude-copies/copy-proj-20260312_150001
# ℹ Original: ~/proj
#
# Review changes:
#   diff -r ~/proj ~/.cache/claude-copies/copy-proj-20260312_150001
#
# Copy back if you like it:
#   rsync -av ~/.cache/claude-copies/copy-proj-20260312_150001/ ~/proj/
#
# Or delete:
#   rm -rf ~/.cache/claude-copies/copy-proj-20260312_150001
```

**Benefits:**
- ✅ Original never modified
- ✅ Run multiple experiments simultaneously
- ✅ Easy comparison of different approaches
- ✅ Discard bad ideas, keep good ones

### Running Claude Autonomously

```bash
# Plan mode (shows plan, asks for approval)
./claude-pod.sh -m ~/myproject:/workspace/proj \
    claude "add error handling" plan

# Auto mode (approves safe operations)
./claude-pod.sh -m ~/myproject:/workspace/proj \
    claude "add logging" auto

# Don't ask mode (fewer prompts)
./claude-pod.sh -m ~/myproject:/workspace/proj \
    claude "format code" dontAsk

# Bypass permissions (dangerous! use with git branch)
./claude-pod.sh -m ~/myproject:/workspace/proj \
    claude "refactor" bypassPermissions
```

## Real-World Examples

### Example 1: Quick Exploration

```bash
# Mount a project and explore
./claude-pod.sh -m ~/thinbg/my-cool-project:/workspace/cool shell

# Inside container:
cd /workspace/cool
ls -la
mvn test
claude "explain the architecture"
```

### Example 2: Safe Experimentation

```bash
# Make a copy first
cp -r ~/myproject ~/tmp/myproject-experiment

# Let Claude work on the copy
./claude-pod.sh -m ~/tmp/myproject-experiment:/workspace/exp \
    claude "try using records instead of POJOs" auto

# Review changes
diff -r ~/myproject ~/tmp/myproject-experiment

# Keep or discard
rm -rf ~/tmp/myproject-experiment  # or keep if good
```

### Example 3: Multi-Project Work

```bash
# Work on SDK and application together
./claude-pod.sh \
    -m ~/a2a-sdk:/workspace/sdk \
    -m ~/my-app:/workspace/app \
    shell

# Inside, work across both:
cd /workspace/app
# Update to use new SDK features
```

### Example 4: Testing with Specific Versions

```bash
# The container has Java 17 (default), 21, and 25
./claude-pod.sh -m ~/legacy-project:/workspace/legacy shell

# Inside, switch Java version
sdk use java 21.0.5-tem
mvn clean test

# Or use Java 25
sdk use java 25.0.1-tem
mvn clean test
```

### Example 5: Parallel Experiments with Copy Mode

```bash
# Run three different refactoring approaches simultaneously
./claude-pod.sh -c -m ~/project:/workspace/p \
    claude "use dependency injection pattern" auto &

./claude-pod.sh -c -m ~/project:/workspace/p \
    claude "use factory pattern" auto &

./claude-pod.sh -c -m ~/project:/workspace/p \
    claude "use service locator pattern" auto &

wait  # Wait for all to finish

# Review all three
ls -la ~/.cache/claude-copies/
# copy-project-20260312_150001/  (dependency injection)
# copy-project-20260312_150002/  (factory)
# copy-project-20260312_150003/  (service locator)

# Compare approaches
diff -r ~/.cache/claude-copies/copy-project-150001 \
        ~/.cache/claude-copies/copy-project-150002

# Pick the winner and merge
rsync -av ~/.cache/claude-copies/copy-project-150001/ ~/project/
```

## What's Inside the Container

### Java (All LTS Versions via SDKMan)
- **Java 17.0.13** (default) - Most widely used LTS
- **Java 21.0.5** - Latest stable LTS
- **Java 25.0.1** - Newest LTS
- **Maven 3.9.9**

Switch versions: `sdk use java 21.0.5-tem`

### Languages & Runtimes
- **Python 3.12.3** - Default Python
- **Node.js 20.20.1** - For Claude Code CLI
- **uv** - Fast Python package manager

### Modern CLI Tools
- **gh** (GitHub CLI) - Create PRs, manage issues
- **ripgrep (rg)** - Fast code search
- **fd** - Better find
- **bat** - Cat with syntax highlighting
- **jq** - JSON processor
- **tree** - Directory visualization

### Development Tools
- **Claude Code CLI** - Latest version
- **git** - Version control
- **protobuf** - Protocol buffer compiler
- **gcc/g++/make** - C/C++ build tools

### Python Tools
- **pytest + pytest-asyncio** - Testing
- **ruff** - Fast linter/formatter
- **mypy** - Type checking
- **pre-commit** - Git hooks

### Environment
- **OS**: Ubuntu 24.04
- **User**: `claude` (non-root)
- **Working dir**: `/workspace`
- **Config**: `~/.claude` automatically mounted
- **Network**: Full access (can clone, push, install packages)

### MCP Servers
**Important:** MCPs (Serena, Sequential, etc.) run on your **host Mac**, not in the container. The container connects to them via your mounted `~/.claude` config.

**See [TOOLS.md](TOOLS.md) for complete details**

## Permission Modes Explained

| Mode | Behavior | Use When |
|------|----------|----------|
| `plan` | Shows plan, asks approval | Default, safest |
| `auto` | Auto-approves safe ops, asks for risky | Trusted tasks |
| `dontAsk` | Fewer prompts | Low-risk work |
| `bypassPermissions` | No prompts at all | Throwaway branches only! |

**Always use `plan` mode first** unless you're on a throwaway git branch.

## Safety Best Practices

### 1. Always Use Git Branches

```bash
# Before autonomous Claude
git checkout -b claude-experiment
git commit -am "Before Claude changes"

# Run Claude
./claude-pod.sh -m ~/myproject:/workspace/proj \
    claude "your task" plan

# Review and commit or rollback
git diff
git commit -am "Claude changes"  # or git reset --hard HEAD
```

### 2. Start with Plan Mode

```bash
# See what Claude will do first
./claude-pod.sh -m ~/myproject:/workspace/proj \
    claude "big refactoring" plan

# Review the plan before approving
```

### 3. Work on Copies for Risky Changes

```bash
# Copy first
cp -r ~/myproject ~/tmp/experiment

# Experiment freely
./claude-pod.sh -m ~/tmp/experiment:/workspace/exp \
    claude "try this crazy idea" auto

# Review, then decide to keep or discard
```

## Security Model

⚠️ **The container has full network access** - This is **required** for Claude Code to work.

### Why Network Access Is Required

The container **cannot disable network access** because Claude Code needs it to function:

1. **Claude API**: Must connect to Anthropic/Vertex AI APIs to process requests
2. **MCP Servers**: Run on your host Mac but need network to communicate with container
3. **Package Managers**: npm, pip, apt all require internet to install packages
4. **Git Operations**: Clone, push, pull all require network access

### How Security Actually Works

Security comes from **container isolation** and **selective access**, not network restrictions:

**🔒 Container Isolation**:
- Runs as non-root `claude` user inside container
- Filesystem isolation from your host macOS
- Process isolation - container processes can't affect host
- Ephemeral containers (`--rm` flag) - deleted after exit

**📁 Selective Mounting**:
- **No default mounts** - you explicitly choose what to expose
- Only mounted directories are accessible to Claude
- Everything else on your Mac is invisible to container
- Example: Mount only `~/myproject`, rest of system hidden

**🛡️ Copy Mode Protection**:
- `--copy` flag creates copy in `~/.cache/claude-copies/`
- Original files **never** modified
- Parallel experiments without risk
- Easy discard if results unsatisfactory

**🔐 Credential Safety**:
- Your `~/.claude` mounted read-only by default
- Git credentials optional (mount `~/.ssh` only when needed)
- GCloud credentials read-only
- No credentials stored in container image

### Best Practices for Safe Usage

```bash
# ✅ Safe - Mount only what you need
./claude-pod.sh -m ~/specific-project:/workspace/proj shell

# ✅ Safest - Work on copies
./claude-pod.sh --copy -m ~/project:/workspace/p shell

# ✅ Safe - Use git branches for tracking
git checkout -b claude-experiment
./claude-pod.sh -m ~/project:/workspace/p claude "refactor" plan

# ❌ Not recommended - Mounting entire home directory
./claude-pod.sh -m ~:/workspace/home shell
```

**Security Layers Summary**:
1. Container isolation (process, filesystem, user)
2. Selective mounting (you choose what's accessible)
3. Copy mode (non-destructive experimentation)
4. Ephemeral containers (clean state each run)
5. Git workflow (version control for changes)

## Configuration

### Environment Variables (.env)

```bash
# Authentication (uses your ~/.claude by default)
CLAUDE_CODE_USE_VERTEX=1
ANTHROPIC_VERTEX_PROJECT_ID=your-project-id

# Or use API key
# ANTHROPIC_API_KEY=your-key

# Git config (optional)
GIT_AUTHOR_NAME=Your Name
GIT_AUTHOR_EMAIL=your.email@example.com
```

### Customizing the Image

Edit `Containerfile` to:
- Add more tools
- Change Java/Python versions (via SDKMan)
- Install additional packages

Then rebuild:
```bash
./claude-pod.sh build
```

## Troubleshooting

### Podman not found
```bash
brew install podman
podman machine init
podman machine start
```

### Authentication issues
```bash
# Check .env file
cat .env

# Verify ~/.claude is mounted
./claude-pod.sh shell
ls -la ~/.claude
```

### Permission errors with mounts
Podman on macOS handles this automatically. If you see issues:
```bash
# Ensure Podman machine is running
podman machine start
```

### Image build fails
```bash
# Clean and rebuild
podman rmi claude-sandbox:latest
./claude-pod.sh build
```

## Cleanup

```bash
# Remove stopped containers
podman container prune -f

# Remove the image
podman rmi claude-sandbox:latest

# Remove everything
podman system prune -a

# Clean up copies from --copy mode
ls -la ~/.cache/claude-copies/
rm -rf ~/.cache/claude-copies/*

# Clean old copies (older than 7 days)
find ~/.cache/claude-copies -mtime +7 -exec rm -rf {} \;
```

## Comparison Table

| Feature | Native `/sandbox` | This Podman Sandbox |
|---------|------------------|---------------------|
| **Setup** | None | One-time build |
| **Startup** | Instant | ~3 seconds |
| **OS** | macOS (host) | Linux (Ubuntu 24.04) |
| **Tools** | Your installed | Predefined versions |
| **Isolation** | Directory only | Full container |
| **Persistence** | Session only | Reusable container |
| **Mounting** | N/A | Any directory |
| **Disk Space** | Minimal | ~2.5GB |
| **Team Sharing** | No | Yes (via Containerfile) |

## Advanced Usage

### Custom Commands

```bash
# Chain commands
./claude-pod.sh -m ~/proj:/workspace/p \
    run "cd /workspace/p && mvn clean && mvn test"

# Run Python
./claude-pod.sh -m ~/pyproj:/workspace/py \
    run "cd /workspace/py && pytest tests/"
```

### Working Directory

By default, you start at `/workspace`. Projects mount there:
```bash
./claude-pod.sh -m ~/myproject:/workspace/proj shell

# Inside:
pwd  # /workspace
ls   # proj/
cd proj
```

### Environment Persistence

The container is ephemeral (removed after exit), but:
- ✅ Your `~/.claude` persists (mounted)
- ✅ Your mounted directories persist (they're on your host)
- ❌ Anything you create in `/workspace` without mounts is lost

## Tips

- **Quick tasks**: Use native `/sandbox` in Claude Code chat
- **Development**: Use this Podman sandbox
- **Experiments**: Use `--copy` mode for safe experimentation
- **Parallel work**: Run multiple `--copy` experiments simultaneously
- **Safety**: Always start with `plan` mode
- **Git**: Use branches for autonomous work
- **Java versions**: Switch with `sdk use java 21.0.5-tem`
- **Tools**: See [TOOLS.md](TOOLS.md) for complete reference
- **Clean copies**: Delete old copies in `~/.cache/claude-copies/`

## Next Steps

1. **Build**: `./claude-pod.sh build` (~5 min first time)
2. **Test**: `./claude-pod.sh shell`
3. **Try copy mode**: `./claude-pod.sh -c -m ~/project:/workspace/p shell`
4. **Explore**: `./claude-pod.sh run "gh --version && rg --version | head -1"`
5. **Read docs**:
   - [TOOLS.md](TOOLS.md) - Complete tool reference
   - [INSTALL.md](INSTALL.md) - Advanced setup
   - [GITHUB.md](GITHUB.md) - Safe GitHub publishing

## Support

- **Claude Code docs**: https://code.claude.com/docs
- **Podman docs**: https://podman.io/docs
- **This repo issues**: (if you pushed to GitHub)
