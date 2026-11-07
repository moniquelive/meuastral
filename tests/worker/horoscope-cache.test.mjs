import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { DailyHoroscopeCache } from "../../worker/horoscope-cache.mjs";
import { ZODIAC_SIGNS } from "../../worker/horoscope.mjs";

const TEST_DATE = "2026-11-07";

function freezeDate(testContext, date) {
  testContext.mock.timers.enable({ apis: ["Date"], now: new Date(date) });
}

function createStorage(entries = new Map(), overrides = {}) {
  return {
    entries,
    async get(key) {
      if (overrides.get) {
        return overrides.get(key);
      }
      return structuredClone(entries.get(key));
    },
    async put(key, value) {
      if (overrides.put) {
        return overrides.put(key, value);
      }
      entries.set(key, structuredClone(value));
    },
    async delete(key) {
      if (overrides.delete) {
        return overrides.delete(key);
      }
      return entries.delete(key);
    },
  };
}

function englishPayload(prefix) {
  return {
    signs_list: ZODIAC_SIGNS.map((id) => ({
      id,
      name: id[0].toUpperCase() + id.slice(1),
      resume: `${prefix} reading for ${id}.`,
    })),
  };
}

function englishRss(date = TEST_DATE, signs = ZODIAC_SIGNS, prefix = "Today's") {
  const items = signs
    .map(
      (sign) =>
        `<item><zt:date>${date}</zt:date><zt:sign>${sign}</zt:sign><description>${prefix} reading for ${sign}.</description></item>`,
    )
    .join("");

  return `<rss version="2.0" xmlns:zt="https://zodiactimeline.com/feed"><channel>${items}</channel></rss>`;
}

function portuguesePayload() {
  return {
    signs_list: ZODIAC_SIGNS.map((id) => ({
      id,
      name: id,
      resume: `Leitura Terra para ${id}.`,
    })),
  };
}

function portugueseResponse() {
  return Response.json(portuguesePayload());
}

function requestFor(locale) {
  return new Request(`https://meuastral.com/${locale}`);
}

async function withMockedFetch(fetcher, callback) {
  const originalFetch = globalThis.fetch;
  const originalConsoleError = console.error;
  globalThis.fetch = fetcher;
  console.error = () => {};

  try {
    return await callback();
  } finally {
    globalThis.fetch = originalFetch;
    console.error = originalConsoleError;
  }
}

describe("Shared daily horoscope cache", () => {
  it("coalesces concurrent requests into one upstream fetch", async (testContext) => {
    freezeDate(testContext, `${TEST_DATE}T12:00:00Z`);
    const storage = createStorage();
    const cache = new DailyHoroscopeCache({ storage });
    const requests = Array.from({ length: 24 }, () => requestFor("en-US"));
    let resolveFeed;
    let markFetchStarted;
    const feedReady = new Promise((resolve) => {
      resolveFeed = resolve;
    });
    const fetchStarted = new Promise((resolve) => {
      markFetchStarted = resolve;
    });
    let upstreamCalls = 0;

    await withMockedFetch(
      async (url) => {
        upstreamCalls += 1;
        markFetchStarted();
        await feedReady;
        return new Response(englishRss(), {
          headers: { "content-type": "application/rss+xml" },
        });
      },
      async () => {
        const responses = Promise.all(requests.map((request) => cache.fetch(request)));
        await fetchStarted;
        assert.equal(upstreamCalls, 1);
        resolveFeed();

        const results = await responses;
        assert.ok(results.every((response) => response.status === 200));
        assert.equal(upstreamCalls, 1);
        assert.equal(storage.entries.get("daily:en-US").payload.signs_list.length, 12);
      },
    );
  });

  it("serves a persisted daily snapshot after constructing a new instance", async (testContext) => {
    freezeDate(testContext, `${TEST_DATE}T12:00:00Z`);
    const storage = createStorage();
    let upstreamCalls = 0;

    await withMockedFetch(
      async () => {
        upstreamCalls += 1;
        return new Response(englishRss(), {
          headers: { "content-type": "application/rss+xml" },
        });
      },
      async () => {
        const first = await new DailyHoroscopeCache({ storage }).fetch(
          requestFor("en-US"),
        );
        const second = await new DailyHoroscopeCache({ storage }).fetch(
          requestFor("en-US"),
        );

        assert.equal(first.status, 200);
        assert.equal(second.status, 200);
        assert.equal(second.headers.get("x-horoscope-date"), TEST_DATE);
        assert.equal(second.headers.get("x-horoscope-provider"), "zodiac-timeline");
        assert.equal(upstreamCalls, 1);
      },
    );
  });

  it("refreshes on the São Paulo date rollover", async (testContext) => {
    freezeDate(testContext, "2026-11-07T02:59:59Z");
    const storage = createStorage();
    let upstreamCalls = 0;

    await withMockedFetch(
      async () => {
        upstreamCalls += 1;
        const date = upstreamCalls === 1 ? "2026-11-06" : "2026-11-07";
        const prefix = upstreamCalls === 1 ? "Previous day" : "Current day";
        return new Response(englishRss(date, ZODIAC_SIGNS, prefix), {
          headers: { "content-type": "application/rss+xml" },
        });
      },
      async () => {
        const cache = new DailyHoroscopeCache({ storage });
        const yesterday = await cache.fetch(requestFor("en-US"));
        assert.equal(yesterday.headers.get("x-horoscope-date"), "2026-11-06");

        testContext.mock.timers.setTime(Date.parse("2026-11-07T03:00:01Z"));
        const today = await cache.fetch(requestFor("en-US"));
        const payload = await today.json();

        assert.equal(today.headers.get("x-horoscope-date"), TEST_DATE);
        assert.match(payload.signs_list[0].resume, /^Current day/);
        assert.equal(upstreamCalls, 2);
      },
    );
  });

  it("keeps English and Portuguese snapshots and providers separate", async (testContext) => {
    freezeDate(testContext, `${TEST_DATE}T12:00:00Z`);
    const storage = createStorage();
    const requests = [];

    await withMockedFetch(
      async (input) => {
        const url = new URL(input);
        requests.push(url);
        return url.hostname === "zodiactimeline.com"
          ? new Response(englishRss(), {
              headers: { "content-type": "application/rss+xml" },
            })
          : portugueseResponse();
      },
      async () => {
        const cache = new DailyHoroscopeCache({ storage });
        const [english, portuguese] = await Promise.all([
          cache.fetch(requestFor("en-US")),
          cache.fetch(requestFor("pt-BR")),
        ]);
        const [englishPayloadResult, portuguesePayloadResult] = await Promise.all([
          english.json(),
          portuguese.json(),
        ]);

        assert.equal(english.status, 200);
        assert.equal(portuguese.status, 200);
        assert.equal(english.headers.get("x-horoscope-provider"), "zodiac-timeline");
        assert.equal(portuguese.headers.get("x-horoscope-provider"), "terra");
        assert.match(englishPayloadResult.signs_list[0].resume, /^Today's/);
        assert.match(portuguesePayloadResult.signs_list[0].resume, /^Leitura Terra/);
        assert.equal(storage.entries.get("daily:en-US").provider, "zodiac-timeline");
        assert.equal(storage.entries.get("daily:pt-BR").provider, "terra");
        assert.equal(requests.length, 2);
        assert.equal(requests.filter((url) => url.hostname === "zodiactimeline.com").length, 1);
        assert.equal(requests.filter((url) => url.hostname === "www.terra.com.br").length, 1);
      },
    );
  });

  it("persists failure cooldown and never serves yesterday's data as today's", async (testContext) => {
    freezeDate(testContext, `${TEST_DATE}T12:00:00Z`);
    const storage = createStorage();
    const previousSnapshot = {
      date: "2026-11-06",
      provider: "zodiac-timeline",
      payload: englishPayload("Previous day"),
    };
    storage.entries.set("daily:en-US", previousSnapshot);
    let upstreamCalls = 0;

    await withMockedFetch(
      async () => {
        upstreamCalls += 1;
        return new Response(
          englishRss(TEST_DATE, ZODIAC_SIGNS.slice(0, -1), "Incomplete"),
          { headers: { "content-type": "application/rss+xml" } },
        );
      },
      async () => {
        const first = await new DailyHoroscopeCache({ storage }).fetch(
          requestFor("en-US"),
        );
        const firstBody = await first.json();
        assert.equal(first.status, 502);
        assert.equal(first.headers.get("cache-control"), "no-store");
        assert.equal(first.headers.get("x-horoscope-date"), null);
        assert.deepEqual(firstBody, { error: "horoscope_provider_unavailable" });
        assert.equal(storage.entries.get("daily:en-US").date, "2026-11-06");
        assert.equal(storage.entries.has("retry:en-US"), true);

        const second = await new DailyHoroscopeCache({ storage }).fetch(
          requestFor("en-US"),
        );
        assert.equal(second.status, 502);
        assert.ok(Number(second.headers.get("retry-after")) > 0);
        assert.equal(upstreamCalls, 1);
      },
    );
  });

  it("fails closed when shared storage is unavailable without calling the source", async (testContext) => {
    freezeDate(testContext, `${TEST_DATE}T12:00:00Z`);
    let upstreamCalls = 0;
    const storage = createStorage(new Map(), {
      get: async () => {
        throw new Error("storage unavailable");
      },
    });

    await withMockedFetch(
      async () => {
        upstreamCalls += 1;
        return new Response(englishRss());
      },
      async () => {
        const response = await new DailyHoroscopeCache({ storage }).fetch(
          requestFor("en-US"),
        );

        assert.equal(response.status, 503);
        assert.equal(response.headers.get("cache-control"), "no-store");
        assert.deepEqual(await response.json(), {
          error: "horoscope_provider_unavailable",
        });
        assert.equal(upstreamCalls, 0);
      },
    );
  });

  it("does not repeatedly fetch a provider when the snapshot cannot be saved", async (testContext) => {
    freezeDate(testContext, `${TEST_DATE}T12:00:00Z`);
    const storage = createStorage(new Map(), {
      put: async () => { throw new Error("storage writes unavailable"); },
    });
    let upstreamCalls = 0;
    await withMockedFetch(async () => {
      upstreamCalls += 1;
      return new Response(englishRss());
    }, async () => {
      const cache = new DailyHoroscopeCache({ storage });
      const first = await cache.fetch(requestFor("en-US"));
      const second = await cache.fetch(requestFor("en-US"));
      assert.equal(first.status, 503);
      assert.equal(second.status, 503);
      assert.equal(second.headers.get("cache-control"), "no-store");
      assert.equal(upstreamCalls, 1);
    });
  });
});
