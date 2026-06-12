import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
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
});
