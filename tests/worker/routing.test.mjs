import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  cacheControlForStaticPath,
  localePreferenceCookie,
  localePreferenceFromRequest,
  redirectPathForHomeLocale,
  withStaticCacheHeaders,
} from "../../worker/routing.mjs";

describe("Worker localized routing", () => {
  it("persists an explicit language switch and strips its query parameter", () => {
    assert.deepEqual(
      localePreferenceFromRequest(
        new Request("https://meuastral.com/?lang=pt-BR"),
      ),
      {
        cleanUrl: "https://meuastral.com/",
        locale: "pt-BR",
        source: "query",
      },
    );
    assert.equal(
      localePreferenceCookie("pt-BR"),
      "meuastral-locale=pt-BR; Path=/; Max-Age=31536000; SameSite=Lax; Secure",
    );
  });

  it("uses a stored supported language and ignores unsupported values", () => {
    assert.deepEqual(
      localePreferenceFromRequest(
        new Request("https://meuastral.com/", {
          headers: { cookie: "theme=light; meuastral-locale=en-US" },
        }),
      ),
      { cleanUrl: null, locale: "en-US", source: "cookie" },
    );
    assert.equal(
      localePreferenceFromRequest(
        new Request("https://meuastral.com/?lang=fr-FR", {
          headers: { cookie: "meuastral-locale=fr-FR" },
        }),
      ),
      null,
    );
  });

  it("redirects English browser home requests to the English URL", () => {
    assert.equal(
      redirectPathForHomeLocale(new Request("https://meuastral.com/"), "en-US"),
      "/en/",
    );
    assert.equal(
      redirectPathForHomeLocale(
        new Request("https://meuastral.com/index.html", { method: "HEAD" }),
        "en-US",
      ),
      "/en/",
    );
  });

  it("keeps Portuguese, non-home, and unsafe-method requests on their current path", () => {
    assert.equal(
      redirectPathForHomeLocale(new Request("https://meuastral.com/"), "pt-BR"),
      null,
    );
    assert.equal(
      redirectPathForHomeLocale(new Request("https://meuastral.com/en/"), "en-US"),
      null,
    );
    assert.equal(
      redirectPathForHomeLocale(
        new Request("https://meuastral.com/", { method: "POST" }),
        "en-US",
      ),
      null,
    );
  });

  it("revalidates image assets whose names are not fingerprinted", () => {
    assert.equal(
      cacheControlForStaticPath("/5-hilarion.webp"),
      "public, max-age=86400, stale-while-revalidate=604800",
    );
    assert.equal(
      cacheControlForStaticPath("/logo.png"),
      "public, max-age=86400, stale-while-revalidate=604800",
    );
  });

  it("uses long immutable cache lifetimes for fingerprinted app assets", () => {
    assert.equal(
      cacheControlForStaticPath("/elm.1234abcd99.js"),
      "public, max-age=31536000, immutable",
    );
    assert.equal(
      cacheControlForStaticPath("/app.1234abcd99.css"),
      "public, max-age=31536000, immutable",
    );
    assert.equal(
      cacheControlForStaticPath("/logo.1234abcd99.webp"),
      "public, max-age=31536000, immutable",
    );
  });

  it("uses revalidating cache lifetimes for non-fingerprinted static app assets", () => {
    assert.equal(
      cacheControlForStaticPath("/bootstrap.js"),
      "public, max-age=86400, stale-while-revalidate=604800",
    );
    assert.equal(
      cacheControlForStaticPath("/manifest.json"),
      "public, max-age=86400, stale-while-revalidate=604800",
    );
  });

  it("does not add static cache headers to generated HTML or sitemap files", () => {
    assert.equal(cacheControlForStaticPath("/en/"), null);
    assert.equal(cacheControlForStaticPath("/sitemap.xml"), null);
  });

  it("adds cache headers only to successful static asset responses", async () => {
    const okResponse = withStaticCacheHeaders(
      new Response("image", { status: 200 }),
      "/5-hilarion.webp",
    );

    assert.equal(
      okResponse.headers.get("cache-control"),
      "public, max-age=86400, stale-while-revalidate=604800",
    );
    assert.equal(await okResponse.text(), "image");

    const missingResponse = withStaticCacheHeaders(
      new Response("missing", { status: 404 }),
      "/5-hilarion.webp",
    );

    assert.equal(missingResponse.headers.get("cache-control"), null);
    assert.equal(await missingResponse.text(), "missing");
  });
});
