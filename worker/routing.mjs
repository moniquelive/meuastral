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
