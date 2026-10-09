import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { dirname } from 'node:path';

const DEFAULT_SETTINGS = {
  freeSignalLimit: 2,
  resetPeriod: 'daily',
  distributionMode: 'first_x_free',
  exnessPartnerLink: process.env.EXNESS_PARTNER_LINK || 'https://one.exnessonelink.com/a/i2cmzyptz3'
};

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
      id: crypto.randomUUID(),
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
    if (audience === 'all') return this.data.signals;
    if (audience === 'free') return this.data.signals.filter((signal) => signal.audience === 'free');
    if (audience === 'vip') return this.data.signals.filter((signal) => signal.audience === 'vip');
    return [];
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
    const request = {
      id: crypto.randomUUID(),
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

function countSignalsForPeriod(signals, resetPeriod) {
  if (resetPeriod === 'never') return signals.length;
  const now = new Date();
  return signals.filter((signal) => {
    const created = new Date(signal.createdAt);
    if (resetPeriod === 'daily') return sameDay(created, now);
    if (resetPeriod === 'weekly') return sameWeek(created, now);
    return true;
  }).length;
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

