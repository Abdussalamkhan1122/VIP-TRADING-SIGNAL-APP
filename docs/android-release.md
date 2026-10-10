# Android Release Notes

## Current Build

GitHub Actions creates a debug APK artifact:

```text
hurrair-vip-trading-debug-apk
```

This is good for private beta testing.

## Play Store Release Requirements

For Google Play, we need:

- Google Play Developer account.
- App name, short description, full description.
- App icon.
- Screenshots.
- Privacy policy URL.
- Signed Android App Bundle (`.aab`).
- Keystore stored securely in GitHub secrets or local machine.

## Signing Secrets Needed Later

Do not commit these values:

```text
ANDROID_KEYSTORE_BASE64
ANDROID_KEYSTORE_PASSWORD
ANDROID_KEY_ALIAS
ANDROID_KEY_PASSWORD
```

The debug APK is not the final Play Store build.

