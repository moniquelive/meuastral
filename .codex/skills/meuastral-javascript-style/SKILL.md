---
name: meuastral-javascript-style
description: Use when editing JavaScript in the MeuAstral repo, including Cloudflare Worker code, browser bootstrap scripts, build scripts, Node tests, request routing, caching, API provider logic, or small frontend behavior.
---

# MeuAstral JavaScript Style

Apply these preferences when touching JavaScript in this project.

## General Style

- Keep JavaScript direct and behavior-oriented; avoid abstractions for one-off routing, DOM, or API glue.
- Prefer small pure helpers when they clarify Worker behavior, normalize provider data, or create useful test seams.
- Use modern JavaScript syntax with 2-space indentation.
- Prefer `const` by default, `let` for reassignment, and avoid `var`.
- Prefer early returns over deeply nested branches.
- Use built-in browser, Worker, and Node APIs before adding optional dependencies.

## MeuAstral Boundaries

- Keep provider secrets in the Cloudflare Worker; never expose API keys through Elm flags, bootstrap scripts, static HTML, or browser requests to third-party APIs.
- Keep `src/bootstrap.js` small: read browser/runtime state, pass Elm flags, and wire ports.
- Keep Worker routing explicit: handle API routes first, then static assets, then SPA fallback.
- Keep caching conservative for dynamic API responses; cache normalized public horoscope data by locale/date, not user-specific data.
- Preserve the existing AdSense publisher ID and account-related behavior unless the user explicitly asks otherwise.

## Tests And Commands

- Prefer `node:test` and `node:assert/strict` for small Worker/build/helper test suites.
- Test behavior over snapshots: request routing, locale parsing, provider selection, cache decisions, normalized response shapes, and controlled error responses.
- Use repo-local tasks first, especially `mise run test`, `mise run build`, and `mise run ci` when available.
