# Repository Guidelines

## Project Structure & Module Organization
- `src/` contains all Elm modules (`Main.elm`, `AscentMasters.elm`, `Ports.elm`) plus supporting assets such as `main.css`, `datepicker.css`, and `zodiac.css`. Keep feature-specific helpers in their own `ModuleName.elm` files to match Elm’s module-per-file convention.
- `src/index.js` is the JavaScript entry that boots the Elm app; update ports or service worker wiring there.
- `public/` hosts static assets (`index.html`, icons, manifest). Avoid importing from `public/` directly—drop files there when they must bypass Elm’s module graph.
- `tests/` holds Elm test modules (currently `AscentMastersTests.elm`). Mirror source filenames with a `Tests` suffix for quick discovery.

## Build, Test, and Development Commands
- `mise install` – installs the pinned Node 16 runtime from `mise.toml`, ensuring Elm tooling works.
- `npm install` – pulls `create-elm-app`/`wrangler` into `node_modules`; run once per clone (CI can run `npm ci` for clean installs).
- `npm run start` (or `./dev.sh` to skip auto-opening a browser) – wraps `elm-app start` with hot reload and pins `ELM_HOME=.elm-home` so Elm caches live in-repo.
- `npm run build` – emits the optimized bundle in `build/`, shares the same `ELM_HOME` setting, adds `NODE_OPTIONS=--openssl-legacy-provider`, and is the script executed by Cloudflare.
- `npm test` – runs `elm-app test` once in CI mode so it exits immediately; use `ELM_HOME=.elm-home elm-app test --watch` when you need interactive reruns.
 - Always run `npm run build` and `npm test` before returning results to the user, and report any failures.

## Coding Style & Naming Conventions
- Format Elm files with `elm-format` before committing; it enforces 4-space indentation, trailing newline, and alphabetical import grouping.
- Use PascalCase for module names (`CosmicRay.elm`) and snake_case for functions/values, matching existing modules like `AscentMasters.elm`.
- Keep CSS modules scoped and import them via `src/index.js`; name selectors with BEM-like clarity (`.chart__axis-label`).
- Prefer pure functions and explicit type annotations on public functions, especially when exposing helpers via `Ports.elm`.

## Testing Guidelines
- Tests rely on `elm-explorations/test`; place new suites under `tests/ModuleNameTests.elm` and expose a top-level `all` value for aggregation.
- Aim to cover every `AscentMasters.CosmicRay` branch: validate parsing, formatting, and date handling with `Date.fromCalendarDate`.
- Run `elm-app test` locally and in CI before pushing; failures print descriptive diffs for `Expect.equal`.

## Commit & Pull Request Guidelines
- Follow the existing conventional style (`fix: upgrade elm-charts`, `chore: format`). Use a short type prefix, then a concise subject describing the change.
- Rebase or merge latest `main` before opening a PR, and include: a summary of functional changes, test evidence (`elm-app test` output), and screenshots when UI changes the charts, date picker, or zodiac styling.
- Reference tracking issues in the PR body and note any configuration updates (`elmapp.config.js`, `mise.toml`) so reviewers can verify deployments.

## Cloudflare Worker Deployment
- Install JS dependencies via `npm install` (CI can call `npm ci` first); this makes the local `elm-app` executable available for all scripts.
- Build assets with `npm run build`; the script already exports `ELM_HOME=.elm-home` and `NODE_OPTIONS=--openssl-legacy-provider` so Elm caches stay inside the repo and Webpack remains compatible with Node 20+, and the worker consumes the generated `build/` directory via the `STATIC_CONTENT` binding configured in `wrangler.toml`.
- Preview the worker locally with `npm run dev:worker`, which stitches the Worker runtime with the built static assets so you can test SPA routing.
- Deploy via `npm run deploy`. Populate `account_id`, `route`, and env-specific secrets in `wrangler.toml` (or `wrangler.toml` environments) before shipping; the default `workers_dev = true` preview remains available for smoke tests.
