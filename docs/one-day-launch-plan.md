# One-Day Launch Plan

## Realistic Target

The realistic one-day target is a **private Android beta launch**:

- Users install a test APK.
- Telegram signals flow into the backend.
- Free users see only the Free feed.
- VIP users submit Exness email.
- Admin approves VIP requests.
- Approved users can see VIP signals.

Public Google Play and Apple App Store launch can be prepared, but approval timing is controlled by Google/Apple and cannot be guaranteed in one day.

## Day-1 Must-Haves

- Backend deployed and healthy.
- Telegram webhook connected.
- Signal parser tested with live channel formats.
- Free feed limited to the active free allocation.
- VIP feed locked unless admin approves the submitted email.
- Signals hidden after 24 hours.
- Admin dashboard can approve/reject VIP requests.
- APK available from GitHub Actions.
- Privacy policy and terms available before wider distribution.

## Day-1 Testing Script

1. Post 3 signals in Telegram.
2. Confirm first 2 appear in Free feed.
3. Confirm third appears only for approved VIP users.
4. Submit a test email in the app.
5. Approve that email in admin.
6. Refresh VIP tab and confirm VIP unlocks.
7. Reject a second test email and confirm VIP remains locked.
8. Confirm signal cards show time/age.

## Not Safe To Promise Yet

- Push notifications until Firebase Cloud Messaging is configured.
- SMS messages until an SMS provider is configured.
- iOS TestFlight/App Store until Apple Developer setup is complete.
- Play Store listing until signing, privacy policy URL, screenshots, and review are complete.

