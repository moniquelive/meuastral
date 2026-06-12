import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { redirectPathForHomeLocale } from "../../worker/routing.mjs";

describe("Worker localized routing", () => {
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
});
