import { XMLParser, XMLValidator } from "fast-xml-parser";
import {
  dateKeyInTimeZone,
  providerForLocale,
  resolveLocale,
  resolveLocaleFromRequest,
  ZODIAC_SIGNS,
} from "./horoscope-config.mjs";

export {
  dateKeyInTimeZone,
  providerForLocale,
  resolveLocale,
  resolveLocaleFromAcceptLanguage,
  resolveLocaleFromRequest,
  ZODIAC_SIGNS,
} from "./horoscope-config.mjs";

const TERRA_URL =
  "https://www.terra.com.br/feeder/horoscopo/card-sign-pt?type=json&country=br&jsonp=false";
const ZODIAC_TIMELINE_URL = "https://zodiactimeline.com/feed.xml";
const SITE_TIME_ZONE = "America/Sao_Paulo";
const XML_MAX_LENGTH = 512_000;
const XML_PARSER = new XMLParser({
  ignoreAttributes: true,
  parseTagValue: false,
  processEntities: true,
  removeNSPrefix: false,
  trimValues: true,
});

const SIGN_NAMES = {
  "pt-BR": {
    aries: "Áries",
    taurus: "Touro",
    gemini: "Gêmeos",
    cancer: "Câncer",
    leo: "Leão",
    virgo: "Virgem",
    libra: "Libra",
    scorpio: "Escorpião",
    sagittarius: "Sagitário",
    capricorn: "Capricórnio",
    aquarius: "Aquário",
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

export function normalizeZodiacTimelineResponse(xml, dateKey) {
  if (typeof xml !== "string" || !xml.trim() || xml.length > XML_MAX_LENGTH) {
    throw new Error("Invalid Zodiac Timeline RSS feed size");
  }

  if (!isDateKey(dateKey)) {
    throw new Error("Invalid horoscope date");
  }

  // This feed needs only XML's predefined and numeric references. Reject DTDs
  // before parsing so upstream content cannot introduce custom entities.
  if (/<!\s*DOCTYPE\b/i.test(xml)) {
    throw new Error("Zodiac Timeline RSS must not define XML entities");
  }

  if (XMLValidator.validate(xml) !== true) {
    throw new Error("Malformed Zodiac Timeline RSS XML");
  }

  const feed = XML_PARSER.parse(xml);
  const items = feed?.rss?.channel?.item;

  if (!Array.isArray(items)) {
    throw new Error("Zodiac Timeline RSS is missing its items");
  }

  const todayItems = items.filter((item) => item?.["zt:date"] === dateKey);

  if (todayItems.length !== ZODIAC_SIGNS.length) {
    throw new Error("Zodiac Timeline RSS is missing today's readings");
  }

  const byId = new Map();

  for (const item of todayItems) {
    const id = normalizeSignId(item?.["zt:sign"]);
    const resume = item?.description;

    if (!id || byId.has(id)) {
      throw new Error("Zodiac Timeline RSS has an unknown or duplicate sign");
    }

    if (typeof resume !== "string" || !resume.trim()) {
      throw new Error("Zodiac Timeline RSS has an empty reading");
    }

    byId.set(id, {
      id,
      name: SIGN_NAMES["en-US"][id],
      resume: resume.trim(),
    });
  }

  const payload = {
    signs_list: ZODIAC_SIGNS.map((id) => byId.get(id)).filter(Boolean),
  };

  if (!isCompleteHoroscopePayload(payload)) {
    throw new Error("Zodiac Timeline RSS is missing a zodiac sign");
  }

  return payload;
}

export async function fetchHoroscopePayload(locale, date = new Date()) {
  const normalizedLocale = resolveLocale(locale);
  const provider = providerForLocale(normalizedLocale);
  const response =
    provider === "zodiac-timeline"
      ? await fetch(ZODIAC_TIMELINE_URL, { signal: AbortSignal.timeout(15_000) })
      : await fetch(TERRA_URL, { signal: AbortSignal.timeout(15_000) });

  if (!response.ok) {
    throw new Error(`${provider} request failed with ${response.status}`);
  }

  const payload =
    provider === "zodiac-timeline"
      ? normalizeZodiacTimelineResponse(
          await response.text(),
          dateKeyInTimeZone(date),
        )
      : normalizeTerraResponse(await response.json());

  if (!isCompleteHoroscopePayload(payload)) {
    throw new Error(`${provider} returned an incomplete horoscope`);
  }

  return payload;
}

export function isCompleteHoroscopePayload(payload) {
  if (
    !Array.isArray(payload?.signs_list) ||
    payload.signs_list.length !== ZODIAC_SIGNS.length
  ) {
    return false;
  }

  const seen = new Set();

  return payload.signs_list.every((sign) => {
    if (
      !ZODIAC_SIGNS.includes(sign?.id) ||
      seen.has(sign.id) ||
      typeof sign.name !== "string" ||
      !sign.name.trim() ||
      typeof sign.resume !== "string" ||
      !sign.resume.trim()
    ) {
      return false;
    }

    seen.add(sign.id);
    return true;
  });
}

export function horoscopeResponse(payload, dateKey, locale, nowDate = new Date()) {
  const normalizedLocale = resolveLocale(locale);

  if (!isDateKey(dateKey) || !isCompleteHoroscopePayload(payload)) {
    throw new Error("Cannot cache an incomplete horoscope response");
  }

  return jsonResponse(payload, {
    headers: {
      "cache-control": horoscopeCacheControl(dateKey, nowDate),
      "x-horoscope-date": dateKey,
      "x-horoscope-provider": providerForLocale(normalizedLocale),
    },
  });
}

export async function handleHoroscopeRequest(request, env, ctx) {
  if (request.method !== "GET" && request.method !== "HEAD") {
    return jsonResponse(
      { error: "method_not_allowed" },
      {
        status: 405,
        headers: {
          allow: "GET, HEAD",
          "cache-control": "no-store",
        },
      },
    );
  }

  const locale = resolveLocaleFromRequest(request);
  const cache = getRuntimeCache();

  if (!env?.HOROSCOPE_CACHE) {
    return jsonResponse(
      { error: "horoscope_cache_missing" },
      { status: 503, headers: { "cache-control": "no-store" } },
    );
  }

  let requestDate = new Date();

  for (let attempt = 0; attempt < 2; attempt += 1) {
    const dateKey = dateKeyInTimeZone(requestDate);
    const cacheKey = horoscopeCacheKey(request, locale, dateKey);
    const cachedResponse = cache ? await cache.match(cacheKey) : null;

    if (cachedResponse && hasExpectedHoroscopeHeaders(cachedResponse, locale, dateKey)) {
      const servedAt = new Date();

      if (dateKeyInTimeZone(servedAt) === dateKey) {
        return responseForMethod(
          responseWithCurrentCacheControl(cachedResponse, dateKey, servedAt),
          request.method,
        );
      }

      requestDate = servedAt;
      continue;
    }

    let response;

    try {
      const id = env.HOROSCOPE_CACHE.idFromName(locale);
      const stub = env.HOROSCOPE_CACHE.get(id);
      response = await stub.fetch(
        new Request(`https://horoscope-cache/${locale}`, { method: "GET" }),
      );
    } catch (error) {
      console.error("Horoscope cache request failed", error);
      return jsonResponse(
        { error: "horoscope_cache_unavailable" },
        { status: 503, headers: { "cache-control": "no-store" } },
      );
    }

    if (!response.ok) {
      return responseForMethod(response, request.method);
    }

    const servedAt = new Date();
    const responseDateKey = response.headers.get("x-horoscope-date");

    if (
      !isDateKey(responseDateKey) ||
      response.headers.get("x-horoscope-provider") !== providerForLocale(locale)
    ) {
      return jsonResponse(
        { error: "horoscope_cache_unavailable" },
        { status: 502, headers: { "cache-control": "no-store" } },
      );
    }

    const servedDateKey = dateKeyInTimeZone(servedAt);

    if (responseDateKey !== servedDateKey) {
      requestDate = servedAt;
      continue;
    }

    const completedCacheKey = horoscopeCacheKey(request, locale, servedDateKey);
    const freshResponse = responseWithCurrentCacheControl(
      response,
      responseDateKey,
      servedAt,
    );

    if (cache) {
      try {
        const cachePut = cache.put(completedCacheKey, freshResponse.clone());

        if (ctx?.waitUntil) {
          ctx.waitUntil(cachePut);
        } else {
          await cachePut;
        }
      } catch (error) {
        console.error("Edge horoscope cache write failed", error);
      }
    }

    return responseForMethod(freshResponse, request.method);
  }

  return jsonResponse(
    { error: "horoscope_cache_unavailable" },
    { status: 503, headers: { "cache-control": "no-store" } },
  );
}

function horoscopeCacheKey(request, locale, dateKey) {
  const sourceUrl = new URL(request.url);
  const cacheUrl = new URL("/api/horoscope-cache/v2", sourceUrl.origin);

  cacheUrl.searchParams.set("locale", locale);
  cacheUrl.searchParams.set("provider", providerForLocale(locale));
  cacheUrl.searchParams.set("date", dateKey);

  return new Request(cacheUrl.toString(), { method: "GET" });
}

function horoscopeCacheControl(dateKey, nowDate) {
  if (dateKey !== dateKeyInTimeZone(nowDate)) {
    return "public, max-age=0, s-maxage=0";
  }

  const secondsUntilMidnight = secondsUntilSiteMidnight(nowDate);
  const edgeTtl = Math.min(21_600, secondsUntilMidnight);
  const browserTtl = Math.min(300, edgeTtl);

  return `public, max-age=${browserTtl}, s-maxage=${edgeTtl}`;
}

function secondsUntilSiteMidnight(date) {
  const parts = new Intl.DateTimeFormat("en-US", {
    hour: "2-digit",
    hourCycle: "h23",
    minute: "2-digit",
    second: "2-digit",
    timeZone: SITE_TIME_ZONE,
  }).formatToParts(date);
  const values = Object.fromEntries(parts.map((part) => [part.type, Number(part.value)]));
  const elapsedSeconds =
    values.hour * 3600 +
    values.minute * 60 +
    values.second +
    date.getUTCMilliseconds() / 1000;

  return Math.max(0, Math.floor(86_400 - elapsedSeconds));
}

function hasExpectedHoroscopeHeaders(response, locale, dateKey) {
  return (
    response.headers.get("x-horoscope-date") === dateKey &&
    response.headers.get("x-horoscope-provider") === providerForLocale(locale)
  );
}

function responseWithCurrentCacheControl(response, dateKey, nowDate) {
  const headers = new Headers(response.headers);
  headers.set("cache-control", horoscopeCacheControl(dateKey, nowDate));

  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}

function isDateKey(value) {
  if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    return false;
  }

  const date = new Date(`${value}T00:00:00.000Z`);
  return Number.isFinite(date.getTime()) && date.toISOString().slice(0, 10) === value;
}

function getRuntimeCache() {
  return typeof caches === "undefined" ? null : caches.default;
}

function jsonResponse(payload, init = {}) {
  return new Response(JSON.stringify(payload), {
    ...init,
    headers: {
      "content-type": "application/json; charset=utf-8",
      ...(init.headers ?? {}),
    },
  });
}

function responseForMethod(response, method) {
  if (method !== "HEAD") {
    return response;
  }

  return new Response(null, {
    status: response.status,
    statusText: response.statusText,
    headers: response.headers,
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
