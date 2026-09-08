import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { checkSource, validateResponse } from '../../scripts/check-horoscope-sources.mjs';
import { ZODIAC_SIGNS } from '../../worker/horoscope.mjs';

const signs = () => ZODIAC_SIGNS.map(id => ({ id, name: id, resume: 'A complete reading.' }));
const response = () => Response.json({ signs_list: signs() });

describe('Daily source checks', () => {
  it('rejects a missing English key before making requests', async () => {
    await assert.rejects(checkSource('en-US', {
      env: {},
      providerRequest: () => assert.fail('must not make an unauthenticated request'),
    }), /API_NINJAS_KEY/);
  });

  it('checks the fresh adapter and public API for both supported locales', async () => {
    for (const locale of ['en-US', 'pt-BR']) {
      const calls = [];
      const env = { API_NINJAS_KEY: 'test-key' };
      await checkSource(locale, {
        env,
        providerRequest: async (request, actualEnv) => {
          assert.equal(actualEnv, env);
          calls.push(request.url);
          return response();
        },
        publicRequest: async (url, options) => {
          assert.ok(options.signal);
          assert.equal(options.headers, undefined);
          calls.push(url);
          return response();
        },
      });
      assert.deepEqual(calls, Array(2).fill(`https://meuastral.com/api/horoscope?locale=${locale}`));
    }
  });

  it('rejects HTTP errors and HTML error pages', async () => {
    await assert.rejects(validateResponse(new Response('', { status: 503 }), 'provider'), /HTTP 503/);
    await assert.rejects(validateResponse(new Response('<html>Error</html>'), 'provider'), /invalid JSON/);
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

  it('fails when production is broken even if the source is healthy', async () => {
    await assert.rejects(checkSource('pt-BR', {
      env: {},
      providerRequest: async () => response(),
      publicRequest: async () => new Response('', { status: 502 }),
    }), /production API: HTTP 502/);
  });
});
