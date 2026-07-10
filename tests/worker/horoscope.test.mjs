import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  dateKeyInTimeZone,
  handleHoroscopeRequest,
  normalizeApiNinjasResponses,
  normalizeTerraResponse,
  providerForLocale,
  resolveLocaleFromAcceptLanguage,
} from "../../worker/horoscope.mjs";

describe("Worker locale detection", () => {
  it("chooses Portuguese variants as pt-BR", () => {
    assert.equal(resolveLocaleFromAcceptLanguage("pt-PT,pt;q=0.8"), "pt-BR");
  });

  it("chooses English variants as en-US", () => {
    assert.equal(resolveLocaleFromAcceptLanguage("en-GB,en;q=0.8"), "en-US");
  });

  it("falls back to Portuguese for unsupported locales", () => {
    assert.equal(resolveLocaleFromAcceptLanguage("fr-FR,fr;q=0.9"), "pt-BR");
  });

  it("uses the first supported language when the top preference is unsupported", () => {
    assert.equal(resolveLocaleFromAcceptLanguage("fr-FR,en-US;q=0.9"), "en-US");
  });

  it("ignores languages explicitly disabled with q=0", () => {
    assert.equal(resolveLocaleFromAcceptLanguage("en-US;q=0,pt-BR;q=0.8"), "pt-BR");
  });
});

describe("Worker provider selection", () => {
  it("uses Terra for Portuguese", () => {
    assert.equal(providerForLocale("pt-BR"), "terra");
  });

  it("uses API Ninjas for English", () => {
    assert.equal(providerForLocale("en-US"), "api-ninjas");
  });
});

describe("Worker horoscope cache dates", () => {
  it("uses the configured site day instead of the UTC day", () => {
    assert.equal(
      dateKeyInTimeZone(new Date("2026-07-10T01:30:00Z")),
      "2026-07-09",
    );
  });
});

describe("Worker horoscope normalization", () => {
  it("normalizes Terra's all-sign response", () => {
    assert.deepEqual(
      normalizeTerraResponse({
        signs_list: [
          {
            id: "aries",
            name: "Aries",
            resume: "Resumo de aries.",
          },
        ],
      }),
      {
        signs_list: [
          {
            id: "aries",
            name: "Aries",
            resume: "Resumo de aries.",
          },
        ],
      },
    );
  });

  it("normalizes API Ninjas one-response-per-sign payloads", () => {
    assert.deepEqual(
      normalizeApiNinjasResponses([
        {
          sign: "Aries",
          horoscope: "Start something new.",
        },
        {
          zodiac: "taurus",
          horoscope: "Stay grounded.",
        },
      ]),
      {
        signs_list: [
          {
            id: "aries",
            name: "Aries",
            resume: "Start something new.",
          },
          {
            id: "taurus",
            name: "Taurus",
            resume: "Stay grounded.",
          },
        ],
      },
    );
  });

  it("uses accented Portuguese fallback names", () => {
    assert.deepEqual(
      normalizeTerraResponse({
        signs_list: [{ id: "aquarius", resume: "Resumo." }],
      }).signs_list[0],
      { id: "aquarius", name: "Aquário", resume: "Resumo." },
    );
  });
});

describe("Worker horoscope endpoint", () => {
  it("returns a controlled 503 when API Ninjas key is missing", async () => {
    const response = await handleHoroscopeRequest(
      new Request("https://meuastral.com/api/horoscope?locale=en-US"),
      {},
      {},
    );

    assert.equal(response.status, 503);
    assert.deepEqual(await response.json(), {
      error: "api_ninjas_key_missing",
    });
  });

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

  it("returns a non-cacheable 502 when the provider fails", async () => {
    const originalFetch = globalThis.fetch;
    const originalConsoleError = console.error;
    globalThis.fetch = async () => new Response("unavailable", { status: 503 });
    console.error = () => {};

    try {
      const response = await handleHoroscopeRequest(
        new Request("https://meuastral.com/api/horoscope?locale=pt-BR"),
        {},
        {},
      );

      assert.equal(response.status, 502);
      assert.equal(response.headers.get("cache-control"), "no-store");
      assert.deepEqual(await response.json(), {
        error: "horoscope_provider_unavailable",
      });
    } finally {
      globalThis.fetch = originalFetch;
      console.error = originalConsoleError;
    }
  });

  it("does not cache incomplete provider payloads", async () => {
    const originalFetch = globalThis.fetch;
    const originalConsoleError = console.error;
    globalThis.fetch = async () => {
      return Response.json({
        signs_list: [{ id: "aries", name: "Áries", resume: "Resumo." }],
      });
    };
    console.error = () => {};

    try {
      const response = await handleHoroscopeRequest(
        new Request("https://meuastral.com/api/horoscope?locale=pt-BR"),
        {},
        {},
      );

      assert.equal(response.status, 502);
      assert.equal(response.headers.get("cache-control"), "no-store");
    } finally {
      globalThis.fetch = originalFetch;
      console.error = originalConsoleError;
    }
  });
});
