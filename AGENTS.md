# Repository Guidelines

## Project Structure & Module Organization
- `src/` contains all Elm modules (`Main.elm`, `AscentMasters.elm`, `Ports.elm`) plus supporting assets such as `main.css`, `datepicker.css`, and `zodiac.css`. Keep feature-specific helpers in their own `ModuleName.elm` files to match Elm’s module-per-file convention.
- `src/bootstrap.js` is the JavaScript bootstrap that wires localStorage and Elm ports after `elm.js` loads.
- `config.yaml`, `content/`, `data/`, and `themes/meuastral/` define the Hugo-generated site shell, localized content pages, metadata, sitemap, and robots output.
- `public/` hosts passthrough static assets (icons, manifest, images, `ads.txt`) copied into `build/`.
- `tests/` holds Elm test modules (currently `AscentMastersTests.elm`). Mirror source filenames with a `Tests` suffix for quick discovery.

## Build, Test, and Development Commands
- `mise install` – installs the pinned Node and Hugo runtimes from `mise.toml` so Wrangler, Hugo, and Elm tooling resolve consistently.
- `mise run install` – installs local CLI dependencies (`elm`, `elm-test`, `wrangler`) with `npm ci`.
- `mise run dev` – runs `wrangler dev` with `ELM_HOME=.elm-home`; Wrangler executes the configured custom build before serving assets.
- `mise run build` – runs `scripts/build.mjs`, which rebuilds `build/`, runs Hugo, writes the root sitemap, copies static assets/CSS/bootstrap files, and compiles `src/Main.elm` to `build/elm.js` with `--optimize`.
- `mise run test` – runs Elm and Worker tests; use `npm run test:watch` for local Elm reruns.
- `mise run ci` – runs the test and production build tasks; prefer this before commits and PRs.
- Always run `mise run build` and `mise run test` before returning results to the user, and report any failures.

## Tooling (Mise Preferred)
- Run development tools through `mise` when a task exists.
- Prefer `mise run <task>` over direct `npm` commands for repeated repo workflows.
- Use one-off commands directly only when there is no matching `mise.toml` task.
- Keep local and CI workflows aligned by adding or updating `mise.toml` tasks when a repeated command is needed.
- Keep active CLI tools pinned in `mise.toml`; this project currently uses Hugo, `elm`, `elm-format`, `elm-test`, and `wrangler` directly rather than the older `elm-app` wrapper referenced in historical README text.

## Coding Style & Naming Conventions
- Format Elm files with `elm-format` before committing; it enforces 4-space indentation, trailing newline, and alphabetical import grouping.
- Use PascalCase for module names (`CosmicRay.elm`) and snake_case for functions/values, matching existing modules like `AscentMasters.elm`.
- Keep CSS modules scoped and load them through Hugo templates; name selectors with BEM-like clarity (`.chart__axis-label`).
- Prefer pure functions and explicit type annotations on public functions, especially when exposing helpers via `Ports.elm`.

## Testing Guidelines
- Tests rely on `elm-explorations/test`; place new suites under `tests/ModuleNameTests.elm` and expose a top-level `all` value for aggregation.
- Aim to cover every `AscentMasters.CosmicRay` branch: validate parsing, formatting, and date handling with `Date.fromCalendarDate`.
- Run `mise run test` locally and in CI before pushing; failures print descriptive diffs for `Expect.equal`.

## Commit & Pull Request Guidelines
- Follow the existing conventional style (`fix: upgrade elm-charts`, `chore: format`). Use a short type prefix, then a concise subject describing the change.
- Rebase or merge latest `main` before opening a PR, and include: a summary of functional changes, test evidence (`npm test` output), and screenshots when UI changes the charts, date picker, or zodiac styling.
- Reference tracking issues in the PR body and note any configuration updates (`scripts/build.mjs`, `wrangler.toml`, `mise.toml`) so reviewers can verify deployments.

## Cloudflare Worker Deployment
- Install JS dependencies via `mise run install`; this makes local `elm`, `elm-test`, and `wrangler` binaries available for all scripts.
- Build assets with `mise run build`; the script keeps Elm caches inside `.elm-home`, compiles optimized Elm output, and writes the deployable static bundle consumed by the worker via `STATIC_CONTENT`.
- Preview the worker locally with `mise run dev`, which stitches the Worker runtime with the built static assets so you can test SPA routing.
- Deploy via `npm run deploy`. Populate `account_id`, `route`, and env-specific secrets in `wrangler.toml` (or `wrangler.toml` environments) before shipping; the default `workers_dev = true` preview remains available for smoke tests.
