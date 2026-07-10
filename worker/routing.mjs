const LOCALE_COOKIE_NAME = "meuastral-locale";
const SUPPORTED_LOCALES = new Set(["en-US", "pt-BR"]);

function supportedLocale(locale) {
  return SUPPORTED_LOCALES.has(locale) ? locale : null;
}

export function localePreferenceFromRequest(request) {
  const url = new URL(request.url);
  const explicitLocale = supportedLocale(url.searchParams.get("lang"));

  if (explicitLocale) {
    url.searchParams.delete("lang");

    return {
      cleanUrl: url.toString(),
      locale: explicitLocale,
      source: "query",
    };
  }

  const cookieHeader = request.headers.get("cookie") ?? "";
  const localeCookie = cookieHeader
    .split(";")
    .map((cookie) => cookie.trim().split("="))
    .find(([name]) => name === LOCALE_COOKIE_NAME);
  const storedLocale = supportedLocale(localeCookie?.[1]);

  return storedLocale
    ? { cleanUrl: null, locale: storedLocale, source: "cookie" }
    : null;
}

export function localePreferenceCookie(locale) {
  return `${LOCALE_COOKIE_NAME}=${locale}; Path=/; Max-Age=31536000; SameSite=Lax; Secure`;
}

export function redirectPathForHomeLocale(request, locale) {
  if (request.method !== "GET" && request.method !== "HEAD") {
    return null;
  }

  const url = new URL(request.url);

  if (url.pathname !== "/" && url.pathname !== "/index.html") {
    return null;
  }

  return locale === "en-US" ? "/en/" : null;
}

export function cacheControlForStaticPath(pathname) {
  if (/\.[a-f0-9]{10}\.(avif|css|ico|js|png|webp)$/i.test(pathname)) {
    return "public, max-age=31536000, immutable";
  }

  if (/\.(avif|css|ico|js|json|png|webp)$/i.test(pathname)) {
    return "public, max-age=86400, stale-while-revalidate=604800";
  }

  return null;
}

export function withStaticCacheHeaders(response, pathname) {
  const cacheControl = cacheControlForStaticPath(pathname);

  if (!cacheControl || !response.ok) {
    return response;
  }

  const headers = new Headers(response.headers);
  headers.set("cache-control", cacheControl);

  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}
