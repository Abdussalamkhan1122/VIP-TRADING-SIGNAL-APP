# API Contract

Base URL is controlled by app configuration.

## Public

### `GET /health`

Returns backend health.

### `GET /api/settings`

Returns app settings.

### `GET /api/signals?audience=free|vip|all`

Returns signals visible to the requested audience.

Rules:

- Signals older than 24 hours are hidden.
- `audience=free` returns only the free allocation.
- `audience=vip` requires an approved VIP email query parameter.
- Public `audience=all` is treated as Free-only. Admin all-signal access uses `/api/admin/signals`.

Example:

```http
GET /api/signals?audience=vip&email=client@example.com
```

### `POST /api/vip/request`

Creates a VIP verification request.

```json
{
  "email": "client@example.com",
  "displayName": "Client Name"
}
```

### `GET /api/vip/status?email=client@example.com`

Returns whether a submitted email is `not_submitted`, `pending`, `approved`, or `rejected`.

## Telegram

### `POST /webhooks/telegram`

Receives Telegram Bot API updates. Requires `X-Telegram-Bot-Api-Secret-Token` when `TELEGRAM_WEBHOOK_SECRET` is configured.

## Admin

All admin endpoints require:

```http
Authorization: Bearer ADMIN_API_KEY
```

### `PATCH /api/admin/settings`

Updates Free/VIP rules.

### `GET /api/admin/vip-requests`

Lists VIP verification requests.

### `GET /api/admin/signals`

Lists all active Free and VIP signals for admin review.

### `PATCH /api/admin/vip-requests/:id`

Approves or rejects a request.

```json
{
  "status": "approved"
}
```
