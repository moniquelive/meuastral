const TERRA_URL =
  "https://www.terra.com.br/feeder/horoscopo/card-sign-pt?type=json&country=br&jsonp=false";
const API_NINJAS_URL = "https://api.api-ninjas.com/v1/horoscope";

export const ZODIAC_SIGNS = [
  "aries",
  "taurus",
  "gemini",
  "cancer",
  "leo",
  "virgo",
  "libra",
  "scorpio",
  "sagittarius",
  "capricorn",
  "aquarius",
  "pisces",
];

const SIGN_NAMES = {
  "pt-BR": {
    aries: "Aries",
    taurus: "Touro",
    gemini: "Gemeos",
    cancer: "Cancer",
    leo: "Leao",
    virgo: "Virgem",
    libra: "Libra",
    scorpio: "Escorpiao",
    sagittarius: "Sagitario",
    capricorn: "Capricornio",
    aquarius: "Aquario",
    pisces: "Peixes",
  },
  "en-US": {
    aries: "Aries",
    taurus: "Taurus",
    gemini: "Gemini",
    cancer: "Cancer",
    leo: "Leo",
    virgo: "Virgo",
    libra: "Libra",
    scorpio: "Scorpio",
    sagittarius: "Sagittarius",
    capricorn: "Capricorn",
    aquarius: "Aquarius",
    pisces: "Pisces",
  },
};

const JSON_HEADERS = {
  "content-type": "application/json; charset=utf-8",
  "cache-control": "public, max-age=300, s-maxage=21600",
};

export function resolveLocale(locale) {
  return supportedLocaleForTag(locale) ?? "pt-BR";
}

function supportedLocaleForTag(locale) {
  if (!locale) {
    return null;
  }

  const normalized = locale.trim().toLowerCase();

  if (normalized === "pt" || normalized.startsWith("pt-")) {
    return "pt-BR";
  }

  if (normalized === "en" || normalized.startsWith("en-")) {
    return "en-US";
  }

  return null;
}

export function resolveLocaleFromAcceptLanguage(header) {
  if (!header) {
    return "pt-BR";
  }

  const candidates = header
    .split(",")
    .map((entry, index) => {
      const [tag, ...params] = entry.trim().split(";");
      const qParam = params.find((param) => param.trim().startsWith("q="));
      const q = qParam ? Number(qParam.trim().slice(2)) : 1;

      return {
        index,
        q: Number.isFinite(q) ? q : 0,
        tag: tag.trim(),
      };
    })
    .filter((candidate) => candidate.tag)
    .filter((candidate) => candidate.q > 0)
    .sort((a, b) => b.q - a.q || a.index - b.index);

  for (const candidate of candidates) {
    const locale = supportedLocaleForTag(candidate.tag);

    if (locale === "pt-BR" || locale === "en-US") {
      return locale;
    }
  }

  return "pt-BR";
}

export function resolveLocaleFromRequest(request) {
  const url = new URL(request.url);
  const explicitLocale = url.searchParams.get("locale");

  if (explicitLocale) {
    return resolveLocale(explicitLocale);
  }

  return resolveLocaleFromAcceptLanguage(request.headers.get("accept-language"));
}

export function providerForLocale(locale) {
  return resolveLocale(locale) === "en-US" ? "api-ninjas" : "terra";
}

export function normalizeTerraResponse(payload) {
  let signs = [];

  if (Array.isArray(payload?.signs_list)) {
    signs = payload.signs_list;
  } else if (Array.isArray(payload?.signs)) {
    signs = payload.signs;
  }

  const byId = new Map(
    signs
      .map((sign) => {
        const id = normalizeSignId(sign?.id ?? sign?.sign ?? sign?.zodiac);

        if (!id) {
          return null;
        }

        return [
          id,
          {
            id,
            name: toStringOrFallback(sign?.name, SIGN_NAMES["pt-BR"][id]),
            resume: toStringOrFallback(
              sign?.resume ?? sign?.horoscope ?? sign?.description ?? sign?.text,
              "",
            ),
          },
        ];
      })
      .filter(Boolean),
  );

  return {
    signs_list: ZODIAC_SIGNS.map((id) => byId.get(id)).filter(Boolean),
  };
}

export function normalizeApiNinjasResponses(responses) {
  const byId = new Map(
    responses
      .map((response) => {
        const id = normalizeSignId(response?.zodiac ?? response?.sign);

        if (!id) {
          return null;
        }

        return [
          id,
          {
            id,
            name: SIGN_NAMES["en-US"][id],
            resume: toStringOrFallback(response?.horoscope, ""),
          },
        ];
      })
      .filter(Boolean),
  );

  return {
    signs_list: ZODIAC_SIGNS.map((id) => byId.get(id)).filter(Boolean),
  };
}

export async function handleHoroscopeRequest(request, env, ctx) {
  const locale = resolveLocaleFromRequest(request);
  const cacheKey = horoscopeCacheKey(request, locale);
  const cache = getRuntimeCache();
  const cachedResponse = cache ? await cache.match(cacheKey) : null;

  if (cachedResponse) {
    return cachedResponse;
  }

  if (providerForLocale(locale) === "api-ninjas" && !env.API_NINJAS_KEY) {
    return jsonResponse(
      { error: "api_ninjas_key_missing" },
      {
        status: 503,
        headers: { "cache-control": "no-store" },
      },
    );
  }

  const payload =
    providerForLocale(locale) === "api-ninjas"
      ? await fetchApiNinjasHoroscope(env)
      : await fetchTerraHoroscope();

  const response = jsonResponse(payload);

  if (cache) {
    const cachePut = cache.put(cacheKey, response.clone());

    if (ctx?.waitUntil) {
      ctx.waitUntil(cachePut);
    } else {
      await cachePut;
    }
  }

  return response;
}

export function injectLocaleIntoHtml(html, locale) {
  const resolvedLocale = resolveLocale(locale);
  const localeScript = `<script>window.__MEUASTRAL_LOCALE__ = ${JSON.stringify(
    resolvedLocale,
  )};</script>`;
  const withLang = html.replace(
    /<html([^>]*)\slang="[^"]*"/i,
    `<html$1 lang="${resolvedLocale}"`,
  );

  if (withLang.includes("window.__MEUASTRAL_LOCALE__")) {
    return withLang;
  }

  return withLang.replace("</head>", `  ${localeScript}\n</head>`);
}

export async function responseWithInjectedLocale(response, locale) {
  const html = await response.text();
  const headers = new Headers(response.headers);

  headers.set("content-type", "text/html; charset=utf-8");

  return new Response(injectLocaleIntoHtml(html, locale), {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}

async function fetchTerraHoroscope() {
  const response = await fetch(TERRA_URL);

  if (!response.ok) {
    console.error("Terra horoscope request failed", response.status);
    return { signs_list: [] };
  }

  return normalizeTerraResponse(await response.json());
}

async function fetchApiNinjasHoroscope(env) {
  try {
    const responses = await Promise.all(
      ZODIAC_SIGNS.map(async (sign) => {
        const url = new URL(API_NINJAS_URL);
        url.searchParams.set("zodiac", sign);

        const response = await fetch(url.toString(), {
          headers: { "X-Api-Key": env.API_NINJAS_KEY },
        });

        if (!response.ok) {
          throw new Error(`API Ninjas ${sign} failed with ${response.status}`);
        }

        return response.json();
      }),
    );

    return normalizeApiNinjasResponses(responses);
  } catch (error) {
    console.error("API Ninjas horoscope request failed", error);
    return { signs_list: [] };
  }
}

function horoscopeCacheKey(request, locale) {
  const sourceUrl = new URL(request.url);
  const cacheUrl = new URL("/api/horoscope-cache", sourceUrl.origin);

  cacheUrl.searchParams.set("locale", locale);
  cacheUrl.searchParams.set("date", new Date().toISOString().slice(0, 10));

  return new Request(cacheUrl.toString(), { method: "GET" });
}

function getRuntimeCache() {
  return typeof caches === "undefined" ? null : caches.default;
}

function jsonResponse(payload, init = {}) {
  return new Response(JSON.stringify(payload), {
    ...init,
    headers: {
      ...JSON_HEADERS,
      ...(init.headers ?? {}),
    },
  });
}

function normalizeSignId(value) {
  const normalized = String(value ?? "")
    .trim()
    .toLowerCase();

  return ZODIAC_SIGNS.includes(normalized) ? normalized : "";
}

function toStringOrFallback(value, fallback) {
  const stringValue = String(value ?? "").trim();

  return stringValue || fallback;
}
