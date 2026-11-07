import {
  dateKeyInTimeZone,
  fetchHoroscopePayload,
  horoscopeResponse,
  isCompleteHoroscopePayload,
  providerForLocale,
} from "./horoscope.mjs";

const RETRY_DELAY_MS = 5 * 60 * 1000;

export class DailyHoroscopeCache {
  constructor(ctx) {
    this.storage = ctx.storage;
    this.pending = new Map();
    this.storageRetryUntil = 0;
  }

  async fetch(request) {
    const locale = new URL(request.url).pathname.slice(1);
    if (request.method !== "GET" || !["en-US", "pt-BR"].includes(locale)) {
      return failureResponse(400);
    }
    if (this.storageRetryUntil > Date.now()) {
      return failureResponse(503, this.storageRetryUntil);
    }

    try {
      // One named object coordinates misses from every Cloudflare data center.
      // Share the storage lookup as well as the fetch, avoiding races between
      // an earlier miss and a refresh that has just finished saving.
      if (!this.pending.has(locale)) {
        this.pending.set(
          locale,
          this.readOrRefresh(locale, new Date()).finally(() => this.pending.delete(locale)),
        );
      }
      const result = await this.pending.get(locale);
      if (result.retryUntil) {
        return failureResponse(502, result.retryUntil);
      }

      // A request arriving at midnight may have waited for yesterday's refresh.
      if (result.date !== dateKeyInTimeZone(new Date())) {
        return this.fetch(request);
      }
      return horoscopeResponse(result.payload, result.date, locale);
    } catch (error) {
      console.error("Horoscope shared cache failed", error);
      // Never bypass the shared cache when storage fails: that would let every
      // visitor independently hit the provider again.
      this.storageRetryUntil = Date.now() + RETRY_DELAY_MS;
      return failureResponse(503, this.storageRetryUntil);
    }
  }

  async readOrRefresh(locale, now) {
    const date = dateKeyInTimeZone(now);
    const snapshot = await this.storage.get(`daily:${locale}`);
    if (
      snapshot?.date === date &&
      snapshot.provider === providerForLocale(locale) &&
      isCompleteHoroscopePayload(snapshot.payload)
    ) {
      return snapshot;
    }

    const retry = await this.storage.get(`retry:${locale}`);
    if (retry?.date === date && retry.until > now.getTime()) {
      return { retryUntil: retry.until };
    }
    return this.refresh(locale, now);
  }

  async refresh(locale, now) {
    const date = dateKeyInTimeZone(now);
    let payload;
    try {
      payload = await fetchHoroscopePayload(locale, now);
      if (!isCompleteHoroscopePayload(payload)) {
        throw new Error("Horoscope provider returned an incomplete payload");
      }
    } catch (error) {
      console.error("Horoscope provider request failed", error);
      const retryUntil = Date.now() + RETRY_DELAY_MS;
      await this.storage.put(`retry:${locale}`, { date, until: retryUntil });
      return { retryUntil };
    }

    const snapshot = { date, provider: providerForLocale(locale), payload };
    // Keep only the latest complete snapshot, so storage remains bounded.
    await this.storage.put(`daily:${locale}`, snapshot);
    await this.storage.delete(`retry:${locale}`);
    return snapshot;
  }
}

function failureResponse(status, retryUntil) {
  return Response.json(
    { error: "horoscope_provider_unavailable" },
    {
      status,
      headers: {
        "cache-control": "no-store",
        ...(retryUntil
          ? { "retry-after": String(Math.max(1, Math.ceil((retryUntil - Date.now()) / 1000))) }
          : {}),
      },
    },
  );
}
