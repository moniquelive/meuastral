const SITE_TIME_ZONE = "America/Sao_Paulo";

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

export function resolveLocale(locale) {
  return supportedLocaleForTag(locale) ?? "pt-BR";
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
  return resolveLocale(locale) === "en-US" ? "zodiac-timeline" : "terra";
}

export function dateKeyInTimeZone(date, timeZone = SITE_TIME_ZONE) {
  const formatter = new Intl.DateTimeFormat("en-US", {
    day: "2-digit",
    month: "2-digit",
    timeZone,
    year: "numeric",
  });
  const parts = formatter.formatToParts(date);
  const values = Object.fromEntries(parts.map((part) => [part.type, part.value]));

  return `${values.year}-${values.month}-${values.day}`;
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
