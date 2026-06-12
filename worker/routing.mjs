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
  if (/\.(avif|ico|png|webp)$/i.test(pathname)) {
    return "public, max-age=31536000, immutable";
  }

  if (/\.[a-f0-9]{10}\.(css|js)$/i.test(pathname)) {
    return "public, max-age=31536000, immutable";
  }

  if (/\.(css|js|json)$/i.test(pathname)) {
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
