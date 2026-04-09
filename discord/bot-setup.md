# Discord Bot Setup Guide

## Creating a Discord Bot

### Step 1: Create Application
1. Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. Click **New Application**
3. Enter name: `OpenCode-Agent`
4. Click **Create**

### Step 2: Create Bot User
1. Click **Bot** in left sidebar
2. Click **Reset Token** → Copy and save it securely
   - ⚠️ **This token is only shown once!**
3. Under **Privileged Gateway Intents**, enable:
   - `MESSAGE CONTENT INTENT` (required for reading commands)
4. Under **Bot Permissions**, select:
   - `Send Messages`
   - `Read Message History`
   - `Use Application Commands`
   - `Embed Links`

### Step 3: Generate Invite Link
1. Go to **OAuth2 → URL Generator**
2. Select scopes:
   - ✅ `bot`
3. Select bot permissions:
   - ✅ `Send Messages`
   - ✅ `Read Message History`
   - ✅ `Use Application Commands`
   - ✅ `Embed Links`
4. Copy the generated URL
5. Open URL in browser and select your server

### Step 4: Get Application ID
1. Go to **General Information**
2. Copy **Application ID**
3. Save both **Application ID** and **Token** for config

---

## Environment Variables Required

```bash
# Required for OpenClaw
DISCORD_BOT_TOKEN=your_bot_token_here
DISCORD_APPLICATION_ID=your_app_id_here

# Optional: For local model
OPENCODE_MODEL=opencode/minimax-m2.5-free
```

---

## Channel Setup

### Option 1: Single Channel
```
#opencode-agent    (main interaction channel)
```

### Option 2: Multi-Channel (Recommended)
```
#opencode-agent     ← Main bot interaction
#opencode-logs      ← Execution logs
#opencode-sandbox  ← Isolated testing
```

### Setting Permissions

1. Right-click channel → **Edit Channel**
2. Go to **Permissions** → **Role / Channel Permissions**
3. Add configuration:

| Role/User | Permissions |
|-----------|-------------|
| @everyone | ❌ Read Messages |
| OpenCode-Agent | ✅ Read Messages, Send Messages |
| Admin | ✅ Manage Channels (optional) |

---

## Testing the Bot

1. Invite the bot to your server
2. Go to `#opencode-agent`
3. Send `/opencode` - should see welcome message
4. Try: `/opencode status`

---

## Common Issues

### Bot not responding
- Check: Message Content Intent enabled?
- Check: Bot has correct permissions in channel
- Check: Bot is online (green dot in Developer Portal)

### "Interaction Failed" error
- Re-invite bot with correct permissions
- Check: Application Commands registered

### Bot offline
- Check token validity in Developer Portal
- Regenerate token if needed

---

## Security Notes

- ❌ Never commit bot token to git
- ✅ Use environment variables or secrets
- ✅ Restrict bot permissions to minimum needed
- ✅ Rotate tokens periodically
