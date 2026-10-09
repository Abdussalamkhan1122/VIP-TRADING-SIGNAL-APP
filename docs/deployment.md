# Deployment Notes

## Backend

Recommended host: Render.

Required environment variables:

```env
PORT=10000
APP_BASE_URL=https://your-backend.onrender.com
ADMIN_API_KEY=change-me
TELEGRAM_BOT_TOKEN=private-token-from-botfather
TELEGRAM_CHANNEL=@hurrairtrading
TELEGRAM_WEBHOOK_SECRET=random-private-string
EXNESS_PARTNER_LINK=https://one.exnessonelink.com/a/i2cmzyptz3
```

## Telegram Webhook

After deployment, set the webhook from a secure local terminal or Render shell:

```bash
curl "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/setWebhook" \
  -d "url=$APP_BASE_URL/webhooks/telegram" \
  -d "secret_token=$TELEGRAM_WEBHOOK_SECRET"
```

Do not paste the bot token into chat or commit it to GitHub.

## Mobile Builds

GitHub Actions can run Flutter checks and Android builds.

iOS builds require a macOS runner. Publishing to TestFlight/App Store requires Apple Developer signing setup.

