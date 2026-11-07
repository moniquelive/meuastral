import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  dateKeyInTimeZone,
  fetchHoroscopePayload,
  handleHoroscopeRequest,
  horoscopeResponse,
  isCompleteHoroscopePayload,
  normalizeTerraResponse,
  normalizeZodiacTimelineResponse,
  providerForLocale,
  resolveLocaleFromAcceptLanguage,
  ZODIAC_SIGNS,
} from "../../worker/horoscope.mjs";

const TODAY = "2026-11-07";
const TODAY_DATE = new Date("2026-11-07T15:00:00.000Z");

function rssItem(sign, date = TODAY, reading = `Reading for ${sign}.`) {
  return `<item><zt:sign>${sign}</zt:sign><zt:date>${date}</zt:date><description>${reading}</description></item>`;
}

function rssFeed(items) {
  return `<rss version="2.0" xmlns:zt="https://zodiactimeline.com/feed"><channel><title>Daily readings</title>${items}</channel></rss>`;
}

function todayItems() {
  return ZODIAC_SIGNS.map((sign) => rssItem(sign)).join("");
}

function completePayload() {
  return {
    signs_list: ZODIAC_SIGNS.map((id) => ({
      id,
      name: id[0].toUpperCase() + id.slice(1),
      resume: `Reading for ${id}.`,
    })),
  };
}

describe("Worker locale detection", () => {
  it("chooses Portuguese and English variants", () => {
    assert.equal(resolveLocaleFromAcceptLanguage("pt-PT,pt;q=0.8"), "pt-BR");
    assert.equal(resolveLocaleFromAcceptLanguage("en-GB,en;q=0.8"), "en-US");
  });

  it("uses the first supported preference and ignores disabled languages", () => {
    assert.equal(resolveLocaleFromAcceptLanguage("fr-FR,en-US;q=0.9"), "en-US");
    assert.equal(resolveLocaleFromAcceptLanguage("en-US;q=0,pt-BR;q=0.8"), "pt-BR");
  });

  it("falls back to Portuguese for unsupported locales", () => {
    assert.equal(resolveLocaleFromAcceptLanguage("fr-FR,fr;q=0.9"), "pt-BR");
  });
});

describe("Worker provider selection", () => {
  it("uses Terra for Portuguese and Zodiac Timeline for English", () => {
    assert.equal(providerForLocale("pt-BR"), "terra");
    assert.equal(providerForLocale("en-US"), "zodiac-timeline");
  });
});

describe("Worker horoscope cache dates", () => {
  it("uses the configured site day instead of the UTC day", () => {
    assert.equal(dateKeyInTimeZone(new Date("2026-07-10T01:30:00Z")), "2026-07-09");
  });

  it("limits public cache headers to the remaining site day", () => {
    const midday = horoscopeResponse(completePayload(), TODAY, "en-US", TODAY_DATE);
    assert.equal(midday.headers.get("cache-control"), "public, max-age=300, s-maxage=21600");
    assert.equal(midday.headers.get("x-horoscope-date"), TODAY);
    assert.equal(midday.headers.get("x-horoscope-provider"), "zodiac-timeline");

    const beforeMidnight = new Date("2026-11-07T02:59:30.000Z");
    const yesterday = horoscopeResponse(
      completePayload(),
      "2026-11-06",
      "en-US",
      beforeMidnight,
    );
    assert.equal(yesterday.headers.get("cache-control"), "public, max-age=30, s-maxage=30");
  });
});

describe("Worker horoscope normalization", () => {
  it("normalizes Terra's all-sign response", () => {
    assert.deepEqual(
      normalizeTerraResponse({
        signs_list: [{ id: "aries", name: "Aries", resume: "Resumo de aries." }],
      }),
      {
        signs_list: [{ id: "aries", name: "Aries", resume: "Resumo de aries." }],
      },
    );
  });

  it("selects today's English readings and returns all signs in canonical order", () => {
    const xml = rssFeed(
      `${todayItems()}${rssItem("aries", "2026-11-08", "Tomorrow's reading.")}`,
    );
    const payload = normalizeZodiacTimelineResponse(xml, TODAY);

    assert.deepEqual(
      payload.signs_list,
      ZODIAC_SIGNS.map((id) => ({
        id,
        name: id[0].toUpperCase() + id.slice(1),
        resume: `Reading for ${id}.`,
      })),
    );
    assert.equal(isCompleteHoroscopePayload(payload), true);
  });

  it("decodes standard XML text entities in readings", () => {
    const xml = rssFeed(todayItems().replace("Reading for aries.", "Reading &amp; planning for Aries."));
    const payload = normalizeZodiacTimelineResponse(xml, TODAY);

    assert.equal(payload.signs_list[0].resume, "Reading & planning for Aries.");
  });

  it("rejects a missing date, duplicate signs, and empty readings", () => {
    assert.throws(
      () => normalizeZodiacTimelineResponse(rssFeed(todayItems()), "2026-11-08"),
      /missing today's readings/,
    );

    const duplicateSigns = ZODIAC_SIGNS.map((sign) =>
      rssItem(sign === "aries" ? "taurus" : sign),
    ).join("");
    assert.throws(
      () => normalizeZodiacTimelineResponse(rssFeed(duplicateSigns), TODAY),
      /unknown or duplicate sign/,
    );

    const blankReading = todayItems().replace("Reading for aries.", "   ");
    assert.throws(
      () => normalizeZodiacTimelineResponse(rssFeed(blankReading), TODAY),
      /empty reading/,
    );
  });

  it("rejects malformed XML and feeds with custom entity declarations", () => {
    assert.throws(() => normalizeZodiacTimelineResponse("<rss><channel>", TODAY), /Malformed/);
    assert.throws(
      () => normalizeZodiacTimelineResponse(
        `<!DOCTYPE rss [<!ENTITY custom "text">]>${rssFeed(todayItems())}`,
        TODAY,
      ),
      /must not define XML entities/,
    );
  });

  it("rejects duplicated or incomplete normalized sign lists", () => {
    const payload = completePayload();
    payload.signs_list[0] = payload.signs_list[1];
    assert.equal(isCompleteHoroscopePayload(payload), false);
  });

  it("fetches and normalizes the Zodiac Timeline feed for the requested site date", async () => {
    const originalFetch = globalThis.fetch;
    const calls = [];
    globalThis.fetch = async (url, options) => {
      calls.push({ url, options });
      return new Response(rssFeed(todayItems()), {
        headers: { "content-type": "application/rss+xml" },
      });
    };

    try {
      const payload = await fetchHoroscopePayload("en-US", TODAY_DATE);
      assert.equal(new URL(calls[0].url).href, "https://zodiactimeline.com/feed.xml");
      assert.ok(calls[0].options.signal);
      assert.equal(payload.signs_list.length, 12);
    } finally {
      globalThis.fetch = originalFetch;
    }
  });
});

describe("Worker horoscope endpoint", () => {
  it("rejects unsafe methods", async () => {
    const response = await handleHoroscopeRequest(
      new Request("https://meuastral.com/api/horoscope", { method: "POST" }),
      {},
      {},
    );

    assert.equal(response.status, 405);
    assert.equal(response.headers.get("allow"), "GET, HEAD");
    assert.equal(response.headers.get("cache-control"), "no-store");
  });

  it("fails closed when the shared cache binding is missing", async () => {
    const response = await handleHoroscopeRequest(
      new Request("https://meuastral.com/api/horoscope?locale=en-US"),
      {},
      {},
    );

    assert.equal(response.status, 503);
    assert.equal(response.headers.get("cache-control"), "no-store");
    assert.deepEqual(await response.json(), { error: "horoscope_cache_missing" });
  });

  it("serves a shared-cache response and edge-caches it by provider and date", async () => {
    const originalCaches = Object.getOwnPropertyDescriptor(globalThis, "caches");
    const edgeKeys = [];
    const cacheWrites = [];
    const stubCalls = [];
    const namespace = {
      idFromName: (name) => `id:${name}`,
      get: (id) => ({
        fetch: async (request) => {
          stubCalls.push({ id, url: request.url });
          const now = new Date();
          return horoscopeResponse(completePayload(), dateKeyInTimeZone(now), "en-US", now);
        },
      }),
    };
    Object.defineProperty(globalThis, "caches", {
      configurable: true,
      value: {
        default: {
          match: async (key) => {
            edgeKeys.push(key);
            return null;
          },
          put: async (key, response) => cacheWrites.push({ key, response }),
        },
      },
    });

    try {
      const response = await handleHoroscopeRequest(
        new Request("https://meuastral.com/api/horoscope?locale=en-US"),
        { HOROSCOPE_CACHE: namespace },
        {},
      );
      const payload = await response.json();

      assert.equal(response.status, 200);
      assert.equal(payload.signs_list.length, 12);
      assert.deepEqual(stubCalls, [{
        id: "id:en-US",
        url: "https://horoscope-cache/en-US",
      }]);
      assert.equal(edgeKeys.length, 1);
      const cacheUrl = new URL(edgeKeys[0].url);
      assert.equal(cacheUrl.pathname, "/api/horoscope-cache/v2");
      assert.equal(cacheUrl.searchParams.get("locale"), "en-US");
      assert.equal(cacheUrl.searchParams.get("provider"), "zodiac-timeline");
      assert.equal(cacheUrl.searchParams.get("date"), dateKeyInTimeZone(new Date()));
      assert.equal(cacheWrites.length, 1);
    } finally {
      if (originalCaches) {
        Object.defineProperty(globalThis, "caches", originalCaches);
      } else {
        delete globalThis.caches;
      }
    }
  });

  it("returns HEAD headers without a body and does not edge-cache provider errors", async () => {
    const originalCaches = Object.getOwnPropertyDescriptor(globalThis, "caches");
    const cacheWrites = [];
    const namespace = {
      idFromName: () => "id:en-US",
      get: () => ({
        fetch: async () => horoscopeResponse(
          completePayload(),
          dateKeyInTimeZone(new Date()),
          "en-US",
        ),
      }),
    };
    Object.defineProperty(globalThis, "caches", {
      configurable: true,
      value: {
        default: {
          match: async () => null,
          put: async (...args) => cacheWrites.push(args),
        },
      },
    });

    try {
      const response = await handleHoroscopeRequest(
        new Request("https://meuastral.com/api/horoscope?locale=en-US", { method: "HEAD" }),
        { HOROSCOPE_CACHE: namespace },
        {},
      );

      assert.equal(response.status, 200);
      assert.equal(response.headers.get("x-horoscope-provider"), "zodiac-timeline");
      assert.equal(await response.text(), "");
      assert.equal(cacheWrites.length, 1);

      const failingNamespace = {
        idFromName: () => "id:en-US",
        get: () => ({ fetch: async () => Response.json({ error: "unavailable" }, { status: 502 }) }),
      };
      const failure = await handleHoroscopeRequest(
        new Request("https://meuastral.com/api/horoscope?locale=en-US"),
        { HOROSCOPE_CACHE: failingNamespace },
        {},
      );

      assert.equal(failure.status, 502);
      assert.deepEqual(await failure.json(), { error: "unavailable" });
      assert.equal(cacheWrites.length, 1);
    } finally {
      if (originalCaches) {
        Object.defineProperty(globalThis, "caches", originalCaches);
      } else {
        delete globalThis.caches;
      }
    }
  });

  it("shrinks cache headers on an edge-cache hit near São Paulo midnight", async (testContext) => {
    const originalCaches = Object.getOwnPropertyDescriptor(globalThis, "caches");
    testContext.mock.timers.enable({
      apis: ["Date"],
      now: new Date("2026-11-07T15:00:00.000Z"),
    });
    const cachedResponse = horoscopeResponse(completePayload(), TODAY, "en-US");
    testContext.mock.timers.setTime(Date.parse("2026-11-08T02:59:30.000Z"));
    let sharedFetches = 0;
    Object.defineProperty(globalThis, "caches", {
      configurable: true,
      value: {
        default: {
          match: async () => cachedResponse,
          put: async () => assert.fail("an edge-cache hit must not be written again"),
        },
      },
    });

    try {
      const response = await handleHoroscopeRequest(
        new Request("https://meuastral.com/api/horoscope?locale=en-US"),
        {
          HOROSCOPE_CACHE: {
            idFromName: () => "id:en-US",
            get: () => ({
              fetch: async () => {
                sharedFetches += 1;
                throw new Error("edge hit should not call the shared cache");
              },
            }),
          },
        },
        {},
      );

      assert.equal(response.status, 200);
      assert.equal(response.headers.get("cache-control"), "public, max-age=30, s-maxage=30");
      assert.equal(sharedFetches, 0);
    } finally {
      if (originalCaches) {
        Object.defineProperty(globalThis, "caches", originalCaches);
      } else {
        delete globalThis.caches;
      }
    }
  });

  it("stores a shared-cache response under the completion date across midnight", async (testContext) => {
    const originalCaches = Object.getOwnPropertyDescriptor(globalThis, "caches");
    testContext.mock.timers.enable({
      apis: ["Date"],
      now: new Date("2026-11-07T02:59:59.000Z"),
    });
    const edgeKeys = [];
    const cacheWrites = [];
    Object.defineProperty(globalThis, "caches", {
      configurable: true,
      value: {
        default: {
          match: async (key) => {
            edgeKeys.push(key);
            return null;
          },
          put: async (key, response) => cacheWrites.push({ key, response }),
        },
      },
    });
    const namespace = {
      idFromName: () => "id:en-US",
      get: () => ({
        fetch: async () => {
          testContext.mock.timers.setTime(Date.parse("2026-11-07T03:00:01.000Z"));
          return horoscopeResponse(
            completePayload(),
            "2026-11-07",
            "en-US",
            new Date(),
          );
        },
      }),
    };

    try {
      const response = await handleHoroscopeRequest(
        new Request("https://meuastral.com/api/horoscope?locale=en-US"),
        { HOROSCOPE_CACHE: namespace },
        {},
      );

      assert.equal(response.status, 200);
      assert.equal(response.headers.get("x-horoscope-date"), "2026-11-07");
      assert.equal(edgeKeys.length, 1);
      assert.equal(new URL(edgeKeys[0].url).searchParams.get("date"), "2026-11-06");
      assert.equal(cacheWrites.length, 1);
      assert.equal(new URL(cacheWrites[0].key.url).searchParams.get("date"), "2026-11-07");
    } finally {
      if (originalCaches) {
        Object.defineProperty(globalThis, "caches", originalCaches);
      } else {
        delete globalThis.caches;
      }
    }
  });
});
