# Repository Guidelines

## Project Structure & Module Organization
- `src/` contains all Elm modules (`Main.elm`, `AscentMasters.elm`, `Ports.elm`) plus supporting assets such as `main.css`, `datepicker.css`, and `zodiac.css`. Keep feature-specific helpers in their own `ModuleName.elm` files to match Elm’s module-per-file convention.
- `src/bootstrap.js` is the JavaScript bootstrap that wires localStorage and Elm ports after `elm.js` loads.
- `index.html` is the app shell template copied into `build/`; `public/` hosts passthrough static assets (icons, manifest, images).
- `tests/` holds Elm test modules (currently `AscentMastersTests.elm`). Mirror source filenames with a `Tests` suffix for quick discovery.

## Build, Test, and Development Commands
- `mise install` – installs the pinned Node 20 runtime from `mise.toml` so Wrangler and Elm tooling resolve consistently.
- `npm install` – installs the local CLI dependencies (`elm`, `elm-test`, `wrangler`) used by all scripts; run once per clone (CI can use `npm ci`).
- `npm run start` (or `./dev.sh`) – runs `wrangler dev` with `ELM_HOME=.elm-home`; Wrangler executes the configured custom build before serving assets.
- `npm run build` – runs `scripts/build.mjs`, which rebuilds `build/`, copies static assets/CSS/bootstrap files, and compiles `src/Main.elm` to `build/elm.js` with `--optimize`.
- `npm test` – runs `elm-test` once in CI mode so it exits immediately; use `npm run test:watch` for local reruns.
 - Always run `npm run build` and `npm test` before returning results to the user, and report any failures.

## Coding Style & Naming Conventions
- Format Elm files with `elm-format` before committing; it enforces 4-space indentation, trailing newline, and alphabetical import grouping.
- Use PascalCase for module names (`CosmicRay.elm`) and snake_case for functions/values, matching existing modules like `AscentMasters.elm`.
- Keep CSS modules scoped and load them through `index.html`; name selectors with BEM-like clarity (`.chart__axis-label`).
- Prefer pure functions and explicit type annotations on public functions, especially when exposing helpers via `Ports.elm`.

## Testing Guidelines
- Tests rely on `elm-explorations/test`; place new suites under `tests/ModuleNameTests.elm` and expose a top-level `all` value for aggregation.
- Aim to cover every `AscentMasters.CosmicRay` branch: validate parsing, formatting, and date handling with `Date.fromCalendarDate`.
- Run `npm test` locally and in CI before pushing; failures print descriptive diffs for `Expect.equal`.

## Commit & Pull Request Guidelines
- Follow the existing conventional style (`fix: upgrade elm-charts`, `chore: format`). Use a short type prefix, then a concise subject describing the change.
- Rebase or merge latest `main` before opening a PR, and include: a summary of functional changes, test evidence (`npm test` output), and screenshots when UI changes the charts, date picker, or zodiac styling.
- Reference tracking issues in the PR body and note any configuration updates (`scripts/build.mjs`, `wrangler.toml`, `mise.toml`) so reviewers can verify deployments.

## Cloudflare Worker Deployment
- Install JS dependencies via `npm install` (CI can call `npm ci` first); this makes local `elm`, `elm-test`, and `wrangler` binaries available for all scripts.
- Build assets with `npm run build`; the script keeps Elm caches inside `.elm-home`, compiles optimized Elm output, and writes the deployable static bundle consumed by the worker via `STATIC_CONTENT`.
- Preview the worker locally with `npm run dev:worker`, which stitches the Worker runtime with the built static assets so you can test SPA routing.
- Deploy via `npm run deploy`. Populate `account_id`, `route`, and env-specific secrets in `wrangler.toml` (or `wrangler.toml` environments) before shipping; the default `workers_dev = true` preview remains available for smoke tests.
