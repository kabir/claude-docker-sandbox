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
# The container has Java 21 and Maven 3.9.9
./claude-pod.sh -m ~/legacy-project:/workspace/legacy \
    run "mvn clean test"

# Different from your host machine's versions
```

## What's Inside the Container

### Tools & Versions
- **Java**: OpenJDK 21.0.5 (via SDKMan)
- **Maven**: 3.9.9 (via SDKMan)
- **Python**: 3.12.3
- **Node.js**: 20.20.1
- **Claude Code**: Latest CLI
- **Build tools**: gcc, g++, make
- **Python tools**: pytest, ruff, mypy, pre-commit
- **Utilities**: git, protobuf, curl, wget, jq

### Environment
- **OS**: Ubuntu 24.04
- **User**: `claude` (non-root)
- **Working dir**: `/workspace`
- **Config**: `~/.claude` automatically mounted

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

Edit `Dockerfile` to:
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
| **Team Sharing** | No | Yes (via Dockerfile) |

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
- **Hybrid**: Use both! They complement each other
- **Safety**: Always start with `plan` mode
- **Experiments**: Work on copies, not originals
- **Git**: Use branches for all autonomous work

## Next Steps

1. Build the image: `./claude-pod.sh build`
2. Test it: `./claude-pod.sh shell`
3. Try a simple task: `./claude-pod.sh -m ~/myproject:/workspace/p claude "list files" plan`
4. Read INSTALL.md for advanced setup
5. Read GITHUB.md before pushing to GitHub

## Support

- **Claude Code docs**: https://code.claude.com/docs
- **Podman docs**: https://podman.io/docs
- **This repo issues**: (if you pushed to GitHub)
