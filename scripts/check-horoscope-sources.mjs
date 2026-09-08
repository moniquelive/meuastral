import { appendFile } from 'node:fs/promises';
import { pathToFileURL } from 'node:url';
import {
  dateKeyInTimeZone,
  handleHoroscopeRequest,
  providerForLocale,
  ZODIAC_SIGNS,
} from '../worker/horoscope.mjs';

const LOCALES = ['pt-BR', 'en-US'];

export async function validateResponse(response, label) {
  if (!response.ok) {
    throw new Error(`${label}: HTTP ${response.status}`);
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
  env = process.env,
  providerRequest = handleHoroscopeRequest,
  publicRequest = fetch,
} = {}) {
  if (!LOCALES.includes(locale)) {
    throw new Error('Use pt-BR or en-US');
  }
  if (locale === 'en-US' && !env.API_NINJAS_KEY?.trim()) {
    throw new Error('en-US: configure the API_NINJAS_KEY GitHub Actions secret');
  }

  const provider = providerForLocale(locale);
  const url = `https://meuastral.com/api/horoscope?locale=${locale}`;
  // Node has no Cloudflare Cache API, so this executes the real provider adapter
  // without reading or warming the site's cache. The key stays server-side.
  await validateResponse(
    await providerRequest(new Request(url), env, {}),
    `${locale} / ${provider}`,
  );
  await validateResponse(
    await publicRequest(url, { signal: AbortSignal.timeout(20_000) }),
    `${locale} / production API`,
  );
  return `${locale}: ${provider} and production API each returned 12 complete signs`;
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
