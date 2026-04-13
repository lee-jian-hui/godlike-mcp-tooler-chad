# Code Review Rules

## Overview

All infrastructure code must be reviewed before commit. This ensures security, stability, and proper configuration.

## Required Review Checklist

### Before Any Commit
- [ ] No hardcoded secrets (API keys, passwords, tokens)
- [ ] No exposed credentials in code
- [ ] No sensitive data in logs

### Infrastructure Code (MUST REVIEW)
The following files require mandatory review before commit:

| File Type | Examples | Why |
|-----------|----------|-----|
| **Docker** | `Dockerfile`, `docker-compose.yml` | Security, resource limits |
| **Database** | migrations, schemas | Data integrity |
| **Config** | `*.json`, `*.yaml` configs | Credentials exposure |
| **Secrets** | `.env` templates, secrets files | Security |
| **K8s** | `*.yaml` manifests | Cluster security |

## Review Process

### Step 1: Self-Review
Before committing, check:
1. Does this expose any secrets?
2. Are resource limits defined?
3. Is the code following best practices?

### Step 2: Use Code Reviewer Subagent
For infrastructure code, always use the code-reviewer subagent:
```
Task: Security code review
Subagent: code-reviewer
File: <path to file>
Context: <what this code does>
```

### Step 3: Fix Issues
Address any issues found by the code reviewer before committing.

## Security Checklist

### Docker/Docker Compose
- [ ] No hardcoded credentials in FROM instructions
- [ ] No secrets in ENV variables
- [ ] Resource limits defined (memory, CPU)
- [ ] Non-root user specified (USER 1000)
- [ ] Read-only root filesystem where possible
- [ ] No privileged containers
- [ ] No sensitive ports exposed publicly

### Database
- [ ] No connection strings with credentials in code
- [ ] Use environment variables for DB credentials
- [ ] Passwords are strong/auto-generated
- [ ] SSL/TLS enabled for connections

### General
- [ ] No API keys in source code
- [ ] No tokens in comments
- [ ] No sensitive URLs in code
- [ ] Proper error handling (no stack traces exposing internals)

## Blocking Criteria

A commit MUST be blocked if:
1. Hardcoded secrets are present
2. Credentials are exposed in code
3. Security vulnerabilities identified by code-reviewer

## Exceptions

If you believe a rule should be bypassed:
1. Document the reason
2. Get explicit approval from user
3. Use environment variables instead of hardcoded values

## After Review

Once review passes:
1. Commit with descriptive message
2. Include "[reviewed]" tag in commit message
3. Push to remote

## Reference

See also:
- `rules/secrets.md` - Secrets handling rules
- `rules/git.md` - Git workflow rules
- `subagents/code-reviewer.md` - Code reviewer subagent