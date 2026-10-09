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

assert.equal(parseSignal('hello world'), null);

console.log('parser tests passed');

