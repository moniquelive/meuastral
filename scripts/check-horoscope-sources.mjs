import { appendFile } from 'node:fs/promises';
import { pathToFileURL } from 'node:url';
import {
  dateKeyInTimeZone,
  providerForLocale,
  ZODIAC_SIGNS,
} from '../worker/horoscope-config.mjs';

const LOCALES = ['pt-BR', 'en-US'];

export async function validateResponse(response, label, { date, provider } = {}) {
  if (!response.ok) {
    throw new Error(`${label}: HTTP ${response.status}`);
  }

  if (date && response.headers.get('x-horoscope-date') !== date) {
    throw new Error(`${label}: expected a shared snapshot for ${date}`);
  }
  if (provider && response.headers.get('x-horoscope-provider') !== provider) {
    throw new Error(`${label}: expected provider ${provider}`);
  }

  let payload;
  try {
    payload = await response.json();
  } catch {
    throw new Error(`${label}: invalid JSON`);
  }

  const signs = payload?.signs_list;
  if (!Array.isArray(signs) || signs.length !== ZODIAC_SIGNS.length) {
    throw new Error(`${label}: expected all 12 signs`);
  }

  const ids = new Set(signs.map(sign => sign?.id));
  if (!ZODIAC_SIGNS.every(id => ids.has(id))) {
    throw new Error(`${label}: missing or duplicate signs`);
  }

  if (signs.some(sign => ![sign.name, sign.resume].every(value => typeof value === 'string' && value.trim()))) {
    throw new Error(`${label}: empty name or reading`);
  }

  return signs.length;
}

export async function checkSource(locale, {
  publicRequest = fetch,
  now = () => new Date(),
} = {}) {
  if (!LOCALES.includes(locale)) {
    throw new Error('Use pt-BR or en-US');
  }
  const provider = providerForLocale(locale);
  const url = `https://meuastral.com/api/horoscope?locale=${locale}`;
  // Use the same shared daily snapshot as visitors. An uncached adapter call
  // here would defeat the provider request budget on every monitoring run.
  const response = await publicRequest(url, { signal: AbortSignal.timeout(20_000) });
  await validateResponse(
    response,
    `${locale} / production API`,
    { date: dateKeyInTimeZone(now()), provider },
  );
  return `${locale}: production API returned today's shared ${provider} snapshot with 12 complete signs`;
}

async function main() {
  const locales = process.argv.length > 2 ? process.argv.slice(2) : LOCALES;
  const deadline = setTimeout(() => {
    console.error('Horoscope source check exceeded the 90-second deadline');
    process.exit(1);
  }, 90_000);

  try {
    const results = await Promise.allSettled(locales.map(locale => checkSource(locale)));
    const lines = [`Horoscope source check — ${dateKeyInTimeZone(new Date())} (America/Sao_Paulo)`];
    for (const result of results) {
      if (result.status === 'fulfilled') {
        lines.push(`PASS: ${result.value}`);
      } else {
        process.exitCode = 1;
        lines.push(`FAIL: ${result.reason.message}`);
      }
    }
    console.log(lines.join('\n'));
    if (process.env.GITHUB_STEP_SUMMARY) {
      await appendFile(process.env.GITHUB_STEP_SUMMARY, `${lines.join('\n\n')}\n`);
    }
  } finally {
    clearTimeout(deadline);
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  await main();
}
