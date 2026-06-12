import {
  handleHoroscopeRequest,
  resolveLocaleFromAcceptLanguage,
} from "./horoscope.mjs";
import {
  redirectPathForHomeLocale,
  withStaticCacheHeaders,
} from "./routing.mjs";

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

    return withStaticCacheHeaders(response, url.pathname);
  },
};
