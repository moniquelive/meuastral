import {
  handleHoroscopeRequest,
  resolveLocaleFromAcceptLanguage,
} from "./horoscope.mjs";
import {
  localeForPath,
  redirectPathForHomeLocale,
  responseWithPageMetadata,
  shouldServeAppShellFallback,
} from "./page-meta.mjs";

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    const localeRedirectPath = redirectPathForHomeLocale(
      request,
      resolveLocaleFromAcceptLanguage(request.headers.get("accept-language")),
    );

    if (localeRedirectPath) {
      return new Response(null, {
        status: 302,
        headers: {
          location: new URL(localeRedirectPath, url.origin).toString(),
          vary: "Accept-Language",
        },
      });
    }

    if (url.pathname === "/en") {
      return Response.redirect(new URL("/en/", url.origin).toString(), 301);
    }

    if (url.pathname === "/api/horoscope") {
      return handleHoroscopeRequest(request, env, ctx);
    }

    const response = await env.STATIC_CONTENT.fetch(request);

    if (response.status !== 404) {
      if (shouldInjectMetadata(request)) {
        return responseWithPageMetadata(response, htmlLocale(request));
      }

      return response;
    }

    return handleSpaFallback(request, env);
  },
};

async function handleSpaFallback(request, env) {
  const url = new URL(request.url);

  if (shouldServeAppShellFallback(request)) {
    const indexUrl = new URL("/index.html", url.origin);
    const response = await env.STATIC_CONTENT.fetch(
      new Request(indexUrl.toString(), {
        headers: request.headers,
        method: "GET",
      }),
    );
    const metadataResponse = await responseWithPageMetadata(
      response,
      htmlLocale(request),
    );

    if (request.method === "HEAD") {
      return new Response(null, {
        status: metadataResponse.status,
        statusText: metadataResponse.statusText,
        headers: metadataResponse.headers,
      });
    }

    return metadataResponse;
  }

  return new Response("Not Found", { status: 404 });
}

function shouldInjectMetadata(request) {
  if (request.method !== "GET") {
    return false;
  }

  const url = new URL(request.url);

  return localeForPath(url.pathname) !== null;
}

function htmlLocale(request) {
  const url = new URL(request.url);

  return (
    localeForPath(url.pathname) ??
    resolveLocaleFromAcceptLanguage(request.headers.get("accept-language"))
  );
}
