# Requirements

## Product

Build **Hurrair VIP Trading**, a professional trading signals app for both iOS and Android.

## User-Facing Features

- Free signals feed.
- VIP signals feed.
- Free users can only see the free allocation, currently the first 2 signals in the active signal window.
- VIP signals must be locked unless the user's submitted email is approved by admin.
- Signals remain visible for 24 hours, then disappear from app feeds whether they are Free or VIP.
- Signal cards must show a timestamp/age so users can tell new signals from old signals.
- Signal detail screen.
- Signal history.
- VIP unlock flow using the official Exness partner link.
- Email-only VIP verification.
- Push notifications for new signals.
- Account/profile screen.

## Admin Features

- Change free signal limit.
- Set reset period: daily, weekly, or never.
- View users.
- Approve/reject VIP verification requests.
- View, edit, close, or delete signals.
- Send announcements.
- View basic stats.

## Telegram Signal Source

Signals come from `@hurrairtrading` through a Telegram bot webhook.

Example format:

```text
GOLD SELL NOW 4157-4160

TP
50 pips
100 pips
120 pips
150 pips
200 pips
250 pips

SL 4170
```

Parsed structure:

- Symbol: `GOLD`
- Direction: `SELL`
- Entry: `4157-4160`
- Stop loss: `4170`
- Take profits: `50 pips`, `100 pips`, `120 pips`, `150 pips`, `200 pips`, `250 pips`

One Telegram post counts as one signal, even when it includes multiple TP levels.

## VIP Verification

Official Exness partner link:

```text
https://one.exnessonelink.com/a/i2cmzyptz3
```

Flow:

1. User opens Unlock VIP.
2. User creates an Exness account through the official partner link.
3. User submits the email used for Exness.
4. Admin checks the email in the Exness partner dashboard.
5. Admin approves or rejects VIP access.

The app must not request Exness passwords.

## Notifications

New signal push notifications require Firebase Cloud Messaging setup for Android and iOS.

SMS messages require an SMS provider such as Twilio or another paid/local SMS gateway. The app should not claim SMS delivery is active until provider credentials and phone-number collection are implemented.
