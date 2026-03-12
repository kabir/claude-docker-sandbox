# Installation and Setup Guide

## Overview

This Podman sandbox provides an isolated Linux development environment for Claude Code. It's designed to be:
- **Portable**: Works anywhere Podman runs
- **Flexible**: Mount any directory on-demand
- **Clean**: No projects mounted by default

## Prerequisites

### macOS

```bash
# Install Podman
brew install podman

# Initialize Podman machine (one-time)
podman machine init
podman machine start
```

### Linux

```bash
# Install Podman
sudo apt-get install podman  # Debian/Ubuntu
sudo dnf install podman      # Fedora
sudo yum install podman      # RHEL/CentOS
```

## Installation

### Option 1: Clone from GitHub (if you pushed it)

```bash
git clone https://github.com/yourusername/claude-sandbox.git
cd claude-sandbox
```

### Option 2: Use Existing Directory

If you already have this directory, just ensure you're in it:

```bash
cd ~/sourcecontrol/AI/claude-docker-sandbox
```

## Setup

### 1. Configure Authentication

```bash
# Copy the template
cp .env.example .env

# Edit with your credentials
nano .env
```

Required settings:
```bash
# For Vertex AI (Google Cloud)
CLAUDE_CODE_USE_VERTEX=1
ANTHROPIC_VERTEX_PROJECT_ID=your-gcp-project-id

# OR for standard Anthropic API
# ANTHROPIC_API_KEY=your-api-key
```

Your `~/.claude` directory is automatically mounted, so your existing Claude Code authentication should work out of the box.

### 2. Build the Image

```bash
./claude-pod.sh build
```

This takes ~5 minutes the first time and downloads/builds:
- Ubuntu 24.04 base image
- Java 21 (via SDKMan)
- Maven 3.9.9 (via SDKMan)
- Python 3.12
- Node.js 20
- Claude Code CLI
- Various development tools

### 3. Verify Installation

```bash
# Start a shell
./claude-pod.sh shell

# Inside container, verify tools:
java -version
mvn -version
python --version
claude --version

# Exit
exit
```

## Usage Patterns

### Pattern 1: Quick Exploration

```bash
# Mount a project and explore
./claude-pod.sh -m ~/myproject:/workspace/proj shell

# Inside:
cd /workspace/proj
mvn test
claude "explain this code"
```

### Pattern 2: Autonomous Work

```bash
# Work on a project with Claude
./claude-pod.sh -m ~/myproject:/workspace/proj \
    claude "add comprehensive logging" plan
```

### Pattern 3: Safe Experimentation

```bash
# Work on a copy
cp -r ~/myproject ~/tmp/experiment
./claude-pod.sh -m ~/tmp/experiment:/workspace/exp \
    claude "try a different approach" auto

# Review and decide
diff -r ~/myproject ~/tmp/experiment
```

### Pattern 4: Multiple Projects

```bash
# Mount SDK and application together
./claude-pod.sh \
    -m ~/sdk:/workspace/sdk \
    -m ~/app:/workspace/app \
    shell
```

## Configuration

### Environment Variables

The `.env` file supports:

```bash
# Authentication
CLAUDE_CODE_USE_VERTEX=1
ANTHROPIC_VERTEX_PROJECT_ID=your-project-id
# or
ANTHROPIC_API_KEY=your-api-key

# Git configuration (optional)
GIT_AUTHOR_NAME=Your Name
GIT_AUTHOR_EMAIL=your.email@example.com
GIT_COMMITTER_NAME=Your Name
GIT_COMMITTER_EMAIL=your.email@example.com
```

### Customizing the Image

Edit `Containerfile` to customize:

**Add a tool:**
```dockerfile
USER root
RUN apt-get update && apt-get install -y your-tool
```

**Change Java version:**
```dockerfile
# Change this line:
sdk install java 21.0.5-tem
# To:
sdk install java 17.0.10-tem
```

**Add Python packages:**
```dockerfile
USER claude
RUN pip3 install --user --break-system-packages \
    your-package \
    another-package
```

Then rebuild:
```bash
./claude-pod.sh build
```

## Advanced Setup

### Add to PATH (Optional)

For easier access from anywhere:

```bash
# Add to ~/.zshrc or ~/.bashrc
echo 'export PATH="$HOME/sourcecontrol/AI/claude-docker-sandbox:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Now run from anywhere
claude-pod.sh -m ~/project:/workspace/p shell
```

### Create an Alias

```bash
# Add to ~/.zshrc
echo 'alias cpod="~/sourcecontrol/AI/claude-docker-sandbox/claude-pod.sh"' >> ~/.zshrc
source ~/.zshrc

# Use it
cpod -m ~/project:/workspace/p shell
```

### Shell Function for Common Projects

```bash
# Add to ~/.zshrc
function claude-work() {
    local project_path="$1"
    local project_name=$(basename "$project_path")

    ~/sourcecontrol/AI/claude-docker-sandbox/claude-pod.sh \
        -m "$project_path:/workspace/$project_name" \
        shell
}

# Use it
claude-work ~/myproject
```

## Troubleshooting

### Podman machine not running

```bash
podman machine list
podman machine start
```

### Build fails

```bash
# Clean everything
podman system prune -a

# Rebuild
./claude-pod.sh build
```

### Permission errors on mounts

Podman on macOS handles permissions automatically. If you see errors:

```bash
# Restart Podman machine
podman machine stop
podman machine start
```

### Authentication not working

```bash
# Verify ~/.claude is mounted
./claude-pod.sh shell
ls -la ~/.claude

# Check .env file
cat .env | grep ANTHROPIC
```

### Container won't start

```bash
# Check Podman is running
podman ps

# Check logs
podman logs $(podman ps -ql)

# Try running manually
podman run -it --rm claude-sandbox:latest /bin/bash
```

## Updating

### Update the Image

```bash
# Pull latest changes (if from git)
git pull

# Rebuild
./claude-pod.sh build
```

### Update Tools in Container

Edit `Containerfile`, then:

```bash
./claude-pod.sh build
```

### Update Claude Code CLI

The container uses the latest Claude Code CLI from npm. To update:

```dockerfile
# In Containerfile, the line:
RUN npm install -g @anthropic-ai/claude-code

# Will always get the latest. To force update:
```

```bash
./claude-pod.sh build --no-cache
```

## Multi-Machine Setup

If you want to use on multiple machines:

### On Each Machine

```bash
# Clone or copy the directory
cd ~/sourcecontrol/AI/claude-docker-sandbox

# Create .env with machine-specific settings
cp .env.example .env
nano .env  # Add your credentials

# Build
./claude-pod.sh build
```

The `Containerfile` is the same across machines, ensuring consistent environments.

## Cleanup

### Remove Stopped Containers

```bash
podman container prune -f
```

### Remove the Image

```bash
podman rmi claude-sandbox:latest
```

### Complete Cleanup

```bash
# Remove everything
podman system prune -a

# This removes:
# - All stopped containers
# - All unused images
# - All unused volumes
# - All unused networks
```

## Best Practices

1. **Keep Containerfile in git** - Track your environment
2. **Don't commit .env** - It's in .gitignore for a reason
3. **Use .env.example** - Template for team members
4. **Rebuild regularly** - Keep tools updated
5. **Test builds** - Before sharing with team

## Next Steps

- Read [README.md](README.md) for usage examples
- Read [GITHUB.md](GITHUB.md) before pushing to GitHub
- Customize `Containerfile` for your needs
- Create shell aliases for common workflows
