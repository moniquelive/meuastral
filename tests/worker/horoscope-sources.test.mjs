import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { checkSource, validateResponse } from '../../scripts/check-horoscope-sources.mjs';
import { providerForLocale, ZODIAC_SIGNS } from '../../worker/horoscope.mjs';

const signs = () => ZODIAC_SIGNS.map(id => ({ id, name: id, resume: 'A complete reading.' }));
const now = () => new Date('2026-11-08T01:30:00Z');
const response = (locale, date = '2026-11-07', provider = providerForLocale(locale)) => Response.json(
  { signs_list: signs() },
  { headers: { 'x-horoscope-date': date, 'x-horoscope-provider': provider } },
);

describe('Daily source checks', () => {
  it('rejects unsupported locales before making requests', async () => {
    await assert.rejects(checkSource('fr-FR', {
      publicRequest: () => assert.fail('must not request an unsupported locale'),
    }), /Use pt-BR or en-US/);
  });

  it('checks one shared production response per locale without credentials or provider calls', async () => {
    for (const locale of ['en-US', 'pt-BR']) {
      const calls = [];
      await checkSource(locale, {
        now,
        publicRequest: async (url, options) => {
          assert.ok(options.signal);
          assert.equal(options.headers, undefined);
          calls.push(url);
          return response(locale);
        },
      });
      assert.deepEqual(calls, [`https://meuastral.com/api/horoscope?locale=${locale}`]);
    }
  });

  it('rejects HTTP errors and HTML error pages', async () => {
    await assert.rejects(validateResponse(new Response('', { status: 503 }), 'provider'), /HTTP 503/);
    await assert.rejects(validateResponse(new Response('<html>Error</html>'), 'provider'), /invalid JSON/);
  });

  it('fails on a stale snapshot or the retired provider even when all readings are present', async () => {
    for (const result of [response('en-US', '2026-11-06'), response('en-US', '2026-11-07', 'api-ninjas')]) {
      await assert.rejects(checkSource('en-US', {
        now,
        publicRequest: async () => result,
      }), /expected (a shared snapshot|provider)/);
    }
  });

  it('rejects incomplete, duplicate, and empty readings despite HTTP 200', async () => {
    const incomplete = signs().slice(1);
    const duplicates = signs();
    duplicates[0] = duplicates[1];
    const blank = signs();
    blank[0].resume = '   ';
    for (const entries of [incomplete, duplicates, blank]) {
      await assert.rejects(validateResponse(Response.json({ signs_list: entries }), 'provider'));
    }
  });

  it('fails when production is unavailable', async () => {
    await assert.rejects(checkSource('pt-BR', {
      publicRequest: async () => new Response('', { status: 502 }),
    }), /production API: HTTP 502/);
  });
});
