import { handleHoroscopeRequest } from "./horoscope.mjs";
import {
  cleanLegacyCommentUrl,
  dailyHoroscopeMarkup,
  dailyHoroscopeTarget,
  injectDailyHoroscope,
} from "./daily-horoscope.mjs";
import { withStaticCacheHeaders } from "./routing.mjs";

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    if (url.pathname === "/api/horoscope") {
      return handleHoroscopeRequest(request, env, ctx);
    }

    const cleanLegacyUrl = cleanLegacyCommentUrl(request);

    if (cleanLegacyUrl) {
      return Response.redirect(cleanLegacyUrl, 301);
    }

    if (url.pathname === "/en") {
      return Response.redirect(new URL("/en/", url.origin).toString(), 301);
    }

    const response = await env.STATIC_CONTENT.fetch(request);

    const dailyTarget = dailyHoroscopeTarget(url.pathname);

    if (
      request.method === "GET" &&
      dailyTarget &&
      response.ok &&
      response.headers.get("content-type")?.includes("text/html")
    ) {
      return renderDailyHoroscopePage(
        request,
        response,
        dailyTarget,
        env,
        ctx,
      );
    }

    return withStaticCacheHeaders(response, url.pathname);
  },
};

async function renderDailyHoroscopePage(
  request,
  staticResponse,
  target,
  env,
  ctx,
) {
  const horoscopeUrl = new URL("/api/horoscope", request.url);
  horoscopeUrl.searchParams.set("locale", target.locale);
  const horoscopeResponse = await handleHoroscopeRequest(
    new Request(horoscopeUrl.toString()),
    env,
    ctx,
  );

  if (!horoscopeResponse.ok) {
    return staticResponse;
  }

  const payload = await horoscopeResponse.json();
  const sign = payload.signs_list?.find((entry) => entry.id === target.signId);

  if (!sign) {
    return staticResponse;
  }

  const html = injectDailyHoroscope(
    await staticResponse.text(),
    dailyHoroscopeMarkup(sign, target.locale),
  );
  const headers = new Headers(staticResponse.headers);
  headers.delete("content-length");
  headers.delete("etag");
  headers.set("cache-control", "public, max-age=300, s-maxage=21600");

  return new Response(html, {
    headers,
    status: staticResponse.status,
    statusText: staticResponse.statusText,
  });
}
