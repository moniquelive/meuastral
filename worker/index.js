import {
  handleHoroscopeRequest,
  resolveLocaleFromAcceptLanguage,
} from "./horoscope.mjs";
import {
  localePreferenceCookie,
  localePreferenceFromRequest,
  redirectPathForHomeLocale,
  withStaticCacheHeaders,
} from "./routing.mjs";

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const localePreference = localePreferenceFromRequest(request);

    if (localePreference?.source === "query") {
      return new Response(null, {
        status: 302,
        headers: {
          "cache-control": "private, no-store",
          location: localePreference.cleanUrl,
          "set-cookie": localePreferenceCookie(localePreference.locale),
        },
      });
    }

    const localeRedirectPath = redirectPathForHomeLocale(
      request,
      localePreference?.locale ??
        resolveLocaleFromAcceptLanguage(request.headers.get("accept-language")),
    );

    if (localeRedirectPath) {
      return new Response(null, {
        status: 302,
        headers: {
          "cache-control": "private, no-store",
          location: new URL(localeRedirectPath, url.origin).toString(),
          vary: "Accept-Language, Cookie",
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
