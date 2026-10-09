# Hurrair VIP Trading

Cross-platform trading signals app for iOS and Android.

## What This Project Contains

- `backend/` - Node.js API for Telegram signals, Free/VIP routing, VIP verification, and admin actions.
- `mobile/` - Flutter app scaffold for Android and iOS.
- `admin/` - Web admin dashboard scaffold.
- `docs/` - Product, setup, deployment, and API notes.
- `.github/workflows/` - GitHub Actions for backend checks and Flutter builds.

## Core Flow

```text
Telegram Channel
  -> Telegram Bot Webhook
  -> Backend Signal Parser
  -> Free/VIP Routing Rules
  -> PostgreSQL
  -> Flutter App
  -> Firebase Push Notifications
```

## Security

Never commit secrets. Telegram bot token, database URL, Firebase keys, and admin credentials must be stored as private environment variables.

