import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { describe, it } from "node:test";

const headersFile = await readFile(
  new URL("../../public/_headers", import.meta.url),
  "utf8",
);
const wranglerConfig = await readFile(
  new URL("../../wrangler.toml", import.meta.url),
  "utf8",
);

describe("Workers Static Assets routing", () => {
  it("invokes code only for canonical pages and the horoscope API", () => {
    assert.doesNotMatch(wranglerConfig, /run_worker_first\s*=\s*true/);

    for (const pattern of [
      '"/"',
      '"/*/"',
      '"/en"',
      '"/api/horoscope"',
    ]) {
      assert.match(wranglerConfig, new RegExp(escapeRegex(pattern)));
    }

    assert.doesNotMatch(wranglerConfig, /"\/\*"/);
    assert.doesNotMatch(wranglerConfig, /"\/horoscopo\/\*"/);
    assert.doesNotMatch(wranglerConfig, /"\/en\/horoscope\/\*"/);
  });
});

describe("Workers Static Assets cache policy", () => {
  it("caches fingerprinted application assets immutably", () => {
    for (const pattern of [
      "/app.:app_hash",
      "/elm.:elm_hash",
      "/bootstrap.:bootstrap_hash",
    ]) {
      assert.match(
        headersFile,
        new RegExp(
          `${escapeRegex(pattern)}\\n  Cache-Control: public, max-age=31536000, immutable`,
        ),
      );
    }
  });

  it("revalidates non-fingerprinted images and manifests daily", () => {
    for (const extension of ["avif", "ico", "json", "png", "webp"]) {
      assert.match(
        headersFile,
        new RegExp(
          `${escapeRegex(`/*.${extension}`)}\\n  Cache-Control: public, max-age=86400, stale-while-revalidate=604800`,
        ),
      );
    }
  });

  it("leaves generated HTML and XML on Cloudflare's revalidation policy", () => {
    assert.doesNotMatch(headersFile, /\/\*\.(?:html|xml)/);
  });
});

function escapeRegex(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}
