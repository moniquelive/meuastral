const PORTUGUESE_SLUGS = {
  aquario: "aquarius",
  aries: "aries",
  cancer: "cancer",
  capricornio: "capricorn",
  escorpiao: "scorpio",
  gemeos: "gemini",
  leao: "leo",
  libra: "libra",
  peixes: "pisces",
  sagitario: "sagittarius",
  touro: "taurus",
  virgem: "virgo",
};

const ENGLISH_SIGNS = new Set(Object.values(PORTUGUESE_SLUGS));
const PLACEHOLDER_PATTERN =
  /<section\b[^>]*\bdata-daily-horoscope(?:=(?:""|''|[^\s>]+))?[^>]*>[\s\S]*?<\/section>/i;

export function dailyHoroscopeTarget(pathname) {
  const englishMatch = pathname.match(/^\/en\/horoscope\/([^/]+)\/?$/);

  if (englishMatch && ENGLISH_SIGNS.has(englishMatch[1])) {
    return { locale: "en-US", signId: englishMatch[1] };
  }

  const portugueseMatch = pathname.match(/^\/horoscopo\/([^/]+)\/?$/);
  const signId = portugueseMatch ? PORTUGUESE_SLUGS[portugueseMatch[1]] : null;

  return signId ? { locale: "pt-BR", signId } : null;
}

export function dailyHoroscopeMarkup(sign, locale, date = new Date()) {
  const isEnglish = locale === "en-US";
  const formattedDate = new Intl.DateTimeFormat(locale, {
    dateStyle: "long",
    timeZone: "America/Sao_Paulo",
  }).format(date);
  const eyebrow = isEnglish ? "Today's horoscope" : "Horóscopo de hoje";
  const heading = isEnglish
    ? `${sign.name} horoscope today — ${formattedDate}`
    : `Horóscopo de ${sign.name} hoje — ${formattedDate}`;
  const updateNote = isEnglish
    ? "Daily reading updated for the São Paulo calendar date."
    : "Leitura diária atualizada conforme a data de São Paulo.";

  return [
    '<section class="daily-horoscope" data-daily-horoscope>',
    `<p class="content-eyebrow">${escapeHtml(eyebrow)}</p>`,
    `<h2>${escapeHtml(heading)}</h2>`,
    `<p class="daily-horoscope__reading">${escapeHtml(sign.resume)}</p>`,
    `<p class="daily-horoscope__date">${escapeHtml(updateNote)}</p>`,
    "</section>",
  ].join("");
}

export function injectDailyHoroscope(html, markup) {
  return PLACEHOLDER_PATTERN.test(html)
    ? html.replace(PLACEHOLDER_PATTERN, markup)
    : html;
}

export function cleanLegacyCommentUrl(request) {
  if (request.method !== "GET" && request.method !== "HEAD") {
    return null;
  }

  const url = new URL(request.url);

  if (!url.searchParams.has("fb_comment_id")) {
    return null;
  }

  url.searchParams.delete("fb_comment_id");
  return url.toString();
}

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}
