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
FCM_SERVICE_ACCOUNT_JSON={"type":"service_account","project_id":"..."}
```

## Telegram Webhook

After deployment, set the webhook from a secure local terminal or Render shell:

```bash
curl "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/setWebhook" \
  -d "url=$APP_BASE_URL/webhooks/telegram" \
  -d "secret_token=$TELEGRAM_WEBHOOK_SECRET"
```

Do not paste the bot token into chat or commit it to GitHub.

## Push Notifications

Push notifications use Firebase Cloud Messaging.

Required Firebase setup:

1. Create a Firebase project.
2. Add the Android app package and iOS bundle ID:
   - Android package: `com.trading.hurrairstradingapp`
   - iOS bundle ID: `com.hurrair.hurrairVipTrading`
3. Add these GitHub repository secrets for the mobile build:
   - `FIREBASE_API_KEY`
   - `FIREBASE_PROJECT_ID`
   - `FIREBASE_MESSAGING_SENDER_ID`
   - `FIREBASE_STORAGE_BUCKET`
   - `FIREBASE_ANDROID_APP_ID`
   - `FIREBASE_IOS_APP_ID`
   - `FIREBASE_IOS_BUNDLE_ID`
4. In Firebase, create a service account private key.
5. Paste the full service account JSON into Render as `FCM_SERVICE_ACCOUNT_JSON`.
6. Redeploy the backend and rebuild the APK from GitHub Actions.

The app registers each logged-in phone with the backend. When Telegram sends a new signal:

- Free signals notify all registered app users.
- VIP signals notify only users approved in the VIP Requests admin tab.

## Mobile Builds

GitHub Actions can run Flutter checks and Android builds.

iOS builds require a macOS runner. Publishing to TestFlight/App Store requires Apple Developer signing setup.
