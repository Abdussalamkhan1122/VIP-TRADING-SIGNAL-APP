import assert from 'node:assert/strict';
import { parseSignal } from '../src/parser.js';

const sample = `GOLD SELL NOW 4157-4160

TP
50 pips
100 pips
120 pips
150 pips
200 pips
250 pips

SL 4170`;

const signal = parseSignal(sample);

assert.equal(signal.symbol, 'GOLD');
assert.equal(signal.direction, 'SELL');
assert.equal(signal.entry, '4157-4160');
assert.equal(signal.stopLoss, '4170');
assert.equal(signal.takeProfits.length, 6);
assert.equal(signal.takeProfits[0].value, '50');
assert.equal(signal.takeProfits[0].unit, 'pips');
assert.equal(signal.confidence, 1);

const realTelegramSignal = parseSignal(`GOLD BUY NOW 4121—4118

Tp
50 pips
100 pips
120 pips
200 pips
250pips

Sl 4111`);

assert.equal(realTelegramSignal.symbol, 'GOLD');
assert.equal(realTelegramSignal.direction, 'BUY');
assert.equal(realTelegramSignal.entry, '4121-4118');
assert.equal(realTelegramSignal.stopLoss, '4111');
assert.equal(realTelegramSignal.takeProfits.length, 5);
assert.equal(realTelegramSignal.takeProfits[4].value, '250');

assert.equal(parseSignal('hello world'), null);

console.log('parser tests passed');
