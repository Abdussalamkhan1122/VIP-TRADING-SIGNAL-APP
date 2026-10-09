# API Contract

Base URL is controlled by app configuration.

## Public

### `GET /health`

Returns backend health.

### `GET /api/settings`

Returns app settings.

### `GET /api/signals?audience=free|vip|all`

Returns signals visible to the requested audience.

### `POST /api/vip/request`

Creates a VIP verification request.

```json
{
  "email": "client@example.com",
  "displayName": "Client Name"
}
```

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

### `PATCH /api/admin/vip-requests/:id`

Approves or rejects a request.

```json
{
  "status": "approved"
}
```

