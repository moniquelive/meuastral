import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  cleanLegacyCommentUrl,
  dailyHoroscopeMarkup,
  dailyHoroscopeTarget,
  injectDailyHoroscope,
} from "../../worker/daily-horoscope.mjs";

describe("Daily horoscope pages", () => {
  it("maps localized sign routes to provider IDs", () => {
    assert.deepEqual(dailyHoroscopeTarget("/horoscopo/touro/"), {
      locale: "pt-BR",
      signId: "taurus",
    });
    assert.deepEqual(dailyHoroscopeTarget("/en/horoscope/scorpio/"), {
      locale: "en-US",
      signId: "scorpio",
    });
    assert.equal(dailyHoroscopeTarget("/guias/horoscopo/"), null);
  });

  it("renders localized, escaped, date-specific daily content", () => {
    const markup = dailyHoroscopeMarkup(
      {
        name: "Touro",
        resume: "Escolha <calma> & clareza.",
      },
      "pt-BR",
      new Date("2026-07-10T15:00:00Z"),
    );

    assert.match(markup, /Horóscopo de Touro hoje — 10 de julho de 2026/);
    assert.match(markup, /Escolha &lt;calma&gt; &amp; clareza\./);
  });

  it("replaces only the crawlable daily-reading placeholder", () => {
    const html = [
      "<main>",
      '<section class="daily-horoscope" data-daily-horoscope><p>Fallback</p></section>',
      "<section><p>Evergreen copy</p></section>",
      "</main>",
    ].join("");

    assert.equal(
      injectDailyHoroscope(html, "<section data-daily-horoscope>Today</section>"),
      [
        "<main>",
        "<section data-daily-horoscope>Today</section>",
        "<section><p>Evergreen copy</p></section>",
        "</main>",
      ].join(""),
    );
  });

  it("redirects legacy Facebook comment URLs to the clean canonical", () => {
    assert.equal(
      cleanLegacyCommentUrl(
        new Request(
          "https://meuastral.com/?fb_comment_id=123&utm_source=archive",
        ),
      ),
      "https://meuastral.com/?utm_source=archive",
    );
    assert.equal(
      cleanLegacyCommentUrl(new Request("https://meuastral.com/horoscopo/")),
      null,
    );
  });
});
