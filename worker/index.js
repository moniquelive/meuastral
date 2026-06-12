import {
  handleHoroscopeRequest,
  resolveLocaleFromAcceptLanguage,
  responseWithInjectedLocale,
} from "./horoscope.mjs";

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    if (url.pathname === "/api/horoscope") {
      return handleHoroscopeRequest(request, env, ctx);
    }

    const response = await env.STATIC_CONTENT.fetch(request);

    if (response.status !== 404) {
      if (shouldInjectLocale(request, response)) {
        return responseWithInjectedLocale(response, htmlLocale(request));
      }

      return response;
    }

    return handleSpaFallback(request, env);
  },
};

async function handleSpaFallback(request, env) {
  const url = new URL(request.url);
  const isAssetRequest =
    url.pathname.includes(".") && !url.pathname.endsWith(".html");

  if (!isAssetRequest && request.method === "GET") {
    const indexUrl = new URL("/index.html", url.origin);
    const response = await env.STATIC_CONTENT.fetch(
      new Request(indexUrl.toString(), {
        headers: request.headers,
        method: "GET",
      }),
    );

    return responseWithInjectedLocale(response, htmlLocale(request));
  }

  return new Response("Not Found", { status: 404 });
}

function shouldInjectLocale(request, response) {
  if (request.method !== "GET") {
    return false;
  }

  const url = new URL(request.url);

  if (url.pathname !== "/" && url.pathname !== "/index.html") {
    return false;
  }

  return true;
}

function htmlLocale(request) {
  return resolveLocaleFromAcceptLanguage(request.headers.get("accept-language"));
}
