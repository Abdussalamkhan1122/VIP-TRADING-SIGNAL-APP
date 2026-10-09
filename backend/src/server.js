import { createServer } from 'node:http';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { parseSignal } from './parser.js';
import { JsonStore } from './store.js';

const __dirname = dirname(fileURLToPath(import.meta.url));
const store = new JsonStore(join(__dirname, '..', 'data', 'store.json'));
await store.load();

const PORT = Number(process.env.PORT || 10000);
const ADMIN_API_KEY = process.env.ADMIN_API_KEY || 'change-me';
const TELEGRAM_WEBHOOK_SECRET = process.env.TELEGRAM_WEBHOOK_SECRET || '';

const server = createServer(async (req, res) => {
  try {
    await route(req, res);
  } catch (error) {
    sendJson(res, 500, { error: 'internal_error', message: error.message });
  }
});

server.listen(PORT, () => {
  console.log(`Hurrair backend listening on ${PORT}`);
});

async function route(req, res) {
  const url = new URL(req.url, `http://${req.headers.host}`);

  if (req.method === 'OPTIONS') return sendCors(res);
  if (req.method === 'GET' && url.pathname === '/health') return sendJson(res, 200, { ok: true });
  if (req.method === 'GET' && url.pathname === '/api/settings') return sendJson(res, 200, store.data.settings);

  if (req.method === 'GET' && url.pathname === '/api/signals') {
    return sendJson(res, 200, { signals: store.getSignals(url.searchParams.get('audience') || 'all') });
  }

  if (req.method === 'POST' && url.pathname === '/api/vip/request') {
    const body = await readJson(req);
    if (!isEmail(body.email)) return sendJson(res, 400, { error: 'valid_email_required' });
    const request = await store.createVipRequest(body);
    return sendJson(res, 201, { request });
  }

  if (req.method === 'POST' && url.pathname === '/webhooks/telegram') {
    if (TELEGRAM_WEBHOOK_SECRET) {
      const received = req.headers['x-telegram-bot-api-secret-token'];
      if (received !== TELEGRAM_WEBHOOK_SECRET) return sendJson(res, 401, { error: 'invalid_telegram_secret' });
    }
    const update = await readJson(req);
    const message = update.channel_post || update.message || update.edited_channel_post;
    const text = message?.text || message?.caption || '';
    const parsed = parseSignal(text);
    if (!parsed || parsed.confidence < 0.6) return sendJson(res, 202, { accepted: false, reason: 'not_a_signal' });
    const signal = await store.addSignal(parsed, 'telegram');
    return sendJson(res, 201, { accepted: true, signal });
  }

  if (url.pathname.startsWith('/api/admin/')) {
    if (!isAdmin(req)) return sendJson(res, 401, { error: 'admin_auth_required' });

    if (req.method === 'PATCH' && url.pathname === '/api/admin/settings') {
      const body = await readJson(req);
      const settings = await store.updateSettings(body);
      return sendJson(res, 200, { settings });
    }

    if (req.method === 'GET' && url.pathname === '/api/admin/vip-requests') {
      return sendJson(res, 200, { requests: store.data.vipRequests });
    }

    const vipMatch = url.pathname.match(/^\/api\/admin\/vip-requests\/([^/]+)$/);
    if (req.method === 'PATCH' && vipMatch) {
      const body = await readJson(req);
      const request = await store.updateVipRequest(vipMatch[1], body.status);
      if (!request) return sendJson(res, 404, { error: 'vip_request_not_found' });
      return sendJson(res, 200, { request });
    }
  }

  return sendJson(res, 404, { error: 'not_found' });
}

function isAdmin(req) {
  return req.headers.authorization === `Bearer ${ADMIN_API_KEY}`;
}

async function readJson(req) {
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  const raw = Buffer.concat(chunks).toString('utf8') || '{}';
  return JSON.parse(raw);
}

function sendJson(res, status, data) {
  res.writeHead(status, {
    'content-type': 'application/json',
    'access-control-allow-origin': '*',
    'access-control-allow-methods': 'GET,POST,PATCH,OPTIONS',
    'access-control-allow-headers': 'content-type,authorization,x-telegram-bot-api-secret-token'
  });
  res.end(JSON.stringify(data));
}

function sendCors(res) {
  res.writeHead(204, {
    'access-control-allow-origin': '*',
    'access-control-allow-methods': 'GET,POST,PATCH,OPTIONS',
    'access-control-allow-headers': 'content-type,authorization,x-telegram-bot-api-secret-token'
  });
  res.end();
}

function isEmail(value) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(String(value || '').trim());
}

