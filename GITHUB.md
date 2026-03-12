# GitHub Repository Setup

## Safety Checklist ✅

Before pushing to GitHub, verify these items:

### ✅ Safe to Commit
- ✅ `Containerfile` - No secrets, just build instructions
- ✅ `docker-entrypoint.sh` - Generic script, no secrets
- ✅ `claude-pod.sh` - Helper script, no secrets
- ✅ `.env.example` - Template file only, no actual credentials
- ✅ `README.md` - Documentation only
- ✅ `INSTALL.md` - Documentation only
- ✅ `.gitignore` - Protects sensitive files

### ❌ Never Commit (Protected by .gitignore)
- ❌ `.env` - Contains your actual credentials
- ❌ `.env.local` - Any local overrides
- ❌ `*.log` - Log files that might contain sensitive data

## Creating the GitHub Repository

### Step 1: Initialize Git (if not already done)

```bash
cd ~/sourcecontrol/AI/claude-docker-sandbox  # or wherever you put it

# Initialize git if needed
git init

# Verify .gitignore is in place
cat .gitignore
```

### Step 2: Check What Will Be Committed

```bash
# See what git will track
git status

# Verify .env is NOT listed
# It should show:
# - .gitignore
# - Containerfile
# - docker-entrypoint.sh
# - claude-pod.sh
# - .env.example (safe - just a template)
# - README.md
# - INSTALL.md
# - GITHUB.md
```

### Step 3: Create Initial Commit

```bash
# Add all safe files
git add .

# Double check what's staged
git diff --cached --name-only

# Commit
git commit -m "Initial commit: Claude Code Podman sandbox"
```

### Step 4: Create GitHub Repository

```bash
# Option 1: Using GitHub CLI
gh repo create claude-sandbox --private --source=. --remote=origin
git push -u origin main

# Option 2: Manual via GitHub web
# 1. Go to https://github.com/new
# 2. Create repository named "claude-sandbox"
# 3. Choose Private or Public
# 4. Don't initialize with README (you already have files)
# 5. Copy the remote URL

# Then locally:
git remote add origin https://github.com/YOUR_USERNAME/claude-sandbox.git
git branch -M main
git push -u origin main
```

## Public vs Private Repository

### Make it **Private** if:
- You include any organization-specific settings
- You want to keep your development setup private
- Your .env.example contains your actual GCP project ID

### Can be **Public** if:
- You want to share this setup with others
- You've genericized the `.env.example`
- You're comfortable sharing your development workflow

**Recommendation**: Start with **private**, you can always make it public later.

## Sanitizing for Public Release

If you want to make it public, sanitize `.env.example`:

```bash
# Edit .env.example to use generic placeholders
nano .env.example

# Change from:
ANTHROPIC_VERTEX_PROJECT_ID=itpc-gcp-cp-pe-eng-claude

# To:
ANTHROPIC_VERTEX_PROJECT_ID=your-gcp-project-id

git add .env.example
git commit -m "Sanitize .env.example for public release"
```

## Ongoing Usage

### Adding Your Real Configuration (After Clone)

When you or others clone the repo:

```bash
# Clone the repo
git clone https://github.com/YOUR_USERNAME/claude-sandbox.git
cd claude-sandbox

# Create .env from template
cp .env.example .env

# Edit with your actual credentials
nano .env

# .env is gitignored, so it won't be committed
git status  # should NOT show .env
```

### Making Changes

```bash
# Work on improvements
git add Containerfile
git commit -m "Update: Add new tool to Docker image"
git push

# Your .env stays local and private
```

## Verification Commands

Before pushing, always verify:

```bash
# Check what would be pushed
git diff origin/main

# Verify .env is ignored
git check-ignore .env
# Should output: .env

# List all tracked files
git ls-files
# Should NOT include .env

# Search for potential secrets in tracked files
git grep -i "api.*key" -- ':(exclude).env'
git grep -i "secret" -- ':(exclude).env'
git grep -i "password" -- ':(exclude).env'
# Should find nothing sensitive
```

## Security Best Practices

1. **Never commit `.env`** - It's in `.gitignore`, but double-check
2. **Review before pushing** - Always `git diff` before `git push`
3. **Use `.env.example`** - Keep it generic, no real credentials
4. **Private by default** - Start with private repo, make public only if needed
5. **Rotate credentials** - If you accidentally commit secrets, rotate them immediately

## Accidental Secret Commit Recovery

If you accidentally commit secrets:

```bash
# Remove the file from git history
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch .env" \
  --prune-empty --tag-name-filter cat -- --all

# Force push (if already pushed)
git push origin --force --all

# IMPORTANT: Rotate any exposed credentials immediately
```

**Better**: Use a tool like `git-secrets` to prevent commits with secrets:

```bash
# Install git-secrets
brew install git-secrets

# Set up for this repo
git secrets --install
git secrets --register-aws

# Add custom patterns
git secrets --add 'ANTHROPIC_API_KEY=.*'
git secrets --add 'ANTHROPIC_VERTEX_PROJECT_ID=.*'
```

## Contributing (If Public)

If you make this public and want contributions:

1. Add a `CONTRIBUTING.md`
2. Add a `LICENSE` file (e.g., MIT, Apache 2.0)
3. Update README with contribution guidelines
4. Consider adding GitHub Actions for testing the build

Example LICENSE (MIT):
```bash
cat > LICENSE << 'EOF'
MIT License

Copyright (c) 2026 Your Name

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

git add LICENSE
git commit -m "Add MIT license"
```

## Current Status

As of now, your claude-docker-sandbox folder contains:
- ✅ No actual credentials (.env.example is just a template)
- ✅ Proper .gitignore in place
- ✅ All sensitive config is in ignored .env
- ✅ Safe to push to GitHub (private or public with sanitization)

**You're good to go!** 🚀

## Files in Repository

**Tracked:**
- `Containerfile` - Image definition
- `docker-entrypoint.sh` - Container startup script
- `claude-pod.sh` - Flexible runner script
- `.env.example` - Configuration template
- `.gitignore` - Protection for secrets
- `README.md` - Usage documentation
- `INSTALL.md` - Setup guide
- `GITHUB.md` - This file

**Ignored (not tracked):**
- `.env` - Your actual configuration
- Any log files
- Any local overrides
