import { createSign } from 'node:crypto';

const FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';
const TOKEN_URL = 'https://oauth2.googleapis.com/token';

let cachedAccessToken = null;

export async function sendSignalPush(signal, deviceTokens) {
  const tokens = [...new Set(deviceTokens.filter(Boolean))];
  if (tokens.length === 0) return { sent: 0, skipped: true };

  const serviceAccount = getServiceAccount();
  if (!serviceAccount) {
    console.warn('FCM_SERVICE_ACCOUNT_JSON is not configured; push notification skipped.');
    return { sent: 0, skipped: true };
  }

  const accessToken = await getAccessToken(serviceAccount);
  const url = `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`;
  const title = `${signal.audience === 'vip' ? 'VIP' : 'Free'} ${signal.symbol} ${signal.direction}`;
  const body = `Entry ${signal.entry || '-'} | SL ${signal.stopLoss || '-'}`;
  let sent = 0;

  for (const token of tokens) {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        authorization: `Bearer ${accessToken}`,
        'content-type': 'application/json'
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title, body },
          data: {
            signalId: signal.id,
            audience: signal.audience,
            symbol: signal.symbol,
            direction: signal.direction
          }
        }
      })
    });

    if (response.ok) {
      sent += 1;
    } else {
      console.warn(`FCM push failed for one token: ${response.status}`);
    }
  }

  return { sent, skipped: false };
}

function getServiceAccount() {
  const raw = process.env.FCM_SERVICE_ACCOUNT_JSON;
  if (!raw) return null;
  try {
    return JSON.parse(raw);
  } catch {
    console.warn('FCM_SERVICE_ACCOUNT_JSON is not valid JSON.');
    return null;
  }
}

async function getAccessToken(serviceAccount) {
  if (cachedAccessToken && cachedAccessToken.expiresAt > Date.now() + 60000) {
    return cachedAccessToken.token;
  }

  const now = Math.floor(Date.now() / 1000);
  const assertion = signJwt({
    iss: serviceAccount.client_email,
    scope: FCM_SCOPE,
    aud: TOKEN_URL,
    iat: now,
    exp: now + 3600
  }, serviceAccount.private_key);

  const response = await fetch(TOKEN_URL, {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion
    })
  });

  if (!response.ok) {
    throw new Error(`FCM auth failed: ${response.status}`);
  }

  const body = await response.json();
  cachedAccessToken = {
    token: body.access_token,
    expiresAt: Date.now() + Number(body.expires_in || 3600) * 1000
  };
  return cachedAccessToken.token;
}

function signJwt(payload, privateKey) {
  const header = { alg: 'RS256', typ: 'JWT' };
  const body = `${base64Url(JSON.stringify(header))}.${base64Url(JSON.stringify(payload))}`;
  const signature = createSign('RSA-SHA256').update(body).sign(privateKey);
  return `${body}.${base64Url(signature)}`;
}

function base64Url(value) {
  return Buffer.from(value)
    .toString('base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
}
