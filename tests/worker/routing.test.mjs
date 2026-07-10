import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  cacheControlForStaticPath,
  withStaticCacheHeaders,
} from "../../worker/routing.mjs";

describe("Worker localized routing", () => {
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
