import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { dirname } from 'node:path';
import { randomUUID } from 'node:crypto';

export const DEFAULT_SETTINGS = {
  freeSignalLimit: 2,
  resetPeriod: 'daily',
  distributionMode: 'first_x_free',
  exnessPartnerLink: process.env.EXNESS_PARTNER_LINK || 'https://one.exnessonelink.com/a/i2cmzyptz3'
};

const SIGNAL_TTL_HOURS = 24;

export async function createStore(filePath) {
  if (process.env.DATABASE_URL) {
    const { Pool } = await import('pg');
    const store = new PgStore(new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : undefined
    }));
    await store.load();
    return store;
  }

  const store = new JsonStore(filePath);
  await store.load();
  return store;
}

export class JsonStore {
  constructor(filePath) {
    this.filePath = filePath;
    this.data = {
      settings: DEFAULT_SETTINGS,
      signals: [],
      vipRequests: [],
      users: []
    };
  }

  async load() {
    try {
      const raw = await readFile(this.filePath, 'utf8');
      this.data = { ...this.data, ...JSON.parse(raw) };
    } catch {
      await this.save();
    }
  }

  async save() {
    await mkdir(dirname(this.filePath), { recursive: true });
    await writeFile(this.filePath, JSON.stringify(this.data, null, 2));
  }

  async addSignal(parsed, source = 'telegram') {
    const signalNumber = countSignalsForPeriod(this.data.signals, this.data.settings.resetPeriod) + 1;
    const audience = signalNumber <= Number(this.data.settings.freeSignalLimit) ? 'free' : 'vip';
    const signal = {
      id: randomUUID(),
      source,
      audience,
      signalNumber,
      status: 'active',
      createdAt: new Date().toISOString(),
      ...parsed
    };
    this.data.signals.unshift(signal);
    await this.save();
    return signal;
  }

  getSignals(audience = 'all') {
    const freeSignalLimit = Number(this.data.settings.freeSignalLimit);
    const freshSignals = this.data.signals.filter(isFreshSignal);
    if (audience === 'all') return freshSignals;
    if (audience === 'free') return freshSignals.filter((signal) => signal.signalNumber <= freeSignalLimit);
    if (audience === 'vip') return freshSignals.filter((signal) => signal.signalNumber > freeSignalLimit);
    return [];
  }

  getSettings() {
    return this.data.settings;
  }

  getVipRequests() {
    return this.data.vipRequests;
  }

  findVipRequestByEmail(email) {
    const normalizedEmail = String(email || '').trim().toLowerCase();
    return this.data.vipRequests.find((request) => request.email === normalizedEmail) || null;
  }

  async updateSettings(patch) {
    const next = { ...this.data.settings };
    if (patch.freeSignalLimit !== undefined) next.freeSignalLimit = clampNumber(patch.freeSignalLimit, 0, 100);
    if (['daily', 'weekly', 'never'].includes(patch.resetPeriod)) next.resetPeriod = patch.resetPeriod;
    if (patch.exnessPartnerLink) next.exnessPartnerLink = String(patch.exnessPartnerLink);
    this.data.settings = next;
    await this.save();
    return this.data.settings;
  }

  async createVipRequest(input) {
    const existing = this.findVipRequestByEmail(input.email);
    if (existing && ['approved', 'pending'].includes(existing.status)) return existing;

    const request = {
      id: randomUUID(),
      email: String(input.email || '').trim().toLowerCase(),
      displayName: String(input.displayName || '').trim(),
      status: 'pending',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
    this.data.vipRequests.unshift(request);
    await this.save();
    return request;
  }

  async updateVipRequest(id, status) {
    const request = this.data.vipRequests.find((item) => item.id === id);
    if (!request) return null;
    if (!['approved', 'rejected', 'pending'].includes(status)) return null;
    request.status = status;
    request.updatedAt = new Date().toISOString();
    await this.save();
    return request;
  }
}

export class PgStore {
  constructor(pool) {
    this.pool = pool;
  }

  async load() {
    await this.pool.query(`
      create table if not exists app_settings (
        id integer primary key default 1,
        free_signal_limit integer not null default 2,
        reset_period text not null default 'daily',
        distribution_mode text not null default 'first_x_free',
        exness_partner_link text not null,
        updated_at timestamptz not null default now(),
        constraint one_settings_row check (id = 1)
      );

      create table if not exists signals (
        id uuid primary key,
        source text not null default 'telegram',
        audience text not null check (audience in ('free', 'vip')),
        signal_number integer not null,
        symbol text not null,
        direction text not null check (direction in ('BUY', 'SELL')),
        entry text,
        stop_loss text,
        take_profits jsonb not null default '[]'::jsonb,
        raw_text text not null,
        status text not null default 'active',
        created_at timestamptz not null default now()
      );

      create table if not exists vip_requests (
        id uuid primary key,
        email text not null,
        display_name text,
        status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
        created_at timestamptz not null default now(),
        updated_at timestamptz not null default now()
      );

      create index if not exists signals_audience_created_at_idx on signals (audience, created_at desc);
      create index if not exists vip_requests_status_created_at_idx on vip_requests (status, created_at desc);
    `);

    await this.pool.query(
      `insert into app_settings (id, free_signal_limit, reset_period, distribution_mode, exness_partner_link)
       values (1, $1, $2, $3, $4)
       on conflict (id) do nothing`,
      [
        DEFAULT_SETTINGS.freeSignalLimit,
        DEFAULT_SETTINGS.resetPeriod,
        DEFAULT_SETTINGS.distributionMode,
        DEFAULT_SETTINGS.exnessPartnerLink
      ]
    );
  }

  async addSignal(parsed, source = 'telegram') {
    const settings = await this.getSettings();
    const signalNumber = await this.countSignalsForPeriod(settings.resetPeriod) + 1;
    const audience = signalNumber <= Number(settings.freeSignalLimit) ? 'free' : 'vip';
    const id = randomUUID();

    const result = await this.pool.query(
      `insert into signals (
        id, source, audience, signal_number, symbol, direction, entry, stop_loss, take_profits, raw_text, status
      ) values ($1, $2, $3, $4, $5, $6, $7, $8, $9::jsonb, $10, 'active')
      returning *`,
      [
        id,
        source,
        audience,
        signalNumber,
        parsed.symbol,
        parsed.direction,
        parsed.entry,
        parsed.stopLoss,
        JSON.stringify(parsed.takeProfits),
        parsed.rawText
      ]
    );

    return mapSignalRow(result.rows[0]);
  }

  async getSignals(audience = 'all') {
    const settings = await this.getSettings();
    const params = [SIGNAL_TTL_HOURS];
    const filters = [`created_at >= now() - ($1::text || ' hours')::interval`];

    if (audience === 'free') {
      params.push(settings.freeSignalLimit);
      filters.push(`signal_number <= $${params.length}`);
    } else if (audience === 'vip') {
      params.push(settings.freeSignalLimit);
      filters.push(`signal_number > $${params.length}`);
    }

    const result = await this.pool.query(
      `select * from signals where ${filters.join(' and ')} order by created_at desc`,
      params
    );
    return result.rows.map(mapSignalRow);
  }

  async getSettings() {
    const result = await this.pool.query('select * from app_settings where id = 1');
    return mapSettingsRow(result.rows[0]);
  }

  async updateSettings(patch) {
    const current = await this.getSettings();
    const next = {
      ...current,
      freeSignalLimit: patch.freeSignalLimit !== undefined ? clampNumber(patch.freeSignalLimit, 0, 100) : current.freeSignalLimit,
      resetPeriod: ['daily', 'weekly', 'never'].includes(patch.resetPeriod) ? patch.resetPeriod : current.resetPeriod,
      exnessPartnerLink: patch.exnessPartnerLink ? String(patch.exnessPartnerLink) : current.exnessPartnerLink
    };

    const result = await this.pool.query(
      `update app_settings
       set free_signal_limit = $1, reset_period = $2, exness_partner_link = $3, updated_at = now()
       where id = 1
       returning *`,
      [next.freeSignalLimit, next.resetPeriod, next.exnessPartnerLink]
    );
    return mapSettingsRow(result.rows[0]);
  }

  async createVipRequest(input) {
    const existing = await this.findVipRequestByEmail(input.email);
    if (existing && ['approved', 'pending'].includes(existing.status)) return existing;

    const result = await this.pool.query(
      `insert into vip_requests (id, email, display_name, status)
       values ($1, $2, $3, 'pending')
       returning *`,
      [randomUUID(), String(input.email || '').trim().toLowerCase(), String(input.displayName || '').trim()]
    );
    return mapVipRequestRow(result.rows[0]);
  }

  async getVipRequests() {
    const result = await this.pool.query('select * from vip_requests order by created_at desc');
    return result.rows.map(mapVipRequestRow);
  }

  async findVipRequestByEmail(email) {
    const result = await this.pool.query(
      'select * from vip_requests where email = $1 order by created_at desc limit 1',
      [String(email || '').trim().toLowerCase()]
    );
    return result.rows[0] ? mapVipRequestRow(result.rows[0]) : null;
  }

  async updateVipRequest(id, status) {
    if (!['approved', 'rejected', 'pending'].includes(status)) return null;
    const result = await this.pool.query(
      `update vip_requests set status = $1, updated_at = now() where id = $2 returning *`,
      [status, id]
    );
    return result.rows[0] ? mapVipRequestRow(result.rows[0]) : null;
  }

  async countSignalsForPeriod(resetPeriod) {
    if (resetPeriod === 'never') {
      const result = await this.pool.query(
        `select count(*)::int as count
         from signals
         where created_at >= now() - ($1::text || ' hours')::interval`,
        [SIGNAL_TTL_HOURS]
      );
      return result.rows[0].count;
    }

    const interval = resetPeriod === 'weekly' ? 'week' : 'day';
    const result = await this.pool.query(
      `select count(*)::int as count
       from signals
       where created_at >= date_trunc($1, now())
         and created_at >= now() - ($2::text || ' hours')::interval`,
      [interval, SIGNAL_TTL_HOURS]
    );
    return result.rows[0].count;
  }
}

function countSignalsForPeriod(signals, resetPeriod) {
  const freshSignals = signals.filter(isFreshSignal);
  if (resetPeriod === 'never') return freshSignals.length;
  const now = new Date();
  return freshSignals.filter((signal) => {
    const created = new Date(signal.createdAt);
    if (resetPeriod === 'daily') return sameDay(created, now);
    if (resetPeriod === 'weekly') return sameWeek(created, now);
    return true;
  }).length;
}

function isFreshSignal(signal) {
  const createdAt = new Date(signal.createdAt);
  if (Number.isNaN(createdAt.getTime())) return false;
  const maxAgeMs = SIGNAL_TTL_HOURS * 60 * 60 * 1000;
  return Date.now() - createdAt.getTime() <= maxAgeMs;
}

function sameDay(a, b) {
  return a.getUTCFullYear() === b.getUTCFullYear() &&
    a.getUTCMonth() === b.getUTCMonth() &&
    a.getUTCDate() === b.getUTCDate();
}

function sameWeek(a, b) {
  const startA = weekStart(a);
  const startB = weekStart(b);
  return startA.getTime() === startB.getTime();
}

function weekStart(date) {
  const copy = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
  const day = copy.getUTCDay() || 7;
  copy.setUTCDate(copy.getUTCDate() - day + 1);
  return copy;
}

function clampNumber(value, min, max) {
  const number = Number(value);
  if (!Number.isFinite(number)) return min;
  return Math.min(max, Math.max(min, Math.floor(number)));
}

function mapSettingsRow(row) {
  return {
    freeSignalLimit: row.free_signal_limit,
    resetPeriod: row.reset_period,
    distributionMode: row.distribution_mode,
    exnessPartnerLink: row.exness_partner_link
  };
}

function mapSignalRow(row) {
  return {
    id: row.id,
    source: row.source,
    audience: row.audience,
    signalNumber: row.signal_number,
    status: row.status,
    createdAt: row.created_at,
    rawText: row.raw_text,
    symbol: row.symbol,
    direction: row.direction,
    entry: row.entry,
    stopLoss: row.stop_loss,
    takeProfits: row.take_profits
  };
}

function mapVipRequestRow(row) {
  return {
    id: row.id,
    email: row.email,
    displayName: row.display_name,
    status: row.status,
    createdAt: row.created_at,
    updatedAt: row.updated_at
  };
}
