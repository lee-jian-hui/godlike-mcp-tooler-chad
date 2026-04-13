# Git Workflow Rules

## Overview

The agent works with TWO git repositories:
1. **Agent Repo** (this repo) - OpenClaw configuration
2. **Workspace Repo** - The project being built (separate repo)

## Repository Mapping

| Repository | URL Env Variable | Purpose |
|------------|------------------|---------|
| Agent Repo | `GIT_REPO_URL` | OpenClaw configs, agent behavior |
| Workspace Repo | `GIT_WORKSPACE_URL` | Project files, infrastructure, code |

## Workspace Repository Rules

The agent should ONLY commit to the **Workspace Repository** (`GIT_WORKSPACE_URL`).

### What to Commit to Workspace
- ✅ Infrastructure (Dockerfile, docker-compose.yml)
- ✅ Source code (src/, mcp-tools/)
- ✅ Configuration (non-secret configs)
- ✅ Documentation (README.md, etc.)
- ✅ MCP server code
- ✅ Generated files (if useful)

### What NOT to Commit
- ❌ `.env` files with secrets
- ❌ API keys, tokens, passwords
- ❌ `.pem`, `.key` files
- ❌ Build artifacts (dist/, node_modules/)
- ❌ IDE configurations
- ❌ OS-specific files

## Commit Guidelines

### Commit Message Format
```
<type>: <short description>

[optional: details]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `infra`: Infrastructure changes
- `mcp`: MCP tool additions
- `config`: Configuration changes

### Example Commit Messages
```
infra: add PostgreSQL docker-compose setup

feat: add property data scraper MCP tool

mcp: create database query MCP server

config: update database schema for price data
```

## Branch Strategy

For the workspace project:
- Work on `main` branch (simpler for now)
- Create feature branches if needed: `feature/<feature-name>`

## Pushing Changes

### Before Push Checklist
1. ✅ Code reviewed with code-reviewer subagent
2. ✅ No secrets in committed files
3. ✅ Tests pass (if applicable)
4. ✅ Commit message is descriptive

### Push Command
```bash
git push origin main
```

## Handling Git Credentials

### Workspace Repo Credentials
Set via environment variables:
- `GIT_WORKSPACE_USERNAME` - GitHub username
- `GIT_WORKSPACE_TOKEN` - GitHub Personal Access Token (PAT)

### Credential Setup
The entrypoint script will configure git with these credentials:
```bash
git config user.name "$GIT_WORKSPACE_USERNAME"
git config user.email "$GIT_WORKSPACE_EMAIL"
git remote set-url origin "$GIT_WORKSPACE_URL"
# Use token for authentication
```

## Emergency: Accidental Secret Commit

If you accidentally commit secrets:
1. IMMEDIATELY notify the user
2. Do NOT try to "fix" by removing - it remains in git history
3. User must rotate the exposed credentials
4. Consider force-pushing to remove (if very sensitive)

## Reference

See also:
- `rules/secrets.md` - Secrets handling rules
- `rules/review.md` - Code review rules
- `subagents/judge.md` - For validating dangerous git operations