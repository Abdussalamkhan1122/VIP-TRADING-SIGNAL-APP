# Requirements

## Product

Build **Hurrair VIP Trading**, a professional trading signals app for both iOS and Android.

## User-Facing Features

- Free signals feed.
- VIP signals feed.
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

