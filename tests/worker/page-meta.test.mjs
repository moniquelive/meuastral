import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { describe, it } from "node:test";

import {
  injectPageMetadata,
  localeForPath,
  redirectPathForHomeLocale,
} from "../../worker/page-meta.mjs";

const INDEX_HTML = readFileSync(new URL("../../index.html", import.meta.url), "utf8");

describe("Worker page metadata", () => {
  it("maps explicit home paths to stable SEO locales", () => {
    assert.equal(localeForPath("/"), "pt-BR");
    assert.equal(localeForPath("/index.html"), "pt-BR");
    assert.equal(localeForPath("/en/"), "en-US");
    assert.equal(localeForPath("/en/index.html"), "en-US");
    assert.equal(localeForPath("/sobre/"), null);
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

  it("keeps Portuguese and non-home requests on their current path", () => {
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

  it("renders Portuguese canonical, social, and hreflang metadata", () => {
    const html = injectPageMetadata(INDEX_HTML, "pt-BR");

    assert.match(html, /<html[^>]+lang="pt-BR"/);
    assert.match(html, /<link rel="canonical" href="https:\/\/meuastral\.com\/" \/>/);
    assert.match(html, /hreflang="pt-BR" href="https:\/\/meuastral\.com\/"/);
    assert.match(html, /hreflang="en-US" href="https:\/\/meuastral\.com\/en\/"/);
    assert.match(html, /property="og:locale" content="pt_BR"/);
    assert.match(html, /property="og:locale:alternate" content="en_US"/);
    assert.match(html, /property="og:url" content="https:\/\/meuastral\.com\/"/);
    assert.match(html, /name="twitter:card" content="summary_large_image"/);
    assert.match(html, /name="google-adsense-account" content="ca-pub-7232537493483974"/);
    assert.match(html, /"inLanguage": "pt-BR"/);
    assert.match(html, /window\.__MEUASTRAL_LOCALE__ = "pt-BR"/);
    assert.match(html, /MeuAstral: horoscopo, biorritmo e mestres ascensionados/);
  });

  it("renders English canonical, social, and hreflang metadata", () => {
    const html = injectPageMetadata(INDEX_HTML, "en-US");

    assert.match(html, /<html[^>]+lang="en-US"/);
    assert.match(html, /<link rel="canonical" href="https:\/\/meuastral\.com\/en\/" \/>/);
    assert.match(html, /hreflang="pt-BR" href="https:\/\/meuastral\.com\/"/);
    assert.match(html, /hreflang="en-US" href="https:\/\/meuastral\.com\/en\/"/);
    assert.match(html, /property="og:locale" content="en_US"/);
    assert.match(html, /property="og:locale:alternate" content="pt_BR"/);
    assert.match(html, /property="og:url" content="https:\/\/meuastral\.com\/en\/"/);
    assert.match(html, /property="og:title" content="MeuAstral: daily horoscope, biorhythm, and ascended masters"/);
    assert.match(html, /name="twitter:title" content="MeuAstral: daily horoscope, biorhythm, and ascended masters"/);
    assert.match(html, /"inLanguage": "en-US"/);
    assert.match(html, /window\.__MEUASTRAL_LOCALE__ = "en-US"/);
    assert.match(html, /MeuAstral offers a free self-knowledge reading/);
  });
});
