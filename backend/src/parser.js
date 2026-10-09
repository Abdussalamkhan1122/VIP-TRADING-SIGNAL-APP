export function parseSignal(text) {
  if (!text || typeof text !== 'string') return null;

  const cleanText = text.replace(/[-–—−]+/g, '-');

  const normalized = cleanText
    .replace(/\r/g, '')
    .split('\n')
    .map((line) => line.trim())
    .filter(Boolean);

  if (normalized.length === 0) return null;

  const joined = normalized.join('\n');
  const header = normalized[0].toUpperCase();
  const directionMatch = header.match(/\b(BUY|SELL)\b/);
  if (!directionMatch) return null;

  const direction = directionMatch[1];
  const symbolMatch = header.match(/^([A-Z]{3,10}|GOLD|XAUUSD)\b/);
  const symbol = symbolMatch ? normalizeSymbol(symbolMatch[1]) : 'UNKNOWN';

  const entryPattern = new RegExp(`${direction}\\s+(?:NOW\\s+)?([0-9]+(?:\\.[0-9]+)?(?:\\s*-\\s*[0-9]+(?:\\.[0-9]+)?)?)`, 'i');
  const entryMatch = joined.match(entryPattern) || joined.match(/\bENTRY[:\s]+([0-9]+(?:\.[0-9]+)?(?:\s*-\s*[0-9]+(?:\.[0-9]+)?)?)/i);
  const entry = entryMatch ? entryMatch[1].replace(/\s+/g, '') : null;

  const slMatch = joined.match(/\bSL[:\s]+([0-9]+(?:\.[0-9]+)?)/i) || joined.match(/\bSTOP\s*LOSS[:\s]+([0-9]+(?:\.[0-9]+)?)/i);
  const stopLoss = slMatch ? slMatch[1] : null;

  const takeProfits = [];
  for (const line of normalized) {
    const tpLine = line.match(/^(?:TP\s*\d*[:\s-]*)?([0-9]+(?:\.[0-9]+)?)(?:\s*(pips?|points?))?$/i);
    if (tpLine && !/^SL\b/i.test(line)) {
      const value = tpLine[1];
      const unit = tpLine[2] ? tpLine[2].toLowerCase() : inferTpUnit(text);
      if (value !== stopLoss) takeProfits.push({ label: `TP${takeProfits.length + 1}`, value, unit });
    }
  }

  const confidence = [
    symbol !== 'UNKNOWN',
    Boolean(direction),
    Boolean(entry),
    Boolean(stopLoss),
    takeProfits.length > 0
  ].filter(Boolean).length / 5;

  return {
    rawText: text,
    symbol,
    direction,
    entry,
    stopLoss,
    takeProfits,
    confidence
  };
}

function normalizeSymbol(symbol) {
  if (symbol === 'GOLD') return 'GOLD';
  return symbol.toUpperCase();
}

function inferTpUnit(text) {
  return /\bpips?\b/i.test(text) ? 'pips' : 'price';
}
